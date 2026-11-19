#!/usr/bin/env dart

// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:code_assets/code_assets.dart';
import 'package:path/path.dart' as p;

import 'ohos_env.dart';

// ════════════════════════════════════════════════════════════════
//  ANSI 颜色
// ════════════════════════════════════════════════════════════════
const String _green = '\x1B[32m';
const String _cyan = '\x1B[36m';
const String _red = '\x1B[31m';
const String _yellow = '\x1B[33m';
const String _magenta = '\x1B[35m';
const String _reset = '\x1B[0m';

Process? _currentProcess;

void _printColor(String text, String color) {
  print('$color$text$_reset');
}

// ════════════════════════════════════════════════════════════════
//  进程工具
// ════════════════════════════════════════════════════════════════

Future<int> _runCommand(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  Map<String, String>? environment,
}) async {
  _printColor('> $executable ${arguments.join(' ')}', _magenta);
  final childEnvironment = environment == null
      ? null
      : <String, String>{...Platform.environment, ...environment};
  final process = await Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    environment: childEnvironment,
    runInShell: true,
  );
  _currentProcess = process;

  process.stdout.transform(systemEncoding.decoder).listen(stdout.write);
  process.stderr.transform(systemEncoding.decoder).listen(stderr.write);

  final exitCode = await process.exitCode;
  _currentProcess = null;
  return exitCode;
}

Future<void> _killProcessTree(Process process) async {
  try {
    if (Platform.isWindows) {
      await Process.run('taskkill', ['/F', '/T', '/PID', '${process.pid}']);
    } else {
      process.kill(ProcessSignal.sigterm);
    }
  } catch (error) {
    _printColor('杀进程失败: $error', _red);
  }
}

// ════════════════════════════════════════════════════════════════
//  参数
// ════════════════════════════════════════════════════════════════

class _Options {
  bool check = false;
  bool rust = false;
  bool hap = false;
  bool all = false;
  bool debug = false;
  bool noImpeller = false;
  bool rustLog = false;
  bool noRust = false;
  bool help = false;
  String entry = 'lib/main_ohos.dart';
  String arch = 'arm64';
  String? flutter;

  static _Options parse(List<String> args) {
    final options = _Options();
    for (var i = 0; i < args.length; i++) {
      final arg = args[i];
      switch (arg) {
        case '--check':
          options.check = true;
        case '--rust':
          options.rust = true;
        case '--hap':
          options.hap = true;
        case '--all':
          options.all = true;
        case '--debug':
          options.debug = true;
        case '--no-impeller':
          options.noImpeller = true;
        case '--rust-log':
          options.rustLog = true;
        case '--no-rust':
          options.noRust = true;
        case '--help' || '-h':
          options.help = true;
        case '--entry':
          if (i + 1 >= args.length) {
            throw ArgumentError('--entry 需要一个路径');
          }
          options.entry = args[++i];
        case '--arch':
          if (i + 1 >= args.length) {
            throw ArgumentError('--arch 需要 arm64 或 x64');
          }
          options.arch = args[++i];
        case '--flutter':
          if (i + 1 >= args.length) {
            throw ArgumentError('--flutter 需要一个路径');
          }
          options.flutter = args[++i];
        default:
          if (arg.startsWith('--flutter=')) {
            options.flutter = arg.substring('--flutter='.length);
          } else if (arg.startsWith('--entry=')) {
            options.entry = arg.substring('--entry='.length);
          } else if (arg.startsWith('--arch=')) {
            options.arch = arg.substring('--arch='.length);
          } else {
            throw ArgumentError('未知参数: $arg');
          }
      }
    }
    if (!options.check &&
        !options.rust &&
        !options.hap &&
        !options.all &&
        !options.help) {
      options.check = true;
    }
    if (options.arch != 'arm64' && options.arch != 'x64') {
      throw ArgumentError('--arch 只支持 arm64 或 x64');
    }
    return options;
  }
}

// ════════════════════════════════════════════════════════════════
//  入口
// ════════════════════════════════════════════════════════════════

