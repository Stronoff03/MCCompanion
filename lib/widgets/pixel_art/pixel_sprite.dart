import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'pixel_sprite_cache.dart';

/// Renders a crisp, nearest-neighbor (`FilterQuality.none`) animated sprite
/// from a horizontal PNG sprite sheet.
class PixelSpriteAnimation extends StatefulWidget {
  const PixelSpriteAnimation({
    super.key,
    required this.spec,
    this.scale = 2.0,
    this.width,
    this.height,
    this.playing = true,
    this.loop = true,
    this.flipHorizontal = false,
    this.fixedFrame,
    this.opacity = 1.0,
    this.speedMultiplier = 1.0,
  });

  final PixelSpriteSheetSpec spec;
  final double scale;
  final double? width;
  final double? height;
  final bool playing;
  final bool loop;
  final bool flipHorizontal;

  /// When non-null, renders only this 0-based frame index without ticking.
  final int? fixedFrame;
  final double opacity;
  final double speedMultiplier;

  @override
  State<PixelSpriteAnimation> createState() => _PixelSpriteAnimationState();
}

class _PixelSpriteAnimationState extends State<PixelSpriteAnimation>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  ui.Image? _image;

  Duration get _totalDuration {
    final totalMs =
        widget.spec.frameDuration.inMilliseconds * widget.spec.frameCount;
    final adjustedMs = (totalMs / widget.speedMultiplier).round().clamp(16, 60000);
    return Duration(milliseconds: adjustedMs);
  }

  @override
  void initState() {
    super.initState();
    _loadImage();
    _syncController();
  }

  @override
  void didUpdateWidget(covariant PixelSpriteAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.spec.assetPath != widget.spec.assetPath) {
      _loadImage();
    }
    if (oldWidget.spec != widget.spec ||
        oldWidget.playing != widget.playing ||
        oldWidget.loop != widget.loop ||
        oldWidget.fixedFrame != widget.fixedFrame ||
        oldWidget.speedMultiplier != widget.speedMultiplier) {
      _syncController();
    }
  }

  void _loadImage() {
    final cached = PixelSpriteCache.instance.getCached(widget.spec.assetPath);
    if (cached != null) {
      _image = cached;
      return;
    }
    PixelSpriteCache.instance.load(widget.spec.assetPath).then((image) {
      if (!mounted) return;
      if (widget.spec.assetPath == widget.spec.assetPath) {
        setState(() => _image = image);
      }
    });
  }

  void _syncController() {
    final shouldAnimate =
        widget.playing && widget.fixedFrame == null && widget.spec.frameCount > 1;
    if (!shouldAnimate) {
      _controller?.stop();
      return;
    }
    final controller = _controller ??= AnimationController(
      vsync: this,
      duration: _totalDuration,
    );
    controller.duration = _totalDuration;
    if (!controller.isAnimating) {
      if (widget.loop) {
        controller.repeat();
      } else {
        controller.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width ?? widget.spec.frameWidth * widget.scale;
    final h = widget.height ?? widget.spec.frameHeight * widget.scale;
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    final image = _image;
    if (image == null) {
      return SizedBox(width: w, height: h);
    }

    final controller = _controller;
    if (controller == null || widget.fixedFrame != null || disableAnimations) {
      final frameIdx =
          (widget.fixedFrame ?? 0).clamp(0, widget.spec.frameCount - 1);
      return RepaintBoundary(
        child: CustomPaint(
          size: Size(w, h),
          painter: _PixelSpritePainter(
            image: image,
            spec: widget.spec,
            frameIndex: frameIdx,
            flipHorizontal: widget.flipHorizontal,
            opacity: widget.opacity,
          ),
        ),
      );
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          final frameIdx = (controller.value * widget.spec.frameCount)
              .floor()
              .clamp(0, widget.spec.frameCount - 1);
          return CustomPaint(
            size: Size(w, h),
            painter: _PixelSpritePainter(
              image: image,
              spec: widget.spec,
              frameIndex: frameIdx,
              flipHorizontal: widget.flipHorizontal,
              opacity: widget.opacity,
            ),
          );
        },
      ),
    );
  }
}

class _PixelSpritePainter extends CustomPainter {
  const _PixelSpritePainter({
    required this.image,
    required this.spec,
    required this.frameIndex,
    required this.flipHorizontal,
    required this.opacity,
  });

  final ui.Image image;
  final PixelSpriteSheetSpec spec;
  final int frameIndex;
  final bool flipHorizontal;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;

    final src = Rect.fromLTWH(
      (frameIndex * spec.frameWidth).toDouble(),
      0,
      spec.frameWidth.toDouble(),
      spec.frameHeight.toDouble(),
    );
    final dst = Offset.zero & size;

    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;

    if (opacity < 1.0) {
      paint.color = Color.fromRGBO(255, 255, 255, opacity.clamp(0.0, 1.0));
    }

    if (flipHorizontal) {
      canvas.save();
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
      canvas.drawImageRect(image, src, dst, paint);
      canvas.restore();
    } else {
      canvas.drawImageRect(image, src, dst, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PixelSpritePainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.frameIndex != frameIndex ||
        oldDelegate.flipHorizontal != flipHorizontal ||
        oldDelegate.opacity != opacity ||
        oldDelegate.spec != spec;
  }
}
