import 'package:zephyr/model/comic_info_meta.dart';

/// 测试用空漫画字段，避免每个 fixture 重复构造。
const emptyComicImage = ComicImage(id: '', url: '', name: '');
const emptyComicCreator = Creator(id: '', name: '', avatar: emptyComicImage);
const emptyComicTitleMeta = <ComicInfoActionItem>[];
const emptyComicMetadata = <ComicInfoMetadata>[];