Future<void> main(List<String> args) async {
  final _Options options;
  try {
    options = _Options.parse(args);
  } on ArgumentError catch (error) {
    _printColor(error.message.toString(), _red);
    _printUsage();
    exitCode = 64;
    return;
  }

  if (options.help) {
    _printUsage();
    return;
  }

  ProcessSignal.sigint.watch().listen((_) async {
    final process = _currentProcess;
    if (process != null) await _killProcessTree(process);
    exit(130);
  });

  final projectRoot = _projectRoot();
  _printColor('Breeze OpenHarmony 构建脚本', _cyan);
  _printColor('项目根目录: $projectRoot', _cyan);

  if (options.check || options.all) {
    await _check(projectRoot, options);
  }
  if (options.rust || options.all) {
    await _rust(projectRoot, options);
  }
  if (options.hap || options.all) {
    // --all 已经跑过 --rust，--hap 不再重复编译。
    if (options.all) options.noRust = true;
    await _hap(projectRoot, options);
  }

  // ProcessSignal.sigint.watch() 会保持事件循环存活，这里显式退出。
  exit(exitCode);
}

String _projectRoot() {
  final scriptPath = Platform.script.toFilePath();
  return p.dirname(p.dirname(p.dirname(scriptPath)));
}

// ════════════════════════════════════════════════════════════════
//  --check
// ════════════════════════════════════════════════════════════════

Future<void> _check(String projectRoot, _Options options) async {
  _printColor('\n== 环境检查 ==', _cyan);

  var toolEnv = <String, String>{};
  try {
    final nativeDir = findOhosNativeDir();
    final sdkRoot = ohosSdkRoot(nativeDir);
    final llvmBase = ohosLlvmBase(nativeDir);
    final clangVersion = ohosClangVersion(nativeDir);
    final clang = p.join(
      llvmBase,
      'bin',
      Platform.isWindows ? 'clang.exe' : 'clang',
    );
    final toolchain = File(
      p.join(nativeDir, 'build', 'cmake', 'ohos.toolchain.cmake'),
    );
    toolEnv = _ohosToolEnvironment(nativeDir);

    _printColor('OHOS native: $nativeDir', _green);
    _printColor('OHOS SDK root: $sdkRoot', _green);
    if (nativeDir.contains(' ')) {
      _printColor(
        '警告: SDK 路径包含空格，RUSTFLAGS/BINDGEN 参数可能被拆分；'
        '建议安装到无空格路径。',
        _yellow,
      );
    }
    _printColor(
      'clang: $clang (version: ${clangVersion ?? 'unknown'})',
      _green,
    );
    _printColor(
      'ohos.toolchain.cmake: ${toolchain.existsSync() ? 'found' : 'missing'}',
      toolchain.existsSync() ? _green : _red,
    );

    final javaHome =
        toolEnv['JAVA_HOME'] ?? Platform.environment['JAVA_HOME'] ?? '(未设置)';
    _printColor('JAVA_HOME: $javaHome', _green);

    final ohosModule = Directory(p.join(projectRoot, 'ohos'));
    _printColor(
      'ohos/ 模块: '
      '${ohosModule.existsSync() ? 'found' : 'missing（先运行 flutter create --platforms ohos .）'}',
      ohosModule.existsSync() ? _green : _yellow,
    );

    final toolHome =
        Platform.environment['TOOL_HOME'] ??
        (Platform.isWindows ? r'C:\Program Files\Huawei\DevEco Studio' : '');
    for (final relative in <String>[
      Platform.isWindows ? 'tools/ohpm/bin/ohpm.bat' : 'tools/ohpm/bin/ohpm',
      Platform.isWindows
          ? 'tools/hvigor/bin/hvigorw.bat'
          : 'tools/hvigor/bin/hvigorw',
      Platform.isWindows ? 'tools/node/node.exe' : 'tools/node/bin/node',
    ]) {
      final found = File(p.join(toolHome, relative)).existsSync();
      _printColor(
        '${p.basename(relative)}: ${found ? 'found' : 'missing'}',
        found ? _green : _yellow,
      );
    }

    final ninja = await Process.run('ninja', ['--version'], runInShell: true);
    _printColor(
      'ninja: ${ninja.exitCode == 0 ? (ninja.stdout as String).trim() : 'missing'}',
      ninja.exitCode == 0 ? _green : _red,
    );
  } on StateError catch (error) {
    _printColor(error.message, _red);
    _printSdkHelp();
  }

  final crateDirectory = p.join(projectRoot, 'rust');
  final channel = readRustToolchainChannel(crateDirectory);
  final installed = await _installedRustTargets(channel);
  for (final triple in <String>[
    ohosArm64Triple,
    ohosArmTriple,
    ohosX64Triple,
  ]) {
    final ok = installed.contains(triple);
    _printColor(
      'rust target $triple: ${ok ? 'installed' : 'missing'}',
      ok ? _green : _yellow,
    );
    if (!ok) {
      _printColor('  rustup target add --toolchain $channel $triple', _yellow);
    }
  }

  final flutter = _resolveFlutterExecutable(_findFlutter(options.flutter));
  _printColor('flutter: $flutter', _cyan);
  final version = await Process.run(
    flutter,
    ['--version'],
    runInShell: true,
    environment: toolEnv,
  );
  if (version.exitCode == 0) {
    final text = version.stdout as String;
    final firstLine = text
        .split('\n')
        .firstWhere((line) => line.trim().isNotEmpty, orElse: () => '')
        .trim();
    if (firstLine.isNotEmpty) _printColor('  $firstLine', _green);
    if (!text.toLowerCase().contains('ohos')) {
      _printColor(
        '  提示: 当前 Flutter 不是 OHOS 分支，HAP 构建会失败。'
        '用 --flutter 或 OHOS_FLUTTER 指向 flutter_flutter。',
        _yellow,
      );
    }
  } else {
    _printColor(
      '  flutter --version 失败；请设置 OHOS_FLUTTER 指向鸿蒙 Flutter SDK',
      _yellow,
    );
  }
}

