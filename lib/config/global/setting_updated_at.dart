// 设置项修改时间工具。
//
// 每个设置项在 [GlobalSettingState.settingUpdatedAt] 中按 JSON 路径记录
// 最近一次修改时间（UTC 毫秒时间戳），同步时按项做 LWW 合并。旧版同步
// 只带块级 `updatedAt`，读取时会用块时间补齐缺省项，从而兼容旧数据。

import 'package:collection/collection.dart';

/// 设置状态 JSON 中保存逐项修改时间的字段名。
const String settingUpdatedAtJsonKey = 'settingUpdatedAt';

/// 同步时间由同步流程单独维护，不参与设置项的修改时间比较。
const String settingsSyncTimePath = 'syncSetting.settingsSyncTime';

const Set<String> _ignoredSettingPaths = <String>{
  settingUpdatedAtJsonKey,
  settingsSyncTimePath,
};

const DeepCollectionEquality _settingValueEquality = DeepCollectionEquality();

/// 把设置 JSON 展开成 `路径 -> 叶子值`。
///
/// 嵌套 Map 递归展开；列表、空 Map 和标量都视为叶子。修改时间本身与同步
/// 时间不参与比较。
Map<String, Object?> flattenSettingJson(
  Map<String, dynamic> json, {
  String prefix = '',
}) {
  final result = <String, Object?>{};
  for (final entry in json.entries) {
    final path = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
    if (_ignoredSettingPaths.contains(path)) {
      continue;
    }
    final value = entry.value;
    if (value is Map) {
      final nested = value is Map<String, dynamic>
          ? value
          : value.map((key, val) => MapEntry(key.toString(), val));
      if (nested.isEmpty) {
        result[path] = const <String, dynamic>{};
      } else {
        result.addAll(flattenSettingJson(nested, prefix: path));
      }
      continue;
    }
    result[path] = value;
  }
  return result;
}

/// 比较两次设置 JSON，返回下一次要持久化的逐项修改时间。
///
/// 值发生变化的项写入 [now]；未变化的项保留 [current] 中的时间（包括
/// 0 基准）；被移除的项直接丢弃。
Map<String, int> updateSettingUpdatedAt({
  required Map<String, dynamic> previous,
  required Map<String, dynamic> next,
  required Map<String, int> current,
  required int now,
}) {
  final previousFlat = flattenSettingJson(previous);
  final nextFlat = flattenSettingJson(next);
  final result = <String, int>{};

  for (final entry in nextFlat.entries) {
    final path = entry.key;
    final knownTimestamp = current[path];
    if (!previousFlat.containsKey(path) ||
        !_settingValueEquality.equals(previousFlat[path], entry.value)) {
      result[path] = now;
    } else if (knownTimestamp != null) {
      result[path] = knownTimestamp;
    }
  }

  return result;
}

/// 为所有当前设置项补齐修改时间记录。
///
/// 缺失的项写入 [baseline]（0 表示未知/从未修改）。已有时间（包括 0）
/// 原样保留。用于旧数据升级时让每个设置项都能参与同步比较，而不是被
/// 当成不存在。
Map<String, int> hydrateSettingUpdatedAt({
  required Map<String, dynamic> stateJson,
  required Map<String, int> current,
  int baseline = 0,
}) {
  final result = <String, int>{};
  for (final path in flattenSettingJson(stateJson).keys) {
    result[path] = current.containsKey(path)
        ? current[path]!
        : (baseline > 0 ? baseline : 0);
  }
  return result;
}

/// 从设置状态的全量时间戳中提取某个同步块内各字段的时间。
///
/// [pathPrefix] 用于把设置路径映射到块内相对路径，例如阅读器块的
/// `readSetting.readMode` 对应块内 `readMode`；缺失的字段回退到 [fallback]。
Map<String, int> settingTimestampsForBlock({
  required Map<String, int> settingUpdatedAt,
  required Map<String, dynamic> blockData,
  required String pathPrefix,
  required int fallback,
}) {
  final result = <String, int>{};
  for (final path in flattenSettingJson(blockData).keys) {
    final statePath = pathPrefix.isEmpty ? path : '$pathPrefix.$path';
    result[path] = _positiveTimestamp(settingUpdatedAt[statePath], fallback);
  }
  return result;
}

/// 解析同步负载中的块级逐项时间。
///
/// 旧版负载没有 `fieldUpdatedAt`，此时整块字段都回退到块级 `updatedAt`，
/// 与旧版“整块 LWW”语义一致。
Map<String, int> settingTimestampsFromPayload({
  required Map<String, dynamic> blockData,
  required Object? rawFieldUpdatedAt,
  required int blockUpdatedAt,
}) {
  final raw = rawFieldUpdatedAt is Map
      ? rawFieldUpdatedAt.map((key, value) => MapEntry(key.toString(), value))
      : const <String, dynamic>{};
  final result = <String, int>{};
  for (final path in flattenSettingJson(blockData).keys) {
    final value = int.tryParse(raw[path]?.toString() ?? '');
    result[path] = _positiveTimestamp(value, blockUpdatedAt);
  }
  return result;
}

int _positiveTimestamp(int? value, int fallback) {
  if (value != null && value > 0) {
    return value;
  }
  return fallback > 0 ? fallback : 0;
}

/// 从设置 JSON 中移除指定路径（点号分隔）。
///
/// 用于把安全/设备相关的本地字段从全量同步块中剔除。父级 Map 不存在时
/// 直接跳过。
void removeSettingPaths(Map<String, dynamic> json, Iterable<String> paths) {
  for (final path in paths) {
    final parts = path.split('.').where((item) => item.isNotEmpty).toList();
    if (parts.isEmpty) {
      continue;
    }
    Map<String, dynamic>? node = json;
    for (var index = 0; index < parts.length - 1; index++) {
      final child = node![parts[index]];
      if (child is Map<String, dynamic>) {
        node = child;
      } else {
        node = null;
        break;
      }
    }
    node?.remove(parts.last);
  }
}

/// 把单个设置项的值写到 JSON 的指定路径上。
///
/// 父级不存在时创建嵌套 Map；列表/标量整体替换。
void setSettingJsonValue(
  Map<String, dynamic> json,
  String path,
  Object? value,
) {
  final parts = path.split('.').where((item) => item.isNotEmpty).toList();
  if (parts.isEmpty) {
    return;
  }
  var node = json;
  for (var index = 0; index < parts.length - 1; index++) {
    final child = node[parts[index]];
    if (child is Map<String, dynamic>) {
      node = child;
    } else {
      final next = <String, dynamic>{};
      node[parts[index]] = next;
      node = next;
    }
  }
  node[parts.last] = value;
}
