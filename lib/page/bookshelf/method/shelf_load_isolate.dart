import 'package:zephyr/database/database.dart';
import 'package:zephyr/database/query_isolate.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/bookshelf/method/comic_search_text.dart';
import 'package:zephyr/page/bookshelf/models/shelf_page_mode.dart';
import 'package:zephyr/page/bookshelf/service/comic_folder_service.dart';
import 'package:zephyr/page/bookshelf/service/comic_link_service.dart';
import 'package:zephyr/util/rust_loader.dart';
import 'package:zephyr/widgets/comic_entry/models/models.dart';
import 'package:zephyr/widgets/comic_simplify_entry/comic_simplify_entry_info.dart';

/// 书架加载任务：只携带可跨 isolate 传递的简单参数。
class ShelfLoadTask {
  const ShelfLoadTask({
    required this.handle,
    required this.mode,
    required this.currentPath,
    required this.keyword,
    required this.sort,
    required this.sources,
  });

  final int handle;
  final String mode;
  final String currentPath;
  final String keyword;
  final String sort;
  final List<String> sources;
}

/// 书架加载结果：全部为普通 Dart 对象，可由 `compute` 零拷贝交回 UI。
class ShelfLoadResult {
  const ShelfLoadResult({
    required this.folders,
    required this.folderComicCounts,
    required this.comics,
    required this.searchTexts,
  });

  final List<ComicFolder> folders;
  final Map<String, int> folderComicCounts;
  final List<ComicSimplifyEntryInfo> comics;
  final Map<String, String> searchTexts;
}

/// 在 compute isolate 内完成书架（收藏/历史/下载）的查询、解码与映射。
///
/// 注意：不能引用 UI 全局状态（`database`、`globalSetting`、`BuildContext`）；
/// RustLib 需要在本 isolate 内初始化。
Future<ShelfLoadResult> loadShelfInIsolate(ShelfLoadTask task) async {
  await initRustLib();
  markDbWorkerIsolate();
  final db = Database.fromHandle(task.handle);
  final mode = ShelfPageMode.values.byName(task.mode);
  final folderType = comicFolderTypeOf(mode);
  final keyword = task.keyword;
  final sort = task.sort;
  final sortAscending = sort == 'da';
  final sortByViewTime =
      (mode == ShelfPageMode.favorite || mode == ShelfPageMode.download) &&
      (sort == 'vd' || sort == 'va');

  final viewTimes = <String, DateTime>{};
  if (sortByViewTime) {
    for (final history in await db.histories.listActive()) {
      viewTimes[history.uniqueKey] = history.lastReadAt;
    }
  }

  final itemTimes = <String, DateTime>{};
  if (sortByViewTime) {
    if (mode == ShelfPageMode.favorite) {
      for (final favorite in await db.favorites.listActive()) {
        itemTimes[favorite.uniqueKey] = favorite.createdAt;
      }
    } else {
      for (final download in await db.downloads.listActive()) {
        itemTimes[download.uniqueKey] = download.downloadedAt;
      }
    }
  }

  final sourceFilter = _sourceFilter(task.sources);

  // 历史无文件夹体系：直读历史表，按更新时间排序。
  if (mode == ShelfPageMode.history) {
    return await _loadHistoryShelf(
      db,
      sortAscending: sortAscending,
      keyword: keyword,
      sourceFilter: sourceFilter,
    );
  }

  // 搜索时不应被“当前所在文件夹”限制，而是全局搜索该类型下的全部漫画。
  final isSearching = keyword.trim().isNotEmpty;
  final normalizedKeyword = isSearching ? normalizeSearchText(keyword) : '';
  final folders = isSearching
      ? <ComicFolder>[]
      : await ComicFolderService.listChildFolders(
          task.currentPath,
          folderType,
          sortAscending: sortAscending,
          db: db,
        );
  final links = isSearching
      ? await ComicLinkService.listAllLinks(
          folderType,
          sortAscending: sortAscending,
          db: db,
        )
      : await ComicLinkService.listLinks(
          task.currentPath.isEmpty ? null : task.currentPath,
          folderType,
          sortAscending: sortAscending,
          db: db,
        );
  final comics = <ComicSimplifyEntryInfo>[];
  final searchTexts = <String, String>{};
  final seenKeys = <String>{};
  for (final link in links) {
    final resolved = await _resolveComic(link.comicUniqueKey, folderType, db);
    if (resolved == null) continue;
    if (sourceFilter != null && !sourceFilter.contains(resolved.info.source)) {
      continue;
    }
    final key = '${resolved.info.from.trim()}:${resolved.info.id}';
    if (!seenKeys.add(key)) continue;
    if (isSearching && !resolved.searchText.contains(normalizedKeyword)) {
      continue;
    }
    comics.add(resolved.info);
    searchTexts[key] = resolved.searchText;
  }
  // 文件夹直属漫画数：详情行副标题用。key 是显示路径（与 page 侧 folderPathOf 一致）。
  final folderComicCounts = <String, int>{};
  if (!isSearching) {
    final bySyncId = <String, ComicFolder>{
      for (final folder in folders) folder.syncId: folder,
    };
    String folderPathOf(ComicFolder folder) {
      final parts = <String>[];
      final visited = <String>{};
      ComicFolder? current = folder;
      while (current != null) {
        if (current.syncId.isNotEmpty && !visited.add(current.syncId)) {
          break;
        }
        parts.add(current.name);
        final parentId = current.parentSyncId;
        if (parentId == null || parentId.isEmpty) break;
        current = bySyncId[parentId];
      }
      return '/${parts.reversed.join('/')}';
    }

    final pathBySyncId = <String, String>{
      for (final folder in folders) folder.syncId: folderPathOf(folder),
    };
    for (final link in links) {
      final folderSyncId = link.folderSyncId;
      if (folderSyncId == null || folderSyncId.isEmpty) continue;
      final path = pathBySyncId[folderSyncId];
      if (path == null) continue;
      folderComicCounts[path] = (folderComicCounts[path] ?? 0) + 1;
    }
  }
  if (sortByViewTime) {
    _sortShelfItemsByViewTime(
      comics,
      viewTimes: viewTimes,
      itemTimes: itemTimes,
      ascending: sort == 'va',
    );
  }

  return ShelfLoadResult(
    folders: folders,
    folderComicCounts: folderComicCounts,
    comics: comics,
    searchTexts: searchTexts,
  );
}

