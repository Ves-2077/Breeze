import 'package:zephyr/model/comic_info_meta.dart';
import 'package:zephyr/object_box/model.dart';
import 'package:zephyr/widgets/comic_entry/models/models.dart';

/// 追更列表展示层纯函数：无 Flutter 依赖，方便单测。
UnifiedComicCover resolveFollowCover(ComicFollow follow) {
  final cover = follow.cover;
  return UnifiedComicCover(
    id: cover.id.trim().isEmpty ? follow.comicId : cover.id,
    url: cover.url,
    path: cover.path,
    extern: cover.extern,
  );
}

/// 解析创建者（作者）名称，缺失返回 null。
String? parseFollowCreatorName(Creator creator) {
  final name = creator.name.trim();
  return name.isEmpty ? null : name;
}

/// 短检测时间：当天只显示时分，同年省略年份（去掉秒，列表更干净）。
String formatFollowCheckTime(DateTime time, {DateTime? now}) {
  final local = time.toLocal();
  final current = (now ?? DateTime.now()).toLocal();
  final hm =
      '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
  final sameDay =
      local.year == current.year &&
      local.month == current.month &&
      local.day == current.day;
  if (sameDay) {
    return hm;
  }
  if (local.year == current.year) {
    return '${local.month}-${local.day} $hm';
  }
  return '${local.year}-${local.month}-${local.day} $hm';
}

/// 阅读进度 0..1，数据缺失或越界时钳制。
double followReadProgress({
  required int readOrder,
  required int detectedTotal,
}) {
  if (readOrder <= 0 || detectedTotal <= 0) {
    return 0;
  }
  return (readOrder / detectedTotal).clamp(0.0, 1.0).toDouble();
}
