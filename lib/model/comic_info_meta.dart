import 'package:freezed_annotation/freezed_annotation.dart';

part 'comic_info_meta.freezed.dart';
part 'comic_info_meta.g.dart';

/// 漫画展示用的通用结构。
///
/// 这些类型既用于插件详情（[ComicInfo]），也用于本地 SQLite 记录
/// （收藏/历史/下载/追更）的 JSON 字段，因此放在 `lib/model/` 而不是
/// 详情页模块里，避免存储模型反向依赖页面。
@freezed
abstract class ComicInfoActionItem with _$ComicInfoActionItem {
  const factory ComicInfoActionItem({
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'onTap') @Default({}) Map<String, dynamic> onTap,
    @JsonKey(name: 'onLongPress') String? onLongPress,
    @JsonKey(name: 'extern') @Default({}) Map<String, dynamic> extern,
  }) = _ComicInfoActionItem;

  factory ComicInfoActionItem.fromJson(Map<String, dynamic> json) =>
      _$ComicInfoActionItemFromJson(json);
}

@freezed
abstract class ComicInfoMetadata with _$ComicInfoMetadata {
  const factory ComicInfoMetadata({
    @JsonKey(name: 'type') required String type,
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'value') required List<ComicInfoActionItem> value,
  }) = _ComicInfoMetadata;

  factory ComicInfoMetadata.fromJson(Map<String, dynamic> json) =>
      _$ComicInfoMetadataFromJson(json);
}

@freezed
abstract class ComicImage with _$ComicImage {
  const factory ComicImage({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'url') required String url,
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'path') @Default('') String path,
    @JsonKey(name: 'extern') @Default({}) Map<String, dynamic> extern,
  }) = _ComicImage;

  factory ComicImage.fromJson(Map<String, dynamic> json) =>
      _$ComicImageFromJson(json);
}

@freezed
abstract class Creator with _$Creator {
  const factory Creator({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'avatar') required ComicImage avatar,
    @JsonKey(name: 'onTap') @Default({}) Map<String, dynamic> onTap,
    @JsonKey(name: 'extern') @Default({}) Map<String, dynamic> extern,
  }) = _Creator;

  factory Creator.fromJson(Map<String, dynamic> json) =>
      _$CreatorFromJson(json);
}
