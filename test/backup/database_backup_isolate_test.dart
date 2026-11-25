import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';

import '../test_helper.dart';

void main() {
  setUpAll(TestDatabaseHelper.setUpTestDatabase);
  tearDownAll(TestDatabaseHelper.tearDownTestDatabase);
  tearDown(TestDatabaseHelper.cleanComicFolderBoxes);

  test('writeAllDataJsonFileAsync 在 worker 内写出全库 JSON', () async {
    await database.favorites.put(createTestFavorite('isolate_backup'));

    final path = p.join(TestDatabaseHelper.tempPath, 'backup.json');
    await database.writeAllDataJsonFileAsync(path);

    final map =
        jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;
    final favorites = map['unifiedComicFavorite'] as List<dynamic>;
    expect(favorites, hasLength(1));
    expect(
      (favorites.single as Map<String, dynamic>)['uniqueKey'],
      'isolate_backup',
    );
  });

  test('不含下载的备份 JSON 不写下载文件夹和链接', () async {
    await database.folders.put(_folder('fav', 'Favorite', 'favorite'));
    await database.folders.put(_folder('dl', 'Downloads', 'download'));
    await database.links.put(_link('test:fav', 'fav', 'favorite'));
    await database.links.put(_link('test:dl', 'dl', 'download'));

    final path = p.join(TestDatabaseHelper.tempPath, 'backup-no-download.json');
    await database.writeAllDataJsonFileAsync(
      path,
      removeIds: true,
      includeDownloadFolders: false,
    );

    final map =
        jsonDecode(await File(path).readAsString()) as Map<String, dynamic>;
    final folderTypes = (map['comicFolder'] as List)
        .cast<Map<String, dynamic>>()
        .map((item) => item['typeData'])
        .toSet();
    final linkTypes = (map['comicLink'] as List)
        .cast<Map<String, dynamic>>()
        .map((item) => item['typeData'])
        .toSet();

    expect(folderTypes, {'favorite'});
    expect(linkTypes, {'favorite'});

    final fullPath = p.join(TestDatabaseHelper.tempPath, 'backup-full.json');
    await database.writeAllDataJsonFileAsync(fullPath, removeIds: true);
    final fullMap =
        jsonDecode(await File(fullPath).readAsString()) as Map<String, dynamic>;
    expect(
      (fullMap['comicFolder'] as List)
          .cast<Map<String, dynamic>>()
          .map((item) => item['typeData'])
          .toSet(),
      {'favorite', 'download'},
    );
  });
}

ComicFolder _folder(String syncId, String name, String typeData) {
  final now = DateTime.now().toUtc().millisecondsSinceEpoch;
  return ComicFolder(
    syncId: syncId,
    parentSyncId: null,
    uniqueKey: '|$name|$typeData',
    name: name,
    typeData: typeData,
    versionVector: {'test': 1},
    createdAt: now,
    updatedAt: now,
  );
}

ComicLink _link(String comicKey, String folderSyncId, String typeData) {
  final now = DateTime.now().toUtc().millisecondsSinceEpoch;
  return ComicLink(
    uniqueKey: '$comicKey|$folderSyncId|$typeData',
    comicUniqueKey: comicKey,
    folderSyncId: folderSyncId,
    typeData: typeData,
    versionVector: {'test': 1},
    createdAt: now,
    updatedAt: now,
  );
}
