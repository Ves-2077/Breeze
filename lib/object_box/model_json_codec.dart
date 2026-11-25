import 'dart:convert';

import 'package:zephyr/model/comic_info_meta.dart';
import 'package:zephyr/service/download/models/download_task_json.dart';
import 'package:zephyr/util/json/json_sanitize.dart';
import 'package:zephyr/util/json/json_value.dart';

/// SQLite/备份里的 JSON 字段与内存模型之间的转换。
///
/// 存储层是 TEXT，保持旧版本的 JSON 字符串格式以兼容历史备份/云同步；
/// 读取时同时接受字符串和已解析的 Map/List，便于新代码直接传结构体。
Map<String, dynamic> jsonObjectFromField(dynamic value) {
  if (value is String) return decodeJsonMap(value);
  if (value is Map) return asJsonMap(value);
  return const <String, dynamic>{};
}

Map<String, dynamic> _sanitizedMap(dynamic value) =>
    asJsonMap(sanitizeDynamic(jsonObjectFromField(value)));

List<dynamic> _jsonListFromField(dynamic value) {
  if (value is String) return decodeJsonList(value);
  if (value is List) return value;
  return const <dynamic>[];
}

/// 下载任务 payload：列与旧备份里是 `dbTaskInfoStr` JSON 字符串。
DownloadTaskJson? downloadTaskInfoFromField(dynamic value) {
  final map = jsonObjectFromField(value);
  if (map.isEmpty) return null;
  try {
    return DownloadTaskJson.fromJson(map);
  } catch (_) {
    return null;
  }
}

String? downloadTaskInfoToField(DownloadTaskJson? value) =>
    value == null ? null : jsonEncode(sanitizeDynamic(value.toJson()));

String jsonObjectToField(Map<String, dynamic> value) =>
    jsonEncode(sanitizeDynamic(value));

/// 搜索书签的封面列历史上是非空 TEXT（未设置时为空串），
/// 写入时保持该形状，避免旧版本导入新备份时 `as String` 失败。
String searchBookmarkCoverToField(ComicImage? value) =>
    value == null ? '' : comicImageToField(value);

/// 同步版本向量：DB/备份/云同步仍是 `{"device":n}` 字符串，
/// 内存里用 Map 直接比较/合并。
Map<String, int> versionVectorFromField(dynamic value) {
  final map = jsonObjectFromField(value);
  final vector = <String, int>{};
  map.forEach((key, raw) {
    final count = raw is num
        ? raw.toInt()
        : int.tryParse(raw?.toString() ?? '');
    if (count != null) vector[key] = count;
  });
  return vector;
}

String versionVectorToField(Map<String, int> value) => jsonEncode(value);

Map<String, int> bumpVersionVector(Map<String, int> vector, String deviceId) {
  final next = Map<String, int>.from(vector);
  next[deviceId] = (next[deviceId] ?? 0) + 1;
  return next;
}

ComicImage comicImageFromField(dynamic value) {
  final map = jsonObjectFromField(value);
  final extern = _externOrLegacyExtension(map);
  final path = map['path']?.toString().trim() ?? '';
  final externPath = extern['path']?.toString().trim() ?? '';
  return ComicImage(
    id: map['id']?.toString() ?? '',
    url: map['url']?.toString() ?? '',
    name: map['name']?.toString() ?? '',
    path: path.isNotEmpty ? path : externPath,
    extern: extern,
  );
}

ComicImage? comicImageOrNullFromField(dynamic value) {
  final map = jsonObjectFromField(value);
  return map.isEmpty ? null : comicImageFromField(map);
}

String comicImageToField(ComicImage value) => jsonEncode(
  sanitizeDynamic(<String, dynamic>{
    'id': value.id,
    'url': value.url,
    'name': value.name,
    'path': value.path,
    'extern': value.extern,
  }),
);

String? comicImageOrNullToField(ComicImage? value) =>
    value == null ? null : comicImageToField(value);

Map<String, dynamic> _externOrLegacyExtension(Map<String, dynamic> map) =>
    map['extern'] is Map
    ? _sanitizedMap(map['extern'])
    : _sanitizedMap(map['extension']);

ComicInfoActionItem comicActionItemFromField(dynamic value) {
  final map = jsonObjectFromField(value);
  return ComicInfoActionItem(
    name: map['name']?.toString() ?? '',
    onTap: _sanitizedMap(map['onTap']),
    onLongPress: map['onLongPress']?.toString(),
    extern: _externOrLegacyExtension(map),
  );
}

Creator creatorFromField(dynamic value) {
  final map = jsonObjectFromField(value);
  return Creator(
    id: map['id']?.toString() ?? '',
    name: map['name']?.toString() ?? '',
    avatar: comicImageFromField(map['avatar']),
    onTap: _sanitizedMap(map['onTap']),
    extern: _externOrLegacyExtension(map),
  );
}

String creatorToField(Creator value) => jsonEncode(
  sanitizeDynamic(<String, dynamic>{
    'id': value.id,
    'name': value.name,
    'avatar': value.avatar.toJson(),
    'onTap': value.onTap,
    'extern': value.extern,
  }),
);

List<ComicInfoActionItem> comicTitleMetaFromField(dynamic value) {
  final items = <ComicInfoActionItem>[];
  for (final entry in _jsonListFromField(value)) {
    if (entry is ComicInfoActionItem) {
      if (entry.name.trim().isNotEmpty) items.add(entry);
    } else if (entry is Map) {
      final item = comicActionItemFromField(entry);
      if (item.name.trim().isNotEmpty) items.add(item);
    } else {
      final name = entry?.toString().trim() ?? '';
      if (name.isNotEmpty) items.add(ComicInfoActionItem(name: name));
    }
  }
  return items;
}

String comicTitleMetaToField(List<ComicInfoActionItem> value) =>
    jsonEncode(sanitizeDynamic(value.map((item) => item.toJson()).toList()));

List<ComicInfoMetadata> comicMetadataFromField(dynamic value) {
  final result = <ComicInfoMetadata>[];
  for (final entry in _jsonListFromField(value)) {
    if (entry is ComicInfoMetadata) {
      result.add(entry);
      continue;
    }
    if (entry is! Map) continue;
    final map = asJsonMap(entry);
    final values = <ComicInfoActionItem>[];
    for (final item in _jsonListFromField(map['value'])) {
      if (item is ComicInfoActionItem) {
        if (item.name.trim().isNotEmpty) values.add(item);
      } else if (item is Map) {
        final action = comicActionItemFromField(item);
        if (action.name.trim().isNotEmpty) values.add(action);
      } else {
        final name = item?.toString().trim() ?? '';
        if (name.isNotEmpty) values.add(ComicInfoActionItem(name: name));
      }
    }
    result.add(
      ComicInfoMetadata(
        type: map['type']?.toString() ?? '',
        name: map['name']?.toString() ?? '',
        value: values,
      ),
    );
  }
  return result;
}

String comicMetadataToField(List<ComicInfoMetadata> value) =>
    jsonEncode(sanitizeDynamic(value.map((item) => item.toJson()).toList()));

/// 搜索书签的外层 filter JSON，结构完全由插件定义，只保证是对象。
Map<String, dynamic> searchBookmarkExternFromField(dynamic value) =>
    _sanitizedMap(value);

String searchBookmarkExternToField(Map<String, dynamic> value) =>
    jsonObjectToField(value);
