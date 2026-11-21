import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../../l10n/app_localizations.dart';
import 'pixel_art_settings.dart';

/// Shared top-bar status badge used by both Desktop [ClientShell] and Mobile
/// [AppTopBar]. Renders a slow, wavy pixelated Nether-portal shimmer when
/// [broadcasting] is true and pixel effects are enabled.
class PortalStatusBadge extends StatelessWidget {
  const PortalStatusBadge({
    super.key,
    required this.broadcasting,
    this.showWhenIdle = true,
  });

  final ValueListenable<bool> broadcasting;
  final bool showWhenIdle;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: broadcasting,
      builder: (context, live, _) {
        final l = AppLocalizations.of(context)!;
        if (!live) {
          if (!showWhenIdle) return const SizedBox.shrink();
          return DsBadge(
            label: l.pixelStatusReady,
            color: DsColor.textFaint,
            dot: true,
          );
        }
        return ValueListenableBuilder<bool>(
          valueListenable: PixelArtSettings.instance.effectsEnabled,
          builder: (context, effectsOn, _) {
            final reduceMotion =
                MediaQuery.maybeDisableAnimationsOf(context) ?? false;
            if (!effectsOn || reduceMotion) {
              return DsBadge(
                label: l.pixelStatusPortalActive,
                color: const Color(0xFFA882E0),
                dot: true,
              );
            }
            return _PortalActiveBadge(label: l.pixelStatusPortalActive);
          },
        );
      },
    );
  }
}

class _PortalActiveBadge extends StatefulWidget {
  const _PortalActiveBadge({required this.label});

  final String label;

  @override
  State<_PortalActiveBadge> createState() => _PortalActiveBadgeState();
}

class _PortalActiveBadgeState extends State<_PortalActiveBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const portalAccent = Color(0xFFA882E0);
    const portalText = Color(0xFFB896EC);
    const portalGlowDot = Color(0xFFD6BAFF);

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (_, _) {
          final phase = _controller.value * math.pi * 2;
          final breath = 0.5 + 0.5 * math.sin(phase);
          final dotColor = Color.lerp(portalAccent, portalGlowDot, breath * 0.65)!;

          return PixelFrame(
            notch: 2.0,
            fillColor: const Color(0xFF191328),
            borderColor: portalAccent.withValues(alpha: 0.36 + breath * 0.20),
            bottomLipHeight: 1.0,
            bottomLipColor: const Color(0xFF0E091A).withValues(alpha: 0.55),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(1.0),
                    child: CustomPaint(
                      painter: _NetherPortalWavePainter(phase: phase),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DsSpace.sm + 2,
                    vertical: DsSpace.xs,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 5, height: 5, color: dotColor),
                      const SizedBox(width: DsSpace.sm - 2),
                      Text(
                        widget.label,
                        style: const TextStyle(
                          fontFamily: 'JetBrainsMono',
                          color: portalText,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          shadows: [
                            Shadow(
                              color: Color(0x990B0714),
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _NetherPortalWavePainter extends CustomPainter {
  const _NetherPortalWavePainter({required this.phase});

  final double phase;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    const cell = 3.0;
    final cols = (size.width / cell).ceil();
    final rows = (size.height / cell).ceil();

    final deepPaint = Paint()
      ..isAntiAlias = false
      ..color = const Color(0xFF56289E).withValues(alpha: 0.14);
    final midPaint = Paint()
      ..isAntiAlias = false
      ..color = const Color(0xFF8C52E8).withValues(alpha: 0.17);
    final crestPaint = Paint()
      ..isAntiAlias = false
      ..color = const Color(0xFFC29BFF).withValues(alpha: 0.19);

    for (var gy = 0; gy < rows; gy++) {
      final y = gy * cell;
      for (var gx = 0; gx < cols; gx++) {
        final w1 = math.sin(gx * 0.44 - phase + gy * 0.28);
        final w2 = math.cos(gy * 0.82 - gx * 0.22 + phase);
        final wave = w1 * 0.56 + w2 * 0.44;

        final Paint? p;
        if (wave > 0.58) {
          p = crestPaint;
        } else if (wave > 0.20) {
          p = midPaint;
        } else if (wave > -0.18) {
          p = deepPaint;
        } else {
          p = null;
        }

        if (p != null) {
          canvas.drawRect(Rect.fromLTWH(gx * cell, y, cell, cell), p);
        }
      }
    }

    final t = phase / (math.pi * 2);
    final motePaint = Paint()..isAntiAlias = false;
    for (var i = 0; i < 3; i++) {
      final u = (t + i * 0.34) % 1.0;
      final mx = ((u * size.width) / 2.0).floor() * 2.0;
      final myBase = size.height * (0.24 + i * 0.26);
      final myOffset = math.sin(phase + i * 2.1) * 2.2;
      final my = ((myBase + myOffset) / 2.0).floor() * 2.0;
      final moteAlpha = (math.sin(u * math.pi) * 0.30).clamp(0.0, 0.30);
      if (moteAlpha > 0.02) {
        motePaint.color = const Color(0xFFD8BEFF).withValues(alpha: moteAlpha);
        canvas.drawRect(Rect.fromLTWH(mx, my, 2, 2), motePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NetherPortalWavePainter oldDelegate) =>
      oldDelegate.phase != phase;
}
