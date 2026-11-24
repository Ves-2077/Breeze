import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/config/global/setting_updated_at.dart';
import 'package:zephyr/network/sync/settings_sync_payload.dart';

void main() {
  group('extractSyncableSettingsData', () {
    test('过滤安全、设备相关和内部字段', () {
      final state = const GlobalSettingState().copyWith(
        dynamicColor: false,
        showScrollbar: true,
        chineseConvertMode: ChineseConvertMode.simplified,
        proxySetting: const ProxySettingState(
          enabled: true,
          address: 'http://127.0.0.1:7890',
        ),
        dohSetting: const DohSettingState(
          enabled: true,
          providers: <String>['https://doh.example/dns-query'],
        ),
        eInkSetting: const EInkSettingState(
          enabled: true,
          detectionHandled: true,
          refreshMode: EinkRefreshMode.whiteFlash,
          autoRefreshEveryNTurns: 9,
        ),
        bookshelfSetting: const BookshelfSettingState(
          homePageIndex: 3,
          favoriteSort: 'da',
        ),
        comicDetailSetting: const ComicDetailSettingState(
          showLikeAction: false,
        ),
        appLockSetting: const AppLockSettingState(gesturePasswordHash: 'hash'),
        cacheSetting: const CacheSettingState(cacheSizeLimit: 42),
        settingUpdatedAt: const <String, int>{'dynamicColor': 100},
      );

      final data = extractSyncableSettingsData(state.toJson());

      expect(data['dynamicColor'], isFalse);
      expect(data['showScrollbar'], isTrue);
      expect(data['chineseConvertMode'], isNotNull);
      expect(data['proxySetting']['address'], 'http://127.0.0.1:7890');
      expect(data['dohSetting']['enabled'], isTrue);
      expect(data['comicDetailSetting']['showLikeAction'], isFalse);
      expect(data.containsKey('syncSetting'), isFalse);
      expect(data.containsKey('appLockSetting'), isFalse);
      expect(data.containsKey('cacheSetting'), isFalse);
      expect(data.containsKey('customExportPath'), isFalse);
      expect(data.containsKey('windowWidth'), isFalse);
      expect(data.containsKey('logAddress'), isFalse);
      expect(data.containsKey('compatibleVersion'), isFalse);
      expect(data.containsKey('themeInitState'), isFalse);
      expect(data.containsKey('settingUpdatedAt'), isFalse);

      final eInk = data['eInkSetting'] as Map<String, dynamic>;
      expect(eInk.containsKey('enabled'), isFalse);
      expect(eInk.containsKey('detectionHandled'), isFalse);
      expect(eInk['autoRefreshEveryNTurns'], 9);

      final bookshelf = data['bookshelfSetting'] as Map<String, dynamic>;
      expect(bookshelf.containsKey('homePageIndex'), isFalse);
      expect(bookshelf['favoriteSort'], 'da');
    });
  });

  group('applySyncedSettingItems', () {
    test('逐项写入并保留本地专属字段', () {
      final local = const GlobalSettingState().copyWith(
        dynamicColor: true,
        chineseConvertMode: ChineseConvertMode.off,
        eInkSetting: const EInkSettingState(
          enabled: true,
          detectionHandled: true,
          refreshMode: EinkRefreshMode.none,
        ),
        bookshelfSetting: const BookshelfSettingState(
          homePageIndex: 2,
          favoriteSort: 'dd',
        ),
        appLockSetting: const AppLockSettingState(
          gesturePasswordHash: 'local-hash',
        ),
      );
      final remoteData = extractSyncableSettingsData(
        const GlobalSettingState()
            .copyWith(
              dynamicColor: false,
              chineseConvertMode: ChineseConvertMode.simplified,
              eInkSetting: const EInkSettingState(
                enabled: false,
                detectionHandled: false,
                refreshMode: EinkRefreshMode.fullFlash,
              ),
              bookshelfSetting: const BookshelfSettingState(favoriteSort: 'da'),
            )
            .toJson(),
      );
      final items = <String, SyncedSettingItem>{
        ...buildSyncedSettingItems(
          data: remoteData,
          updatedAtByPath: const <String, int>{
            'dynamicColor': 300,
            'chineseConvertMode': 400,
            'eInkSetting.refreshMode': 500,
            'bookshelfSetting.favoriteSort': 600,
          },
        ),
        // 即使远端恶意/错误地带上本地专属项，也不能覆盖。
        'eInkSetting.enabled': const SyncedSettingItem(
          value: false,
          updatedAt: 700,
        ),
        'appLockSetting.gesturePasswordHash': const SyncedSettingItem(
          value: 'remote-hash',
          updatedAt: 800,
        ),
      };

      final stateJson = local.toJson();
      applySyncedSettingItems(stateJson, items);
      final restored = GlobalSettingState.fromJson(stateJson);

      expect(restored.dynamicColor, isFalse);
      expect(restored.chineseConvertMode, ChineseConvertMode.simplified);
      expect(restored.eInkSetting.refreshMode, EinkRefreshMode.fullFlash);
      expect(restored.bookshelfSetting.favoriteSort, 'da');
      // 本地专属字段即使出现在远端 items 里也不会被应用。
      expect(restored.eInkSetting.enabled, isTrue);
      expect(restored.eInkSetting.detectionHandled, isTrue);
      expect(restored.bookshelfSetting.homePageIndex, 2);
      expect(restored.appLockSetting.gesturePasswordHash, 'local-hash');
      expect(restored.settingUpdatedAt['dynamicColor'], 300);
      expect(
        restored.settingUpdatedAt.containsKey(
          'appLockSetting.gesturePasswordHash',
        ),
        isFalse,
      );
    });

    test('keepNewerLocalTimestamps=false 时采用远端字段时间', () {
      final state = const GlobalSettingState().copyWith(
        settingUpdatedAt: const <String, int>{'dynamicColor': 900},
      );
      final stateJson = state.toJson();
      applySyncedSettingItems(stateJson, const <String, SyncedSettingItem>{
        'dynamicColor': SyncedSettingItem(value: false, updatedAt: 100),
      }, keepNewerLocalTimestamps: false);

      expect(
        GlobalSettingState.fromJson(stateJson).settingUpdatedAt['dynamicColor'],
        100,
      );
    });
  });

  group('mergeSyncedSettingItems', () {
    test('按设置项自己的时间取新旧值，时间相同本地优先', () {
      const local = <String, SyncedSettingItem>{
        'dynamicColor': SyncedSettingItem(value: true, updatedAt: 300),
        'chineseConvertMode': SyncedSettingItem(value: 'off', updatedAt: 500),
        'readSetting.readMode': SyncedSettingItem(value: 0, updatedAt: 200),
      };
      const remote = <String, SyncedSettingItem>{
        'dynamicColor': SyncedSettingItem(value: false, updatedAt: 200),
        'chineseConvertMode': SyncedSettingItem(
          value: 'simplified',
          updatedAt: 600,
        ),
        'readSetting.readMode': SyncedSettingItem(value: 2, updatedAt: 200),
      };

      final merged = mergeSyncedSettingItems(local, remote);

      expect(merged['dynamicColor']!.value, isTrue);
      expect(merged['chineseConvertMode']!.value, 'simplified');
      expect(merged['readSetting.readMode']!.value, 0);
      expect(maxSyncedItemUpdatedAt(merged), 600);
      expect(settingItemsDiffer(local, merged), isTrue);
    });

    test('设置项独立合并，不会因为某个项变化抬高其他项', () {
      const local = <String, SyncedSettingItem>{
        'themeMode': SyncedSettingItem(value: 'system', updatedAt: 900),
        'readSetting.readMode': SyncedSettingItem(value: 0, updatedAt: 100),
      };
      const remote = <String, SyncedSettingItem>{
        'themeMode': SyncedSettingItem(value: 'dark', updatedAt: 500),
        'readSetting.readMode': SyncedSettingItem(value: 2, updatedAt: 600),
      };

      final merged = mergeSyncedSettingItems(local, remote);

      expect(merged['themeMode']!.value, 'system');
      expect(merged['themeMode']!.updatedAt, 900);
      expect(merged['readSetting.readMode']!.value, 2);
      expect(merged['readSetting.readMode']!.updatedAt, 600);
    });
  });

  group('removeSettingPaths', () {
    test('可移除嵌套路径并保留同级字段', () {
      final json = <String, dynamic>{
        'eInkSetting': <String, dynamic>{
          'enabled': true,
          'refreshMode': 'fullFlash',
        },
        'themeMode': 'system',
      };

      removeSettingPaths(json, const <String>[
        'eInkSetting.enabled',
        'themeMode',
      ]);

      expect(json['eInkSetting'], <String, dynamic>{
        'refreshMode': 'fullFlash',
      });
      expect(json.containsKey('themeMode'), isFalse);
    });
  });
}
