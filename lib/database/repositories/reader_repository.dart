import 'package:zephyr/database/db.dart';
import 'package:zephyr/database/row_codec.dart';
import 'package:zephyr/object_box/model.dart';

const _preferenceInsert =
    'INSERT INTO "ComicReadPreference" '
    '("uniqueKey","source","comicId","readMode","updatedAt","deleted",'
    '"overridesJson") VALUES (?,?,?,?,?,?,?)';

const _preferenceUpsert =
    'INSERT INTO "ComicReadPreference" '
    '("id","uniqueKey","source","comicId","readMode","updatedAt","deleted",'
    '"overridesJson") VALUES (?,?,?,?,?,?,?,?) '
    'ON CONFLICT("id") DO UPDATE SET '
    '"uniqueKey"=excluded."uniqueKey","source"=excluded."source",'
    '"comicId"=excluded."comicId","readMode"=excluded."readMode",'
    '"updatedAt"=excluded."updatedAt","deleted"=excluded."deleted",'
    '"overridesJson"=excluded."overridesJson"';

class ComicReadPreferenceRepository {
  final BreezeDatabase db;

  const ComicReadPreferenceRepository(this.db);

  static const String table = 'ComicReadPreference';

  Future<ComicReadPreference?> getByKey(String uniqueKey) async {
    final rows = await db.query(
      'SELECT * FROM "ComicReadPreference" WHERE "uniqueKey" = ? LIMIT 1',
      <Object?>[uniqueKey],
    );
    return rows.isEmpty ? null : _decode(rows.first);
  }

  Future<List<ComicReadPreference>> getAll() async {
    final rows = await db.query(
      'SELECT * FROM "ComicReadPreference" ORDER BY "id"',
    );
    return rows.map(_decode).toList();
  }

  Future<List<ComicReadPreference>> listActive() async {
    final rows = await db.query(
      'SELECT * FROM "ComicReadPreference" WHERE "deleted" = 0 ORDER BY "id"',
    );
    return rows.map(_decode).toList();
  }

  Future<int> count() async {
    final rows = await db.query(
      'SELECT COUNT(*) AS c FROM "ComicReadPreference"',
    );
    return (rows.single['c'] as num).toInt();
  }

  Future<int> put(ComicReadPreference value) async {
    if (value.id > 0) {
      await db.execute(_preferenceUpsert, _params(value, includeId: true));
      return value.id;
    }
    final result = await db.execute(
      _preferenceInsert,
      _params(value, includeId: false),
    );
    value.id = result.lastInsertId;
    return value.id;
  }

  Future<List<int>> putMany(List<ComicReadPreference> values) async {
    if (values.isEmpty) return const <int>[];
    return db.transaction((tx) async {
      final ids = <int>[];
      for (final value in values) {
        ids.add(await _putInTx(tx, value));
      }
      return ids;
    });
  }

  Future<int> removeAll() async {
    final result = await db.execute('DELETE FROM "ComicReadPreference"');
    return result.changes;
  }

  Future<int> _putInTx(DbTransaction tx, ComicReadPreference value) async {
    if (value.id > 0) {
      await tx.execute(_preferenceUpsert, _params(value, includeId: true));
      return value.id;
    }
    final result = await tx.execute(
      _preferenceInsert,
      _params(value, includeId: false),
    );
    value.id = result.lastInsertId;
    return value.id;
  }

  List<Object?> _params(ComicReadPreference v, {required bool includeId}) {
    return <Object?>[
      if (includeId) v.id,
      v.uniqueKey,
      v.source,
      v.comicId,
      v.readMode,
      dateToDb(v.updatedAt),
      boolToDb(v.deleted),
      v.overridesJson,
    ];
  }

  ComicReadPreference _decode(Map<String, dynamic> row) {
    return ComicReadPreference.fromJson(
      normalizeRow(
        withDefaultId(row),
        dates: const <String>{'updatedAt'},
        bools: const <String>{'deleted'},
      ),
    );
  }
}

const _chapterInsert =
    'INSERT INTO "ComicReadChapter" '
    '("uniqueKey","source","comicId","chapterId","chapterTitle",'
    '"chapterOrder","readAt","updatedAt") VALUES (?,?,?,?,?,?,?,?)';

const _chapterUpsert =
    'INSERT INTO "ComicReadChapter" '
    '("id","uniqueKey","source","comicId","chapterId","chapterTitle",'
    '"chapterOrder","readAt","updatedAt") VALUES (?,?,?,?,?,?,?,?,?) '
    'ON CONFLICT("id") DO UPDATE SET '
    '"uniqueKey"=excluded."uniqueKey","source"=excluded."source",'
    '"comicId"=excluded."comicId","chapterId"=excluded."chapterId",'
    '"chapterTitle"=excluded."chapterTitle",'
    '"chapterOrder"=excluded."chapterOrder","readAt"=excluded."readAt",'
    '"updatedAt"=excluded."updatedAt"';

class ComicReadChapterRepository {
  final BreezeDatabase db;

  const ComicReadChapterRepository(this.db);

  static const String table = 'ComicReadChapter';

  Future<ComicReadChapter?> getByKey(String uniqueKey) async {
    final rows = await db.query(
      'SELECT * FROM "ComicReadChapter" WHERE "uniqueKey" = ? LIMIT 1',
      <Object?>[uniqueKey],
    );
    return rows.isEmpty ? null : _decode(rows.first);
  }

  Future<List<ComicReadChapter>> listByComic({
    required String source,
    required String comicId,
  }) async {
    final rows = await db.query(
      'SELECT * FROM "ComicReadChapter" WHERE "source" = ? AND "comicId" = ? '
      'ORDER BY "chapterOrder", "id"',
      <Object?>[source, comicId],
    );
    return rows.map(_decode).toList();
  }

  Future<List<ComicReadChapter>> getAll() async {
    final rows = await db.query(
      'SELECT * FROM "ComicReadChapter" ORDER BY "id"',
    );
    return rows.map(_decode).toList();
  }

  Future<int> count() async {
    final rows = await db.query('SELECT COUNT(*) AS c FROM "ComicReadChapter"');
    return (rows.single['c'] as num).toInt();
  }

  Future<int> put(ComicReadChapter value) async {
    if (value.id > 0) {
      await db.execute(_chapterUpsert, _params(value, includeId: true));
      return value.id;
    }
    final result = await db.execute(
      _chapterInsert,
      _params(value, includeId: false),
    );
    value.id = result.lastInsertId;
    return value.id;
  }

  Future<int> removeAll() async {
    final result = await db.execute('DELETE FROM "ComicReadChapter"');
    return result.changes;
  }

  List<Object?> _params(ComicReadChapter v, {required bool includeId}) {
    return <Object?>[
      if (includeId) v.id,
      v.uniqueKey,
      v.source,
      v.comicId,
      v.chapterId,
      v.chapterTitle,
      v.chapterOrder,
      dateToDb(v.readAt),
      dateToDb(v.updatedAt),
    ];
  }

  ComicReadChapter _decode(Map<String, dynamic> row) {
    return ComicReadChapter.fromJson(
      normalizeRow(
        withDefaultId(row),
        dates: const <String>{'readAt', 'updatedAt'},
      ),
    );
  }
}
