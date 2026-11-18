import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/database/database.dart';
import 'package:zephyr/cubit/string_select.dart';
import 'package:zephyr/main.dart';

import 'package:zephyr/object_box/migration/migration_v1_to_v2.dart';
import 'package:zephyr/object_box/migration/migration_v2_to_v3.dart';
import 'package:zephyr/object_box/migration/migration_v3_to_v4.dart';
import 'package:zephyr/object_box/migration/migration_v4_to_v5.dart';
import 'package:zephyr/object_box/migration/migration_v5_to_v6.dart';
import 'package:zephyr/object_box/migration/migration_v6_to_v7.dart';
import 'package:zephyr/object_box/migration/migration_v7_to_v8.dart';
import 'package:zephyr/object_box/migration/migration_v8_to_v9.dart';
import 'package:zephyr/object_box/migration/migration_v9_to_v10.dart';
import 'package:zephyr/object_box/migration/migration_v10_to_v11.dart';
import 'package:zephyr/object_box/migration/migration_v11_to_v12.dart';

const _defaultCompatibleVersion = 'v1';
const _latestCompatibleVersion = 'v12';

Future<void> ensureCompatibleMigration(BuildContext context) async {
  try {
    var version = await getCompatibleVersion(database);
    var migrated = false;

    if (version == 'v1' || version == 'v2') {
      if (context.mounted) {
        context.read<StringSelectCubit>().setDate('数据迁移中，请耐心等待');
      }
    }

    if (version == 'v1') {
      await migrateV1ToV2(database);
      await migrateLegacyDownloadFilesToPluginUuidLayout();
      await setCompatibleVersion(database, 'v2');
      version = 'v2';
      migrated = true;
    }

    if (version == 'v2') {
      await migrateV2ToV3(database);
      await setCompatibleVersion(database, 'v3');
      version = 'v3';
      migrated = true;
    }

    if (version == 'v3') {
      await migrateV3ToV4(database);
      await setCompatibleVersion(database, 'v4');
      version = 'v4';
      migrated = true;
    }

    if (version == 'v4') {
      await migrateV4ToV5(database);
      await setCompatibleVersion(database, 'v5');
      migrated = true;
      version = 'v5';
    }

    if (version == 'v5') {
      await migrateV5ToV6(database);
      await setCompatibleVersion(database, 'v6');
      migrated = true;
      version = 'v6';
    }

    if (version == 'v6') {
      await migrateV6ToV7(database);
      await setCompatibleVersion(database, 'v7');
      migrated = true;
      version = 'v7';
    }

    if (version == 'v7') {
      await migrateV7ToV8(database);
      await setCompatibleVersion(database, 'v8');
      migrated = true;
      version = 'v8';
    }

    if (version == 'v8') {
      await migrateV8ToV9(database);
      await setCompatibleVersion(database, 'v9');
      migrated = true;
      version = 'v9';
    }

    if (version == 'v9') {
      await migrateV9ToV10(database);
      await setCompatibleVersion(database, 'v10');
      migrated = true;
      version = 'v10';
    }
    if (version == 'v10') {
      await migrateV10ToV11(database);
      await setCompatibleVersion(database, 'v11');
      migrated = true;
      version = 'v11';
    }

    if (version == 'v11') {
      await migrateV11ToV12(database);
      await setCompatibleVersion(database, _latestCompatibleVersion);
      migrated = true;
      version = 'v12';
    }

    if (migrated) {
      final setting = await database.userSettings.get();
      if (!context.mounted) return;
      if (setting != null) {
        context.read<GlobalSettingCubit>().updateALl(setting.globalSetting);
      }
    }
  } catch (e, stackTrace) {
    logger.e('Compatible migration failed', error: e, stackTrace: stackTrace);
  }
}

Future<String> getCompatibleVersion(Database database) async {
  final setting = await database.userSettings.get();
  if (setting == null) {
    throw Exception('Global setting not found');
  }
  final version = setting.globalSetting.compatibleVersion;
  return version.isEmpty ? _defaultCompatibleVersion : version;
}

Future<void> setCompatibleVersion(Database database, String version) async {
  final setting = await database.userSettings.get();
  if (setting == null) {
    throw Exception('Global setting not found');
  }
  setting.globalSetting = setting.globalSetting.copyWith(
    compatibleVersion: version,
  );
  await database.userSettings.put(setting);
}
