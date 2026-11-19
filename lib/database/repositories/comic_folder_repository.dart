import 'package:zephyr/database/db.dart';
import 'package:zephyr/database/query_isolate.dart';
import 'package:zephyr/database/row_codec.dart';
import 'package:zephyr/object_box/model.dart';

const _folderInsert =
    'INSERT INTO "ComicFolder" '
    '("uniqueKey","name","typeData","versionVectorJson","deletedAt",'
    '"createdAt","updatedAt","syncId","parentSyncId") '
    'VALUES (?,?,?,?,?,?,?,?,?)';

const _folderUpsert =
    'INSERT INTO "ComicFolder" '
    '("id","uniqueKey","name","typeData","versionVectorJson","deletedAt",'
    '"createdAt","updatedAt","syncId","parentSyncId") '
    'VALUES (?,?,?,?,?,?,?,?,?,?) '
    'ON CONFLICT("id") DO UPDATE SET '
    '"uniqueKey"=excluded."uniqueKey","name"=excluded."name",'
    '"typeData"=excluded."typeData",'
    '"versionVectorJson"=excluded."versionVectorJson",'
    '"deletedAt"=excluded."deletedAt","createdAt"=excluded."createdAt",'
    '"updatedAt"=excluded."updatedAt","syncId"=excluded."syncId",'
    '"parentSyncId"=excluded."parentSyncId"';

class ComicFolderRepository {
  final BreezeDatabase db;

  const ComicFolderRepository(this.db);

  static const String table = 'ComicFolder';

  Future<ComicFolder?> getById(int id) => runDbRead(
    db,
    sql: 'SELECT * FROM "ComicFolder" WHERE "id" = ? LIMIT 1',
    params: <Object?>[id],
    decode: _decodeFirst,
  );

  Future<ComicFolder?> getByUniqueKey(String uniqueKey) => runDbRead(
    db,
    sql: 'SELECT * FROM "ComicFolder" WHERE "uniqueKey" = ? LIMIT 1',
    params: <Object?>[uniqueKey],
    decode: _decodeFirst,
  );

  Future<ComicFolder?> getBySyncId(String syncId) => runDbRead(
    db,
    sql: 'SELECT * FROM "ComicFolder" WHERE "syncId" = ? LIMIT 1',
    params: <Object?>[syncId],
    decode: _decodeFirst,
  );

  Future<List<ComicFolder>> getAll() => runDbRead(
    db,
    sql: 'SELECT * FROM "ComicFolder" ORDER BY "id"',
    decode: _decodeAll,
  );

  Future<List<ComicFolder>> listByType(
    String typeData, {
    bool ascending = true,
  }) {
    final direction = ascending ? 'ASC' : 'DESC';
    return runDbRead(
      db,
      sql:
          'SELECT * FROM "ComicFolder" WHERE "typeData" = ? '
          'ORDER BY "name" $direction, "id" $direction',
      params: <Object?>[typeData],
      decode: _decodeAll,
    );
  }

  Future<List<ComicFolder>> listChildren(
    String? parentSyncId,
    String typeData, {
    bool ascending = true,
  }) {
    final direction = ascending ? 'ASC' : 'DESC';
    final sql = parentSyncId == null || parentSyncId.isEmpty
        ? 'SELECT * FROM "ComicFolder" WHERE "typeData" = ? '
              'AND ("parentSyncId" IS NULL OR "parentSyncId" = \'\') '
              'ORDER BY "name" $direction, "id" $direction'
        : 'SELECT * FROM "ComicFolder" WHERE "typeData" = ? '
              'AND "parentSyncId" = ? '
              'ORDER BY "name" $direction, "id" $direction';
    return runDbRead(
      db,
      sql: sql,
      params: parentSyncId == null || parentSyncId.isEmpty
          ? <Object?>[typeData]
          : <Object?>[typeData, parentSyncId],
      decode: _decodeAll,
    );
  }

  /// 某类型下所有未软删除的文件夹，按 createdAt 排序。
  Future<List<ComicFolder>> listActiveByType(
    String typeData, {
    bool ascending = false,
  }) {
    final direction = ascending ? 'ASC' : 'DESC';
    return runDbRead(
      db,
      sql:
          'SELECT * FROM "ComicFolder" WHERE "typeData" = ? '
          'AND "deletedAt" IS NULL '
          'ORDER BY "createdAt" $direction, "id" $direction',
      params: <Object?>[typeData],
      decode: _decodeAll,
    );
  }

