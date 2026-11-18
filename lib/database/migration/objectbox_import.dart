import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:zephyr/database/db.dart';
import 'package:zephyr/database/migration/legacy_columns.dart';
import 'package:zephyr/src/rust/api/database.dart' as rust;

const String _importStateKey = 'objectbox_import_state';

/// 一次性把旧 ObjectBox LMDB 数据导入 SQLite。
///
/// - 旧库 schema 从 LMDB meta 行读取，不依赖 objectbox-model.json；
/// - 只按当前表列白名单插入，旧库缺列交给 SQL DEFAULT；
/// - 保留原 object id；
/// - 状态写在 app_meta，失败下次启动会清表重试。
Future<void> ensureObjectBoxImport(BreezeDatabase db, String oldDir) async {
  final state = await _readState(db);
  if (state == 'done') return;

  final dataFile = File(p.join(oldDir, 'data.mdb'));
  if (!await dataFile.exists()) {
    await _writeState(db, 'none');
    return;
  }

  await _writeState(db, 'started');
  final payloadText = await rust.dbInspectObjectbox(oldDir: oldDir);
  final payload = jsonDecode(payloadText) as Map<String, dynamic>;
  final entities = payload['entities'] as Map<String, dynamic>? ?? const {};

  var imported = 0;
  final counts = <String, int>{};

  await db.transaction((tx) async {
    // 上次可能中途失败；先清空全部业务表，避免重复主键。
    for (final table in legacyTableColumns.keys) {
      await tx.execute('DELETE FROM ${_quote(table)}');
    }

    for (final entry in entities.entries) {
      final table = entry.key;
      final columns = legacyTableColumns[table];
      if (columns == null) continue;
      final records = (entry.value as List).cast<Map>();
      var count = 0;
      for (final raw in records) {
        final record = Map<String, dynamic>.from(raw);
        final present = <String>[
          for (final column in columns)
            if (record.containsKey(column)) column,
        ];
        if (present.isEmpty) continue;
        final sql =
            'INSERT INTO ${_quote(table)} '
            '(${present.map(_quote).join(', ')}) '
            'VALUES (${List.filled(present.length, '?').join(', ')})';
        await tx.execute(sql, <Object?>[
          for (final column in present) record[column],
        ]);
        imported++;
        count++;
      }
      counts[table] = count;
    }

    final report = jsonEncode(<String, Object?>{
      'oldDir': oldDir,
      'objectRows': payload['objectRows'],
      'skippedRows': payload['skippedRows'],
      'imported': imported,
      'entities': counts,
    });
    await tx.execute(
      'INSERT INTO app_meta(key, value) VALUES(?, ?) '
      'ON CONFLICT(key) DO UPDATE SET value = excluded.value',
      <Object?>[_importStateKey, 'done'],
    );
    await tx.execute(
      'INSERT INTO app_meta(key, value) VALUES(?, ?) '
      'ON CONFLICT(key) DO UPDATE SET value = excluded.value',
      <Object?>['objectbox_import_report', report],
    );
  });
}

Future<String?> _readState(BreezeDatabase db) async {
  final rows = await db.query(
    'SELECT value FROM app_meta WHERE key = ?',
    <Object?>[_importStateKey],
  );
  if (rows.isEmpty) return null;
  return rows.first['value'] as String?;
}

Future<void> _writeState(BreezeDatabase db, String value) async {
  await db.execute(
    'INSERT INTO app_meta(key, value) VALUES(?, ?) '
    'ON CONFLICT(key) DO UPDATE SET value = excluded.value',
    <Object?>[_importStateKey, value],
  );
}

String _quote(String identifier) => '"${identifier.replaceAll('"', '""')}"';