Future<Set<String>> _installedRustTargets(String channel) async {
  final result = await Process.run('rustup', [
    'target',
    'list',
    '--installed',
    '--toolchain',
    channel,
  ]);
  if (result.exitCode != 0) return <String>{};
  return (result.stdout as String)
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .toSet();
}

// ════════════════════════════════════════════════════════════════
//  --rust
// ════════════════════════════════════════════════════════════════

Future<void> _rust(String projectRoot, _Options options) async {
  _printColor('\n== 编译 Rust (OpenHarmony) ==', _cyan);
  if (!await _ensureNinja()) return;

  final nativeDir = findOhosNativeDir();
  final crateDirectory = p.join(projectRoot, 'rust');
  final channel = readRustToolchainChannel(crateDirectory);
  final architecture = options.arch == 'x64'
      ? Architecture.x64
      : Architecture.arm64;
  final targetTriple = ohosTargetTriple(architecture);
  final environment = ohosEnvironmentVariables(
    architecture: architecture,
    nativeDir: nativeDir,
  );

  final code = await _runCommand(
    'rustup',
    <String>[
      'run',
      channel,
      'cargo',
      'build',
      if (!options.debug) '--release',
      '--manifest-path',
      p.join(crateDirectory, 'Cargo.toml'),
      '--package',
      'windcore',
      '--target',
      targetTriple,
      '--features',
      'host-fronting',
    ],
    workingDirectory: crateDirectory,
    environment: environment,
  );
  if (code != 0) {
    _printColor('Rust 编译失败（exit $code）', _red);
    exitCode = code;
  } else {
    _printColor(
      'Rust 产物: rust/target/$targetTriple/'
      '${options.debug ? 'debug' : 'release'}/libwindcore.so',
      _green,
    );
  }
}

// ════════════════════════════════════════════════════════════════
//  --hap
// ════════════════════════════════════════════════════════════════

