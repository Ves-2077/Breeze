import 'dart:convert';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zephyr/model/comic_info_meta.dart';

export 'package:zephyr/model/comic_info_meta.dart';

part 'normal_comic_all_info.freezed.dart';
part 'normal_comic_all_info.g.dart';

NormalComicAllInfo normalComicAllInfoFromJson(String str) =>
    NormalComicAllInfo.fromJson(json.decode(str));

String normalComicAllInfoToJson(NormalComicAllInfo data) =>
    json.encode(data.toJson());

@freezed
abstract class NormalComicAllInfo with _$NormalComicAllInfo {
  const factory NormalComicAllInfo({
    @JsonKey(name: 'comicInfo') required ComicInfo comicInfo,
    @JsonKey(name: 'preview') @Default({}) Map<String, dynamic> preview,
    @JsonKey(name: 'eps') required List<Ep> eps,
    @JsonKey(name: 'recommend') required List<Recommend> recommend,
    @JsonKey(name: 'totalViews') @Default(0) int totalViews,
    @JsonKey(name: 'totalLikes') @Default(0) int totalLikes,
    @JsonKey(name: 'totalComments') @Default(0) int totalComments,
    @JsonKey(name: 'isFavourite') @Default(false) bool isFavourite,
    @JsonKey(name: 'isLiked') @Default(false) bool isLiked,
    @JsonKey(name: 'allowComments') @Default(false) bool allowComments,
    @JsonKey(name: 'allowLike') @Default(false) bool allowLike,
    @JsonKey(name: 'allowCollected') @Default(false) bool allowCollected,
    @JsonKey(name: 'allowDownload') @Default(true) bool allowDownload,
    @JsonKey(name: 'allowCommentsReason')
    @Default('')
    String allowCommentsReason,
    @JsonKey(name: 'allowLikeReason') @Default('') String allowLikeReason,
    @JsonKey(name: 'allowCollectedReason')
    @Default('')
    String allowCollectedReason,
    @JsonKey(name: 'allowDownloadReason')
    @Default('')
    String allowDownloadReason,
    @JsonKey(name: 'extern') @Default({}) Map<String, dynamic> extern,
  }) = _NormalComicAllInfo;

  factory NormalComicAllInfo.fromJson(Map<String, dynamic> json) =>
      _$NormalComicAllInfoFromJson(json);
}

@freezed
abstract class ComicInfo with _$ComicInfo {
  const factory ComicInfo({
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'title') required String title,
    @JsonKey(name: 'titleMeta') required List<ComicInfoActionItem> titleMeta,
    @JsonKey(name: 'creator')
    @Default(
      Creator(
        id: '',
        name: '',
        avatar: ComicImage(id: '', url: '', name: ''),
      ),
    )
    Creator creator,
    @JsonKey(name: 'description') required String description,
    @JsonKey(name: 'cover') required ComicImage cover,
    @JsonKey(name: 'metadata') required List<ComicInfoMetadata> metadata,
    @JsonKey(name: 'extern') @Default({}) Map<String, dynamic> extern,
  }) = _ComicInfo;

  factory ComicInfo.fromJson(Map<String, dynamic> json) =>
      _$ComicInfoFromJson(json);
}

@freezed
abstract class Ep with _$Ep {
  const factory Ep({
    @JsonKey(name: 'id') @Default('') String id,
    @JsonKey(name: 'name') required String name,
    @JsonKey(name: 'order') required int order,
    @JsonKey(name: 'requestId') @Default('') String requestId,
    @JsonKey(name: 'storageChapterId') @Default('') String storageChapterId,
    @JsonKey(name: 'logicalKey') @Default('') String logicalKey,
    @JsonKey(name: 'groupTitle') @Default('') String groupTitle,
    @JsonKey(name: 'extern') @Default({}) Map<String, dynamic> extern,
  }) = _Ep;

  factory Ep.fromJson(Map<String, dynamic> json) => _$EpFromJson(json);
}

@freezed
abstract class Recommend with _$Recommend {
  const factory Recommend({
    @JsonKey(name: 'source') required String source,
    @JsonKey(name: 'id') required String id,
    @JsonKey(name: 'title') required String title,
    @JsonKey(name: 'subtitle') @Default('') String subtitle,
    @JsonKey(name: 'finished') @Default(false) bool finished,
    @JsonKey(name: 'likesCount') @Default(0) int likesCount,
    @JsonKey(name: 'viewsCount') @Default(0) int viewsCount,
    @JsonKey(name: 'updatedAt') @Default('') updatedAt,
    @JsonKey(name: 'cover') required ComicImage cover,
    @JsonKey(name: 'metadata') @Default([]) List<dynamic> metadata,
    @JsonKey(name: 'raw') @Default({}) Map<String, dynamic> raw,
    @JsonKey(name: 'extern') @Default({}) Map<String, dynamic> extern,
  }) = _Recommend;

  factory Recommend.fromJson(Map<String, dynamic> json) =>
      _$RecommendFromJson(json);
}
