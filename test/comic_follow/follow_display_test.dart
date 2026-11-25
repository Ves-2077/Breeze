import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/model/comic_info_meta.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/page/comic_follow/view/follow_display.dart';

import '../support/comic_fixtures.dart';

ComicFollow _follow({
  ComicImage cover = emptyComicImage,
  Creator creator = emptyComicCreator,
  int detected = 10,
}) {
  final now = DateTime.utc(2026, 9, 30, 12);
  return ComicFollow(
    uniqueKey: 'test:1',
    source: 'test',
    comicId: '1',
    title: 't',
    description: '',
    cover: cover,
    creator: creator,
    titleMeta: emptyComicTitleMeta,
    metadata: emptyComicMetadata,
    lastChapterCount: 0,
    detectedChapterCount: detected,
    detectedChapterTitle: '',
    hasUpdate: false,
    updateTime: now,
    deleted: false,
    createdAt: now,
    updatedAt: now,
    schemaVersion: 1,
  );
}

void main() {
  test('resolveFollowCover falls back to comicId', () {
    final cover = resolveFollowCover(_follow());
    expect(cover.id, '1');
    expect(cover.url, isEmpty);
  });

  test('parseFollowCreatorName reads trimmed name', () {
    const creator = Creator(id: '1', name: '  alice ', avatar: emptyComicImage);
    expect(parseFollowCreatorName(creator), 'alice');
    expect(parseFollowCreatorName(emptyComicCreator), isNull);
  });

  test('formatFollowCheckTime shortens same day', () {
    final now = DateTime(2026, 9, 30, 20, 5);
    expect(
      formatFollowCheckTime(DateTime(2026, 9, 30, 9, 4), now: now),
      '09:04',
    );
    expect(
      formatFollowCheckTime(DateTime(2026, 9, 29, 9, 4), now: now),
      '9-29 09:04',
    );
    expect(
      formatFollowCheckTime(DateTime(2025, 12, 1, 9, 4), now: now),
      '2025-12-1 09:04',
    );
  });

  test('followReadProgress clamps', () {
    expect(followReadProgress(readOrder: 5, detectedTotal: 10), 0.5);
    expect(followReadProgress(readOrder: 0, detectedTotal: 10), 0);
    expect(followReadProgress(readOrder: 12, detectedTotal: 10), 1.0);
    expect(followReadProgress(readOrder: 5, detectedTotal: 0), 0);
  });
}
