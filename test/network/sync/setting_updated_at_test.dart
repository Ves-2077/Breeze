import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/config/global/setting_updated_at.dart';

void main() {
  group('updateSettingUpdatedAt', () {
    test('只为变化项打时间并保留未变化项', () {
      final previous = <String, dynamic>{
        'themeMode': 'system',
        'settingUpdatedAt': <String, int>{'themeMode': 50},
        'syncSetting': <String, dynamic>{
          'autoSync': true,
          'settingsSyncTime': 123,
        },
        'readSetting': <String, dynamic>{'readMode': 0, 'preloadImageCount': 3},
      };
      final next = <String, dynamic>{
        'themeMode': 'system',
        'settingUpdatedAt': <String, int>{'themeMode': 50},
        'syncSetting': <String, dynamic>{
          'autoSync': true,
          'settingsSyncTime': 999,
        },
        'readSetting': <String, dynamic>{'readMode': 1, 'preloadImageCount': 3},
      };

      final result = updateSettingUpdatedAt(
        previous: previous,
        next: next,
        current: const <String, int>{
          'themeMode': 50,
          'readSetting.preloadImageCount': 80,
        },
        now: 200,
      );

      expect(result['themeMode'], 50);
      expect(result['readSetting.readMode'], 200);
      expect(result['readSetting.preloadImageCount'], 80);
      expect(result.containsKey('syncSetting.settingsSyncTime'), isFalse);
      expect(
        result.keys.any((key) => key.startsWith('settingUpdatedAt')),
        isFalse,
      );
    });

    test('列表内容相同不会被视为修改', () {
      final previous = <String, dynamic>{
        'searchHistory': <String>['a', 'b'],
      };
      final next = <String, dynamic>{
        'searchHistory': <String>['a', 'b'],
      };

      final result = updateSettingUpdatedAt(
        previous: previous,
        next: next,
        current: const <String, int>{'searchHistory': 10},
        now: 200,
      );

      expect(result['searchHistory'], 10);
    });

    test('没有历史时间的未变化项不会凭空获得时间', () {
      final result = updateSettingUpdatedAt(
        previous: const <String, dynamic>{'themeMode': 'system'},
        next: const <String, dynamic>{'themeMode': 'system'},
        current: const <String, int>{},
        now: 200,
      );

      expect(result, isEmpty);
    });

    test('已有 0 基准的项变化时保留基准', () {
      final result = updateSettingUpdatedAt(
        previous: const <String, dynamic>{
          'themeMode': 'system',
          'dynamicColor': true,
        },
        next: const <String, dynamic>{
          'themeMode': 'system',
          'dynamicColor': false,
        },
        current: const <String, int>{'themeMode': 0, 'dynamicColor': 0},
        now: 200,
      );

      expect(result['themeMode'], 0);
      expect(result['dynamicColor'], 200);
    });

    test('补齐缺失项时间，已有时间（包括 0）原样保留', () {
      final result = hydrateSettingUpdatedAt(
        stateJson: const <String, dynamic>{
          'themeMode': 'system',
          'dynamicColor': true,
          'readSetting': <String, dynamic>{'readMode': 0},
        },
        current: const <String, int>{
          'themeMode': 0,
          'readSetting.readMode': 500,
        },
        baseline: 100,
      );

      expect(result['themeMode'], 0);
      expect(result['readSetting.readMode'], 500);
      expect(result['dynamicColor'], 100);
    });
  });

  group('settingTimestamps', () {
    test('块内缺失时间回退到块级时间', () {
      final fields = settingTimestampsFromPayload(
        blockData: const <String, dynamic>{
          'themeMode': 'dark',
          'isAMOLED': true,
        },
        rawFieldUpdatedAt: const <String, dynamic>{'themeMode': '300'},
        blockUpdatedAt: 100,
      );

      expect(fields['themeMode'], 300);
      expect(fields['isAMOLED'], 100);
    });

    test('阅读器块时间从设置路径映射到块内路径', () {
      final fields = settingTimestampsForBlock(
        settingUpdatedAt: const <String, int>{
          'readSetting.readMode': 400,
          'themeMode': 900,
        },
        blockData: const <String, dynamic>{
          'readMode': 0,
          'preloadImageCount': 3,
        },
        pathPrefix: 'readSetting',
        fallback: 100,
      );

      expect(fields['readMode'], 400);
      expect(fields['preloadImageCount'], 100);
      expect(fields.containsKey('themeMode'), isFalse);
    });
  });

  group('GlobalSettingState', () {
    test('旧版设置 JSON 仍可读取，修改时间为空', () {
      final state = GlobalSettingState.fromJson(<String, dynamic>{
        'themeMode': 'dark',
        'dynamicColor': false,
      });

      expect(state.dynamicColor, isFalse);
      expect(state.settingUpdatedAt, isEmpty);
    });

    test('逐项修改时间可随设置 JSON 往返', () {
      final state = const GlobalSettingState().copyWith(
        settingUpdatedAt: const <String, int>{
          'themeMode': 100,
          'readSetting.readMode': 200,
        },
      );

      final restored = GlobalSettingState.fromJson(state.toJson());
      expect(restored.settingUpdatedAt, state.settingUpdatedAt);
    });
  });
}
