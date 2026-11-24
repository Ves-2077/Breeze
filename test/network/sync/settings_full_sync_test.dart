import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/config/global/setting_updated_at.dart';
import 'package:zephyr/network/sync/settings_sync_payload.dart';
import 'package:zephyr/network/sync/sync_service.dart';

GlobalSettingState _localState() {
  return const GlobalSettingState().copyWith(
    syncSetting: const SyncSettingState(
      syncSettings: true,
      syncPlugins: false,
      settingsSyncTime: 100,
    ),
    dynamicColor: true,
    chineseConvertMode: ChineseConvertMode.off,
    readSetting: const ReadSettingState(readMode: 0),
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
    windowWidth: 1111,
    settingUpdatedAt: const <String, int>{
      'dynamicColor': 300,
      'chineseConvertMode': 500,
    },
  );
}

GlobalSettingState _remoteState() {
  return const GlobalSettingState().copyWith(
    syncSetting: const SyncSettingState(
      syncSettings: true,
      syncPlugins: false,
      settingsSyncTime: 2000,
    ),
    dynamicColor: false,
    chineseConvertMode: ChineseConvertMode.simplified,
    readSetting: const ReadSettingState(readMode: 2),
    eInkSetting: const EInkSettingState(
      enabled: false,
      detectionHandled: false,
      refreshMode: EinkRefreshMode.fullFlash,
    ),
    bookshelfSetting: const BookshelfSettingState(
      homePageIndex: 9,
      favoriteSort: 'da',
    ),
    appLockSetting: const AppLockSettingState(
      gesturePasswordHash: 'remote-hash',
    ),
    windowWidth: 999,
    settingUpdatedAt: const <String, int>{
      'dynamicColor': 200,
      'chineseConvertMode': 600,
    },
  );
}

