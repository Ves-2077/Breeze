import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/bookshelf/method/shelf_load_isolate.dart';

import '../test_helper.dart';

Future<ShelfLoadResult> _load(String mode) {
  return loadShelfInIsolate(
    ShelfLoadTask(
      handle: database.db.handle,
      mode: mode,
      currentPath: '',
      keyword: '',
      sort: 'dd',
      sources: const <String>[],
    ),
  );
}

Future<void> _addLink(String comicUniqueKey, String type) async {
  final now = DateTime.now().toUtc();
  await database.links.put(
    ComicLink(
      uniqueKey: '$comicUniqueKey||$type',
      comicUniqueKey: comicUniqueKey,
      typeData: type,
      versionVectorJson: '{}',
      createdAt: now.millisecondsSinceEpoch,
      updatedAt: now.millisecondsSinceEpoch,
    ),
  );
}

void main() {
  setUpAll(TestDatabaseHelper.setUpTestDatabase);
  tearDownAll(TestDatabaseHelper.tearDownTestDatabase);
  tearDown(TestDatabaseHelper.cleanComicFolderBoxes);

  test('收藏书架在 worker 内加载', () async {
    final favorite = createTestFavorite('test:fav');
    await database.favorites.put(favorite);
    await _addLink(favorite.uniqueKey, ComicFolderType.favorite.name);

    final result = await _load('favorite');
    expect(result.comics, hasLength(1));
    expect(result.comics.single.id, favorite.comicId);
    expect(result.searchTexts, isNotEmpty);
  });

  test('历史书架在 worker 内加载', () async {
    final history = createTestHistory('test:hist');
    await database.histories.put(history);

    final result = await _load('history');
    expect(result.comics, hasLength(1));
    expect(result.comics.single.id, history.comicId);
  });

  test('下载书架在 worker 内加载', () async {
    final download = createTestDownload('test:dl');
    await database.downloads.put(download);
    await _addLink(download.uniqueKey, ComicFolderType.download.name);

    final result = await _load('download');
    expect(result.comics, hasLength(1));
    expect(result.comics.single.id, download.comicId);
  });
}