Future<ShelfLoadResult> _loadHistoryShelf(
  Database db, {
  required bool sortAscending,
  required String keyword,
  required Set<String>? sourceFilter,
}) async {
  final isSearching = keyword.trim().isNotEmpty;
  final normalizedKeyword = isSearching ? normalizeSearchText(keyword) : '';
  final comics = <ComicSimplifyEntryInfo>[];
  final searchTexts = <String, String>{};
  // sourceFilter 为 null/空集视为不过滤，与收藏/下载一致。
  final filterSources = sourceFilter != null && sourceFilter.isNotEmpty;
  for (final history in await db.histories.listActive(
    ascending: sortAscending,
  )) {
    if (filterSources && !sourceFilter.contains(history.source)) continue;
    final info = unifiedComicFromUnifiedHistory(history).toSimplifyEntryInfo();
    final key = '${info.from.trim()}:${info.id}';
    final searchText = buildComicSearchText(history);
    if (isSearching && !searchText.contains(normalizedKeyword)) {
      continue;
    }
    comics.add(info);
    searchTexts[key] = searchText;
  }
  return ShelfLoadResult(
    folders: const <ComicFolder>[],
    folderComicCounts: const <String, int>{},
    comics: comics,
    searchTexts: searchTexts,
  );
}

Future<({ComicSimplifyEntryInfo info, String searchText})?> _resolveComic(
  String uniqueKey,
  ComicFolderType folderType,
  Database db,
) async {
  switch (folderType) {
    case ComicFolderType.favorite:
      final comic = await db.favorites.getByKey(uniqueKey);
      if (comic == null || comic.deleted) return null;
      return (
        info: unifiedComicFromUnifiedFavorite(comic).toSimplifyEntryInfo(),
        searchText: buildComicSearchText(comic),
      );
    case ComicFolderType.download:
      final comic = await db.downloads.getByKey(uniqueKey);
      if (comic == null || comic.deleted) return null;
      return (
        info: unifiedComicFromUnifiedDownload(comic).toSimplifyEntryInfo(),
        searchText: buildComicSearchText(comic),
      );
    case ComicFolderType.history:
      final comic = await db.histories.getByKey(uniqueKey);
      if (comic == null || comic.deleted) return null;
      return (
        info: unifiedComicFromUnifiedHistory(comic).toSimplifyEntryInfo(),
        searchText: buildComicSearchText(comic),
      );
  }
}

void _sortShelfItemsByViewTime(
  List<ComicSimplifyEntryInfo> items, {
  required Map<String, DateTime> viewTimes,
  required Map<String, DateTime> itemTimes,
  required bool ascending,
}) {
  items.sort((left, right) {
    final leftKey = '${left.from.trim()}:${left.id}';
    final rightKey = '${right.from.trim()}:${right.id}';
    final leftViewTime = viewTimes[leftKey];
    final rightViewTime = viewTimes[rightKey];

    // 未观看的条目没有可比较的观看时间，始终放在已观看项目之后。
    if (leftViewTime == null && rightViewTime != null) return 1;
    if (leftViewTime != null && rightViewTime == null) return -1;
    if (leftViewTime != null && rightViewTime != null) {
      final result = leftViewTime.compareTo(rightViewTime);
      if (result != 0) return ascending ? result : -result;
    }

    final leftItemTime = itemTimes[leftKey];
    final rightItemTime = itemTimes[rightKey];
    if (leftItemTime != null && rightItemTime != null) {
      final result = leftItemTime.compareTo(rightItemTime);
      if (result != 0) return ascending ? result : -result;
    }
    return leftKey.compareTo(rightKey);
  });
}

Set<String>? _sourceFilter(List<String> sources) {
  final cleaned = sources
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toSet();
  return cleaned.isEmpty ? null : cleaned;
}
