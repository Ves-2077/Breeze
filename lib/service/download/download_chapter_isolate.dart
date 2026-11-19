import 'package:zephyr/database/database.dart';
import 'package:zephyr/database/query_isolate.dart';
import 'package:zephyr/page/comic_read/json/common_ep_info_json/common_ep_info_json.dart'
    show Doc;
import 'package:zephyr/page/comic_read/model/normal_comic_ep_info.dart';
import 'package:zephyr/page/download/adapters/download_chapter_matcher.dart';
import 'package:zephyr/page/download/models/download_chapter.dart';
import 'package:zephyr/page/download/models/unified_comic_download.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/util/rust_loader.dart';

/// 下载章节查找任务：在 worker isolate 内读库并解析 chapters JSON。
class DownloadChapterLookupTask {
  const DownloadChapterLookupTask({
    required this.handle,
    required this.downloadKey,
    this.chapterKeys = const <String>[],
    this.order,
    this.fallbackFirst = false,
    this.includeRecord = false,
  });

  final int handle;

  /// `'$source:$comicId'`。
  final String downloadKey;

  /// 依次尝试匹配的章节 key（id / requestId / ...）。
  final List<String> chapterKeys;

  /// chapterKeys 都未命中时按顺序匹配。
  final int? order;

  /// 全部未命中时回落到第一章。
  final bool fallbackFirst;

  /// 是否把完整下载记录（含 chapters/detailJson）一起返回给调用方。
  final bool includeRecord;
}

class DownloadChapterLookup {
  const DownloadChapterLookup({
    required this.chapter,
    required this.chapterCount,
    required this.record,
  });

  final DownloadChapter? chapter;
  final int chapterCount;

  /// 仅在 [DownloadChapterLookupTask.includeRecord] 且命中章节时返回。
  final UnifiedComicDownload? record;
}

/// 在 worker isolate 内完成「下载记录读取 + chapters JSON 解析 + 目标章节匹配」。
///
/// UI 侧只传 handle / key / 少量匹配参数，章节与图片的 JSON 解析不占 UI 线程。
Future<DownloadChapterLookup> lookupDownloadedChapterInIsolate(
  DownloadChapterLookupTask task,
) async {
  await initRustLib();
  markDbWorkerIsolate();
  final db = Database.fromHandle(task.handle);
  // includeRecord 时一次取整行（避免先读 chapters 再读整行）；否则只读 chapters，
  // 仅当 chapters 里没有图片时才补读 detailJson 兜底。
  final record = task.includeRecord
      ? await db.downloads.getByKey(task.downloadKey)
      : null;
  final chapters = record != null
      ? resolveDownloadChaptersFromJson(
          chaptersJson: record.chapters,
          detailJson: record.detailJson,
        )
      : await _resolveChaptersFromDb(db, task.downloadKey);
  const matcher = DownloadChapterMatcher();

  DownloadChapter? byKeys() {
    for (final key in task.chapterKeys) {
      final trimmed = key.trim();
      if (trimmed.isEmpty) continue;
      for (final chapter in chapters) {
        if (matcher.matches(chapter, trimmed)) return chapter;
      }
    }
    return null;
  }

  DownloadChapter? byOrder() =>
      task.order == null ? null : matcher.findByOrder(chapters, task.order!);

  var chapter = byKeys() ?? byOrder();
  if (chapter == null && task.fallbackFirst && chapters.isNotEmpty) {
    chapter = chapters.first;
  }

  return DownloadChapterLookup(
    chapter: chapter,
    chapterCount: chapters.length,
    record: chapter == null ? null : record,
  );
}

/// 只读 `chapters`，没有图片时再补读 `detailJson`（避免每次搬 240KB）。
Future<List<DownloadChapter>> _resolveChaptersFromDb(
  Database db,
  String key,
) async {
  final chaptersJson = await db.downloads.getChaptersJson(key);
  if (chaptersJson == null) return const <DownloadChapter>[];
  final chapters = resolveDownloadChaptersFromJson(
    chaptersJson: chaptersJson,
    detailJson: '',
  );
  if (chapters.any((chapter) => chapter.images.isNotEmpty)) return chapters;
  final detailJson = await db.downloads.getDetailJson(key);
  if (detailJson == null || detailJson.isEmpty) return chapters;
  final fallback = resolveDownloadChaptersFromJson(
    chaptersJson: '',
    detailJson: detailJson,
  );
  return fallback.isNotEmpty ? fallback : chapters;
}

/// 本地（已下载）章节读取任务：返回该章的图片列表，供阅读页直接使用。
class LocalChapterReadTask {
  const LocalChapterReadTask({
    required this.handle,
    required this.pluginId,
    required this.comicId,
    required this.epsId,
  });

  final int handle;
  final String pluginId;
  final String comicId;
  final int epsId;
}

/// 在 worker isolate 内把 `chapters` JSON 解析成目标章节的 `NormalComicEpInfo`。
///
/// 章节切换时每个章节都会调用；解析（含图片列表）全部在 worker 完成。
Future<NormalComicEpInfo> readLocalChapterInIsolate(
  LocalChapterReadTask task,
) async {
  await initRustLib();
  markDbWorkerIsolate();
  final db = Database.fromHandle(task.handle);
  final key = '${task.pluginId}:${task.comicId}';
  final chapters = await _resolveChaptersFromDb(db, key);
  if (chapters.isEmpty) {
    throw StateError('本地下载没有章节数据: $key');
  }

  const matcher = DownloadChapterMatcher();
  final targetId = task.epsId.toString();
  final chapter =
      matcher.findByOrder(chapters, task.epsId) ??
      matcher.find(chapters, targetId) ??
      chapters.first;

  final docs = chapter.images
      .map(
        (image) => Doc(
          originalName: image.name,
          path: image.path,
          fileServer: image.url,
          id: image.id.isNotEmpty
              ? image.id
              : (image.path.isNotEmpty ? image.path : image.name),
          storageChapterId: chapter.effectiveStorageId,
          extern: Map<String, dynamic>.from(image.extern),
        ),
      )
      .toList();

  return NormalComicEpInfo(
    length: docs.length,
    epPages: docs.length.toString(),
    docs: docs,
    epId: chapter.id,
    epName: chapter.displayName,
  );
}
