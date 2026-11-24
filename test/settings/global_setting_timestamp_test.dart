import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/main.dart';

import '../test_helper.dart';

void main() {
  setUpAll(TestDatabaseHelper.setUpTestDatabase);
  tearDownAll(TestDatabaseHelper.tearDownTestDatabase);

  test('修改设置时按项写入修改时间，不改动无关项', () async {
    final cubit = GlobalSettingCubit();
    await cubit.initBox();
    final initial = cubit.state.settingUpdatedAt;
    expect(initial, isNotEmpty);
    expect(initial['dynamicColor'], 0);
    expect(initial['readSetting.readMode'], 0);
    expect(initial['readSetting.preloadChapterCount'], 0);

    cubit.updateState((current) => current.copyWith(dynamicColor: false));
    final afterAppearance = cubit.state.settingUpdatedAt;
    expect(afterAppearance['dynamicColor'], greaterThan(0));
    expect(afterAppearance['themeMode'], 0);

    cubit.updateReadSetting((current) => current.copyWith(readMode: 1));
    final afterReader = cubit.state.settingUpdatedAt;
    expect(afterReader['dynamicColor'], afterAppearance['dynamicColor']);
    expect(
      afterReader['readSetting.readMode'],
      greaterThanOrEqualTo(afterAppearance['dynamicColor']!),
    );
    expect(afterReader['readSetting.preloadChapterCount'], 0);

    cubit.updateSyncSetting((current) => current.copyWith(autoSync: false));
    final afterSync = cubit.state.settingUpdatedAt;
    expect(afterSync['syncSetting.autoSync'], greaterThan(0));
    // 同步时间由同步流程维护，不应被当成用户修改。
    expect(afterSync.containsKey('syncSetting.settingsSyncTime'), isFalse);

    // 等待 fire-and-forget 的持久化完成，避免测试库关闭时仍有写入。
    await Future<void>.delayed(const Duration(milliseconds: 100));
  });

  test('备份导入按原样替换，不补时间、不保留本地字段', () async {
    const raw =
        '{"dynamicColor":false,"appLockSetting":{"gesturePasswordHash":"backup-hash"},"settingUpdatedAt":{}}';
    await database.userSettings.putGlobalSettingData(raw);

    final cubit = GlobalSettingCubit();
    cubit.adoptRestoredState(
      GlobalSettingState.fromJson(jsonDecode(raw) as Map<String, dynamic>),
    );

    expect(cubit.state.dynamicColor, isFalse);
    expect(cubit.state.appLockSetting.gesturePasswordHash, 'backup-hash');
    expect(cubit.state.settingUpdatedAt, isEmpty);

    // 内存替换不能回写数据库，数据库保持备份原始 JSON。
    expect(await database.userSettings.getGlobalSettingData(), raw);
  });
}
