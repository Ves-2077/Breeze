import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/setting/data_backup/backup_restore.dart';

import '../test_helper.dart';

void main() {
  setUpAll(TestDatabaseHelper.setUpTestDatabase);
  tearDownAll(TestDatabaseHelper.tearDownTestDatabase);

  test('备份 JSON 在 worker 池内恢复收藏并保留下载记录', () async {
    final favorite = createTestFavorite('test:restore');
    final download = createTestDownload('test:keep');
    await database.favorites.put(favorite);
    await database.downloads.put(download);

    final json = await database.collectAllDataJson(removeIds: true);
    final path = p.join(TestDatabaseHelper.tempPath, 'objectbox.json');
    await File(path).writeAsString(json);

    await database.favorites.removeAll();

    // includeDownloads=false：恢复备份里的收藏，同时保留本机下载记录。
    final restored = await importBackupData(
      RestoreBackupTask(
        handle: database.db.handle,
        dataJsonPath: path,
        includeDownloads: false,
      ),
    );

    expect(restored, isNotNull, reason: '备份里的 UserSetting 应恢复成功');
    final restoredFavorite = await database.favorites.getByKey('test:restore');
    expect(restoredFavorite?.title, favorite.title);
    expect(
      await database.downloads.getByKey('test:keep'),
      isNotNull,
      reason: '不含下载文件的备份不应清掉本机下载记录',
    );
  });

  test('不含下载的备份导入保留本机下载文件夹和链接', () async {
    await database.folders.putMany([
      _folder('fav', 'Favorite', 'favorite'),
      _folder('dl', 'Downloads', 'download'),
    ]);
    await database.links.putMany([
      _link('test:fav', 'fav', 'favorite'),
      _link('test:dl', 'dl', 'download'),
    ]);
    await database.downloads.put(createTestDownload('test:dl'));

    final json = await database.collectAllDataJson(
      removeIds: true,
      includeDownloadFolders: false,
    );
    final exported = jsonDecode(json) as Map<String, dynamic>;
    expect(
      (exported['comicFolder'] as List)
          .cast<Map<String, dynamic>>()
          .map((item) => item['typeData'])
          .toSet(),
      {'favorite'},
    );

    final path = p.join(
      TestDatabaseHelper.tempPath,
      'objectbox-no-download.json',
    );
    await File(path).writeAsString(json);

    final restored = await importBackupData(
      RestoreBackupTask(
        handle: database.db.handle,
        dataJsonPath: path,
        includeDownloads: false,
      ),
    );

    expect(restored, isNotNull);
    expect(
      await database.folders.getBySyncId('fav'),
      isNotNull,
      reason: '备份里的收藏文件夹应恢复',
    );
    expect(
      await database.folders.getBySyncId('dl'),
      isNotNull,
      reason: '本机下载文件夹不应因导入无下载备份而丢失',
    );
    expect(
      await database.links.getByUniqueKey('test:fav|fav|favorite'),
      isNotNull,
    );
    expect(
      await database.links.getByUniqueKey('test:dl|dl|download'),
      isNotNull,
      reason: '本机下载链接不应因导入无下载备份而丢失',
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
    versionVectorJson: '{"test":1}',
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
    versionVectorJson: '{"test":1}',
    createdAt: now,
    updatedAt: now,
  );
}
