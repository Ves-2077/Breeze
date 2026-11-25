import 'package:zephyr/model/comic_info_meta.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/search_result/models/unified_plugin_search.dart';
import 'package:zephyr/util/json/json_sanitize.dart';
import 'package:zephyr/util/storage/path_util.dart';

import 'package:zephyr/widgets/comic_entry/models/unified_comic_list_item.dart';

UnifiedComicListItem unifiedComicFromPluginSearchItem(
  UnifiedPluginSearchItem item,
  String source,
) {
  return _requireUnifiedPluginItem(
    item.data,
    source: source,
    context: 'search:$source:${item.id}',
  );
}

UnifiedComicListItem unifiedComicFromPluginListMap(
  Map<String, dynamic> item, {
  required String source,
}) {
  return _requireUnifiedPluginItem(
    item,
    source: source,
    context: 'list:$source:${item['id']?.toString() ?? ''}',
  );
}

UnifiedComicListItem unifiedComicFromUnifiedFavorite(
  UnifiedComicFavorite comic,
) {
  return UnifiedComicListItem(
    source: comic.source,
    id: comic.comicId,
    title: comic.title,
    subtitle: '',
    finished: false,
    likesCount: 0,
    viewsCount: _viewCountFromTitleMeta(comic.titleMeta),
    updatedAt: comic.updatedAt.toIso8601String(),
    cover: _coverFromStored(comic.source, comic.comicId, comic.cover),
    metadata: _metadataFromTyped(comic.metadata),
    raw: _buildFavoriteRaw(comic),
    extern: const <String, dynamic>{},
  );
}

UnifiedComicListItem unifiedComicFromUnifiedHistory(UnifiedComicHistory comic) {
  return UnifiedComicListItem(
    source: comic.source,
    id: comic.comicId,
    title: comic.title,
    subtitle: comic.chapterTitle,
    finished: false,
    likesCount: 0,
    viewsCount: _viewCountFromTitleMeta(comic.titleMeta),
    updatedAt: comic.updatedAt.toIso8601String(),
    cover: _coverFromStored(comic.source, comic.comicId, comic.cover),
    metadata: _metadataFromTyped(comic.metadata),
    raw: _buildHistoryRaw(comic),
    extern: const <String, dynamic>{},
  );
}

UnifiedComicListItem unifiedComicFromUnifiedDownload(
  UnifiedComicDownload comic, {

  /// 书架只需要列表字段；`chapters` 里带全部图片信息，跳过可省大量解析。
  bool includeRaw = true,
}) {
  final cover = _coverFromStored(comic.source, comic.comicId, comic.cover);
  final extern = Map<String, dynamic>.from(cover.extern);
  return UnifiedComicListItem(
    source: comic.source,
    id: comic.comicId,
    title: comic.title,
    subtitle: '',
    finished: false,
    likesCount: comic.totalLikes,
    viewsCount: comic.totalViews,
    updatedAt: comic.updatedAt.toIso8601String(),
    cover: UnifiedComicCover(
      id: cover.id,
      url: cover.url,
      path: cover.path,
      extern: extern,
    ),
    metadata: _metadataFromTyped(comic.metadata),
    raw: includeRaw ? _buildDownloadRaw(comic) : const <String, dynamic>{},
    extern: const <String, dynamic>{},
  );
}

Map<String, dynamic> _buildFavoriteRaw(UnifiedComicFavorite comic) {
  return _buildBaseRaw(
    source: comic.source,
    comicId: comic.comicId,
    title: comic.title,
    description: comic.description,
    cover: comic.cover,
    creator: comic.creator,
    titleMeta: comic.titleMeta,
    metadata: comic.metadata,
    updatedAt: comic.updatedAt,
  );
}

Map<String, dynamic> _buildHistoryRaw(UnifiedComicHistory comic) {
  return {
    ..._buildBaseRaw(
      source: comic.source,
      comicId: comic.comicId,
      title: comic.title,
      description: comic.description,
      cover: comic.cover,
      creator: comic.creator,
      titleMeta: comic.titleMeta,
      metadata: comic.metadata,
      updatedAt: comic.updatedAt,
    ),
    'chapterId': comic.chapterId,
    'chapterTitle': comic.chapterTitle,
    'chapterOrder': comic.chapterOrder,
    'pageIndex': comic.pageIndex,
  };
}

Map<String, dynamic> _buildDownloadRaw(UnifiedComicDownload comic) {
  return {
    ..._buildBaseRaw(
      source: comic.source,
      comicId: comic.comicId,
      title: comic.title,
      description: comic.description,
      cover: comic.cover,
      creator: comic.creator,
      titleMeta: comic.titleMeta,
      metadata: comic.metadata,
      updatedAt: comic.updatedAt,
    ),
    'chapters': sanitizeDynamic(comic.chapters),
    'storageRoot': comic.storageRoot,
  };
}

Map<String, dynamic> _buildBaseRaw({
  required String source,
  required String comicId,
  required String title,
  required String description,
  required ComicImage cover,
  required Creator creator,
  required List<ComicInfoActionItem> titleMeta,
  required List<ComicInfoMetadata> metadata,
  required DateTime updatedAt,
}) {
  return {
    'source': source,
    'comicId': comicId,
    'title': title,
    'description': description,
    'cover': sanitizeDynamic(cover.toJson()),
    'creator': sanitizeDynamic(creator.toJson()),
    'titleMeta': sanitizeDynamic(
      titleMeta.map((item) => item.toJson()).toList(),
    ),
    'metadata': sanitizeDynamic(metadata.map((item) => item.toJson()).toList()),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

UnifiedComicCover _coverFromStored(
  String source,
  String comicId,
  ComicImage cover,
) {
  final coverId = cover.id.trim().isNotEmpty ? cover.id : comicId;
  final resolvedPath = cover.path.trim().isNotEmpty
      ? cover.path
      : _buildFallbackCoverPath(coverId, cover.url);
  return UnifiedComicCover(
    id: coverId,
    url: cover.url,
    path: resolvedPath,
    extern: cover.extern,
  );
}

String _buildFallbackCoverPath(String id, String url) {
  final safeId = sanitizePathSegment(id.trim().isEmpty ? 'cover' : id);
  final extension = extractImageExtension(url);
  return '$safeId.$extension';
}

List<UnifiedComicMetadata> _metadataFromTyped(
  List<ComicInfoMetadata> metadata,
) {
  return metadata
      .map((item) {
        final value = item.value
            .map((entry) => entry.name.trim())
            .where((entry) => entry.isNotEmpty)
            .toList();
        if (value.isEmpty) return null;
        return UnifiedComicMetadata(
          type: item.type,
          name: item.name,
          value: value,
        );
      })
      .whereType<UnifiedComicMetadata>()
      .toList();
}

int _viewCountFromTitleMeta(List<ComicInfoActionItem> titleMeta) {
  for (final item in titleMeta) {
    final name = item.name;
    if (name.startsWith('浏览：')) {
      return int.tryParse(name.substring(3)) ?? 0;
    }
  }
  return 0;
}

UnifiedComicListItem _requireUnifiedPluginItem(
  Map<String, dynamic> item, {
  required String source,
  required String context,
}) {
  if (item['cover'] is! Map || item['metadata'] is! List) {
    throw StateError('插件返回非统一漫画结构: $context');
  }
  return UnifiedComicListItem.fromJson(item).copyWith(source: source.trim());
}
