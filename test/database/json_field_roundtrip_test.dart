import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/model/comic_info_meta.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/service/download/models/download_task_json.dart';

import '../support/comic_fixtures.dart';
import '../test_helper.dart';

void main() {
  setUpAll(TestDatabaseHelper.setUpTestDatabase);
  tearDownAll(TestDatabaseHelper.tearDownTestDatabase);

  final now = DateTime.utc(2026, 1, 1);
  const cover = ComicImage(
    id: 'c1',
    url: 'https://e/1.jpg',
    name: '1.jpg',
    path: '1.jpg',
    extern: {'path': '1.jpg'},
  );
  const creator = Creator(id: 'a1', name: 'alice', avatar: emptyComicImage);
  const titleMeta = [ComicInfoActionItem(name: '浏览：42')];
  const metadata = [
    ComicInfoMetadata(
      type: 'author',
      name: '作者',
      value: [ComicInfoActionItem(name: 'alice')],
    ),
  ];

  test('收藏/历史/下载的 JSON 字段通过 SQLite 往返', () async {
    final favorite = UnifiedComicFavorite(
      uniqueKey: 'test:1',
      source: 'test',
      comicId: '1',
      title: 't',
      description: 'd',
      cover: cover,
      creator: creator,
      titleMeta: titleMeta,
      metadata: metadata,
      createdAt: now,
      updatedAt: now,
      deleted: false,
      schemaVersion: 1,
    );
    await database.favorites.put(favorite);
    final readFavorite = await database.favorites.getByKey('test:1');
    expect(readFavorite!.cover, cover);
    expect(readFavorite.creator, creator);
    expect(readFavorite.titleMeta, titleMeta);
    expect(readFavorite.metadata, metadata);

    final history = UnifiedComicHistory(
      uniqueKey: 'test:1',
      source: 'test',
      comicId: '1',
      title: 't',
      description: 'd',
      cover: cover,
      creator: creator,
      titleMeta: titleMeta,
      metadata: metadata,
      chapterId: 'ch1',
      chapterTitle: '第 1 话',
      chapterOrder: 1,
      pageIndex: 3,
      createdAt: now,
      lastReadAt: now,
      updatedAt: now,
      deleted: false,
      schemaVersion: 1,
    );
    await database.histories.put(history);
    final readHistory = await database.histories.getByKey('test:1');
    expect(readHistory!.cover, cover);
    expect(readHistory.creator, creator);
    expect(readHistory.titleMeta, titleMeta);
    expect(readHistory.metadata, metadata);

    final download = UnifiedComicDownload(
      uniqueKey: 'test:1',
      source: 'test',
      comicId: '1',
      title: 't',
      description: 'd',
      cover: cover,
      creator: creator,
      titleMeta: titleMeta,
      metadata: metadata,
      totalViews: 0,
      totalLikes: 0,
      totalComments: 0,
      isFavourite: false,
      isLiked: false,
      allowComment: false,
      allowLike: false,
      allowFavorite: false,
      allowDownload: false,
      chapters: '[]',
      detailJson: '{}',
      storageRoot: '',
      createdAt: now,
      updatedAt: now,
      downloadedAt: now,
      deleted: false,
      schemaVersion: 1,
      coverOverride: cover,
    );
    await database.downloads.put(download);
    final readDownload = await database.downloads.getByKey('test:1');
    expect(readDownload!.cover, cover);
    expect(readDownload.creator, creator);
    expect(readDownload.titleMeta, titleMeta);
    expect(readDownload.metadata, metadata);
    expect(readDownload.coverOverride, cover);

    final shelf = await database.downloads.getShelfByKeys(['test:1']);
    expect(shelf.single.coverOverride, cover);
  });

  test('追更/阅读覆盖/搜索书签/任务 payload 往返', () async {
    final follow = ComicFollow(
      uniqueKey: 'test:1',
      source: 'test',
      comicId: '1',
      title: 't',
      description: 'd',
      cover: cover,
      creator: creator,
      titleMeta: titleMeta,
      metadata: metadata,
      lastChapterCount: 1,
      detectedChapterCount: 2,
      detectedChapterTitle: '第 2 话',
      hasUpdate: true,
      updateTime: now,
      deleted: false,
      createdAt: now,
      updatedAt: now,
      schemaVersion: 1,
    );
    await database.follows.put(follow);
    final readFollow = await database.follows.getByKey('test:1');
    expect(readFollow!.cover, cover);
    expect(readFollow.creator, creator);
    expect(readFollow.titleMeta, titleMeta);
    expect(readFollow.metadata, metadata);

    final preference = ComicReadPreference(
      uniqueKey: 'test:1',
      source: 'test',
      comicId: '1',
      overrides: const {'readMode': 2},
      updatedAt: now,
    );
    await database.readPreferences.put(preference);
    final readPreference = await database.readPreferences.getByKey('test:1');
    expect(readPreference!.overrides, const {'readMode': 2});
    expect(readPreference.overrideSetting?.setting.readMode, 2);

    final bookmark = SearchBookmark(
      uniqueKey: 'test|kw|1',
      source: 'test',
      keyword: 'kw',
      extern: const {'category': 'x'},
      anchorComicId: '1',
      anchorTitle: 't',
      anchorCover: cover,
      anchorPage: 1,
      createdAt: now,
      updatedAt: now,
    );
    await database.bookmarks.put(bookmark);
    final readBookmark = await database.bookmarks.getByKey('test|kw|1');
    expect(readBookmark!.extern, const {'category': 'x'});
    expect(readBookmark.anchorCover, cover);

    final payload = DownloadTaskJson(
      from: 'test',
      comicId: '1',
      comicName: 't',
      chapterRef: const DownloadChapterTaskRef(chapterId: 'ch1'),
      totalImages: 3,
      completedImages: 2,
    );
    final task = DownloadTask()
      ..comicId = '1'
      ..comicName = 't'
      ..status = 'running'
      ..taskInfo = payload;
    await database.downloadTasks.put(task);
    final readTask = await database.downloadTasks.getById(task.id);
    expect(readTask!.taskInfo?.chapterRef.chapterId, 'ch1');
    expect(readTask.taskInfo?.completedImages, 2);
  });
}
