import 'package:flutter/foundation.dart' show compute;
import 'package:zephyr/main.dart';
import 'package:zephyr/page/comic_read/model/normal_comic_ep_info.dart';
import 'package:zephyr/service/download/download_chapter_isolate.dart';

/// 读取本地（已下载）章节的图片列表。
///
/// 下载记录读取与 `chapters` JSON 解析全部在 worker isolate 完成，UI 只拿
/// 目标章节的 docs（章节切换时每章调用一次）。
Future<NormalComicEpInfo> getPluginInfoFromLocal(
  String pluginId,
  String comicId,
  int epsId,
) {
  return compute(
    readLocalChapterInIsolate,
    LocalChapterReadTask(
      handle: database.db.handle,
      pluginId: pluginId,
      comicId: comicId,
      epsId: epsId,
    ),
  );
}
