import 'dart:convert';

import 'package:zephyr/database/db.dart';
import 'package:zephyr/object_box/model.dart';

class UserSettingRepository {
  final BreezeDatabase db;
  Future<void> _writeChain = Future<void>.value();

  UserSettingRepository(this.db);

  Future<T> _enqueueWrite<T>(Future<T> Function() action) {
    final next = _writeChain.then((_) => action());
    _writeChain = next.then<void>((_) {}, onError: (_) {});
    return next;
  }

  Future<UserSetting?> get() async {
    final rows = await db.query(
      'SELECT * FROM "UserSetting" WHERE "id" = 1 LIMIT 1',
    );
    if (rows.isEmpty) return null;
    return _decode(rows.first);
  }

  Future<UserSetting> getOrCreate() async {
    final existing = await get();
    if (existing != null) return existing;
    final setting = UserSetting();
    await put(setting);
    return setting;
  }

  Future<void> put(UserSetting setting) {
    if (db.inTransaction) return _doPut(setting);
    return _enqueueWrite(() => _doPut(setting));
  }

  Future<void> _doPut(UserSetting setting) async {
    await db.execute(
      'INSERT INTO "UserSetting" '
      '("id","globalSettingData","bikaSettingData","jmSettingData","jmJwt") '
      'VALUES (1,?,?,?,?) '
      'ON CONFLICT("id") DO UPDATE SET '
      '"globalSettingData"=excluded."globalSettingData",'
      '"bikaSettingData"=excluded."bikaSettingData",'
      '"jmSettingData"=excluded."jmSettingData",'
      '"jmJwt"=excluded."jmJwt"',
      <Object?>[
        setting.globalSettingData,
        setting.bikaSettingData,
        setting.jmSettingData,
        setting.jmJwt,
      ],
    );
  }

  Future<String?> getGlobalSettingData() async {
    final rows = await db.query(
      'SELECT "globalSettingData" FROM "UserSetting" WHERE "id" = 1',
    );
    if (rows.isEmpty) return null;
    return rows.first['globalSettingData'] as String?;
  }

  Future<void> putGlobalSettingData(String data) {
    if (db.inTransaction) return _doPutGlobalSettingData(data);
    return _enqueueWrite(() => _doPutGlobalSettingData(data));
  }

  Future<void> _doPutGlobalSettingData(String data) async {
    await db.execute(
      'INSERT INTO "UserSetting" ("id","globalSettingData","jmJwt") '
      'VALUES (1,?, \'\') '
      'ON CONFLICT("id") DO UPDATE SET '
      '"globalSettingData"=excluded."globalSettingData"',
      <Object?>[data],
    );
  }

  UserSetting _decode(Map<String, dynamic> row) {
    return UserSetting.fromJson(<String, dynamic>{
      ...row,
      'globalSetting': _settingMap(row['globalSettingData']),
      'bikaSetting': _settingMap(row['bikaSettingData']),
      'jmSetting': _settingMap(row['jmSettingData']),
    });
  }

  Map<String, dynamic> _settingMap(Object? raw) {
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return const <String, dynamic>{};
  }
}
