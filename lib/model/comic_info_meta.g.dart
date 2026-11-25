// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comic_info_meta.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ComicInfoActionItem _$ComicInfoActionItemFromJson(Map<String, dynamic> json) =>
    _ComicInfoActionItem(
      name: json['name'] as String,
      onTap: json['onTap'] as Map<String, dynamic>? ?? const {},
      onLongPress: json['onLongPress'] as String?,
      extern: json['extern'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$ComicInfoActionItemToJson(
  _ComicInfoActionItem instance,
) => <String, dynamic>{
  'name': instance.name,
  'onTap': instance.onTap,
  'onLongPress': instance.onLongPress,
  'extern': instance.extern,
};

_ComicInfoMetadata _$ComicInfoMetadataFromJson(Map<String, dynamic> json) =>
    _ComicInfoMetadata(
      type: json['type'] as String,
      name: json['name'] as String,
      value: (json['value'] as List<dynamic>)
          .map((e) => ComicInfoActionItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ComicInfoMetadataToJson(_ComicInfoMetadata instance) =>
    <String, dynamic>{
      'type': instance.type,
      'name': instance.name,
      'value': instance.value.map((e) => e.toJson()).toList(),
    };

_ComicImage _$ComicImageFromJson(Map<String, dynamic> json) => _ComicImage(
  id: json['id'] as String,
  url: json['url'] as String,
  name: json['name'] as String,
  path: json['path'] as String? ?? '',
  extern: json['extern'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$ComicImageToJson(_ComicImage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'name': instance.name,
      'path': instance.path,
      'extern': instance.extern,
    };

_Creator _$CreatorFromJson(Map<String, dynamic> json) => _Creator(
  id: json['id'] as String,
  name: json['name'] as String,
  avatar: ComicImage.fromJson(json['avatar'] as Map<String, dynamic>),
  onTap: json['onTap'] as Map<String, dynamic>? ?? const {},
  extern: json['extern'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$CreatorToJson(_Creator instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'avatar': instance.avatar.toJson(),
  'onTap': instance.onTap,
  'extern': instance.extern,
};
