import 'dart:convert';
import 'dart:io';

import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/database/database.dart';
import 'package:zephyr/network/sync/sync_device_id.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/util/async/worker_pool.dart';
import 'package:zephyr/util/rust/rust_loader.dart';

/// 备份导入任务：只带可跨 isolate 传递的参数。
class RestoreBackupTask {
  const RestoreBackupTask({
    required this.handle,
    required this.dataJsonPath,
    required this.includeDownloads,
  });

  final int handle;

  /// 备份内的 objectbox.json（历史文件名）路径；备份没有该文件时为 null。
  final String? dataJsonPath;

  /// 备份是否包含下载文件；不包含时保留下载记录。
  final bool includeDownloads;
}

/// 恢复备份数据：读 JSON、清库、恢复全部表，整体在 worker 池内完成。
///
/// 全库 JSON 解码与逐表 fromJson/写入都很重，放 UI isolate 会明显卡顿；
/// 已在 worker 内时直接执行，不重复入池。
Future<GlobalSettingState?> importBackupData(RestoreBackupTask task) {
  return runInWorker(() => _importBackupDataInWorker(task));
}

/// 单事务：读备份 JSON → 清库 → 恢复全部表，失败回滚保留导入前数据。
Future<GlobalSettingState?> _importBackupDataInWorker(
  RestoreBackupTask task,
) async {
  await initRustLib();
  final db = Database.fromHandle(task.handle);
  final path = task.dataJsonPath;
  final json = path == null
      ? null
      : Map<String, dynamic>.from(
          jsonDecode(File(path).readAsStringSync()) as Map,
        );

  GlobalSettingState? restoredGlobal;
  await db.transaction((_) async {
    final preserveDownloads = !task.includeDownloads;
    await _clearAllData(db, preserveDownloads: preserveDownloads);
    if (json != null) {
      restoredGlobal = await _restoreAllData(
        db,
        json,
        preserveDownloads: preserveDownloads,
      );
    }
  });
  return restoredGlobal;
}

/// 清空所有业务表。
///
/// 当 [preserveDownloads] 为 true 时，保留下载记录，用于导入
/// 不含下载文件的备份，避免本机已下载文件变成无记录的孤儿文件。
///
/// 下载任务在任何情况下都不会被导入，因此下载任务表总是被清空。
Future<void> _clearAllData(
  Database db, {
  bool preserveDownloads = false,
}) async {
  await db.legacy.clearBikaHistories();
  if (!preserveDownloads) await db.legacy.clearBikaDownloads();
  await db.legacy.clearJmFavorites();
  await db.legacy.clearJmHistories();
  if (!preserveDownloads) await db.legacy.clearJmDownloads();
  await db.favorites.removeAll();
  await db.histories.removeAll();
  await db.follows.removeAll();
  if (!preserveDownloads) await db.downloads.removeAll();
  // 注意：UserSetting 不在这里清除，而是在 _restoreUserSetting 中直接覆盖 id=1，
  // 因为应用其他位置假设 UserSetting 的 id 始终为 1。
  // 下载任务在任何情况下都不导入，所以这里总是先清空本地下载任务。
  await db.downloadTasks.removeAll();
  await db.plugins.removeAllConfigs();
  await db.plugins.removeAllInfos();
  if (preserveDownloads) {
    // 不含下载文件的备份不包含下载书架；只清空会从备份恢复的收藏/历史目录，
    // 保留本机下载文件夹和链接，避免下载记录还在但目录结构丢失。
    for (final type in const [
      ComicFolderType.favorite,
      ComicFolderType.history,
    ]) {
      await db.folders.removeByType(type.name);
      await db.links.removeByType(type.name);
    }
  } else {
    await db.folders.removeAll();
    await db.links.removeAll();
  }
  await db.readPreferences.removeAll();
  await db.readChapters.removeAll();
  await db.bookmarks.removeAll();
}

/// 为缺少 `id` 的 JSON 补一个默认 0，避免 json_serializable 生成代码里对 `id` 做非空强制转换时崩溃。
Map<String, dynamic> _withDefaultId(Map<String, dynamic> json) {
  if (!json.containsKey('id') || json['id'] == null) {
    json['id'] = 0;
  }
  return json;
}

