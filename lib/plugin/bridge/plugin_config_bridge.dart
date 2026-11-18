import 'dart:async';
import 'dart:convert';

import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/src/rust/api/qjs.dart';

final Map<String, PluginConfig> _configCache = <String, PluginConfig>{};

/// 启动时把 PluginConfig 读入内存；同步读接口只读这份缓存。
Future<void> preloadPluginConfigs() async {
  final list = await database.plugins.listConfigs();
  _configCache
    ..clear()
    ..addEntries(list.map((item) => MapEntry(item.name, item)));
}

Future<String> onSavePluginConfig(String name, String key, String value) async {
  final existing =
      _configCache[name] ?? await database.plugins.getConfigByName(name);
  final parsedValue = _decodeMaybeJson(value);

  final entity = existing ?? PluginConfig(name: name, config: '{}');
  final data = _decodeObjectMap(entity.config);
  if (key.isNotEmpty) {
    data[key] = parsedValue;
  }
  entity.config = jsonEncode(data);
  await database.plugins.putConfig(entity);
  _configCache[name] = entity;
  return '{"ok":true}';
}

Future<String> onLoadPluginConfig(
  String name,
  String key,
  String fallback,
) async {
  final entity =
      _configCache[name] ?? await database.plugins.getConfigByName(name);
  final data = _decodeObjectMap(entity?.config ?? '');
  final value = key.isEmpty ? data : (data[key] ?? _decodeMaybeJson(fallback));
  return '{"ok":true,"value":${jsonEncode(value)}}';
}

Map<String, dynamic> _decodeObjectMap(String raw) {
  final text = raw.trim();
  if (text.isEmpty) {
    return <String, dynamic>{};
  }
  try {
    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    if (decoded is Map) {
      return decoded.map((key, value) => MapEntry(key.toString(), value));
    }
  } catch (_) {}
  return <String, dynamic>{};
}

dynamic _decodeMaybeJson(String value) {
  final text = value.trim();
  if (text.isEmpty) {
    return value;
  }
  try {
    return jsonDecode(text);
  } catch (_) {
    return value;
  }
}

void _register(
  String functionName,
  FutureOr<String> Function(String) dartCallback,
) {
  registerFunction(functionName: functionName, dartCallback: dartCallback);
}

void registerPersistentCallbacks() {
  _register('save_plugin_config', (String data) async {
    final args = jsonDecode(data) as List<dynamic>;
    final runtime = args[0] as String;
    final pluginName = args[1] as String;
    final value = args[2] as String;
    return onSavePluginConfig(runtime, pluginName, value);
  });

  _register('load_plugin_config', (String data) async {
    final args = jsonDecode(data) as List<dynamic>;
    final runtime = args[0] as String;
    final pluginName = args[1] as String;
    final fallback = args[2] as String;
    return onLoadPluginConfig(runtime, pluginName, fallback);
  });
}

Future<void> savePluginConfigValue(
  String pluginName,
  String key,
  dynamic value,
) async {
  await onSavePluginConfig(pluginName, key, jsonEncode(value));
}

/// 同步写接口：先更新内存缓存，数据库写入异步完成。
///
/// 插件配置在启动时已 [preloadPluginConfigs]，因此同步读/写都只操作缓存；
/// 这样 QJS 同步宿主调用和旧 UI 代码不需要改成异步。
void savePluginConfigValueSync(String pluginName, String key, dynamic value) {
  final entity =
      _configCache[pluginName] ?? PluginConfig(name: pluginName, config: '{}');
  final data = _decodeObjectMap(entity.config);
  data[key] = value;
  entity.config = jsonEncode(data);
  _configCache[pluginName] = entity;
  unawaited(database.plugins.putConfig(entity));
}

T loadPluginConfigValue<T>(
  String pluginName,
  String key, {
  required T fallback,
}) {
  final entity = _configCache[pluginName];
  if (entity == null) return fallback;
  final data = _decodeObjectMap(entity.config);
  final value = data[key];
  return value is T ? value : fallback;
}
