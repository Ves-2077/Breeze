import 'dart:convert';

import 'package:zephyr/model/comic_info_meta.dart';
import 'package:zephyr/util/text/chinese_convert.dart';

/// 构建列表本地搜索用的归一化文本。
///
/// 纯 Dart（`t2s` 走 Rust OpenCC，同步 FFI），可以在 compute isolate 内调用。
String buildComicSearchText(dynamic comic) {
  final text = [
    comic.comicId?.toString() ?? '',
    comic.title?.toString() ?? '',
    comic.description?.toString() ?? '',
    _creatorName(comic.creator),
    _titleMetaText(comic.titleMeta),
    _metadataText(comic.metadata),
    comic.source?.toString() ?? '',
  ].join();
  return normalizeSearchText(text);
}

String _creatorName(dynamic creator) {
  if (creator is Creator) return creator.name;
  final raw = creator?.toString() ?? '';
  if (raw.trim().isEmpty) return '';
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map) return decoded['name']?.toString() ?? '';
  } catch (_) {}
  return '';
}

String _titleMetaText(dynamic value) {
  if (value is! List) return value?.toString() ?? '';
  return value.map((item) {
    if (item is ComicInfoActionItem) return item.name;
    if (item is Map) return item['name']?.toString() ?? '';
    return item?.toString() ?? '';
  }).join();
}

String _metadataText(dynamic value) {
  if (value is! List) return value?.toString() ?? '';
  final buffer = StringBuffer();
  for (final item in value) {
    if (item is ComicInfoMetadata) {
      buffer
        ..write(item.type)
        ..write(item.name);
      for (final entry in item.value) {
        buffer.write(entry.name);
      }
    } else if (item is Map) {
      buffer
        ..write(item['type']?.toString() ?? '')
        ..write(item['name']?.toString() ?? '');
      final entries = item['value'];
      if (entries is List) {
        for (final entry in entries) {
          if (entry is Map) {
            buffer.write(entry['name']?.toString() ?? '');
          } else {
            buffer.write(entry?.toString() ?? '');
          }
        }
      }
    } else {
      buffer.write(item?.toString() ?? '');
    }
  }
  return buffer.toString();
}

String normalizeSearchText(String text) {
  final lower = text.trim().toLowerCase();
  if (lower.isEmpty) return '';
  try {
    return t2s(lower);
  } catch (_) {
    return lower;
  }
}
