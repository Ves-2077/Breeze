import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:zephyr/network/sync/comic_sync_core.dart';
import 'package:zephyr/util/rust/rust_loader.dart';

void main() {
  setUpAll(() async {
    await initRustLib(silent: true);
  });

  test('自定义密钥可加密解密，并能回退读取旧默认密钥数据', () async {
    final raw = utf8.encode('breeze encrypted payload');

    final custom = await ComicSyncCore.encodeEncryptedPayload(
      raw,
      passphrase: 'my-sync-key',
    );
    expect(
      await ComicSyncCore.decodeEncryptedPayload(
        custom,
        passphrase: 'my-sync-key',
      ),
      raw,
    );

    // 旧数据固定使用默认密钥；配置自定义密钥后仍要能读。
    final legacy = await ComicSyncCore.encodeEncryptedPayload(raw);
    expect(
      await ComicSyncCore.decodeEncryptedPayload(
        legacy,
        passphrase: 'my-sync-key',
      ),
      raw,
    );
    expect(await ComicSyncCore.decodeEncryptedPayload(legacy), raw);

    // 自定义密钥加密的数据不能用默认密钥读取。
    await expectLater(
      ComicSyncCore.decodeEncryptedPayload(custom),
      throwsA(isA<SyncDecryptionException>()),
    );
    await expectLater(
      ComicSyncCore.decodeEncryptedPayload(custom, passphrase: 'wrong-key'),
      throwsA(isA<SyncDecryptionException>()),
    );
  });
}
