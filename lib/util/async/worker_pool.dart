import 'dart:async';

import 'package:worker_manager/worker_manager.dart';

bool _inWorkerTask = false;

/// 在全局 worker 池（[workerManager]）里执行耗时任务。
///
/// 池内 isolate 常驻，省掉了 `compute` 每次 spawn + JIT 预热的固定开销；
/// 参数与结果通过 `SendPort` 深拷贝（普通模型图实测毫秒级），因此适合
/// 「计算重」的任务，没必要为一条小查询单独入池。
///
/// [task] 是跨 isolate 发送的闭包，只在 worker 内执行：
///
/// - 闭包里不要访问 `main.dart` 的全局状态（`database`、`logger`、
///   `globalSetting` 等）：worker isolate 从未执行过 `main()`，这些是空的。
///   需要在 worker 里用的值（handle、参数、模型）必须在**调用方**先算好，
///   再作为闭包的捕获变量带过去。
/// - 不要捕获 `Database`、`Cubit`、`BuildContext` 等对象；worker 内用
///   `Database.fromHandle(handle)` + `initRustLib()` 重建。
/// - 已在池内时直接执行，不重复入池（池满时嵌套提交会死锁）。
Future<R> runInWorker<R>(FutureOr<R> Function() task) {
  if (_inWorkerTask) return Future<R>.sync(task);
  return workerManager.execute(() => _runWorkerTask<R>(task));
}

Future<R> _runWorkerTask<R>(FutureOr<R> Function() task) {
  _inWorkerTask = true;
  return Future<R>.sync(task);
}
