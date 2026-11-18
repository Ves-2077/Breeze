import 'package:zephyr/database/db.dart';
import 'package:zephyr/database/row_codec.dart';
import 'package:zephyr/object_box/model.dart';

const _followInsert =
    'INSERT INTO "ComicFollow" '
    '("uniqueKey","source","comicId","title","description","cover","creator",'
    '"titleMeta","metadata","lastChapterCount","detectedChapterCount",'
    '"hasUpdate","updateTime","deleted","createdAt","updatedAt",'
    '"schemaVersion","detectedChapterTitle") VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)';

const _followUpsert =
    'INSERT INTO "ComicFollow" '
    '("id","uniqueKey","source","comicId","title","description","cover",'
    '"creator","titleMeta","metadata","lastChapterCount",'
    '"detectedChapterCount","hasUpdate","updateTime","deleted","createdAt",'
    '"updatedAt","schemaVersion","detectedChapterTitle") '
    'VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) '
    'ON CONFLICT("id") DO UPDATE SET '
    '"uniqueKey"=excluded."uniqueKey","source"=excluded."source",'
    '"comicId"=excluded."comicId","title"=excluded."title",'
    '"description"=excluded."description","cover"=excluded."cover",'
    '"creator"=excluded."creator","titleMeta"=excluded."titleMeta",'
    '"metadata"=excluded."metadata",'
    '"lastChapterCount"=excluded."lastChapterCount",'
    '"detectedChapterCount"=excluded."detectedChapterCount",'
    '"hasUpdate"=excluded."hasUpdate","updateTime"=excluded."updateTime",'
    '"deleted"=excluded."deleted","createdAt"=excluded."createdAt",'
    '"updatedAt"=excluded."updatedAt",'
    '"schemaVersion"=excluded."schemaVersion",'
    '"detectedChapterTitle"=excluded."detectedChapterTitle"';

class ComicFollowRepository {
  final BreezeDatabase db;

  const ComicFollowRepository(this.db);

  static const String table = 'ComicFollow';

  Future<ComicFollow?> getById(int id) async {
    final rows = await db.query(
      'SELECT * FROM "ComicFollow" WHERE "id" = ? LIMIT 1',
      <Object?>[id],
    );
    return rows.isEmpty ? null : _decode(rows.first);
  }

  Future<ComicFollow?> getByKey(String uniqueKey) async {
    final rows = await db.query(
      'SELECT * FROM "ComicFollow" WHERE "uniqueKey" = ? LIMIT 1',
      <Object?>[uniqueKey],
    );
    return rows.isEmpty ? null : _decode(rows.first);
  }

  Future<List<ComicFollow>> getAll() async {
    final rows = await db.query('SELECT * FROM "ComicFollow" ORDER BY "id"');
    return rows.map(_decode).toList();
  }

  Future<List<ComicFollow>> listActive() async {
    final rows = await db.query(
      'SELECT * FROM "ComicFollow" WHERE "deleted" = 0 '
      'ORDER BY "hasUpdate" DESC, "updateTime" DESC, "id" DESC',
    );
    return rows.map(_decode).toList();
  }

  Future<int> count() async {
    final rows = await db.query('SELECT COUNT(*) AS c FROM "ComicFollow"');
    return (rows.single['c'] as num).toInt();
  }

  Future<int> put(ComicFollow value) async {
    if (value.id > 0) {
      await db.execute(_followUpsert, _params(value, includeId: true));
      return value.id;
    }
    final result = await db.execute(
      _followInsert,
      _params(value, includeId: false),
    );
    value.id = result.lastInsertId;
    return value.id;
  }

  Future<List<int>> putMany(List<ComicFollow> values) async {
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
    final result = await db.execute('DELETE FROM "ComicFollow"');
    return result.changes;
  }

  Future<int> _putInTx(DbTransaction tx, ComicFollow value) async {
    if (value.id > 0) {
      await tx.execute(_followUpsert, _params(value, includeId: true));
      return value.id;
    }
    final result = await tx.execute(
      _followInsert,
      _params(value, includeId: false),
    );
    value.id = result.lastInsertId;
    return value.id;
  }

  List<Object?> _params(ComicFollow v, {required bool includeId}) {
    return <Object?>[
      if (includeId) v.id,
      v.uniqueKey,
      v.source,
      v.comicId,
      v.title,
      v.description,
      v.cover,
      v.creator,
      v.titleMeta,
      v.metadata,
      v.lastChapterCount,
      v.detectedChapterCount,
      boolToDb(v.hasUpdate),
      dateToDb(v.updateTime),
      boolToDb(v.deleted),
      dateToDb(v.createdAt),
      dateToDb(v.updatedAt),
      v.schemaVersion,
      v.detectedChapterTitle,
    ];
  }

  ComicFollow _decode(Map<String, dynamic> row) {
    return ComicFollow.fromJson(
      normalizeRow(
        withDefaultId(row),
        dates: const <String>{'updateTime', 'createdAt', 'updatedAt'},
        bools: const <String>{'hasUpdate', 'deleted'},
      ),
    );
  }
}
