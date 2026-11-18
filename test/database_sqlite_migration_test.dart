import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:zephyr/database/app_database.dart';
import 'package:zephyr/util/rust_loader.dart';

void main() {
  setUpAll(() async {
    await initRustLib();
  });

  test('SQLite schema, CRUD, rollback and table watcher', () async {
    final temp = await Directory.systemTemp.createTemp('breeze_sqlite_');
    final path = p.join(temp.path, 'breeze.sqlite3');
    final db = await openAppDatabase(
      path: path,
      legacyObjectBoxDir: p.join(temp.path, 'missing_objectbox'),
    );
    try {
      final version = await db.query('PRAGMA user_version');
      expect(version.single['user_version'], currentSchemaVersion);

      final write = await db.execute(
        'INSERT INTO "PluginConfig" ("name", "config") VALUES (?, ?)',
        <Object?>['demo', '{}'],
      );
      expect(write.lastInsertId, 1);

      final rows = await db.query(
        'SELECT * FROM "PluginConfig" WHERE "name" = ?',
        <Object?>['demo'],
      );
      expect(rows, hasLength(1));
      expect(rows.single['config'], '{}');

      await expectLater(
        db.transaction((tx) async {
          await tx.execute(
            'INSERT INTO "PluginConfig" ("name", "config") VALUES (?, ?)',
            <Object?>['rolled-back', '{}'],
          );
          throw StateError('rollback');
        }),
        throwsStateError,
      );
      final count = await db.query('SELECT COUNT(*) AS c FROM "PluginConfig"');
      expect(count.single['c'], 1);

      final change = db.changes.firstWhere(
        (tables) => tables.contains('PluginConfig'),
      );
      await db.execute(
        'INSERT INTO "PluginConfig" ("name", "config") VALUES (?, ?)',
        <Object?>['watched', '{}'],
      );
      expect(
        await change.timeout(const Duration(seconds: 5)),
        contains('PluginConfig'),
      );
    } finally {
      await db.close();
      await temp.delete(recursive: true);
    }
  });

  final oldDb = Platform.environment['BREEZE_OBJECTBOX_TEST_DB'];
  test(
    'imports a real ObjectBox LMDB database',
    () async {
      final temp = await Directory.systemTemp.createTemp('breeze_import_');
      final db = await openAppDatabase(
        path: p.join(temp.path, 'breeze.sqlite3'),
        legacyObjectBoxDir: oldDb!,
      );
      try {
        Future<int> count(String table) async {
          final rows = await db.query('SELECT COUNT(*) AS c FROM "$table"');
          return (rows.single['c'] as num).toInt();
        }

        expect(await count('UserSetting'), 1);
        expect(await count('PluginConfig'), 4);
        expect(await count('PluginInfo'), 6);
        expect(await count('UnifiedComicDownload'), 3);
        expect(await count('UnifiedComicFavorite'), 3);
        expect(await count('UnifiedComicHistory'), 10);
        expect(await count('ComicLink'), 6);
        expect(await count('ComicFollow'), 5);
        expect(await count('ComicReadChapter'), 17);

        final setting = await db.query(
          'SELECT "globalSettingData" FROM "UserSetting" WHERE "id" = 1',
        );
        expect(
          setting.single['globalSettingData'] as String,
          contains('compatibleVersion'),
        );
      } finally {
        await db.close();
        await temp.delete(recursive: true);
      }
    },
    skip: oldDb == null
        ? 'set BREEZE_OBJECTBOX_TEST_DB to an ObjectBox db directory'
        : false,
  );
}