Map<String, dynamic> _itemsPayload(GlobalSettingState state) {
  final data = extractSyncableSettingsData(state.toJson());
  final itemUpdatedAt = settingTimestampsForBlock(
    settingUpdatedAt: state.settingUpdatedAt,
    blockData: data,
    pathPrefix: '',
    fallback: 200,
  );
  final items = buildSyncedSettingItems(
    data: data,
    updatedAtByPath: itemUpdatedAt,
  );
  return <String, dynamic>{
    'version': 'v1',
    'schemaVersion': 'v3',
    'syncTime': maxSyncedItemUpdatedAt(items),
    'settingItems': <String, dynamic>{
      for (final entry in items.entries) entry.key: entry.value.toJson(),
    },
  };
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  test('按每个设置项的修改时间合并，并保留本地专属字段', () async {
    final remote = _remoteState();
    final remotePayload = _itemsPayload(remote);
    final result = await mergeSyncSettingsForTest(
      local: _localState(),
      remotePayload: remotePayload,
      remoteFallbackSyncTime: remotePayload['syncTime'] as int,
    );
    final merged = result.mergedState;

    // 逐项 LWW：dynamicColor 本地更新，chineseConvertMode 云端更新。
    expect(merged.dynamicColor, isTrue);
    expect(merged.chineseConvertMode, ChineseConvertMode.simplified);
    expect(merged.readSetting.readMode, 2);
    expect(merged.eInkSetting.refreshMode, EinkRefreshMode.fullFlash);
    expect(merged.bookshelfSetting.favoriteSort, 'da');
    expect(merged.settingUpdatedAt['dynamicColor'], 300);
    expect(merged.settingUpdatedAt['chineseConvertMode'], 600);

    // 本地专属/安全/设备字段不被云端覆盖。
    expect(merged.eInkSetting.enabled, isTrue);
    expect(merged.eInkSetting.detectionHandled, isTrue);
    expect(merged.bookshelfSetting.homePageIndex, 2);
    expect(merged.appLockSetting.gesturePasswordHash, 'local-hash');
    expect(merged.windowWidth, 1111);

    final items = result.payload['settingItems'] as Map<String, dynamic>;
    expect(items.containsKey('dynamicColor'), isTrue);
    expect(items.containsKey('chineseConvertMode'), isTrue);
    expect(items.containsKey('readSetting.readMode'), isTrue);
    expect(items.containsKey('eInkSetting.refreshMode'), isTrue);
    expect(items.containsKey('syncSetting'), isFalse);
    expect(items.containsKey('appLockSetting'), isFalse);
    expect(items.containsKey('windowWidth'), isFalse);
    expect(items.containsKey('eInkSetting.enabled'), isFalse);

    final blocks = result.payload['blocks'] as Map<String, dynamic>;
    expect(blocks.containsKey('settings'), isFalse);
    expect(blocks.containsKey('appearance'), isTrue);
    expect(blocks.containsKey('library'), isTrue);
    expect(blocks.containsKey('reader'), isTrue);

    final appearanceData = (blocks['appearance'] as Map)['data'] as Map;
    expect(appearanceData['dynamicColor'], isTrue);
    final readerData = (blocks['reader'] as Map)['data'] as Map;
    expect(readerData['readMode'], 2);

    final legacyGlobal = result.payload['globalSetting'] as Map;
    expect(legacyGlobal.containsKey('syncSetting'), isFalse);
    expect(legacyGlobal.containsKey('appLockSetting'), isFalse);
    expect(legacyGlobal.containsKey('windowWidth'), isFalse);
    expect(result.payload['schemaVersion'], 'v3');
  });

  test('首次同步时未标记时间的本地默认值不会覆盖云端', () async {
    final local = const GlobalSettingState().copyWith(
      syncSetting: const SyncSettingState(
        syncSettings: true,
        syncPlugins: false,
        settingsSyncTime: 0,
      ),
      dynamicColor: true,
      chineseConvertMode: ChineseConvertMode.off,
      readSetting: const ReadSettingState(readMode: 0),
    );
    final remote = _remoteState();
    final remotePayload = _itemsPayload(remote);

    final result = await mergeSyncSettingsForTest(
      local: local,
      remotePayload: remotePayload,
      remoteFallbackSyncTime: remotePayload['syncTime'] as int,
    );

    expect(result.mergedState.dynamicColor, isFalse);
    expect(
      result.mergedState.chineseConvertMode,
      ChineseConvertMode.simplified,
    );
    expect(result.mergedState.readSetting.readMode, 2);
  });

  test('旧本地数据缺少项时间时用上次同步时间补基准', () async {
    final local = _localState().copyWith(
      syncSetting: const SyncSettingState(
        syncSettings: true,
        syncPlugins: false,
        settingsSyncTime: 700,
      ),
      settingUpdatedAt: const <String, int>{},
    );
    final remote = _remoteState().copyWith(
      dynamicColor: false,
      settingUpdatedAt: const <String, int>{'dynamicColor': 600},
    );
    final remotePayload = _itemsPayload(remote);

    final result = await mergeSyncSettingsForTest(
      local: local,
      remotePayload: remotePayload,
      remoteFallbackSyncTime: remotePayload['syncTime'] as int,
    );

    // 本地缺项时间时补成上次同步时间 700，比远端 600 新，本地保留。
    expect(result.mergedState.dynamicColor, isTrue);
    expect(result.mergedState.settingUpdatedAt['dynamicColor'], 700);
  });

  test('旧版三块负载会合成逐项记录，按块时间继续参与逐项同步', () async {
    final remote = _remoteState();
    final remoteJson = remote.toJson();
    remoteJson['settingUpdatedAt'] = <String, int>{'chineseConvertMode': 600};
    final appearanceData = <String, dynamic>{
      'dynamicColor': remoteJson['dynamicColor'],
      'themeMode': remoteJson['themeMode'],
      'isAMOLED': remoteJson['isAMOLED'],
      'seedColor': remoteJson['seedColor'],
      'locale': remoteJson['locale'],
      'showPluginHome': remoteJson['showPluginHome'],
      'showPluginCloudFavorite': remoteJson['showPluginCloudFavorite'],
      'welcomePageNum': remoteJson['welcomePageNum'],
    };
    final readerData = remoteJson['readSetting'] as Map<String, dynamic>;
    final legacyPayload = <String, dynamic>{
      'version': 'v1',
      'schemaVersion': 'v3',
      'syncTime': 600,
      'globalSetting': remoteJson,
      'blocks': <String, dynamic>{
        'appearance': <String, dynamic>{
          'updatedAt': 200,
          'fieldUpdatedAt': <String, int>{
            for (final key in appearanceData.keys) key: 200,
          },
          'data': appearanceData,
        },
        'reader': <String, dynamic>{
          'updatedAt': 600,
          'fieldUpdatedAt': <String, int>{
            for (final key in flattenSettingJson(readerData).keys) key: 600,
          },
          'data': readerData,
        },
      },
    };

    final result = await mergeSyncSettingsForTest(
      local: _localState(),
      remotePayload: legacyPayload,
      remoteFallbackSyncTime: 600,
    );
    final merged = result.mergedState;

    // 旧版块覆盖的字段按块时间；块外的新字段也能从 globalSetting 合成。
    expect(merged.dynamicColor, isTrue);
    expect(merged.chineseConvertMode, ChineseConvertMode.simplified);
    expect(merged.readSetting.readMode, 2);
    expect(merged.bookshelfSetting.favoriteSort, 'da');

    // 本地专属字段仍然保留。
    expect(merged.eInkSetting.enabled, isTrue);
    expect(merged.bookshelfSetting.homePageIndex, 2);
    expect(merged.appLockSetting.gesturePasswordHash, 'local-hash');
    expect(merged.windowWidth, 1111);
  });
}