  /// 某路径下未软删除的直接子文件夹，按 createdAt 排序。
  Future<List<ComicFolder>> listActiveChildren(
    String? parentSyncId,
    String typeData, {
    bool ascending = false,
  }) {
    final direction = ascending ? 'ASC' : 'DESC';
    final sql = parentSyncId == null || parentSyncId.isEmpty
        ? 'SELECT * FROM "ComicFolder" WHERE "typeData" = ? '
              'AND "deletedAt" IS NULL '
              'AND ("parentSyncId" IS NULL OR "parentSyncId" = \'\') '
              'ORDER BY "createdAt" $direction, "id" $direction'
        : 'SELECT * FROM "ComicFolder" WHERE "typeData" = ? '
              'AND "deletedAt" IS NULL AND "parentSyncId" = ? '
              'ORDER BY "createdAt" $direction, "id" $direction';
    return runDbRead(
      db,
      sql: sql,
      params: parentSyncId == null || parentSyncId.isEmpty
          ? <Object?>[typeData]
          : <Object?>[typeData, parentSyncId],
      decode: _decodeAll,
    );
  }

  Future<List<ComicFolder>> listBySyncIds(List<String> syncIds) async {
    if (syncIds.isEmpty) return const <ComicFolder>[];
    final marks = List.filled(syncIds.length, '?').join(',');
    return runDbRead(
      db,
      sql: 'SELECT * FROM "ComicFolder" WHERE "syncId" IN ($marks)',
      params: syncIds,
      decode: _decodeAll,
    );
  }

  Future<int> count() => runDbRead(
    db,
    sql: 'SELECT COUNT(*) AS c FROM "ComicFolder"',
    decode: countFromRows,
  );

  Future<int> put(ComicFolder value) async {
    if (value.id > 0) {
      await db.execute(_folderUpsert, _params(value, includeId: true));
      return value.id;
    }
    final result = await db.execute(
      _folderInsert,
      _params(value, includeId: false),
    );
    value.id = result.lastInsertId;
    return value.id;
  }

  Future<List<int>> putMany(List<ComicFolder> values) async {
    if (values.isEmpty) return const <int>[];
    return db.transaction((tx) async {
      final ids = <int>[];
      for (final value in values) {
        ids.add(await _putInTx(tx, value));
      }
      return ids;
    });
  }

  Future<int> removeById(int id) async {
    final result = await db.execute(
      'DELETE FROM "ComicFolder" WHERE "id" = ?',
      <Object?>[id],
    );
    return result.changes;
  }

  Future<int> removeAll() async {
    final result = await db.execute('DELETE FROM "ComicFolder"');
    return result.changes;
  }

  Future<int> _putInTx(DbTransaction tx, ComicFolder value) async {
    if (value.id > 0) {
      await tx.execute(_folderUpsert, _params(value, includeId: true));
      return value.id;
    }
    final result = await tx.execute(
      _folderInsert,
      _params(value, includeId: false),
    );
    value.id = result.lastInsertId;
    return value.id;
  }

  List<Object?> _params(ComicFolder v, {required bool includeId}) {
    return <Object?>[
      if (includeId) v.id,
      v.uniqueKey,
      v.name,
      v.typeData,
      v.versionVectorJson,
      v.deletedAt,
      v.createdAt,
      v.updatedAt,
      v.syncId,
      v.parentSyncId,
    ];
  }

  static ComicFolder _decodeRow(Map<String, dynamic> row) {
    return ComicFolder.fromJson(withDefaultId(row));
  }

  static List<ComicFolder> _decodeAll(List<Map<String, dynamic>> rows) =>
      rows.map(_decodeRow).toList();

  static ComicFolder? _decodeFirst(List<Map<String, dynamic>> rows) =>
      rows.isEmpty ? null : _decodeRow(rows.first);
}

const _linkInsert =
    'INSERT INTO "ComicLink" '
    '("uniqueKey","typeData","versionVectorJson","deletedAt","createdAt",'
    '"updatedAt","comicUniqueKey","folderSyncId") VALUES (?,?,?,?,?,?,?,?)';

