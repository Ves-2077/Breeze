import 'dart:async';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zephyr/config/global/global_setting.dart';
import 'package:zephyr/cubit/comic_read_preference_cubit.dart';
import 'package:zephyr/main.dart';
import 'package:zephyr/page/comic_read/cubit/image_size_cubit.dart';
import 'package:zephyr/page/comic_read/cubit/reader_cubit.dart';
import 'package:zephyr/page/comic_read/method/image_header_size.dart';

class ImageDisplay extends StatefulWidget {
  final String imagePath;
  final bool isColumn;
  final int pageSlotIndex;
  final int sizeCacheIndex;
  final Alignment imageAlignment;

  const ImageDisplay({
    super.key,
    required this.imagePath,
    required this.isColumn,
    required this.pageSlotIndex,
    required this.sizeCacheIndex,
    this.imageAlignment = Alignment.center,
  });

  @override
  State<ImageDisplay> createState() => _ImageDisplayState();
}

class _ImageDisplayState extends State<ImageDisplay> {
  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;
  Timer? _einkDelayTimer;

  /// 图片宽高比（height / width）。null 表示尚未解析出来。
  double? _aspectRatio;
  bool _einkDelayFinished = true;
  bool _wasRowActive = false;

  bool get isColumn => widget.isColumn;

  @override
  void initState() {
    super.initState();
    _resolveImageMeta();
    _startEinkDelayIfNeeded(context.readEffectiveReadSetting());
  }

  @override
  void didUpdateWidget(covariant ImageDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.imagePath != oldWidget.imagePath) {
      _stopListening();
      _aspectRatio = null;
      _resolveImageMeta();
    }

    if (widget.isColumn) {
      _einkDelayTimer?.cancel();
      _einkDelayFinished = true;
      _wasRowActive = false;
      return;
    }