Future<void> _hap(String projectRoot, _Options options) async {
  _printColor('\n== 构建 HAP (${options.entry}) ==', _cyan);

  final ohosModule = Directory(p.join(projectRoot, 'ohos'));
  if (!ohosModule.existsSync()) {
    _printColor(
      '未找到 ohos/ 模块。先运行 `flutter create --platforms ohos .` 生成平台工程。',
      _red,
    );
    exitCode = 66;
    return;
  }

  final nativeDir = findOhosNativeDir();

  if (!options.noRust) {
    await _rust(projectRoot, options);
    if (exitCode != 0) return;
  }

  final flutter = _resolveFlutterExecutable(_findFlutter(options.flutter));
  // OHOS fork 的 Dart 3.13 无法解析桌面栈（要求 ^3.14）；构建期间临时裁剪，
  // 结束后恢复。备份在 .dart_tool/ohos_pub_backup/，进程被杀也能手动恢复。
  final pubBackup = await _prepareOhosPubspec(projectRoot, flutter);

  late int code;
  final marker = File(p.join(projectRoot, '.dart_tool', 'ohos_build_marker'));
  final impellerFile = File(
    p.join(
      projectRoot,
      'ohos',
      'entry',
      'src',
      'main',
      'resources',
      'rawfile',
      'buildinfo.json5',
    ),
  );
  String? impellerBackup;
  try {
    if (options.noImpeller && await impellerFile.exists()) {
      impellerBackup = await impellerFile.readAsString();
      await impellerFile.writeAsString(
        impellerBackup.replaceAll('"value": "true"', '"value": "false"'),
      );
    }
    await marker.parent.create(recursive: true);
    await marker.writeAsString('${DateTime.now().toIso8601String()}\n');
    await _stageWindcore(
      projectRoot,
      release: !options.debug,
      arch: options.arch,
    );
    if (exitCode != 0) return;
    code = await _runCommand(
      flutter,
      <String>[
        'build',
        'hap',
        '-t',
        options.entry,
        '--target-platform',
        options.arch == 'x64' ? 'ohos-x64' : 'ohos-arm64',
        if (options.debug) '--debug',
        if (options.rustLog) '--dart-define=rust_log=true',
        if (Platform.environment['BREEZE_OHOS_VERBOSE'] == '1') '--verbose',
      ],
      workingDirectory: projectRoot,
      environment: _ohosToolEnvironment(nativeDir),
    );
  } finally {
    if (await marker.exists()) await marker.delete();
    if (impellerBackup != null) {
      await impellerFile.writeAsString(impellerBackup);
    }
    await pubBackup?.restore();
  }
  if (code != 0) {
    _printColor('HAP 构建失败（exit $code）', _red);
    _printColor(
      '确认使用的是 OHOS Flutter 分支（3.41+ohos 或更新），'
      '并通过 --flutter 或 OHOS_FLUTTER 指定。',
      _yellow,
    );
    exitCode = code;
  } else {
    _printColor('HAP 产物目录: ohos/entry/build/default/outputs/default', _green);
  }
}

/// 把 Rust 产物放进 OHOS 模块的 native libs 目录。
///
/// Flutter OH 的 native assets 对 OHOS 支持不可靠，因此 OHOS 走
/// 「预编译 + HAP 直接打包」：hvigor 会把 `entry/libs/<abi>/*.so`
/// 原样放进 HAP 的 `libs/<abi>/`，FRB loader 用
/// `DynamicLibrary.open('libwindcore.so')` 加载。
Future<void> _stageWindcore(
  String projectRoot, {
  required bool release,
  required String arch,
}) async {
  _printColor('\n== 打包 libwindcore.so ==', _cyan);
  final source = File(
    p.join(
      projectRoot,
      'rust',
      'target',
      arch == 'x64' ? ohosX64Triple : ohosArm64Triple,
      release ? 'release' : 'debug',
      'libwindcore.so',
    ),
  );
  if (!source.existsSync()) {
    _printColor('找不到 Rust 产物: ${source.path}（先运行 --rust）', _red);
    exitCode = 66;
    return;
  }

  // 清掉另一个 ABI 的旧产物，避免 hvigor 把 arm64/x64 一起打进同一个 HAP。
  for (final abi in <String>['arm64-v8a', 'x86_64']) {
    final stale = File(
      p.join(projectRoot, 'ohos', 'entry', 'libs', abi, 'libwindcore.so'),
    );
    if (await stale.exists()) await stale.delete();
  }

  final destDir = Directory(
    p.join(
      projectRoot,
      'ohos',
      'entry',
      'libs',
      arch == 'x64' ? 'x86_64' : 'arm64-v8a',
    ),
  );
  await destDir.create(recursive: true);
  final dest = File(p.join(destDir.path, 'libwindcore.so'));
  await source.copy(dest.path);

  if (release) {
    final strip = p.join(
      ohosLlvmBase(findOhosNativeDir()),
      'bin',
      Platform.isWindows ? 'llvm-strip.exe' : 'llvm-strip',
    );
    if (File(strip).existsSync()) {
      final result = await Process.run(strip, <String>[
        '--strip-unneeded',
        dest.path,
      ]);
      if (result.exitCode != 0) {
        _printColor('llvm-strip 失败，保留未 strip 的产物', _yellow);
      }
    } else {
      _printColor('未找到 llvm-strip，跳过 strip', _yellow);
    }
  }

  final sizeMb = (await dest.length()) / 1024 / 1024;
  _printColor(
    '${p.relative(dest.path, from: projectRoot)} '
    '(${sizeMb.toStringAsFixed(1)} MB)',
    _green,
  );
}

