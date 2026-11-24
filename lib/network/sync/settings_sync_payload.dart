// 设置同步的逐项协议。
//
// 同步负载中的 `settingItems` 把每个设置项单独表示为
// `{value, updatedAt}`，路径为设置 JSON 路径（如 `readSetting.readMode`）。
// 合并、上传、下载都以单个设置项为单位，不存在“设置块整体覆盖”。

import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:zephyr/config/global/setting_updated_at.dart';

/// 同步负载中逐项设置记录的字段名。
const String settingItemsPayloadKey = 'settingItems';

/// 不参与跨设备同步的设置路径。
///
/// 这些字段要么是设备相关（窗口、缓存、日志、导出目录），要么是安全敏感
/// （应用锁、同步服务凭据），要么是内部状态（迁移版本、瞬态清理标记）。
const Set<String> localOnlySettingPaths = <String>{
  'syncSetting',
  'appLockSetting',
  'cacheSetting',
  'customExportPath',
  'windowWidth',
  'windowHeight',
  'windowX',
  'windowY',
  'enableMemoryDebug',
  'blockRustHttpRequests',
  'logAddress',
  'forceEnableImpeller',
  'androidKeepAliveEnabled',
  'compatibleVersion',
  'themeInitState',
  'needCleanCache',
  // 墨水屏开关与检测结果跟具体设备绑定；其余墨水屏偏好仍可同步。
  'eInkSetting.enabled',
  'eInkSetting.detectionHandled',
  // 上次停留的书架页签属于本机 UI 状态。
  'bookshelfSetting.homePageIndex',
};

bool isLocalOnlySettingPath(String path) {
  for (final excluded in localOnlySettingPaths) {
    if (path == excluded || path.startsWith('$excluded.')) {
      return true;
    }
  }
  return false;
}

/// 从 `GlobalSettingState.toJson()` 提取可跨设备同步的完整设置树。
///
/// 返回的是深拷贝，调用方可以安全地修改。
Map<String, dynamic> extractSyncableSettingsData(
  Map<String, dynamic> stateJson,
) {
  final json = jsonDecode(jsonEncode(stateJson)) as Map<String, dynamic>;
  removeSettingPaths(json, localOnlySettingPaths);
  json.remove(settingUpdatedAtJsonKey);
  return json;
}

/// 单个设置项的同步记录。
class SyncedSettingItem {
  const SyncedSettingItem({required this.value, required this.updatedAt});

  factory SyncedSettingItem.fromJson(
    Object? raw, {
    required int fallbackUpdatedAt,
  }) {
    final json = raw is Map
        ? raw.map((key, value) => MapEntry(key.toString(), value))
        : const <String, dynamic>{};
    final timestamp = int.tryParse(json['updatedAt']?.toString() ?? '') ?? 0;
    return SyncedSettingItem(
      value: json['value'],
      updatedAt: timestamp > 0 ? timestamp : fallbackUpdatedAt,
    );
  }

  final Object? value;
  final int updatedAt;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{'value': value, 'updatedAt': updatedAt};
  }
}

/// 把展平后的设置树组装成逐项记录。
Map<String, SyncedSettingItem> buildSyncedSettingItems({
  required Map<String, dynamic> data,
  required Map<String, int> updatedAtByPath,
}) {
  final result = <String, SyncedSettingItem>{};
  for (final entry in flattenSettingJson(data).entries) {
    if (isLocalOnlySettingPath(entry.key)) {
      continue;
    }
    final timestamp = updatedAtByPath[entry.key] ?? 0;
    result[entry.key] = SyncedSettingItem(
      value: entry.value,
      updatedAt: timestamp > 0 ? timestamp : 0,
    );
  }
  return result;
}

/// 解析同步负载中的逐项设置记录，并过滤本地专属字段。
Map<String, SyncedSettingItem> parseSyncedSettingItems(
  Object? raw, {
  required int fallbackUpdatedAt,
}) {
  final json = raw is Map
      ? raw.map((key, value) => MapEntry(key.toString(), value))
      : const <String, dynamic>{};
  final result = <String, SyncedSettingItem>{};
  for (final entry in json.entries) {
    if (isLocalOnlySettingPath(entry.key)) {
      continue;
    }
    result[entry.key] = SyncedSettingItem.fromJson(
      entry.value,
      fallbackUpdatedAt: fallbackUpdatedAt,
    );
  }
  return result;
}

/// 按设置项自身的修改时间合并；时间相同保持本地优先。
Map<String, SyncedSettingItem> mergeSyncedSettingItems(
  Map<String, SyncedSettingItem> local,
  Map<String, SyncedSettingItem> remote,
) {
  final result = Map<String, SyncedSettingItem>.from(local);
  for (final entry in remote.entries) {
    final localItem = result[entry.key];
    if (localItem == null || entry.value.updatedAt > localItem.updatedAt) {
      result[entry.key] = entry.value;
    }
  }
  return result;
}

/// 判断合并结果里是否有设置项的值与本地不同。
bool settingItemsDiffer(
  Map<String, SyncedSettingItem> local,
  Map<String, SyncedSettingItem> merged,
) {
  const equality = DeepCollectionEquality();
  final paths = <String>{...local.keys, ...merged.keys};
  for (final path in paths) {
    final localItem = local[path];
    final mergedItem = merged[path];
    if (localItem == null || mergedItem == null) {
      return true;
    }
    if (!equality.equals(localItem.value, mergedItem.value)) {
      return true;
    }
  }
  return false;
}

/// 把逐项设置写入设置 JSON，并同步更新 `settingUpdatedAt`。
void applySyncedSettingItems(
  Map<String, dynamic> stateJson,
  Map<String, SyncedSettingItem> items, {
  bool keepNewerLocalTimestamps = true,
}) {
  final timestamps = <String, int>{};
  final rawTimestamps = stateJson[settingUpdatedAtJsonKey];
  if (rawTimestamps is Map) {
    for (final entry in rawTimestamps.entries) {
      final timestamp = int.tryParse(entry.value?.toString() ?? '') ?? 0;
      timestamps[entry.key.toString()] = timestamp;
    }
  }

  for (final entry in items.entries) {
    if (isLocalOnlySettingPath(entry.key)) {
      continue;
    }
    setSettingJsonValue(stateJson, entry.key, entry.value.value);
    final existing = timestamps[entry.key] ?? 0;
    if (!keepNewerLocalTimestamps || entry.value.updatedAt > existing) {
      timestamps[entry.key] = entry.value.updatedAt;
    }
  }
  stateJson[settingUpdatedAtJsonKey] = timestamps;
}

int maxSyncedItemUpdatedAt(Map<String, SyncedSettingItem> items) {
  var result = 0;
  for (final item in items.values) {
    if (item.updatedAt > result) {
      result = item.updatedAt;
    }
  }
  return result;
}
