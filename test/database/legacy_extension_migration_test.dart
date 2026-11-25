import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/model/comic_info_meta.dart';
import 'package:zephyr/object_box/migration/migration_v4_to_v5.dart';
import 'package:zephyr/object_box/migration/migration_v6_to_v7.dart';
import 'package:zephyr/object_box/model.dart';

import '../support/comic_fixtures.dart';
import '../test_helper.dart';

void main() {
  setUpAll(TestDatabaseHelper.setUpTestDatabase);
  tearDownAll(TestDatabaseHelper.tearDownTestDatabase);

  final now = DateTime.utc(2026, 1, 1);

  UnifiedComicFavorite buildFavorite({required bool nested}) {
    return UnifiedComicFavorite(
      uniqueKey: 'test:1',
      source: 'test',
      comicId: '1',
      title: 't',
      description: 'd',
      cover: ComicImage(
        id: 'c1',
        url: '',
        name: '',
        path: '1.jpg',
        extern: nested
            ? const {
                'extension': {'foo': 'bar'},
              }
            : const {},
      ),
      creator: emptyComicCreator,
      titleMeta: const [ComicInfoActionItem(name: '浏览：1')],
      metadata: const [],
      createdAt: now,
      updatedAt: now,
      deleted: false,
      schemaVersion: 1,
    );
  }

  test(
    'v4/v6 migrations read typed fields and rewrite nested extension',
    () async {
      await database.favorites.put(buildFavorite(nested: true));

      await migrateV4ToV5(database);
      final afterV4 = await database.favorites.getByKey('test:1');
      expect(afterV4!.cover.path, '1.jpg');
      expect(afterV4.titleMeta.single.name, '浏览：1');
      expect(afterV4.cover.extern.containsKey('extension'), isFalse);

      await database.favorites.removeAll();
      await database.favorites.put(buildFavorite(nested: true));
      await migrateV6ToV7(database);
      final afterV6 = await database.favorites.getByKey('test:1');
      expect(afterV6!.cover.path, '1.jpg');
      expect(afterV6.titleMeta.single.name, '浏览：1');
      expect(afterV6.cover.extern.containsKey('extension'), isFalse);
    },
  );
}