/// OHOS Flutter/hvigor 需要的环境变量：DevEco SDK 根目录和内置工具链。
Map<String, String> _ohosToolEnvironment(String nativeDir) {
  final environment = <String, String>{};
  final sdkHome = _devecoSdkHome(nativeDir);
  if (sdkHome != null &&
      (Platform.environment['DEVECO_SDK_HOME'] ?? '').isEmpty) {
    environment['DEVECO_SDK_HOME'] = sdkHome;
  }

  final toolHome =
      Platform.environment['TOOL_HOME'] ??
      (Platform.isWindows ? r'C:\Program Files\Huawei\DevEco Studio' : '');
  final extraPaths = <String>[];
  for (final relative in <String>[
    'tools/ohpm/bin',
    'tools/hvigor/bin',
    'tools/node',
  ]) {
    final directory = p.join(toolHome, relative);
    if (Directory(directory).existsSync()) extraPaths.add(directory);
  }
  if (extraPaths.isNotEmpty) {
    environment['PATH'] = <String>[
      ...extraPaths,
      Platform.environment['PATH'] ?? '',
    ].join(Platform.isWindows ? ';' : ':');
  }

  final javaHome = Platform.environment['JAVA_HOME'] ?? '';
  final java = p.join(
    javaHome,
    'bin',
    Platform.isWindows ? 'java.exe' : 'java',
  );
  if (javaHome.isEmpty || !File(java).existsSync()) {
    final jbr = p.join(toolHome, 'jbr');
    if (Directory(jbr).existsSync()) environment['JAVA_HOME'] = jbr;
  }
  return environment;
}

/// 从 `<sdk>/default/openharmony/native` 还原 DevEco 的 SDK 根目录。
String? _devecoSdkHome(String nativeDir) {
  final parts = p.split(p.normalize(nativeDir));
  final index = parts.lastIndexOf('native');
  if (index >= 3 &&
      parts[index - 1] == 'openharmony' &&
      parts[index - 2] == 'default') {
    return p.joinAll(parts.sublist(0, index - 3));
  }
  return null;
}

// ════════════════════════════════════════════════════════════════
//  工具
// ════════════════════════════════════════════════════════════════

