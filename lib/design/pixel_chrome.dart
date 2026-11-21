import 'package:flutter/material.dart';

/// Builds a crisp, 2-step pixel-notched (chamfered) rectangular [Path] so
/// panels, buttons, inputs, and badges have unmistakable block-crafted
/// Minecraft / Hytale silhouette geometry instead of soft rounded pills.
Path buildPixelNotchedPath(Rect rect, double notch) {
  final n = notch.clamp(0.0, rect.shortestSide / 3);
  if (n <= 0.5) {
    return Path()..addRect(rect);
  }
  final l = rect.left;
  final t = rect.top;
  final r = rect.right;
  final b = rect.bottom;
  final half = (n / 2).roundToDouble();

  return Path()
    ..moveTo(l + n, t)
    ..lineTo(r - n, t)
    ..lineTo(r - n, t + half)
    ..lineTo(r - half, t + half)
    ..lineTo(r - half, t + n)
    ..lineTo(r, t + n)
    ..lineTo(r, b - n)
    ..lineTo(r - half, b - n)
    ..lineTo(r - half, b - half)
    ..lineTo(r - n, b - half)
    ..lineTo(r - n, b)
    ..lineTo(l + n, b)
    ..lineTo(l + n, b - half)
    ..lineTo(l + half, b - half)
    ..lineTo(l + half, b - n)
    ..lineTo(l, b - n)
    ..lineTo(l, t + n)
    ..lineTo(l + half, t + n)
    ..lineTo(l + half, t + half)
    ..lineTo(l + n, t + half)
    ..close();
}

/// A crisp stepped pixel-notched [ShapeBorder] usable with [Material],
/// [ClipPath], [ShapeDecoration], and [InputBorder].
class PixelNotchedBorder extends OutlinedBorder {
  const PixelNotchedBorder({
    this.notch = 4.0,
    super.side = BorderSide.none,
  });

  final double notch;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(side.width);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      buildPixelNotchedPath(rect.deflate(side.width), (notch - side.width).clamp(0, notch));

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) =>
      buildPixelNotchedPath(rect, notch);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    if (side.style == BorderStyle.none || side.width <= 0) return;
    final paint = side.toPaint()..isAntiAlias = false;
    canvas.drawPath(buildPixelNotchedPath(rect.deflate(side.width / 2), notch), paint);
  }

  @override
  ShapeBorder scale(double t) => PixelNotchedBorder(
    notch: notch * t,
    side: side.scale(t),
  );

  @override
  OutlinedBorder copyWith({BorderSide? side, double? notch}) =>
      PixelNotchedBorder(
        notch: notch ?? this.notch,
        side: side ?? this.side,
      );
}

/// Renders a bespoke Hytale / Modern Minecraft carved matte block surface
/// with stepped pixel-notched corners, subtle 1px top specular catchlight,
/// crisp border outline, carved bottom bevel lip, and optional pixel rivets.
class PixelFrame extends StatelessWidget {
  const PixelFrame({
    super.key,
    required this.child,
    required this.fillColor,
    required this.borderColor,
    this.topHighlightColor,
    this.bottomLipColor,
    this.bottomLipHeight = 2.0,
    this.notch = 4.0,
    this.padding,
    this.showRivets = false,
    this.rivetColor,
    this.recessed = false,
    this.enableTexture = false,
    this.gradient,
  });

  final Widget child;
  final Color fillColor;
  final Color borderColor;
  final Color? topHighlightColor;
  final Color? bottomLipColor;
  final double bottomLipHeight;
  final double notch;
  final EdgeInsetsGeometry? padding;
  final bool showRivets;
  final Color? rivetColor;
  final bool recessed;
  final bool enableTexture;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _PixelFramePainter(
        fillColor: fillColor,
        borderColor: borderColor,
        topHighlightColor: topHighlightColor,
        bottomLipColor: bottomLipColor,
        bottomLipHeight: bottomLipHeight,
        notch: notch,
        showRivets: showRivets,
        rivetColor: rivetColor,
        recessed: recessed,
        enableTexture: enableTexture,
        gradient: gradient,
      ),
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: PixelNotchedBorder(notch: notch)),
        child: padding == null
            ? child
            : Padding(padding: padding!, child: child),
      ),
    );
  }
}

class _PixelFramePainter extends CustomPainter {
  const _PixelFramePainter({
    required this.fillColor,
    required this.borderColor,
    required this.topHighlightColor,
    required this.bottomLipColor,
    required this.bottomLipHeight,
    required this.notch,
    required this.showRivets,
    required this.rivetColor,
    required this.recessed,
    required this.enableTexture,
    required this.gradient,
  });

