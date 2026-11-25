import 'dart:convert';

import 'package:zephyr/database/database.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/object_box/model.dart';

const _comicJsonFields = <String>['cover', 'creator', 'titleMeta', 'metadata'];
const _downloadJsonFields = <String>[
  ..._comicJsonFields,
  'chapters',
  'detailJson',
];

Future<void> migrateV4ToV5(Database database) async {
  final favorites = await database.favorites.getAll();
  final changedFavorites = <UnifiedComicFavorite>[];
  for (final item in favorites) {
    final migrated = _migrateFavorite(item);
    if (migrated != null) changedFavorites.add(migrated);
  }
  await database.favorites.putMany(changedFavorites);

  final histories = await database.histories.getAll();
  final changedHistories = <UnifiedComicHistory>[];
  for (final item in histories) {
    final migrated = _migrateHistory(item);
    if (migrated != null) changedHistories.add(migrated);
  }
  await database.histories.putMany(changedHistories);

  final downloads = await database.downloads.getAll();
  final changedDownloads = <UnifiedComicDownload>[];
  for (final item in downloads) {
    final migrated = _migrateDownload(item);
    if (migrated != null) changedDownloads.add(migrated);
  }
  await database.downloads.putMany(changedDownloads);

  logger.d(
    '[migration_v4_to_v5] favorite=${changedFavorites.length}, '
    'history=${changedHistories.length}, download=${changedDownloads.length}',
  );
}

UnifiedComicFavorite? _migrateFavorite(UnifiedComicFavorite item) {
  final json = item.toJson();
  if (!_renameFields(json, _comicJsonFields)) return null;
  return UnifiedComicFavorite.fromJson(json);
}

UnifiedComicHistory? _migrateHistory(UnifiedComicHistory item) {
  final json = item.toJson();
  if (!_renameFields(json, _comicJsonFields)) return null;
  return UnifiedComicHistory.fromJson(json);
}

UnifiedComicDownload? _migrateDownload(UnifiedComicDownload item) {
  final json = item.toJson();
  if (!_renameFields(json, _downloadJsonFields)) return null;
  return UnifiedComicDownload.fromJson(json);
}

bool _renameFields(Map<String, dynamic> json, List<String> fields) {
  var changed = false;
  for (final key in fields) {
    final raw = json[key];
    if (raw is! String) continue;
    final renamed = _renameExtensionToExternInJsonString(raw);
    if (renamed != null) {
      json[key] = renamed;
      changed = true;
    }
  }
  return changed;
}

String? _renameExtensionToExternInJsonString(String jsonStr) {
  if (!jsonStr.contains('extension')) return null;
  final decoded = jsonDecode(jsonStr);
  final renamed = _renameExtensionToExtern(decoded);
  return jsonEncode(renamed);
}

dynamic _renameExtensionToExtern(dynamic value) {
  if (value is Map<String, dynamic>) {
    final map = <String, dynamic>{};
    for (final entry in value.entries) {
      final key = entry.key == 'extension' ? 'extern' : entry.key;
      map[key] = _renameExtensionToExtern(entry.value);
    }
    return map;
  }
  if (value is List) {
    return value.map(_renameExtensionToExtern).toList();
  }
  return value;
}