/// OHOS fork 的 Dart < 3.14 时，桌面栈（window_manager/tray_manager/
/// screen_retriever → nativeapi 0.6）无法解析。构建期间通过 dependency_overrides
/// 把它们替换成本地 no-op stub（并接入 UI fork），结束后恢复 pubspec/lock。
Future<_PubBackup?> _prepareOhosPubspec(
  String projectRoot,
  String flutter,
) async {
  final pubspec = File(p.join(projectRoot, 'pubspec.yaml'));
  if (!await pubspec.exists()) return null;
  final content = await pubspec.readAsString();

  final version = await Process.run(
    flutter,
    ['--version'],
    runInShell: true,
    environment: _ohosToolEnvironment(findOhosNativeDir()),
  );
  final text = '${version.stdout}\n${version.stderr}';
  final match = RegExp(r'Dart (\d+)\.(\d+)\.').firstMatch(text);
  if (match == null) {
    _printColor('无法识别 OHOS Flutter 的 Dart 版本，跳过依赖替换', _yellow);
    return null;
  }
  final major = int.parse(match.group(1)!);
  final minor = int.parse(match.group(2)!);
  final needStubs = major < 3 || (major == 3 && minor < 14);

  _printColor(
    needStubs
        ? 'OHOS Dart $major.$minor < 3.14：桌面依赖替换为 no-op stub'
        : 'OHOS Dart $major.$minor：保留桌面依赖',
    needStubs ? _yellow : _cyan,
  );

  // 纯 Dart fork 通过 GitHub git 依赖引入，仓库内不再保留完整源码。
  final gitOverrides = <String, ({String url, String ref})>{
    'material_ui': (
      url: 'https://github.com/deretame/material_ui_ohos.git',
      ref: 'ohos-1.11.1',
    ),
    'cupertino_ui': (
      url: 'https://github.com/deretame/cupertino_ui_ohos.git',
      ref: 'ohos-1.1.7',
    ),
    'easy_refresh': (
      url: 'https://github.com/deretame/easy_refresh_ohos.git',
      ref: 'ohos-4.0.0',
    ),
  };

  final overridePaths = <String, String>{
    // 桌面栈依赖 nativeapi 0.6（要求 Dart 3.14）；OHOS 不执行这些路径。
    if (needStubs) ...<String, String>{
      'window_manager': 'third_party/ohos_stubs/window_manager',
      'screen_retriever': 'third_party/ohos_stubs/screen_retriever',
      'tray_manager': 'third_party/ohos_stubs/tray_manager',
    },
  };

  final forkOverrides = <String>[];
  for (final entry in gitOverrides.entries) {
    forkOverrides.add(
      '  ${entry.key}:\n'
      '    git:\n'
      '      url: ${entry.value.url}\n'
      '      ref: ${entry.value.ref}\n',
    );
  }
  for (final entry in overridePaths.entries) {
    final fork = Directory(p.join(projectRoot, entry.value));
    if (await fork.exists()) {
      forkOverrides.add('  ${entry.key}:\n    path: ${entry.value}\n');
    }
  }
  if (forkOverrides.isEmpty) return null;

  final backupDir = Directory(
    p.join(projectRoot, '.dart_tool', 'ohos_pub_backup'),
  );
  await backupDir.create(recursive: true);
  await File(p.join(backupDir.path, 'pubspec.yaml')).writeAsString(content);

  final lock = File(p.join(projectRoot, 'pubspec.lock'));
  final lockContent = await lock.exists() ? await lock.readAsString() : null;
  if (lockContent != null) {
    await File(p.join(backupDir.path, 'pubspec.lock'))
        .writeAsString(lockContent);
  }

  var trimmed = content;
  final overrideEntries = forkOverrides.join();
  if (trimmed.contains('dependency_overrides:\n')) {
    trimmed = trimmed.replaceFirst(
      'dependency_overrides:\n',
      'dependency_overrides:\n$overrideEntries',
    );
  } else {
    trimmed = '$trimmed\ndependency_overrides:\n$overrideEntries';
  }
  await pubspec.writeAsString(trimmed);
  return _PubBackup(
    projectRoot: projectRoot,
    pubspecContent: content,
    lockContent: lockContent,
  );
}

class _PubBackup {
  _PubBackup({
    required this.projectRoot,
    required this.pubspecContent,
    required this.lockContent,
  });

  final String projectRoot;
  final String pubspecContent;
  final String? lockContent;

  Future<void> restore() async {
    await File(p.join(projectRoot, 'pubspec.yaml'))
        .writeAsString(pubspecContent);
    final lock = lockContent;
    if (lock != null) {
      await File(p.join(projectRoot, 'pubspec.lock')).writeAsString(lock);
    }
    // 恢复后的 pubspec.lock mtime 晚于 OHOS pub get 写出的 package_config，
    // Flutter 下一次构建会自动重新 pub get；不要删除 package_config，
    // 否则下一次 `dart script/build/build_ohos.dart` 无法解析 package: 导入。
    // 备份保留（每次构建覆盖）：进程被强杀时 restore 不会执行，可从这里手动恢复。
    final backupDir = p.join(projectRoot, '.dart_tool', 'ohos_pub_backup');
    _printColor('备份: $backupDir/pubspec.yaml', _cyan);
    _printColor(
      '已恢复 pubspec.yaml / pubspec.lock；下一次 Flutter 构建会重新 pub get',
      _cyan,
    );
  }
}

