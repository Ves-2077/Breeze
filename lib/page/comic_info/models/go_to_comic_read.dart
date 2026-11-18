import 'package:auto_route/auto_route.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/comic_info/method/get_plugin_detail.dart';
import 'package:zephyr/page/download/adapters/download_chapter_adapter.dart';
import 'package:zephyr/page/download/adapters/download_chapter_matcher.dart';
import 'package:zephyr/page/download/models/download_chapter.dart';
import 'package:zephyr/page/download/models/unified_comic_download.dart';
import 'package:zephyr/service/download/models/download_task_json.dart';
import 'package:zephyr/page/comic_read/type/chapter_extern.dart';
import 'package:zephyr/type/enum.dart';
import 'package:zephyr/config/router/router.gr.dart' show ComicReadRoute;

import 'package:zephyr/page/comic_info/models/read_launch_adapter.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/widgets/toast.dart';

Future<void> goToComicRead(
  BuildContext context,
  String comicId,
  ComicEntryType type,
  dynamic allInfo,
  String from,
) async {
  try {
    await _goToComicRead(context, comicId, type, allInfo, from);
  } catch (e) {
    // 插件详情数据异常时不要让点击无反应，也不要冒到 FlutterError。
    logger.e(e);
    showErrorToast(e.toString());
  }
}

Future<void> _goToComicRead(
  BuildContext context,
  String comicId,
  ComicEntryType type,
  dynamic allInfo,
  String from,
) async {
  final isDownload =
      type == ComicEntryType.download ||
      type == ComicEntryType.historyAndDownload;
  final historyForChapter = await database.histories.getByKey('$from:$comicId');
  final chapter = _resolveChapter(allInfo, from, historyForChapter);

  // 在线入口统一查库：目标章节已下载则直接读本地，不再看来源 type。
  dynamic readInfo = allInfo;
  var readIsDownload = isDownload;
  var readComicId = '';
  DownloadChapter? readChapter = chapter;
  var readEpsCount = 0;
  if (!isDownload && chapter != null) {
    final record = await database.downloads.getByKey(
      buildDownloadTaskKey(from, comicId),
    );
    final local = record == null
        ? null
        : _findStoredChapter(record, chapter.id) ??
              _findStoredChapter(record, chapter.effectiveRequestId);
    if (local != null && record != null) {
      readInfo = record;
      readIsDownload = true;
      readComicId = record.comicId;
      readChapter = local;
      readEpsCount = resolveStoredDownloadChapters(record).length;
    }
  }
  if (!readIsDownload) {
    readEpsCount = resolveReadEpsCount(allInfo, from, isDownload: false);
    readComicId = resolveReadComicId(allInfo, from, isDownload: false);
  } else if (readInfo == allInfo) {
    readEpsCount = resolveReadEpsCount(allInfo, from, isDownload: true);
    readComicId = resolveReadComicId(allInfo, from, isDownload: true);
  }
  if (!context.mounted) return;
  final hasHistory = context.read<StringSelectCubit>().state.isNotEmpty;

  final typeVal = hasHistory
      ? (readIsDownload
            ? ComicEntryType.historyAndDownload
            : ComicEntryType.history)
      : (readIsDownload ? ComicEntryType.download : ComicEntryType.normal);
  final orderVal = readChapter?.order ?? _resolveInitialOrder(readInfo, from);

  context.pushRoute(
    ComicReadRoute(
      comicId: readComicId,
      order: orderVal,
      chapterId: readChapter?.id ?? '',
      requestId: readChapter?.effectiveRequestId ?? '',
      storageChapterId: readChapter?.storageId ?? '',
      logicalKey: readChapter?.id ?? '',
      chapterExtern: ChapterExtern.from(
        readChapter?.extern ?? const <String, dynamic>{},
      ),
      epsNumber: readEpsCount,
      from: from,
      type: typeVal,
      comicInfo: readInfo,
      stringSelectCubit: context.read<StringSelectCubit>(),
    ),
  );
}

/// 在本地下载记录里按章节 key（id / requestId）查找章节。
DownloadChapter? _findStoredChapter(
  UnifiedComicDownload record,
  String chapterKey,
) {
  final key = chapterKey.trim();
  if (key.isEmpty) return null;
  const matcher = DownloadChapterMatcher();
  try {
    for (final candidate in resolveDownloadChapters(record)) {
      if (matcher.matches(candidate, key)) return candidate;
    }
  } catch (_) {
    return null;
  }
  return null;
}

DownloadChapter? _resolveChapter(
  dynamic allInfo,
  String from,
  UnifiedComicHistory? history,
) {
  final chapterRefs = resolveUnifiedComicChapters(allInfo, from);
  if (chapterRefs.isEmpty) {
    return null;
  }

  const adapter = DownloadChapterAdapter();
  const matcher = DownloadChapterMatcher();
  final chapters = chapterRefs.map(adapter.fromChapterRef).toList();

  if (history != null) {
    // 优先按 history.chapterId 匹配（可能是 logicalKey / id / requestId）。
    final chapterId = (history.chapterId).trim();
    if (chapterId.isNotEmpty) {
      final matched = matcher.find(chapters, chapterId);
      if (matched != null) {
        return matched;
      }
    }

    // 再按 history.chapterOrder 匹配。
    if (history.chapterOrder > 0) {
      final matched = matcher.findByOrder(chapters, history.chapterOrder);
      if (matched != null) {
        return matched;
      }
    }

    // 兼容老数据：chapterOrder 曾经被当 chapterId 用。
    final matched = matcher.find(chapters, history.chapterOrder.toString());
    if (matched != null) {
      return matched;
    }
  }

  return chapters.first;
}

int _resolveInitialOrder(dynamic allInfo, String from) {
  final chapters = resolveUnifiedComicChapters(allInfo, from);
  if (chapters.isEmpty) {
    return 1;
  }
  return chapters.first.order;
}
