import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:zephyr/plugin/plugin_bytecode_cache.dart';
import 'package:zephyr/src/rust/qjs.dart';

class _FakeBackend implements PluginBytecodeBackend {
  _FakeBackend({this.publish = true});

  /// 编译是否产出字节码（false 用来模拟「编译失败/空结果」）。
  final bool publish;

  final List<({String bundleName, String source})> compiles =
      <({String bundleName, String source})>[];
  final List<String> appVersions = <String>[];

  @override
  int bytecodeVersion() => 26;

  @override
  void setAppVersion(String value) => appVersions.add(value);

  @override
  String hashPluginId(String pluginId) =>
      'f_${pluginId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';

  @override
  Future<List<int>> compile({
    required String bundleName,
    required String source,
  }) async {
    compiles.add((bundleName: bundleName, source: source));
    return publish ? <int>[1, 2, 3, 4] : <int>[];
  }
}

const _pluginA = '11111111-aaaa-bbbb-cccc-000000000001';
const _pluginB = '22222222-aaaa-bbbb-cccc-000000000002';

String _hash(String pluginId) =>
    'f_${pluginId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';

void main() {
  late Directory tempDir;
  late _FakeBackend backend;

  PluginBytecodeCache buildCache() => PluginBytecodeCache(
    directory: () async => tempDir.path,
    backend: backend,
  );

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('plugin-bytecode-test');
    backend = _FakeBackend();
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('缺失缓存时返回 null 且不触发编译', () async {
    final cache = buildCache();
    final bytes = await cache.load(pluginId: _pluginA, pluginDebug: false);
    expect(bytes, isNull);
    expect(backend.compiles, isEmpty);
  });

  test('调试插件既不读也不写字节码', () async {
    final cache = buildCache();
    final file = File(p.join(tempDir.path, '26_${_hash(_pluginA)}.bc'));
    file.writeAsBytesSync(<int>[9, 9, 9]);

    expect(await cache.load(pluginId: _pluginA, pluginDebug: true), isNull);

    await cache.afterLoad(
      pluginId: _pluginA,
      bundleName: _pluginA,
      source: 'module.exports = {};',
      pluginDebug: true,
      result: const QjsBundleInstallResult(usedBytecode: false),
    );
    expect(backend.compiles, isEmpty);
    expect(file.existsSync(), isTrue);
  });

  test('字节码命中时不再编译', () async {
    final cache = buildCache();
    final file = File(p.join(tempDir.path, '26_${_hash(_pluginA)}.bc'));
    file.writeAsBytesSync(<int>[1, 2, 3]);

    expect(await cache.load(pluginId: _pluginA, pluginDebug: false), <int>[1, 2, 3]);

    await cache.afterLoad(
      pluginId: _pluginA,
      bundleName: _pluginA,
      source: 'module.exports = {};',
      pluginDebug: false,
      result: const QjsBundleInstallResult(usedBytecode: true),
    );
    expect(backend.compiles, isEmpty);
  });

  test('未命中时后台编译并以版本_hash 落盘', () async {
    final cache = buildCache();
    await cache.afterLoad(
      pluginId: _pluginA,
      bundleName: _pluginA,
      source: 'module.exports = { value: 1 };',
      pluginDebug: false,
      result: const QjsBundleInstallResult(
        usedBytecode: false,
        bytecodeError: 'bytecode-source-mismatch',
      ),
    );

    expect(backend.compiles, hasLength(1));
    expect(backend.compiles.single.bundleName, _pluginA);
    expect(backend.appVersions, isNotEmpty);

    final file = File(p.join(tempDir.path, '26_${_hash(_pluginA)}.bc'));
    expect(file.existsSync(), isTrue);
    expect(await file.readAsBytes(), <int>[1, 2, 3, 4]);
    expect(await cache.load(pluginId: _pluginA, pluginDebug: false), <int>[
      1,
      2,
      3,
      4,
    ]);
  });

  test('编译前删除同插件其它版本的缓存，且不误删其它插件', () async {
    final cache = buildCache();
    final staleA1 = File(p.join(tempDir.path, '25_${_hash(_pluginA)}.bc'))
      ..writeAsBytesSync(<int>[1]);
    final staleATmp = File(p.join(tempDir.path, '25_${_hash(_pluginA)}.bc.tmp'))
      ..writeAsBytesSync(<int>[2]);
    final otherPlugin = File(p.join(tempDir.path, '25_${_hash(_pluginB)}.bc'))
      ..writeAsBytesSync(<int>[3]);

    await cache.afterLoad(
      pluginId: _pluginA,
      bundleName: _pluginA,
      source: 'module.exports = {};',
      pluginDebug: false,
      result: const QjsBundleInstallResult(usedBytecode: false),
    );

    expect(staleA1.existsSync(), isFalse);
    expect(staleATmp.existsSync(), isFalse);
    expect(otherPlugin.existsSync(), isTrue);
    expect(
      File(p.join(tempDir.path, '26_${_hash(_pluginA)}.bc')).existsSync(),
      isTrue,
    );
  });

  test('空源码或空编译结果不落盘', () async {
    backend = _FakeBackend(publish: false);
    final cache = buildCache();

    await cache.afterLoad(
      pluginId: _pluginA,
      bundleName: _pluginA,
      source: '   ',
      pluginDebug: false,
      result: const QjsBundleInstallResult(usedBytecode: false),
    );
    expect(backend.compiles, isEmpty);

    await cache.afterLoad(
      pluginId: _pluginA,
      bundleName: _pluginA,
      source: 'module.exports = {};',
      pluginDebug: false,
      result: const QjsBundleInstallResult(usedBytecode: false),
    );
    expect(backend.compiles, hasLength(1));
    expect(
      Directory(tempDir.path).listSync().whereType<File>(),
      isEmpty,
      reason: '编译失败不应留下空文件或临时文件',
    );
  });

  test('删除插件缓存只清理该插件', () async {
    final cache = buildCache();
    final a1 = File(p.join(tempDir.path, '25_${_hash(_pluginA)}.bc'))
      ..writeAsBytesSync(<int>[1]);
    final a2 = File(p.join(tempDir.path, '26_${_hash(_pluginA)}.bc'))
      ..writeAsBytesSync(<int>[2]);
    final b = File(p.join(tempDir.path, '26_${_hash(_pluginB)}.bc'))
      ..writeAsBytesSync(<int>[3]);

    await cache.delete(_pluginA);

    expect(a1.existsSync(), isFalse);
    expect(a2.existsSync(), isFalse);
    expect(b.existsSync(), isTrue);
  });
}
