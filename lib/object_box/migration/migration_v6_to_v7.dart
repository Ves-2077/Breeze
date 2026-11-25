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

Future<void> migrateV6ToV7(Database database) async {
  final favorites = await database.favorites.getAll();
  final nextFavorites = <UnifiedComicFavorite>[];
  for (final item in favorites) {
    final migrated = _migrateFavorite(item);
    if (migrated != null) nextFavorites.add(migrated);
  }
  await database.favorites.putMany(nextFavorites);

  final histories = await database.histories.getAll();
  final nextHistories = <UnifiedComicHistory>[];
  for (final item in histories) {
    final migrated = _migrateHistory(item);
    if (migrated != null) nextHistories.add(migrated);
  }
  await database.histories.putMany(nextHistories);

  final downloads = await database.downloads.getAll();
  final nextDownloads = <UnifiedComicDownload>[];
  for (final item in downloads) {
    final migrated = _migrateDownload(item);
    if (migrated != null) nextDownloads.add(migrated);
  }
  await database.downloads.putMany(nextDownloads);

  logger.d(
    '[migration_v6_to_v7] '
    'favorite=${nextFavorites.length}, '
    'history=${nextHistories.length}, '
    'download=${nextDownloads.length}',
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
    final renamed = _renameExtensionToExternDeep(raw);
    if (renamed != null) {
      json[key] = renamed;
      changed = true;
    }
  }
  return changed;
}

String? _renameExtensionToExternDeep(String jsonStr) {
  if (!jsonStr.contains('"extension"')) return null;
  try {
    final decoded = jsonDecode(jsonStr);
    final result = _renameExtensionToExtern(decoded);
    if (!result.changed) return null;
    return jsonEncode(result.value);
  } catch (_) {
    return null;
  }
}

class _RenameResult {
  _RenameResult(this.value, this.changed);

  final dynamic value;
  final bool changed;
}

_RenameResult _renameExtensionToExtern(dynamic value) {
  if (value is Map<String, dynamic>) {
    var changed = false;
    final result = <String, dynamic>{};
    for (final entry in value.entries) {
      final newKey = entry.key == 'extension' ? 'extern' : entry.key;
      if (entry.key == 'extension') changed = true;
      final renamedValue = _renameExtensionToExtern(entry.value);
      if (renamedValue.changed) changed = true;
      result[newKey] = renamedValue.value;
    }
    return _RenameResult(result, changed);
  }
  if (value is List) {
    var changed = false;
    final result = <dynamic>[];
    for (final item in value) {
      final renamedItem = _renameExtensionToExtern(item);
      if (renamedItem.changed) changed = true;
      result.add(renamedItem.value);
    }
    return _RenameResult(result, changed);
  }
  if (value is String) {
    if (value.contains('"extension"')) {
      try {
        final decoded = jsonDecode(value);
        final renamed = _renameExtensionToExtern(decoded);
        if (renamed.changed) {
          return _RenameResult(jsonEncode(renamed.value), true);
        }
      } catch (_) {}
    }
    return _RenameResult(value, false);
  }
  return _RenameResult(value, false);
}
