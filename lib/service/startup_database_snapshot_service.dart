import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:zephyr/main.dart' as app;
import 'package:zephyr/src/rust/api/simple.dart';
import 'package:zephyr/util/get_path.dart';

const _startupDatabaseSnapshotFileName = 'database_snapshot.br';

/// 启动时异步生成数据库快照（Brotli 压缩）。
Future<void> saveStartupDatabaseSnapshot() async {
  try {
    final snapshotPath = p.join(
      await getFilePath(),
      _startupDatabaseSnapshotFileName,
    );
    final json = await app.database.collectAllDataJson();
    final compressed = await compressExtreme(data: utf8.encode(json));
    await File(snapshotPath).writeAsBytes(compressed, flush: true);
    app.logger.i('数据库启动快照已更新：$snapshotPath');
  } catch (error, stackTrace) {
    app.logger.e('更新数据库启动快照失败', error: error, stackTrace: stackTrace);
  }
}
