import 'package:zephyr/database/db.dart';
import 'package:zephyr/database/row_codec.dart';
import 'package:zephyr/object_box/model.dart';

const _pluginInfoInsert =
    'INSERT INTO "PluginInfo" '
    '("version","insertedAt","updatedAt","isEnabled","isDeleted","uuid",'
    '"lastLoadSuccess","lastLoadError","deletedAt","debug","debugUrl",'
    '"originScript","getInfoJson","sortOrder") '
    'VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)';

const _pluginInfoUpsert =
    'INSERT INTO "PluginInfo" '
    '("id","version","insertedAt","updatedAt","isEnabled","isDeleted","uuid",'
    '"lastLoadSuccess","lastLoadError","deletedAt","debug","debugUrl",'
    '"originScript","getInfoJson","sortOrder") '
    'VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?) '
    'ON CONFLICT("id") DO UPDATE SET '
    '"version"=excluded."version","insertedAt"=excluded."insertedAt",'
    '"updatedAt"=excluded."updatedAt","isEnabled"=excluded."isEnabled",'
    '"isDeleted"=excluded."isDeleted","uuid"=excluded."uuid",'
    '"lastLoadSuccess"=excluded."lastLoadSuccess",'
    '"lastLoadError"=excluded."lastLoadError","deletedAt"=excluded."deletedAt",'
    '"debug"=excluded."debug","debugUrl"=excluded."debugUrl",'
    '"originScript"=excluded."originScript","getInfoJson"=excluded."getInfoJson",'
    '"sortOrder"=excluded."sortOrder"';

const _pluginConfigInsert =
    'INSERT INTO "PluginConfig" ("name","config") VALUES (?,?)';

const _pluginConfigUpsert =
    'INSERT INTO "PluginConfig" ("id","name","config") VALUES (?,?,?) '
    'ON CONFLICT("id") DO UPDATE SET '
    '"name"=excluded."name","config"=excluded."config"';

class PluginRepository {
  final BreezeDatabase db;

  const PluginRepository(this.db);

  static const String infoTable = 'PluginInfo';
  static const String configTable = 'PluginConfig';

  Future<List<PluginInfo>> listInfos() async {
    final rows = await db.query('SELECT * FROM "PluginInfo" ORDER BY "id"');
    return rows.map(_decodeInfo).toList();
  }

  Future<PluginInfo?> getInfoById(int id) async {
    final rows = await db.query(
      'SELECT * FROM "PluginInfo" WHERE "id" = ? LIMIT 1',
      <Object?>[id],
    );
    return rows.isEmpty ? null : _decodeInfo(rows.first);
  }

  Future<PluginInfo?> getInfoByUuid(String uuid) async {
    final rows = await db.query(
      'SELECT * FROM "PluginInfo" WHERE "uuid" = ? LIMIT 1',
      <Object?>[uuid],
    );
    return rows.isEmpty ? null : _decodeInfo(rows.first);
  }

  Future<List<PluginInfo>> listDeletedInfos() async {
    final rows = await db.query(
      'SELECT * FROM "PluginInfo" WHERE "isDeleted" = 1 ORDER BY "id"',
    );
    return rows.map(_decodeInfo).toList();
  }

  Future<int> putInfo(PluginInfo value) async {
    if (value.id > 0) {
      await db.execute(_pluginInfoUpsert, _infoParams(value, includeId: true));
      return value.id;
    }
    final result = await db.execute(
      _pluginInfoInsert,
      _infoParams(value, includeId: false),
    );
    value.id = result.lastInsertId;
    return value.id;
  }

  Future<List<int>> putInfos(List<PluginInfo> values) async {
    if (values.isEmpty) return const <int>[];
    return db.transaction((tx) async {
      final ids = <int>[];
      for (final value in values) {
        ids.add(await _putInfoInTx(tx, value));
      }
      return ids;
    });
  }

  Future<int> removeInfoById(int id) async {
    final result = await db.execute(
      'DELETE FROM "PluginInfo" WHERE "id" = ?',
      <Object?>[id],
    );
    return result.changes;
  }

  Future<int> removeInfosByIds(List<int> ids) async {
    if (ids.isEmpty) return 0;
    final marks = List.filled(ids.length, '?').join(',');
    final result = await db.execute(
      'DELETE FROM "PluginInfo" WHERE "id" IN ($marks)',
      ids,
    );
    return result.changes;
  }

