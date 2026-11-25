// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'normal_comic_all_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NormalComicAllInfo _$NormalComicAllInfoFromJson(Map<String, dynamic> json) =>
    _NormalComicAllInfo(
      comicInfo: ComicInfo.fromJson(json['comicInfo'] as Map<String, dynamic>),
      preview: json['preview'] as Map<String, dynamic>? ?? const {},
      eps: (json['eps'] as List<dynamic>)
          .map((e) => Ep.fromJson(e as Map<String, dynamic>))
          .toList(),
      recommend: (json['recommend'] as List<dynamic>)
          .map((e) => Recommend.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalViews: (json['totalViews'] as num?)?.toInt() ?? 0,
      totalLikes: (json['totalLikes'] as num?)?.toInt() ?? 0,
      totalComments: (json['totalComments'] as num?)?.toInt() ?? 0,
      isFavourite: json['isFavourite'] as bool? ?? false,
      isLiked: json['isLiked'] as bool? ?? false,
      allowComments: json['allowComments'] as bool? ?? false,
      allowLike: json['allowLike'] as bool? ?? false,
      allowCollected: json['allowCollected'] as bool? ?? false,
      allowDownload: json['allowDownload'] as bool? ?? true,
      allowCommentsReason: json['allowCommentsReason'] as String? ?? '',
      allowLikeReason: json['allowLikeReason'] as String? ?? '',
      allowCollectedReason: json['allowCollectedReason'] as String? ?? '',
      allowDownloadReason: json['allowDownloadReason'] as String? ?? '',
      extern: json['extern'] as Map<String, dynamic>? ?? const {},
    );

Map<String, dynamic> _$NormalComicAllInfoToJson(_NormalComicAllInfo instance) =>
    <String, dynamic>{
      'comicInfo': instance.comicInfo.toJson(),
      'preview': instance.preview,
      'eps': instance.eps.map((e) => e.toJson()).toList(),
      'recommend': instance.recommend.map((e) => e.toJson()).toList(),
      'totalViews': instance.totalViews,
      'totalLikes': instance.totalLikes,
      'totalComments': instance.totalComments,
      'isFavourite': instance.isFavourite,
      'isLiked': instance.isLiked,
      'allowComments': instance.allowComments,
      'allowLike': instance.allowLike,
      'allowCollected': instance.allowCollected,
      'allowDownload': instance.allowDownload,
      'allowCommentsReason': instance.allowCommentsReason,
      'allowLikeReason': instance.allowLikeReason,
      'allowCollectedReason': instance.allowCollectedReason,
      'allowDownloadReason': instance.allowDownloadReason,
      'extern': instance.extern,
    };

_ComicInfo _$ComicInfoFromJson(Map<String, dynamic> json) => _ComicInfo(
  id: json['id'] as String,
  title: json['title'] as String,
  titleMeta: (json['titleMeta'] as List<dynamic>)
      .map((e) => ComicInfoActionItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  creator: json['creator'] == null
      ? const Creator(
          id: '',
          name: '',
          avatar: ComicImage(id: '', url: '', name: ''),
        )
      : Creator.fromJson(json['creator'] as Map<String, dynamic>),
  description: json['description'] as String,
  cover: ComicImage.fromJson(json['cover'] as Map<String, dynamic>),
  metadata: (json['metadata'] as List<dynamic>)
      .map((e) => ComicInfoMetadata.fromJson(e as Map<String, dynamic>))
      .toList(),
  extern: json['extern'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$ComicInfoToJson(_ComicInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'titleMeta': instance.titleMeta.map((e) => e.toJson()).toList(),
      'creator': instance.creator.toJson(),
      'description': instance.description,
      'cover': instance.cover.toJson(),
      'metadata': instance.metadata.map((e) => e.toJson()).toList(),
      'extern': instance.extern,
    };

_Ep _$EpFromJson(Map<String, dynamic> json) => _Ep(
  id: json['id'] as String? ?? '',
  name: json['name'] as String,
  order: (json['order'] as num).toInt(),
  requestId: json['requestId'] as String? ?? '',
  storageChapterId: json['storageChapterId'] as String? ?? '',
  logicalKey: json['logicalKey'] as String? ?? '',
  groupTitle: json['groupTitle'] as String? ?? '',
  extern: json['extern'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$EpToJson(_Ep instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'order': instance.order,
  'requestId': instance.requestId,
  'storageChapterId': instance.storageChapterId,
  'logicalKey': instance.logicalKey,
  'groupTitle': instance.groupTitle,
  'extern': instance.extern,
};

_Recommend _$RecommendFromJson(Map<String, dynamic> json) => _Recommend(
  source: json['source'] as String,
  id: json['id'] as String,
  title: json['title'] as String,
  subtitle: json['subtitle'] as String? ?? '',
  finished: json['finished'] as bool? ?? false,
  likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
  viewsCount: (json['viewsCount'] as num?)?.toInt() ?? 0,
  updatedAt: json['updatedAt'] ?? '',
  cover: ComicImage.fromJson(json['cover'] as Map<String, dynamic>),
  metadata: json['metadata'] as List<dynamic>? ?? const [],
  raw: json['raw'] as Map<String, dynamic>? ?? const {},
  extern: json['extern'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$RecommendToJson(_Recommend instance) =>
    <String, dynamic>{
      'source': instance.source,
      'id': instance.id,
      'title': instance.title,
      'subtitle': instance.subtitle,
      'finished': instance.finished,
      'likesCount': instance.likesCount,
      'viewsCount': instance.viewsCount,
      'updatedAt': instance.updatedAt,
      'cover': instance.cover.toJson(),
      'metadata': instance.metadata,
      'raw': instance.raw,
      'extern': instance.extern,
    };