    _startEinkDelayIfNeeded(context.readEffectiveReadSetting());
  }

  void _startEinkDelayIfNeeded(ReadSettingState readSetting) {
    if (isColumn) {
      _einkDelayTimer?.cancel();
      _einkDelayFinished = true;
      return;
    }

    if (!readSetting.einkOptimization) {
      _einkDelayTimer?.cancel();
      _einkDelayFinished = true;
      return;
    }

    _einkDelayTimer?.cancel();
    _einkDelayFinished = false;
    final delayMs = readSetting.einkDelayMs.clamp(50, 500);
    _einkDelayTimer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted) return;
      setState(() {
        _einkDelayFinished = true;
      });
    });
  }

  /// 解析图片宽高比。
  ///
  /// 优先只读文件头拿宽高（不解码），只有文件头解析失败时才退回整图解码探测，
  /// 避免为了拿一个宽高比把整张大图解码进 ImageCache。
  void _resolveImageMeta() {
    unawaited(_resolveAspectRatioFromHeader());
  }

  Future<void> _resolveAspectRatioFromHeader() async {
    final path = widget.imagePath;
    final Size? headerSize = await readImageHeaderSize(path);
    if (!mounted || path != widget.imagePath) return;

    if (headerSize != null && headerSize.width > 0 && headerSize.height > 0) {
      _aspectRatio = headerSize.height / headerSize.width;
      _reportSizeToCubit();
      return;
    }

    _resolveAspectRatioByDecoding();
  }

  void _resolveAspectRatioByDecoding() {
    final imageProvider = FileImage(File(widget.imagePath));
    final newStream = imageProvider.resolve(ImageConfiguration.empty);

    final newListener = ImageStreamListener(
      (ImageInfo imageInfo, bool synchronousCall) {
        if (!mounted) return;

        final int width = imageInfo.image.width;
        final int height = imageInfo.image.height;
        if (width <= 0 || height <= 0) return;

        _aspectRatio = height / width;
        _reportSizeToCubit();
      },
      onError: (exception, stackTrace) {
        logger.e('Failed to resolve image size: $exception');
      },
    );

    _imageStream = newStream;
    _imageListener = newListener;
    newStream.addListener(newListener);
  }

  void _reportSizeToCubit() {
    if (!mounted) return;
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      _updateCubitSize(renderBox.size.width);
      return;
    }
    // 首次布局还没完成，等这一帧结束后再上报。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        _updateCubitSize(box.size.width);
      }
    });
  }

  void _updateCubitSize(double actualWidth) {
    final ratio = _aspectRatio;
    if (ratio == null || actualWidth <= 0) return;

    final index = widget.sizeCacheIndex;
    final cubit = context.read<ImageSizeCubit>();

    final double finalHeight = ratio * actualWidth;

    final currentCachedSize = cubit.getSize(index);

    if (!currentCachedSize.isCached ||
        (currentCachedSize.size.height - finalHeight).abs() > 0.05 ||
        (currentCachedSize.size.width - actualWidth).abs() > 0.05) {
      cubit.updateSize(index, Size(actualWidth, finalHeight));
    }
  }

  void _stopListening() {
    if (_imageStream != null && _imageListener != null) {
      _imageStream!.removeListener(_imageListener!);
    }
    _imageStream = null;
    _imageListener = null;
  }

  @override
  void dispose() {
    _stopListening();
    _einkDelayTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final readSetting = context.watchEffectiveReadSetting();
    final showStaticPlaceholder = context.select(
      (GlobalSettingCubit c) => c.state.eInkSetting.shouldRemoveLoadingSpinner,
    );
    final brightness = Theme.of(context).brightness;
    final backgroundColor = readSetting.resolveReaderBackgroundColor(
      brightness,
    );
    final foregroundColor = readSetting.resolveReaderForegroundColor(
      brightness,
    );
    final progressColor = foregroundColor.withValues(alpha: 0.3);
    final readMode = context.watchEffectiveReadMode();
    final currentPageIndex = context.select(
      (ReaderCubit c) => c.state.currentSlot,
    );
    final canUseEinkMask =
        !isColumn && readMode != 0 && readSetting.einkOptimization;
    final isActiveRowImage =
        !isColumn && currentPageIndex == widget.pageSlotIndex;

    if (canUseEinkMask && isActiveRowImage && !_wasRowActive) {
      _wasRowActive = true;
      _startEinkDelayIfNeeded(readSetting);
    } else if (!isActiveRowImage && _wasRowActive) {
      _wasRowActive = false;
    }

    if (!canUseEinkMask && !_einkDelayFinished) {
      _einkDelayTimer?.cancel();
      _einkDelayFinished = true;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // cacheWidth 的单位是物理像素；这里手动乘 devicePixelRatio，
        // 等价于 Flutter 3.50 的 useLogicalCacheSize（OHOS fork 3.47 没有该参数）。
        // 条漫模式不做重采样解码：按显示宽缩放后的位图高是独立取整的整数像素，
        // 与槽位高度（宽高比 × 显示宽）对不齐，图片在槽位内居中后会在接缝处
        // 露出一条背景色的抗锯齿细线。按原图尺寸解码时两者同源同值，可无缝拼接。
        final decodeWidth = !isColumn && width.isFinite && width >= 1
            ? (width * MediaQuery.devicePixelRatioOf(context)).ceil()
            : null;

        if (_aspectRatio != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _updateCubitSize(width);
          });
        }

        Widget loadingPlaceholder() {
          if (showStaticPlaceholder) {
            return Container(width: width, color: backgroundColor);
          }
          return Container(
            width: width,
            color: backgroundColor,
            alignment: Alignment.center,
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: progressColor,
              ),
            ),
          );
        }

        final image = Image.file(
          File(widget.imagePath),
          width: width,
          // 条漫模式把图片高度钉死为宽高比 × 显示宽，与槽位高度同源计算，
          // 再向下多画 1px 盖住接缝（见下方 OverflowBox 说明）。
          height:
              isColumn &&
                  _aspectRatio != null &&
                  width.isFinite &&
                  width >= 1
              ? width * _aspectRatio! + 1
              : null,
          // 按屏幕物理像素解码，避免高 DPI 设备上按逻辑宽度解码后放大发虚；
          // ResizeImage 默认 allowUpscaling=false，小图不会被放大，超大扫描图
          // 也只解码到屏幕像素宽度，不会整张原图进 ImageCache。
          cacheWidth: decodeWidth,
          fit: isColumn ? BoxFit.fill : BoxFit.contain,
          alignment: widget.imageAlignment,
          gaplessPlayback: true,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) {
              if (!isColumn &&
                  canUseEinkMask &&
                  isActiveRowImage &&
                  !_einkDelayFinished) {
                return Container(width: width, color: Colors.white);
              }
              return child;
            }

            if (canUseEinkMask && isActiveRowImage && !_einkDelayFinished) {
              return Container(width: width, color: Colors.white);
            }
            return loadingPlaceholder();
          },
        );

        if (isColumn &&
            _aspectRatio != null &&
            width.isFinite &&
            width >= 1) {
          // 条漫无缝：槽位高度不变，图片向下多画 1px 盖住接缝行。
          // OverflowBox 允许图片画出槽位下边缘，下一张上沿随后盖住这 1px，
          // 接缝两侧都是图片内容，背景无从露出。
          return OverflowBox(
            alignment: Alignment.topCenter,
            minWidth: 0,
            maxWidth: double.infinity,
            minHeight: 0,
            maxHeight: double.infinity,
            child: SizedBox(
              width: width,
              height: width * _aspectRatio! + 1,
              child: image,
            ),
          );
        }

        return Align(alignment: widget.imageAlignment, child: image);
      },
    );
  }
}