  Future<int> removeAllInfos() async {
    final result = await db.execute('DELETE FROM "PluginInfo"');
    return result.changes;
  }

  Future<List<PluginConfig>> listConfigs() async {
    final rows = await db.query('SELECT * FROM "PluginConfig" ORDER BY "id"');
    return rows.map(_decodeConfig).toList();
  }

  Future<PluginConfig?> getConfigById(int id) async {
    final rows = await db.query(
      'SELECT * FROM "PluginConfig" WHERE "id" = ? LIMIT 1',
      <Object?>[id],
    );
    return rows.isEmpty ? null : _decodeConfig(rows.first);
  }

  Future<PluginConfig?> getConfigByName(String name) async {
    final rows = await db.query(
      'SELECT * FROM "PluginConfig" WHERE "name" = ? LIMIT 1',
      <Object?>[name],
    );
    return rows.isEmpty ? null : _decodeConfig(rows.first);
  }

  Future<int> putConfig(PluginConfig value) async {
    if (value.id > 0) {
      await db.execute(_pluginConfigUpsert, <Object?>[
        value.id,
        value.name,
        value.config,
      ]);
      return value.id;
    }
    final result = await db.execute(_pluginConfigInsert, <Object?>[
      value.name,
      value.config,
    ]);
    value.id = result.lastInsertId;
    return value.id;
  }

  Future<List<int>> putConfigs(List<PluginConfig> values) async {
    if (values.isEmpty) return const <int>[];
    return db.transaction((tx) async {
      final ids = <int>[];
      for (final value in values) {
        ids.add(await _putConfigInTx(tx, value));
      }
      return ids;
    });
  }

  Future<int> removeConfigByIds(List<int> ids) async {
    if (ids.isEmpty) return 0;
    final marks = List.filled(ids.length, '?').join(',');
    final result = await db.execute(
      'DELETE FROM "PluginConfig" WHERE "id" IN ($marks)',
      ids,
    );
    return result.changes;
  }

  Future<int> removeConfigByName(String name) async {
    final result = await db.execute(
      'DELETE FROM "PluginConfig" WHERE "name" = ?',
      <Object?>[name],
    );
    return result.changes;
  }

  Future<int> removeAllConfigs() async {
    final result = await db.execute('DELETE FROM "PluginConfig"');
    return result.changes;
  }

  Future<int> _putInfoInTx(DbTransaction tx, PluginInfo value) async {
    if (value.id > 0) {
      await tx.execute(_pluginInfoUpsert, _infoParams(value, includeId: true));
      return value.id;
    }
    final result = await tx.execute(
      _pluginInfoInsert,
      _infoParams(value, includeId: false),
    );
    value.id = result.lastInsertId;
    return value.id;
  }

  List<Object?> _infoParams(PluginInfo v, {required bool includeId}) {
    return <Object?>[
      if (includeId) v.id,
      v.version,
      dateToDb(v.insertedAt),
      dateToDb(v.updatedAt),
      boolToDb(v.isEnabled),
      boolToDb(v.isDeleted),
      v.uuid,
      boolToDb(v.lastLoadSuccess),
      v.lastLoadError,
      dateToDb(v.deletedAt),
      boolToDb(v.debug),
      v.debugUrl,
      v.originScript,
      v.getInfoJson,
      v.sortOrder,
    ];
  }

  Future<int> _putConfigInTx(DbTransaction tx, PluginConfig value) async {
    if (value.id > 0) {
      await tx.execute(_pluginConfigUpsert, <Object?>[
        value.id,
        value.name,
        value.config,
      ]);
      return value.id;
    }
    final result = await tx.execute(_pluginConfigInsert, <Object?>[
      value.name,
      value.config,
    ]);
    value.id = result.lastInsertId;
    return value.id;
  }

  PluginInfo _decodeInfo(Map<String, dynamic> row) {
    return PluginInfo.fromJson(
      normalizeRow(
        withDefaultId(row),
        dates: const <String>{'insertedAt', 'updatedAt'},
        nullableDates: const <String>{'deletedAt'},
        bools: const <String>{
          'isEnabled',
          'isDeleted',
          'lastLoadSuccess',
          'debug',
        },
      ),
    );
  }

  PluginConfig _decodeConfig(Map<String, dynamic> row) {
    return PluginConfig.fromJson(withDefaultId(row));
  }
}