/// aws-lc-sys 在 Windows 上必须用 Ninja 生成器，否则 CMake 会选 MSVC。
Future<bool> _ensureNinja() async {
  final result = await Process.run('ninja', ['--version'], runInShell: true);
  if (result.exitCode == 0) return true;
  _printColor(
    '未找到 Ninja。aws-lc-sys 的 CMake 需要 Ninja 生成器；'
    '安装后确保 `ninja` 在 PATH 中（winget install Ninja-build.Ninja）。',
    _red,
  );
  exitCode = 69;
  return false;
}

String _findFlutter(String? explicit) {
  if (explicit != null && explicit.isNotEmpty) return explicit;
  final fromEnvironment = Platform.environment['OHOS_FLUTTER'];
  if (fromEnvironment != null && fromEnvironment.isNotEmpty) {
    return fromEnvironment;
  }
  return Platform.isWindows ? 'flutter.bat' : 'flutter';
}

String _resolveFlutterExecutable(String value) {
  if (Directory(value).existsSync()) {
    final executable = p.join(
      value,
      'bin',
      Platform.isWindows ? 'flutter.bat' : 'flutter',
    );
    if (File(executable).existsSync()) return executable;
  }
  return value;
}

void _printUsage() {
  print('''
用法: dart ./script/build/build_ohos.dart [选项]

选项:
  --check            检查 OHOS SDK / Rust target / Flutter 环境（默认）
  --rust             只编译 Rust（windcore, aarch64-unknown-linux-ohos）
  --hap              编译 Rust + 打包 libwindcore.so + 构建 HAP
  --all              check + rust + hap
  --debug            Rust / HAP 使用 debug 模式（不 strip）
  --no-rust          --hap 时跳过 Rust 编译，直接用已有产物
  --entry <path>     HAP 入口，默认 lib/main_ohos.dart
  --arch <abi>       arm64（默认）或 x64（模拟器）
  --no-impeller      构建期间关闭 Impeller（模拟器白屏时用，构建后恢复）
  --rust-log         HAP 传 --dart-define=rust_log=true（release 也能出 Rust 日志）
  --flutter <path>   OHOS Flutter 可执行文件或 SDK 目录
  -h, --help         显示帮助

环境变量:
  OHOS_SDK_NATIVE    OpenHarmony SDK 的 native 目录
  DEVECO_SDK_HOME    DevEco SDK 根目录（其下含 native/）
  TOOL_HOME          DevEco Studio 安装目录（默认 C:\\Program Files\\Huawei\\DevEco Studio）
  OHOS_FLUTTER       flutter_flutter 的 bin/flutter(.bat) 或 SDK 目录
  PUB_CACHE          建议与官方 Flutter 分开（Dart 3.13 vs 3.14）
''');
}

void _printSdkHelp() {
  _printColor('''
OpenHarmony SDK 下载:
  1) DevEco Studio（含 SDK）:
     https://developer.huawei.com/consumer/cn/deveco-studio/
  2) 命令行 SDK（约 2.67 GB）:
     https://repo.huaweicloud.com/openharmony/os/5.0.0-Release/ohos-sdk-windows_linux-public.tar.gz
     https://repo.huaweicloud.com/openharmony/os/5.0.0-Release/ohos-sdk-windows_linux-public.tar.gz.sha256

解压后设置:
  OHOS_SDK_NATIVE=<sdk>/native
  DEVECO_SDK_HOME=<sdk>

OHOS Flutter:
  git clone https://gitcode.com/CPF-Flutter/flutter_flutter.git
  cd flutter_flutter
  git checkout 3.47.7+ohos-0.0.1-pre
  set OHOS_FLUTTER=<path>/bin/flutter.bat   （或直接指向 SDK 目录）
  首次运行会下载 Dart 3.13.5 / OHOS engine 产物
''', _yellow);
}