/// 从 JSON 恢复所有实体；导入时重置 id 让数据库重新分配主键。
///
/// 旧 Bika/Jm 表通过 [LegacyComicRepository] 的显式插入方法恢复（备份 JSON
/// 是模型形态：日期为 ISO 字符串、列表为数组、布尔为 bool）。
///
/// 对于 ComicFolder / ComicLink，还会用当前设备的 syncDeviceId 对
/// versionVectorJson 做一次 bump，避免导入后同步时出现设备 ID 不一致的冲突。
Future<GlobalSettingState?> _restoreAllData(
  Database db,
  Map<String, dynamic> json, {
  required bool preserveDownloads,
}) async {
  final currentDeviceId = syncDeviceId;
  GlobalSettingState? restoredGlobal;

  String bumpVersionVector(String raw) {
    final map = _parseVersionVector(raw);
    map[currentDeviceId] = (map[currentDeviceId] ?? 0) + 1;
    return jsonEncode(map);
  }

  List<Map<String, dynamic>> rowsOf(String key) {
    return (json[key] as List? ?? const <dynamic>[])
        .whereType<Map>()
        .map((e) => _withDefaultId(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> putAll<T>(
    String key,
    T Function(Map<String, dynamic>) fromJson,
    Future<void> Function(List<T>) write, {
    bool Function(Map<String, dynamic>)? where,
  }) async {
    final items = rowsOf(key)
        .where(where ?? (_) => true)
        .map(fromJson)
        .toList();
    if (items.isEmpty) return;
    await write(items);
  }

  final legacy = db.legacy;
  await legacy.restoreBikaHistories(rowsOf('bikaComicHistory'));
  if (!preserveDownloads) {
    await legacy.restoreBikaDownloads(rowsOf('bikaComicDownload'));
  }
  await legacy.restoreJmFavorites(rowsOf('jmFavorite'));
  await legacy.restoreJmHistories(rowsOf('jmHistory'));
  if (!preserveDownloads) {
    await legacy.restoreJmDownloads(rowsOf('jmDownload'));
  }

  await putAll(
    'unifiedComicFavorite',
    UnifiedComicFavorite.fromJson,
    db.favorites.putMany,
  );
  await putAll(
    'unifiedComicHistory',
    UnifiedComicHistory.fromJson,
    db.histories.putMany,
  );
  await putAll('comicFollow', ComicFollow.fromJson, db.follows.putMany);
  // 不含下载文件的备份：本机下载记录保留，备份里的下载行不再写入，
  // 否则 uniqueKey 冲突（备份 JSON 始终包含下载表）。
  if (!preserveDownloads) {
    await putAll(
      'unifiedComicDownload',
      UnifiedComicDownload.fromJson,
      db.downloads.putMany,
    );
  }
  restoredGlobal = await _restoreUserSetting(db, json['userSetting'] as List?);
  // 下载任务不导入，避免恢复后继续执行已过期的下载任务。
  await putAll('pluginConfig', PluginConfig.fromJson, db.plugins.putConfigs);
  await putAll(
    'pluginInfo',
    PluginInfo.fromJson,
    db.plugins.putInfosWithScripts,
  );
  await putAll(
    'comicFolder',
    (j) {
      final folder = ComicFolder.fromJson(j);
      folder.versionVectorJson = bumpVersionVector(folder.versionVectorJson);
      return folder;
    },
    db.folders.putMany,
    where: preserveDownloads
        ? (j) => j['typeData'] != ComicFolderType.download.name
        : null,
  );
  await putAll(
    'comicLink',
    (j) {
      final link = ComicLink.fromJson(j);
      link.versionVectorJson = bumpVersionVector(link.versionVectorJson);
      return link;
    },
    db.links.putMany,
    where: preserveDownloads
        ? (j) => j['typeData'] != ComicFolderType.download.name
        : null,
  );
  await putAll(
    'comicReadPreference',
    ComicReadPreference.fromJson,
    db.readPreferences.putMany,
  );
  await putAll('comicReadChapter', ComicReadChapter.fromJson, (items) async {
    for (final item in items) {
      await db.readChapters.put(item);
    }
  });
  await putAll('searchBookmark', SearchBookmark.fromJson, (items) async {
    for (final item in items) {
      await db.bookmarks.put(item);
    }
  });
  return restoredGlobal;
}

/// 恢复 UserSetting。
///
/// 应用大量代码假设 UserSetting 的主键固定为 1，[UserSettingRepository.put]
/// 也只会写入 id=1 的槽位，因此这里不先清空再插入，而是直接覆盖该槽位。
/// 恢复后由调用方把恢复结果推回 [GlobalSettingCubit]（必须在 UI isolate 做）。
///
/// 导入是整包覆盖：备份里的全局设置原样写回，不与当前设备做任何合并，
/// 也不修改备份里的设置项修改时间。
Future<GlobalSettingState?> _restoreUserSetting(
  Database db,
  List<dynamic>? list,
) async {
  if (list == null || list.isEmpty) return null;

  final backup = UserSetting.fromJson(
    _withDefaultId(Map<String, dynamic>.from(list.first as Map)),
  );

  final current = await db.userSettings.get();
  final hasBackupGlobal =
      backup.globalSettingData != null && backup.globalSettingData!.isNotEmpty;

  // 复用现有 id=1 的 slot：备份没有的字段沿用本机值。
  final next = UserSetting(
    id: 1,
    globalSettingData: current?.globalSettingData,
    bikaSettingData: current?.bikaSettingData,
    jmSettingData: current?.jmSettingData,
    jmJwt: current?.jmJwt ?? '',
  );
  if (hasBackupGlobal) {
    // 直接写备份原始 JSON，避免重新序列化丢字段或补默认值。
    next.globalSettingData = backup.globalSettingData;
  }
  if (backup.bikaSettingData != null && backup.bikaSettingData!.isNotEmpty) {
    next.bikaSettingData = backup.bikaSettingData;
  }
  if (backup.jmSettingData != null && backup.jmSettingData!.isNotEmpty) {
    next.jmSettingData = backup.jmSettingData;
  }
  next.jmJwt = backup.jmJwt;

  await db.userSettings.put(next);
  return hasBackupGlobal ? backup.globalSetting : null;
}

Map<String, int> _parseVersionVector(String raw) {
  if (raw.trim().isEmpty) return <String, int>{};
  try {
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, (v as num).toInt()));
  } catch (_) {
    return <String, int>{};
  }
}
