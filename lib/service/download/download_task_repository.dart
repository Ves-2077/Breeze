import 'dart:convert';

import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/download/adapters/download_chapter_matcher.dart';
import 'package:zephyr/page/download/models/download_chapter.dart';
import 'package:zephyr/page/download/models/unified_comic_download.dart';
import 'package:zephyr/service/download/models/download_task_json.dart';

/// DownloadTask 的唯一读写入口。
///
/// 任务 payload 和检查点都存放在 [DownloadTask.dbTaskInfoStr] 对应的
/// 版本化 JSON 中。这样旧任务仍可读取，新任务可以在进程退出后恢复章节级
/// 进度。所有读写都经过 `database.downloadTasks`（异步 SQLite）。
class DownloadTaskRepository {
  const DownloadTaskRepository();

  /// taskKey -> DownloadTask.id 缓存。taskKey 一旦写入不可变；
  /// 命中时仍校验实体存在且 key 一致，外部直接删库导致的过期项会被清掉。
  static final Map<String, int> _taskKeyCache = <String, int>{};

  /// 同 taskKey 后台写的串行链。后台写是 fire-and-forget，必须保证
  /// 同一任务的写按序落库，状态迁移前调 [flushTaskWrites] 排空。
  static final Map<String, Future<void>> _pendingTaskWrites =
      <String, Future<void>>{};

  Future<List<DownloadTask>> getAll({bool incompleteOnly = false}) {
    return incompleteOnly
        ? database.downloadTasks.listIncomplete()
        : database.downloadTasks.getAll();
  }

  Future<DownloadTask?> findByTaskKey(
    String taskKey, {
    bool incompleteOnly = false,
  }) async {
    DownloadTask? result;
    final normalizedKey = taskKey.trim();
    if (normalizedKey.isNotEmpty) {
      final cachedId = _taskKeyCache[normalizedKey];
      if (cachedId != null) {
        final cached = await database.downloadTasks.getById(cachedId);
        if (cached != null &&
            (!incompleteOnly || !cached.isCompleted) &&
            _taskKeyOf(cached) == normalizedKey) {
          return cached;
        }
        _taskKeyCache.remove(normalizedKey);
      }
      for (final task in await getAll(incompleteOnly: incompleteOnly)) {
        if (_taskKeyOf(task) == normalizedKey) {
          result = task;
          _taskKeyCache[normalizedKey] = task.id;
          break;
        }
      }
    }
    return result;
  }

  Future<DownloadTask?> findByPayload({
    required String from,
    required String comicId,
    bool incompleteOnly = false,
  }) {
    return findByTaskKey(
      buildDownloadTaskKey(from, comicId),
      incompleteOnly: incompleteOnly,
    );
  }

  /// 查找本漫画的本地下载记录，没有返回 null。
  Future<UnifiedComicDownload?> findDownloadRecord(
    String from,
    String comicId,
  ) async {
    try {
      return await database.downloads.getByKey(
        buildDownloadTaskKey(from, comicId),
      );
    } catch (_) {
      return null;
    }
  }

  /// 查找某本漫画的未完成任务（章节级任务也包含）。
  ///
  /// [findByPayload] 用的是漫画级 taskKey，而实际下载任务是章节级 key，
  /// 不能用来判断“这本漫画是否还有下载在跑”。
  Future<List<DownloadTask>> findIncompleteByComic({
    required String from,
    required String comicId,
  }) async {
    final normalizedFrom = from.trim();
    final normalizedComicId = comicId.trim();
    if (normalizedFrom.isEmpty || normalizedComicId.isEmpty) {
      return const <DownloadTask>[];
    }
    final tasks = await database.downloadTasks.listByComicId(normalizedComicId);
    return tasks.where((task) {
      if (task.isCompleted && !task.isDownloading) return false;
      if (task.comicId.trim() != normalizedComicId) return false;
      final payload = readPayload(task);
      if (payload == null) return true;
      return payload.from.trim() == normalizedFrom;
    }).toList();
  }