const _linkUpsert =
    'INSERT INTO "ComicLink" '
    '("id","uniqueKey","typeData","versionVectorJson","deletedAt","createdAt",'
    '"updatedAt","comicUniqueKey","folderSyncId") VALUES (?,?,?,?,?,?,?,?,?) '
    'ON CONFLICT("id") DO UPDATE SET '
    '"uniqueKey"=excluded."uniqueKey","typeData"=excluded."typeData",'
    '"versionVectorJson"=excluded."versionVectorJson",'
    '"deletedAt"=excluded."deletedAt","createdAt"=excluded."createdAt",'
    '"updatedAt"=excluded."updatedAt",'
    '"comicUniqueKey"=excluded."comicUniqueKey",'
    '"folderSyncId"=excluded."folderSyncId"';

class ComicLinkRepository {
  final BreezeDatabase db;

  const ComicLinkRepository(this.db);

  static const String table = 'ComicLink';

  Future<ComicLink?> getById(int id) => runDbRead(
    db,
    sql: 'SELECT * FROM "ComicLink" WHERE "id" = ? LIMIT 1',
    params: <Object?>[id],
    decode: _decodeFirst,
  );

  Future<ComicLink?> getByUniqueKey(String uniqueKey) => runDbRead(
    db,
    sql: 'SELECT * FROM "ComicLink" WHERE "uniqueKey" = ? LIMIT 1',
    params: <Object?>[uniqueKey],
    decode: _decodeFirst,
  );

  Future<List<ComicLink>> getAll() => runDbRead(
    db,
    sql: 'SELECT * FROM "ComicLink" ORDER BY "id"',
    decode: _decodeAll,
  );

  Future<List<ComicLink>> listByType(String typeData, {bool ascending = true}) {
    final direction = ascending ? 'ASC' : 'DESC';
    return runDbRead(
      db,
      sql:
          'SELECT * FROM "ComicLink" WHERE "typeData" = ? '
          'ORDER BY "createdAt" $direction, "id" $direction',
      params: <Object?>[typeData],
      decode: _decodeAll,
    );
  }

  Future<List<ComicLink>> listByFolder(
    String? folderSyncId,
    String typeData, {
    bool ascending = true,
  }) {
    final direction = ascending ? 'ASC' : 'DESC';
    final sql = folderSyncId == null || folderSyncId.isEmpty
        ? 'SELECT * FROM "ComicLink" WHERE "typeData" = ? '
              'AND ("folderSyncId" IS NULL OR "folderSyncId" = \'\') '
              'ORDER BY "createdAt" $direction, "id" $direction'
        : 'SELECT * FROM "ComicLink" WHERE "typeData" = ? '
              'AND "folderSyncId" = ? '
              'ORDER BY "createdAt" $direction, "id" $direction';
    return runDbRead(
      db,
      sql: sql,
      params: folderSyncId == null || folderSyncId.isEmpty
          ? <Object?>[typeData]
          : <Object?>[typeData, folderSyncId],
      decode: _decodeAll,
    );
  }

  /// 某类型下全部未软删除的链接，按 createdAt 排序。
  Future<List<ComicLink>> listActiveByType(
    String typeData, {
    bool ascending = false,
  }) {
    final direction = ascending ? 'ASC' : 'DESC';
    return runDbRead(
      db,
      sql:
          'SELECT * FROM "ComicLink" WHERE "typeData" = ? '
          'AND "deletedAt" IS NULL '
          'ORDER BY "createdAt" $direction, "id" $direction',
      params: <Object?>[typeData],
      decode: _decodeAll,
    );
  }

  /// 某路径下未软删除的链接，按 createdAt 排序。
  Future<List<ComicLink>> listActiveByFolder(
    String? folderSyncId,
    String typeData, {
    bool ascending = false,
  }) {
    final direction = ascending ? 'ASC' : 'DESC';
    final sql = folderSyncId == null || folderSyncId.isEmpty
        ? 'SELECT * FROM "ComicLink" WHERE "typeData" = ? '
              'AND "deletedAt" IS NULL '
              'AND ("folderSyncId" IS NULL OR "folderSyncId" = \'\') '
              'ORDER BY "createdAt" $direction, "id" $direction'
        : 'SELECT * FROM "ComicLink" WHERE "typeData" = ? '
              'AND "deletedAt" IS NULL AND "folderSyncId" = ? '
              'ORDER BY "createdAt" $direction, "id" $direction';
    return runDbRead(
      db,
      sql: sql,
      params: folderSyncId == null || folderSyncId.isEmpty
          ? <Object?>[typeData]
          : <Object?>[typeData, folderSyncId],
      decode: _decodeAll,
    );
  }