  final Color fillColor;
  final Color borderColor;
  final Color? topHighlightColor;
  final Color? bottomLipColor;
  final double bottomLipHeight;
  final double notch;
  final bool showRivets;
  final Color? rivetColor;
  final bool recessed;
  final bool enableTexture;
  final Gradient? gradient;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 2 || size.height <= 2) return;
    final rect = Offset.zero & size;
    final path = buildPixelNotchedPath(rect, notch);

    // 1. Matte block fill (optional subtle gradient)
    final fillPaint = Paint()..isAntiAlias = false;
    if (gradient != null) {
      fillPaint.shader = gradient!.createShader(rect);
    } else {
      fillPaint.color = fillColor;
    }
    canvas.drawPath(path, fillPaint);

    canvas.save();
    canvas.clipPath(path);

    // 1b. Ultra-subtle procedural deepslate stone pixel grain (zero glare)
    if (enableTexture && size.width >= 48 && size.height >= 48) {
      const tile = 24.0;
      final lightGrain = Paint()
        ..color = Colors.white.withValues(alpha: 0.024)
        ..isAntiAlias = false;
      final darkGrain = Paint()
        ..color = Colors.black.withValues(alpha: 0.055)
        ..isAntiAlias = false;
      for (double y = 4; y < size.height - 4; y += tile) {
        final row = (y / tile).floor();
        for (double x = 4; x < size.width - 4; x += tile) {
          final col = (x / tile).floor();
          final h = (row * 31 + col * 17) % 11;
          if (h == 0 || h == 4) {
            canvas.drawRect(Rect.fromLTWH(x, y, 4, 4), lightGrain);
          } else if (h == 2 || h == 7) {
            canvas.drawRect(Rect.fromLTWH(x + 8, y + 4, 4, 4), darkGrain);
          } else if (h == 5) {
            canvas.drawRect(Rect.fromLTWH(x + 4, y + 12, 8, 4), darkGrain);
          }
        }
      }
    }

    // 2. Inner bevel catchlight & carved lip
    if (recessed) {
      // Recessed slot: dark top inner shadow, faint lower catchlight
      final topShadow = Paint()
        ..color = Colors.black.withValues(alpha: 0.42)
        ..isAntiAlias = false;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 2), topShadow);
      final bottomRim = Paint()
        ..color = Colors.white.withValues(alpha: 0.05)
        ..isAntiAlias = false;
      canvas.drawRect(
        Rect.fromLTWH(0, size.height - 1, size.width, 1),
        bottomRim,
      );
    } else {
      if (topHighlightColor != null) {
        final topPaint = Paint()
          ..color = topHighlightColor!
          ..isAntiAlias = false;
        canvas.drawRect(Rect.fromLTWH(notch, 1, size.width - notch * 2, 1.5), topPaint);
      }
      if (bottomLipColor != null && bottomLipHeight > 0) {
        final lipPaint = Paint()
          ..color = bottomLipColor!
          ..isAntiAlias = false;
        canvas.drawRect(
          Rect.fromLTWH(
            0,
            size.height - bottomLipHeight,
            size.width,
            bottomLipHeight,
          ),
          lipPaint,
        );
      }
    }

    // 3. Optional subtle 2x2 pixel corner rivets for hero/crafted panels
    if (showRivets) {
      final rPaint = Paint()
        ..color = rivetColor ?? Colors.white.withValues(alpha: 0.14)
        ..isAntiAlias = false;
      final inset = notch + 4;
      const rSize = 2.0;
      canvas.drawRect(Rect.fromLTWH(inset, inset, rSize, rSize), rPaint);
      canvas.drawRect(
        Rect.fromLTWH(size.width - inset - rSize, inset, rSize, rSize),
        rPaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(inset, size.height - inset - rSize, rSize, rSize),
        rPaint,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          size.width - inset - rSize,
          size.height - inset - rSize,
          rSize,
          rSize,
        ),
        rPaint,
      );
    }

    canvas.restore();

    // 4. Crisp stepped 1px outer pixel border
    final strokePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..isAntiAlias = false;
    canvas.drawPath(buildPixelNotchedPath(rect.deflate(0.5), notch), strokePaint);
  }

  @override
  bool shouldRepaint(covariant _PixelFramePainter old) =>
      old.fillColor != fillColor ||
      old.borderColor != borderColor ||
      old.topHighlightColor != topHighlightColor ||
      old.bottomLipColor != bottomLipColor ||
      old.bottomLipHeight != bottomLipHeight ||
      old.notch != notch ||
      old.showRivets != showRivets ||
      old.rivetColor != rivetColor ||
      old.recessed != recessed ||
      old.enableTexture != enableTexture ||
      old.gradient != gradient;
}
