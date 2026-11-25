import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/model/comic_info_meta.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/object_box/model_json_codec.dart';

void main() {
  test('comic records read legacy JSON strings and write them back', () {
    final favorite = UnifiedComicFavorite.fromJson(const <String, dynamic>{
      'uniqueKey': 'src:1',
      'source': 'src',
      'comicId': '1',
      'title': 't',
      'description': 'd',
      'cover':
          '{"id":"c1","url":"https://e/1.jpg","name":"1.jpg","path":"1.jpg"}',
      'creator':
          '{"id":"a1","name":"alice","avatar":{"id":"","url":"","name":""}}',
      'titleMeta': '[{"name":"浏览：42"},{"name":"更新时间：昨天"}]',
      'metadata':
          '[{"type":"author","name":"作者","value":[{"name":"alice"},"bob"]}]',
    });

    expect(favorite.cover.id, 'c1');
    expect(favorite.cover.url, 'https://e/1.jpg');
    expect(favorite.creator.name, 'alice');
    expect(favorite.titleMeta.map((e) => e.name), ['浏览：42', '更新时间：昨天']);
    expect(favorite.metadata.single.type, 'author');
    expect(favorite.metadata.single.value.map((e) => e.name), ['alice', 'bob']);

    final json = favorite.toJson();
    expect(json['cover'], isA<String>());
    expect(json['creator'], isA<String>());
    expect(json['titleMeta'], isA<String>());
    expect(json['metadata'], isA<String>());

    final restored = UnifiedComicFavorite.fromJson(json);
    expect(restored.cover, favorite.cover);
    expect(restored.creator, favorite.creator);
    expect(restored.titleMeta, favorite.titleMeta);
    expect(restored.metadata, favorite.metadata);
  });

  test('download cover override accepts legacy string and stays a string', () {
    final download = UnifiedComicDownload.fromJson(const <String, dynamic>{
      'uniqueKey': 'src:1',
      'source': 'src',
      'comicId': '1',
      'cover': '{}',
      'coverOverride':
          '{"id":"local","url":"","name":"cover.png","path":"cover.png"}',
    });

    expect(download.coverOverride?.id, 'local');
    expect(download.coverOverride?.path, 'cover.png');

    final json = download.toJson();
    expect(json['coverOverride'], isA<String>());
    expect(
      UnifiedComicDownload.fromJson(json).coverOverride,
      download.coverOverride,
    );
  });

  test('search bookmark supports map/string extern and nullable cover', () {
    final bookmark = SearchBookmark.fromJson(const <String, dynamic>{
      'uniqueKey': 'k',
      'source': 'src',
      'keyword': 'kw',
      'externJson': '{"category":"x"}',
      'anchorComicId': '1',
      'anchorTitle': 't',
      'anchorCover': '',
      'anchorPage': 1,
    });

    expect(bookmark.extern, {'category': 'x'});
    expect(bookmark.anchorCover, isNull);

    final json = bookmark.toJson();
    expect(json['externJson'], isA<String>());
    expect(json['anchorCover'], '');

    final withCover = SearchBookmark.fromJson({
      ...json,
      'anchorCover': {'id': '1', 'url': '', 'name': '', 'path': '1.jpg'},
    });
    expect(withCover.anchorCover?.path, '1.jpg');
  });

  test('read preference overrides accept legacy string and map', () {
    final legacy = ComicReadPreference.fromJson(const <String, dynamic>{
      'uniqueKey': 'src:1',
      'source': 'src',
      'comicId': '1',
      'overridesJson': '{"readMode":2}',
    });
    expect(legacy.overrides, {'readMode': 2});
    expect(legacy.toJson()['overridesJson'], isA<String>());

    final fromMap = ComicReadPreference.fromJson({
      'uniqueKey': 'src:1',
      'source': 'src',
      'comicId': '1',
      'overridesJson': {'readMode': 1},
    });
    expect(fromMap.overrides, {'readMode': 1});
  });

  test('download task payload is typed and still encodes as dbTaskInfoStr', () {
    final task = DownloadTask.fromJson(const <String, dynamic>{
      'id': 1,
      'comicId': '1',
      'comicName': 'n',
      'isCompleted': false,
      'isDownloading': true,
      'status': 'running',
      'dbTaskInfoStr': '{"from":"src","comicId":"1","comicName":"n","chapterRef":{"chapterId":"ch1"},"totalImages":2}',
    });

    expect(task.taskInfo?.chapterRef.chapterId, 'ch1');
    expect(task.taskInfo?.totalImages, 2);

    final json = task.toJson();
    expect(json['dbTaskInfoStr'], isA<String>());
    expect(DownloadTask.fromJson(json).taskInfo?.comicId, '1');

    final empty = DownloadTask.fromJson(const <String, dynamic>{
      'id': 2,
      'comicId': '1',
      'comicName': 'n',
      'isCompleted': false,
      'isDownloading': false,
      'status': 'queued',
    });
    expect(empty.taskInfo, isNull);
    expect(empty.toJson()['dbTaskInfoStr'], isNull);
  });

  test('legacy extension key maps to extern', () {
    final image = comicImageFromField(const <String, dynamic>{
      'id': 'c',
      'url': 'u',
      'name': 'n',
      'extension': {'path': 'p.jpg'},
    });
    expect(image.extern['path'], 'p.jpg');
    expect(image.path, 'p.jpg');
  });

  test('version vector accepts legacy string and emits string', () {
    final folder = ComicFolder.fromJson(const <String, dynamic>{
      'syncId': 's1',
      'uniqueKey': '|A|favorite',
      'name': 'A',
      'typeData': 'favorite',
      'versionVectorJson': '{"device_a":2,"device_b":1}',
    });
    expect(folder.versionVector, {'device_a': 2, 'device_b': 1});
    expect(folder.toJson()['versionVectorJson'], isA<String>());

    final fromMap = ComicLink.fromJson(const <String, dynamic>{
      'uniqueKey': 'c|s1|favorite',
      'comicUniqueKey': 'c',
      'typeData': 'favorite',
      'versionVectorJson': {'device_a': 3},
    });
    expect(fromMap.versionVector, {'device_a': 3});
    expect(fromMap.toJson()['versionVectorJson'], isA<String>());

    expect(versionVectorFromField('not-json'), isEmpty);
    expect(versionVectorFromField('{"a":"4"}'), {'a': 4});
  });

  test('codec accepts already-typed entries from migration code', () {
    final metadata = comicMetadataFromField(const <ComicInfoMetadata>[
      ComicInfoMetadata(
        type: 'author',
        name: '作者',
        value: [ComicInfoActionItem(name: 'alice')],
      ),
    ]);
    expect(metadata.single.value.single.name, 'alice');
  });
}