  /// 漫画在某类型下未软删除的全部链接（含根目录）。
  Future<List<ComicLink>> listActiveByComic(
    String comicUniqueKey,
    String typeData,
  ) => runDbRead(
    db,
    sql:
        'SELECT * FROM "ComicLink" WHERE "typeData" = ? '
        'AND "deletedAt" IS NULL AND "comicUniqueKey" = ? '
        'ORDER BY "createdAt" ASC, "id" ASC',
    params: <Object?>[typeData, comicUniqueKey],
    decode: _decodeAll,
  );

  Future<List<ComicLink>> listByComic(
    String comicUniqueKey, {
    String? typeData,
  }) {
    final sql = typeData == null
        ? 'SELECT * FROM "ComicLink" WHERE "comicUniqueKey" = ?'
        : 'SELECT * FROM "ComicLink" WHERE "comicUniqueKey" = ? '
              'AND "typeData" = ?';
    return runDbRead(
      db,
      sql: sql,
      params: typeData == null
          ? <Object?>[comicUniqueKey]
          : <Object?>[comicUniqueKey, typeData],
      decode: _decodeAll,
    );
  }

  Future<List<ComicLink>> listByFolderSyncIds(
    List<String> syncIds, {
    String? typeData,
  }) async {
    if (syncIds.isEmpty) return const <ComicLink>[];
    final marks = List.filled(syncIds.length, '?').join(',');
    final sql = typeData == null
        ? 'SELECT * FROM "ComicLink" WHERE "folderSyncId" IN ($marks)'
        : 'SELECT * FROM "ComicLink" WHERE "folderSyncId" IN ($marks) '
              'AND "typeData" = ?';
    return runDbRead(
      db,
      sql: sql,
      params: typeData == null ? syncIds : <Object?>[...syncIds, typeData],
      decode: _decodeAll,
    );
  }

  Future<int> count() => runDbRead(
    db,
    sql: 'SELECT COUNT(*) AS c FROM "ComicLink"',
    decode: countFromRows,
  );

  Future<int> put(ComicLink value) async {
    if (value.id > 0) {
      await db.execute(_linkUpsert, _params(value, includeId: true));
      return value.id;
    }
    final result = await db.execute(
      _linkInsert,
      _params(value, includeId: false),
    );
    value.id = result.lastInsertId;
    return value.id;
  }

  Future<List<int>> putMany(List<ComicLink> values) async {
    if (values.isEmpty) return const <int>[];
    return db.transaction((tx) async {
      final ids = <int>[];
      for (final value in values) {
        ids.add(await _putInTx(tx, value));
      }
      return ids;
    });
  }

  Future<int> removeById(int id) async {
    final result = await db.execute(
      'DELETE FROM "ComicLink" WHERE "id" = ?',
      <Object?>[id],
    );
    return result.changes;
  }

  Future<int> removeAll() async {
    final result = await db.execute('DELETE FROM "ComicLink"');
    return result.changes;
  }

  Future<int> _putInTx(DbTransaction tx, ComicLink value) async {
    if (value.id > 0) {
      await tx.execute(_linkUpsert, _params(value, includeId: true));
      return value.id;
    }
    final result = await tx.execute(
      _linkInsert,
      _params(value, includeId: false),
    );
    value.id = result.lastInsertId;
    return value.id;
  }

  List<Object?> _params(ComicLink v, {required bool includeId}) {
    return <Object?>[
      if (includeId) v.id,
      v.uniqueKey,
      v.typeData,
      v.versionVectorJson,
      v.deletedAt,
      v.createdAt,
      v.updatedAt,
      v.comicUniqueKey,
      v.folderSyncId,
    ];
  }

  static ComicLink _decodeRow(Map<String, dynamic> row) {
    return ComicLink.fromJson(withDefaultId(row));
  }

  static List<ComicLink> _decodeAll(List<Map<String, dynamic>> rows) =>
      rows.map(_decodeRow).toList();

  static ComicLink? _decodeFirst(List<Map<String, dynamic>> rows) =>
      rows.isEmpty ? null : _decodeRow(rows.first);
}
