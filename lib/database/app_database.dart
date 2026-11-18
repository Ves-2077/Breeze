import 'package:zephyr/database/db.dart';
import 'package:zephyr/database/migration/objectbox_import.dart';
import 'package:zephyr/database/schema.dart';

const int currentSchemaVersion = 1;

class DatabaseIncompatibleException implements Exception {
  const DatabaseIncompatibleException(this.message);

  final String message;

  @override
  String toString() => 'DatabaseIncompatibleException: $message';
}

/// 打开应用数据库：建表/索引 → 校验版本 → 一次性导入旧 ObjectBox 数据。
Future<BreezeDatabase> openAppDatabase({
  required String path,
  required String legacyObjectBoxDir,
}) async {
  final db = await BreezeDatabase.open(path);
  try {
    await _ensureSchema(db);
    await ensureObjectBoxImport(db, legacyObjectBoxDir);
    return db;
  } catch (_) {
    await db.close();
    rethrow;
  }
}

Future<void> _ensureSchema(BreezeDatabase db) async {
  final rows = await db.query('PRAGMA user_version');
  final version = rows.isEmpty
      ? 0
      : (rows.first['user_version'] as num?)?.toInt() ?? 0;
  if (version == 0) {
    await db.executeScript(databaseSchemaSql);
    return;
  }
  if (version > currentSchemaVersion) {
    throw DatabaseIncompatibleException(
      'SQLite schema v$version is newer than app v$currentSchemaVersion',
    );
  }
  // 未来 schema 升级：在这里按版本顺序执行 migration。
}
