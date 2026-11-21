import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'pixel_art_settings.dart';
import 'pixel_particle_overlay.dart';
import 'pixel_sprite_cache.dart';

class _PollenMote {
  _PollenMote({
    required this.x,
    required this.y,
    required this.vy,
    required this.maxAge,
    required this.color,
  });

  double x;
  double y;
  final double vy;
  final double maxAge;
  final Color color;
  double age = 0;
}

class _BeeAgent {
  _BeeAgent({
    required this.x,
    required this.y,
    required this.targetX,
    required this.targetY,
    required this.drawSize,
    required this.baseSpeed,
    required this.bobPhase,
    required this.animTime,
  });

  double x;
  double y;
  double vx = 0;
  double vy = 0;
  double targetX;
  double targetY;
  final double drawSize;
  final double baseSpeed;
  double bobPhase;
  double animTime;
  bool facingRight = true;
  double hoverRestTimer = 0;
  double excitedTimer = 0;
  double pollenCooldown = 1.6;
}

/// Non-intrusive, interactive ambient Minecraft bee layer for desktop screens.
///
/// Wraps [child] with a translucent pointer listener (never blocking clicks)
/// and paints 1–2 crisp `FilterQuality.none` bees that lazily roam open areas,
/// shy away from the cursor so they never obstruct buttons, and burst cute
/// pixel hearts when booped.
class AmbientMinecraftBeesHost extends StatefulWidget {
  const AmbientMinecraftBeesHost({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AmbientMinecraftBeesHost> createState() =>
      _AmbientMinecraftBeesHostState();
}

class _AmbientMinecraftBeesHostState extends State<AmbientMinecraftBeesHost>
    with SingleTickerProviderStateMixin {
  final math.Random _rng = math.Random();
  final List<_BeeAgent> _bees = <_BeeAgent>[];
  final List<_PollenMote> _pollen = <_PollenMote>[];
  final ValueNotifier<int> _paintTick = ValueNotifier<int>(0);

  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  Size _bounds = Size.zero;
  Offset? _cursorLocal;
  ui.Image? _beeSheet;
  bool _disableSystemAnimations = false;

  bool get _enabled =>
      PixelArtSettings.instance.effectsEnabled.value &&
      PixelArtSettings.instance.ambientBeesEnabled.value;

  @override
  void initState() {
    super.initState();
    _beeSheet = PixelSpriteCache.instance.getCached(
      PixelArtAssets.mcBee.assetPath,
    );
    if (_beeSheet == null) {
      PixelSpriteCache.instance.load(PixelArtAssets.mcBee.assetPath).then((img) {
        if (!mounted) return;
        _beeSheet = img;
        _paintTick.value++;
      });
    }

    _ticker = createTicker(_onTick);
    PixelArtSettings.instance.effectsEnabled.addListener(_syncRunning);
    PixelArtSettings.instance.ambientBeesEnabled.addListener(_syncRunning);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _disableSystemAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _syncRunning(rebuild: false);
  }

  @override
  void dispose() {
    PixelArtSettings.instance.effectsEnabled.removeListener(_syncRunning);
    PixelArtSettings.instance.ambientBeesEnabled.removeListener(_syncRunning);
    _ticker.dispose();
    _paintTick.dispose();
    super.dispose();
  }

  void _syncRunning({bool rebuild = true}) {
    if (!mounted) return;
    final shouldRun = _enabled && !_disableSystemAnimations;
    if (shouldRun && !_ticker.isActive) {
      _lastElapsed = Duration.zero;
      _ticker.start();
    } else if (!shouldRun && _ticker.isActive) {
      _ticker.stop();
    }
    if (rebuild && mounted) setState(() {});
  }

  void _ensureBeesInitialized(Size size) {
    if (size.width < 220 || size.height < 180) return;
    // Keep a single calm bee so ambient motion stays peaceful and unobtrusive.
    const desiredCount = 1;

    if (_bees.length == desiredCount) return;
    if (_bees.length > desiredCount) {
      _bees.removeRange(desiredCount, _bees.length);
      return;
    }

    while (_bees.length < desiredCount) {
      final startX = size.width * 0.72;
      final startY = size.height * 0.76;
      final target = _pickRoamTarget(size);
      _bees.add(
        _BeeAgent(
          x: startX.clamp(120, math.max(120, size.width - 48)),
          y: startY.clamp(48, math.max(48, size.height - 56)),
          targetX: target.dx,
          targetY: target.dy,
          drawSize: 40,
          baseSpeed: 26,
          bobPhase: _rng.nextDouble() * math.pi * 2,
          animTime: _rng.nextDouble() * 0.48,
        ),
      );
    }
  }

  Offset _pickRoamTarget(Size size) {
    // Prefer open lower & right night-horizon areas away from the reading area.
    final minX = math.min(size.width * 0.30, 260.0);
    final maxX = math.max(minX + 40, size.width - 54);
    final minY = math.max(56.0, size.height * 0.56);
    final maxY = math.max(minY + 30, size.height - 56);

    return Offset(
      minX + _rng.nextDouble() * (maxX - minX),
      minY + _rng.nextDouble() * (maxY - minY),
    );
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!_enabled || _bees.isEmpty) return;
    final local = event.localPosition;
    for (final bee in _bees) {
      final dx = local.dx - bee.x;
      final dy = local.dy - bee.y;
      final hitRadius = bee.drawSize * 0.72;
      if (dx * dx + dy * dy <= hitRadius * hitRadius) {
        bee.excitedTimer = 1.6;
        bee.hoverRestTimer = 0;
        bee.vy = -75;
        bee.vx = (dx >= 0 ? -1 : 1) * 85;
        final next = _pickRoamTarget(_bounds);
        bee.targetX = next.dx;
        bee.targetY = next.dy;

        PixelParticleOverlay.burst(
          context,
          event.position,
          preset: PixelParticlePreset.beeLove,
          count: 5,
        );
        break;
      }
    }
  }

  void _onTick(Duration elapsed) {
    final dt = _lastElapsed == Duration.zero
        ? 1 / 60
        : ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;

    if (_bounds.width < 220 || _bounds.height < 180) return;
    _ensureBeesInitialized(_bounds);

    final cursor = _cursorLocal;
    for (final bee in _bees) {
      bee.bobPhase += dt * (bee.excitedTimer > 0 ? 7.5 : 3.2);
      final wingSpeed = bee.excitedTimer > 0 ? 1.85 : 1.0;
      bee.animTime += dt * wingSpeed;
      if (bee.excitedTimer > 0) {
        bee.excitedTimer = math.max(0, bee.excitedTimer - dt);
      }

      // Passive cursor awareness: gently dodge out of the user's click area.
      var dodging = false;
      if (cursor != null) {
        final dx = bee.x - cursor.dx;
        final dy = bee.y - cursor.dy;
        final distSq = dx * dx + dy * dy;
        if (distSq < 74 * 74 && distSq > 1) {
          dodging = true;
          bee.hoverRestTimer = 0;
          bee.excitedTimer = math.max(bee.excitedTimer, 0.45);
          final dist = math.sqrt(distSq);
          final push = (1.0 - dist / 74.0) * 145.0;
          bee.vx += (dx / dist) * push * dt * 4.0;
          bee.vy += (dy / dist) * push * dt * 4.0;
        } else if (distSq < 130 * 130 && bee.hoverRestTimer > 0) {
          // Curious glance toward the user's cursor while resting.
          bee.facingRight = cursor.dx >= bee.x;
        }
      }

      if (!dodging) {
        if (bee.hoverRestTimer > 0) {
          bee.hoverRestTimer -= dt;
          bee.vx *= math.pow(0.08, dt).toDouble();
          bee.vy *= math.pow(0.08, dt).toDouble();
          if (bee.hoverRestTimer <= 0) {
            final next = _pickRoamTarget(_bounds);
            bee.targetX = next.dx;
            bee.targetY = next.dy;
          }
        } else {
          final dx = bee.targetX - bee.x;
          final dy = bee.targetY - bee.y;
          final dist = math.sqrt(dx * dx + dy * dy);
          if (dist < 22) {
            bee.hoverRestTimer = 1.8 + _rng.nextDouble() * 2.4;
          } else {
            final desiredSpeed =
                bee.baseSpeed * (bee.excitedTimer > 0 ? 1.6 : 1.0);
            final desiredVx = (dx / dist) * desiredSpeed;
            final desiredVy = (dy / dist) * desiredSpeed;
            final steer = (dt * 2.4).clamp(0.0, 1.0);
            bee.vx += (desiredVx - bee.vx) * steer;
            bee.vy += (desiredVy - bee.vy) * steer;
          }
        }
      }

      // Speed cap + soft wall padding.
      final speed = math.sqrt(bee.vx * bee.vx + bee.vy * bee.vy);
      final maxSpeed = bee.excitedTimer > 0 ? 140.0 : 68.0;
      if (speed > maxSpeed) {
        bee.vx = (bee.vx / speed) * maxSpeed;
        bee.vy = (bee.vy / speed) * maxSpeed;
      }

      bee.x += bee.vx * dt;
      bee.y += bee.vy * dt;

      const pad = 34.0;
      if (bee.x < pad) {
        bee.x = pad;
        bee.vx = bee.vx.abs() * 0.7;
      } else if (bee.x > _bounds.width - pad) {
        bee.x = _bounds.width - pad;
        bee.vx = -bee.vx.abs() * 0.7;
      }
      if (bee.y < pad) {
        bee.y = pad;
        bee.vy = bee.vy.abs() * 0.7;
      } else if (bee.y > _bounds.height - pad) {
        bee.y = _bounds.height - pad;
        bee.vy = -bee.vy.abs() * 0.7;
      }

      if (bee.vx.abs() > 4.0) {
        bee.facingRight = bee.vx > 0;
      }

      // Drop an occasional tiny golden pollen pixel behind the bee.
      bee.pollenCooldown -= dt;
      if (bee.pollenCooldown <= 0 && speed > 10) {
        bee.pollenCooldown = 1.2 + _rng.nextDouble() * 1.4;
        final tailOffsetX = bee.facingRight ? -bee.drawSize * 0.34 : bee.drawSize * 0.34;
        _pollen.add(
          _PollenMote(
            x: bee.x + tailOffsetX,
            y: bee.y + 4 + (_rng.nextDouble() - 0.5) * 6,
            vy: 10 + _rng.nextDouble() * 10,
            maxAge: 0.9 + _rng.nextDouble() * 0.5,
            color: _rng.nextBool()
                ? const Color(0xFFFFF394)
                : const Color(0xFFFFD23F),
          ),
        );
      }
    }

    for (var i = _pollen.length - 1; i >= 0; i--) {
      final m = _pollen[i];
      m.age += dt;
      if (m.age >= m.maxAge) {
        _pollen.removeAt(i);
        continue;
      }
      m.y += m.vy * dt;
    }

    _paintTick.value++;
  }

  @override
  Widget build(BuildContext context) {
    final disableSystem = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (!_enabled || disableSystem) {
      return widget.child;
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerHover: (e) => _cursorLocal = e.localPosition,
      onPointerMove: (e) => _cursorLocal = e.localPosition,
      onPointerDown: _onPointerDown,
      child: MouseRegion(
        opaque: false,
        onExit: (_) => _cursorLocal = null,
        child: LayoutBuilder(
          builder: (context, constraints) {
            _bounds = Size(constraints.maxWidth, constraints.maxHeight);
            _ensureBeesInitialized(_bounds);
            return Stack(
              fit: StackFit.expand,
              children: [
                widget.child,
                Positioned.fill(
                  child: IgnorePointer(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _AmbientBeesPainter(
                          repaint: _paintTick,
                          beeSheet: _beeSheet,
                          bees: _bees,
                          pollen: _pollen,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AmbientBeesPainter extends CustomPainter {
  _AmbientBeesPainter({
    required super.repaint,
    required this.beeSheet,
    required this.bees,
    required this.pollen,
  });

  final ui.Image? beeSheet;
  final List<_BeeAgent> bees;
  final List<_PollenMote> pollen;

  @override
  void paint(Canvas canvas, Size size) {
    // Draw tiny crisp square pollen motes first.
    for (final m in pollen) {
      final t = (m.age / m.maxAge).clamp(0.0, 1.0);
      final alpha = (1.0 - t) * 0.8;
      if (alpha <= 0.02) continue;
      final paint = Paint()
        ..color = m.color.withValues(alpha: alpha)
        ..isAntiAlias = false;
      canvas.drawRect(
        Rect.fromLTWH(m.x.roundToDouble(), m.y.roundToDouble(), 3, 3),
        paint,
      );
    }

    final sheet = beeSheet;
    if (sheet == null || bees.isEmpty) return;

    const frameW = 32.0;
    const frameH = 32.0;
    const frameCount = 6;
    const frameSeconds = 0.08;

    final spritePaint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false
      ..color = const Color.fromRGBO(255, 255, 255, 0.94);

    for (final bee in bees) {
      final frameIdx = (bee.animTime / frameSeconds).floor() % frameCount;
      final bobY = math.sin(bee.bobPhase) * 4.0;
      final drawX = bee.x.roundToDouble();
      final drawY = (bee.y + bobY).roundToDouble();

      // Subtle soft shadow underneath for floating depth.
      final shadowPaint = Paint()
        ..color = const Color.fromRGBO(4, 10, 13, 0.24)
        ..isAntiAlias = false;
      final shadowW = bee.drawSize * 0.44;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(drawX, drawY + bee.drawSize * 0.46),
          width: shadowW,
          height: 5,
        ),
        shadowPaint,
      );

      final src = Rect.fromLTWH(frameIdx * frameW, 0, frameW, frameH);
      final dst = Rect.fromCenter(
        center: Offset.zero,
        width: bee.drawSize,
        height: bee.drawSize,
      );

      canvas.save();
      canvas.translate(drawX, drawY);
      if (!bee.facingRight) {
        canvas.scale(-1, 1);
      }
      canvas.drawImageRect(sheet, src, dst, spritePaint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientBeesPainter oldDelegate) =>
      oldDelegate.beeSheet != beeSheet;
}