  /// 按章节 key 查找本地已下载章节，找不到返回 null。
  ///
  /// [chapterKey] 可以是逻辑 id / requestId / order 字符串中的任意一个。
  /// 阅读入口统一用它判断“该章是否已下载”，命中则直接读本地。
  Future<DownloadChapter?> findDownloadedChapter({
    required String from,
    required String comicId,
    required String chapterKey,
  }) async {
    final record = await findDownloadRecord(from, comicId);
    if (record == null || chapterKey.trim().isEmpty) return null;
    const matcher = DownloadChapterMatcher();
    try {
      for (final chapter in resolveDownloadChapters(record)) {
        if (matcher.matches(chapter, chapterKey.trim())) return chapter;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  /// 按章节查找未完成任务。章节 key 必须是逻辑身份
  ///（logicalKey > chapterId > requestId，见 [downloadChapterKeyOfRef]）。
  Future<DownloadTask?> findByChapterKey({
    required String from,
    required String comicId,
    required String chapterKey,
    bool incompleteOnly = false,
  }) {
    return findByTaskKey(
      buildDownloadChapterTaskKey(from, comicId, chapterKey),
      incompleteOnly: incompleteOnly,
    );
  }

  DownloadTaskJson? readPayload(DownloadTask task) {
    try {
      return task.taskInfo;
    } catch (error, stackTrace) {
      logger.e(
        '读取下载任务 payload 失败: taskId=${task.id}',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  Future<int> putPayload(
    DownloadTask task,
    DownloadTaskJson payload, {
    String? status,
    bool? isDownloading,
    bool? isCompleted,
  }) async {
    task
      ..taskInfo = payload
      ..comicId = payload.comicId
      ..comicName = payload.comicName;
    if (status != null) task.status = status;
    if (isDownloading != null) task.isDownloading = isDownloading;
    if (isCompleted != null) task.isCompleted = isCompleted;
    final id = await database.downloadTasks.put(task);
    _taskKeyCache[payload.taskKey] = id;
    return id;
  }

  Future<int> putState(
    DownloadTask task, {
    DownloadTaskJson? payload,
    String? status,
    bool? isDownloading,
    bool? isCompleted,
  }) async {
    if (payload != null) {
      task
        ..taskInfo = payload
        ..comicId = payload.comicId
        ..comicName = payload.comicName;
    }
    if (status != null) task.status = status;
    if (isDownloading != null) task.isDownloading = isDownloading;
    if (isCompleted != null) task.isCompleted = isCompleted;
    final id = await database.downloadTasks.put(task);
    if (payload != null) _taskKeyCache[payload.taskKey] = id;
    return id;
  }

  /// 后台写任务库（checkpoint / 状态同步等高频写）。
  ///
  /// 纯数据进、出：payload 在主线程拼好，以 JSON 字符串传入；写库时重新
  /// 读取实体后只覆盖传入字段，避免旧快照覆盖其他字段。同一 taskKey 的
  /// 写通过 [_pendingTaskWrites] 串行执行。
  Future<void> putTaskWriteBackground({
    required String taskKey,
    required int taskId,
    String? status,
    bool? isDownloading,
    bool? isCompleted,
    String? payloadJson,
  }) {
    final normalizedKey = taskKey.trim();
    final args = <String, dynamic>{'id': taskId};
    if (status != null) args['status'] = status;
    if (isDownloading != null) args['isDownloading'] = isDownloading;
    if (isCompleted != null) args['isCompleted'] = isCompleted;
    if (payloadJson != null) args['payloadJson'] = payloadJson;
    final prev = _pendingTaskWrites[normalizedKey] ?? Future.value();
    late final Future<void> next;
    next = prev.then((_) => _applyDownloadTaskWrite(args));
    _pendingTaskWrites[normalizedKey] = next;
    next.whenComplete(() {
      if (identical(_pendingTaskWrites[normalizedKey], next)) {
        _pendingTaskWrites.remove(normalizedKey);
      }
    });
    return next;
  }

  /// 排空指定任务的后台写。状态迁移（完成/失败/取消/重试/删除）前必须调，
  /// 否则在途的旧写可能覆盖新状态。
  Future<void> flushTaskWrites(String taskKey) {
    return _pendingTaskWrites[taskKey.trim()] ?? Future.value();
  }

  Future<void> resetInterruptedTasks() async {
    final interrupted = (await getAll(incompleteOnly: true))
        .where((task) => task.isDownloading)
        .toList();
    if (interrupted.isEmpty) return;

    for (final task in interrupted) {
      final payload = readPayload(task);
      task.isDownloading = false;
      if (payload != null) {
        task.taskInfo = payload.copyWith(
          stateCode: 'queued',
          phaseCode: 'resume',
          lastErrorCode: '',
          lastErrorMessage: '',
        );
      }
    }
    await database.downloadTasks.putMany(interrupted);
    logger.i('重置了 ${interrupted.length} 个中断的下载任务');
  }

  String _taskKeyOf(DownloadTask task) {
    final payload = readPayload(task);
    if (payload != null) return payload.taskKey;
    return task.comicId.trim();
  }
}

String downloadTaskKeyOf(DownloadTask task) {
  try {
    final payload = task.taskInfo;
    if (payload != null) return payload.taskKey;
  } catch (e, st) {
    logger.e(e, stackTrace: st);
    // 旧任务 payload 损坏时仍使用实体中的 comicId 作为最后回退。
  }
  return task.comicId.trim();
}

/// 执行单条任务写（纯数据进）。
///
/// 先按 id 重新读取实体，只覆盖传入字段；实体不存在（已被删）则跳过。
Future<void> _applyDownloadTaskWrite(Map<String, dynamic> args) async {
  final task = await database.downloadTasks.getById(args['id'] as int);
  if (task == null) return;
  task.status = (args['status'] as String?) ?? task.status;
  task.isDownloading = (args['isDownloading'] as bool?) ?? task.isDownloading;
  task.isCompleted = (args['isCompleted'] as bool?) ?? task.isCompleted;
  final payloadJson = args['payloadJson'] as String?;
  if (payloadJson != null) {
    task.taskInfo = DownloadTaskJson.fromJson(
      jsonDecode(payloadJson) as Map<String, dynamic>,
    );
  }
  await database.downloadTasks.put(task);
}
