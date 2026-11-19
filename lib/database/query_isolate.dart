import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:zephyr/database/db.dart';
import 'package:zephyr/util/rust_loader.dart';

/// 一条「SQL 查询 + 行解码」任务，整体在 worker isolate 内执行。
///
/// [decode] 必须是顶层/静态函数（或只捕获轻量数据的闭包），不能捕获仓库实例。
class DbReadTask<R> {
  const DbReadTask({
    required this.handle,
    required this.sql,
    required this.params,
    required this.decode,
  });

  final int handle;
  final String sql;
  final List<Object?> params;
  final R Function(List<Map<String, dynamic>> rows) decode;
}

bool _dbWorkerIsolate = false;

/// 把当前 isolate 标记为数据库 worker。
///
/// 已经是 worker 时，仓库读取直接在当前 isolate 执行，不再二次 spawn
/// （备份、启动快照、书架加载、同步打包等入口本来就在 compute 内）。
void markDbWorkerIsolate() {
  _dbWorkerIsolate = true;
}

/// 查询并在 worker isolate 内完成 JSON→模型 的解码。
///
/// - 事务内调用时自动使用 Zone 中登记的事务连接（[BreezeDatabase.activeHandle]）。
/// - 主 isolate 只做参数归一化与 spawn；行的 JSON 解析、`normalizeRow`、
///   `fromJson` 全部在 worker 内完成。
/// - 结果通过 `Isolate.exit` 转移回主 isolate，不拷贝。
Future<R> runDbRead<R>(
  BreezeDatabase db, {
  required String sql,
  List<Object?> params = const <Object?>[],
  required R Function(List<Map<String, dynamic>> rows) decode,
}) {
  final task = DbReadTask<R>(
    handle: db.activeHandle,
    sql: sql,
    params: params,
    decode: decode,
  );
  if (_dbWorkerIsolate) return _executeDbRead(task);
  return compute(_executeDbRead<R>, task);
}

Future<R> _executeDbRead<R>(DbReadTask<R> task) async {
  _dbWorkerIsolate = true;
  await initRustLib();
  final rows = await BreezeDatabase.fromHandle(task.handle)
      .query(task.sql, task.params);
  return task.decode(rows);
}

/// `SELECT COUNT(*) AS c ...` 的通用解码。
int countFromRows(List<Map<String, dynamic>> rows) =>
    (rows.single['c'] as num).toInt();

/// 按 SQLite 参数上限把列表切成小块（默认 400 个占位符）。
Iterable<List<T>> chunkParams<T>(List<T> values, {int size = 400}) sync* {
  for (var start = 0; start < values.length; start += size) {
    final end = start + size < values.length ? start + size : values.length;
    yield values.sublist(start, end);
  }
}
