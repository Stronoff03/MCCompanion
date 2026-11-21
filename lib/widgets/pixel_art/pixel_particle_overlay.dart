import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'pixel_art_settings.dart';
import 'pixel_sprite_cache.dart';

/// Particle presets matching frames in `assets/pixel_art/particles_sheet.png`.
enum PixelParticlePreset {
  /// Mix of grass chunks, dirt chunks, and occasional glowing XP orb.
  grassBlock,

  /// Pure glowing Minecraft XP orbs.
  xpBurst,

  /// Cute pink hearts + occasional XP sparkle (for the ambient bee!).
  beeLove,
}

class _ActiveParticle {
  _ActiveParticle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.gravity,
    required this.scale,
    required this.frameIndex,
    required this.maxAge,
    required this.spinSpeed,
    required this.isRune,
    required this.swayPhase,
  });

  double x;
  double y;
  double vx;
  double vy;
  final double gravity;
  final double scale;
  final int frameIndex;
  final double maxAge;
  final double spinSpeed;
  final bool isRune;
  final double swayPhase;
  double age = 0;
  double rotation = 0;
}

class _ActiveBlockPop {
  _ActiveBlockPop({
    required this.x,
    required this.y,
    required this.vx,
    required this.maxAge,
    required this.targetSize,
  });

  final double x;
  final double y;
  final double vx;
  final double maxAge;
  final double targetSize;
  double age = 0;
}

/// Zero-overhead-when-idle global overlay for crisp Minecraft pixel particle bursts
/// and pop-up isometric block micro-animations.
///
/// Spawns a single non-interactive [OverlayEntry] while effects are alive and
/// automatically removes it once everything settles.
class PixelParticleOverlay {
  PixelParticleOverlay._();

  static final math.Random _rng = math.Random();
  static _PixelBurstLayerState? _activeState;
  static OverlayEntry? _activeEntry;

  /// Triggers a pixel particle burst at [globalPosition] in screen coordinates.
  ///
  /// When [popGrassBlock] is true, an animated 32×32 isometric Minecraft grass
  /// block also springs upward from the click point and sparkles before fading.
  static void burst(
    BuildContext context,
    Offset globalPosition, {
    PixelParticlePreset preset = PixelParticlePreset.grassBlock,
    int count = 8,
    bool popGrassBlock = false,
  }) {
    if (!PixelArtSettings.instance.effectsEnabled.value) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    // Ensure tiny sprite sheets are loaded in cache.
    if (PixelSpriteCache.instance.getCached(PixelArtAssets.particles.assetPath) ==
        null) {
      PixelSpriteCache.instance.load(PixelArtAssets.particles.assetPath);
    }
    if (PixelSpriteCache.instance.getCached(
          PixelArtAssets.enchantRunes.assetPath,
        ) ==
        null) {
      PixelSpriteCache.instance.load(PixelArtAssets.enchantRunes.assetPath);
    }
    if (popGrassBlock &&
        PixelSpriteCache.instance.getCached(
              PixelArtAssets.grassBlock.assetPath,
            ) ==
            null) {
      PixelSpriteCache.instance.load(PixelArtAssets.grassBlock.assetPath);
    }

    if (_activeEntry == null) {
      final key = GlobalKey<_PixelBurstLayerState>();
      _activeEntry = OverlayEntry(
        builder: (_) => Positioned.fill(
          child: _PixelBurstLayer(
            key: key,
            onDrained: _cleanupOverlay,
          ),
        ),
      );
      overlay.insert(_activeEntry!);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _activeState = key.currentState;
        _activeState?.spawn(
          globalPosition,
          preset: preset,
          count: count,
          popGrassBlock: popGrassBlock,
        );
      });
    } else {
      _activeState?.spawn(
        globalPosition,
        preset: preset,
        count: count,
        popGrassBlock: popGrassBlock,
      );
    }
  }

  /// Convenience helper to burst from the center of a widget's [BuildContext].
  static void burstFromContext(
    BuildContext context, {
    PixelParticlePreset preset = PixelParticlePreset.grassBlock,
    int count = 8,
    bool popGrassBlock = false,
  }) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return;
    final center = box.localToGlobal(box.size.center(Offset.zero));
    burst(
      context,
      center,
      preset: preset,
      count: count,
      popGrassBlock: popGrassBlock,
    );
  }

  static void _cleanupOverlay() {
    _activeEntry?.remove();
    _activeEntry = null;
    _activeState = null;
  }

  static (bool isRune, int frame) _pickParticle(PixelParticlePreset preset) {
    switch (preset) {
      case PixelParticlePreset.grassBlock:
        final roll = _rng.nextDouble();
        if (roll < 0.42) return (false, 0); // grass chunk
        if (roll < 0.78) return (false, 1); // dirt chunk
        return (true, _rng.nextInt(PixelArtAssets.enchantRunes.frameCount));
      case PixelParticlePreset.xpBurst:
        // Enchantment Table Galactic Alphabet Runes!
        return (true, _rng.nextInt(PixelArtAssets.enchantRunes.frameCount));
      case PixelParticlePreset.beeLove:
        return _rng.nextDouble() < 0.78
            ? (false, 3)
            : (true, _rng.nextInt(PixelArtAssets.enchantRunes.frameCount));
    }
  }
}

class _PixelBurstLayer extends StatefulWidget {
  const _PixelBurstLayer({super.key, required this.onDrained});

  final VoidCallback onDrained;

  @override
  State<_PixelBurstLayer> createState() => _PixelBurstLayerState();
}

class _PixelBurstLayerState extends State<_PixelBurstLayer>
    with SingleTickerProviderStateMixin {
  final List<_ActiveParticle> _particles = <_ActiveParticle>[];
  final List<_ActiveBlockPop> _blocks = <_ActiveBlockPop>[];
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  ui.Image? _sheet;
  ui.Image? _runeSheet;
  ui.Image? _grassSheet;

  @override
  void initState() {
    super.initState();
    _sheet = PixelSpriteCache.instance.getCached(
      PixelArtAssets.particles.assetPath,
    );
    if (_sheet == null) {
      PixelSpriteCache.instance
          .load(PixelArtAssets.particles.assetPath)
          .then((img) {
        if (mounted) setState(() => _sheet = img);
      });
    }
    _runeSheet = PixelSpriteCache.instance.getCached(
      PixelArtAssets.enchantRunes.assetPath,
    );
    if (_runeSheet == null) {
      PixelSpriteCache.instance
          .load(PixelArtAssets.enchantRunes.assetPath)
          .then((img) {
        if (mounted) setState(() => _runeSheet = img);
      });
    }
    _grassSheet = PixelSpriteCache.instance.getCached(
      PixelArtAssets.grassBlock.assetPath,
    );
    if (_grassSheet == null) {
      PixelSpriteCache.instance
          .load(PixelArtAssets.grassBlock.assetPath)
          .then((img) {
        if (mounted) setState(() => _grassSheet = img);
      });
    }
    _ticker = createTicker(_onTick);
  }

  void spawn(
    Offset globalOrigin, {
    required PixelParticlePreset preset,
    required int count,
    bool popGrassBlock = false,
  }) {
    if (!mounted) return;
    final box = context.findRenderObject();
    final origin = (box is RenderBox && box.hasSize)
        ? box.globalToLocal(globalOrigin)
        : globalOrigin;

    final rng = PixelParticleOverlay._rng;
    final isGentleFloat = preset == PixelParticlePreset.beeLove;

    if (popGrassBlock) {
      _blocks.add(
        _ActiveBlockPop(
          x: origin.dx,
          y: origin.dy - 6,
          vx: (rng.nextDouble() - 0.5) * 18,
          maxAge: 0.62,
          targetSize: 38,
        ),
      );
    }

    final baseAngle = rng.nextDouble() * math.pi * 2;

    for (var i = 0; i < count; i++) {
      final (isRune, frameIndex) = PixelParticleOverlay._pickParticle(preset);
      if (isRune) {
        // Scatter 360° all around the mouse cursor with whisper-gentle outward drift.
        final sector = count > 0 ? (math.pi * 2) / count : math.pi * 2;
        final angle =
            baseAngle + i * sector + (rng.nextDouble() - 0.5) * sector * 0.55;
        final startRadius = 8.0 + rng.nextDouble() * 9.0;
        final speed = 13.0 + rng.nextDouble() * 11.0;

        _particles.add(
          _ActiveParticle(
            x: origin.dx + math.cos(angle) * startRadius,
            y: origin.dy + math.sin(angle) * startRadius,
            vx: math.cos(angle) * speed,
            vy: math.sin(angle) * speed,
            gravity: 0.0,
            scale: rng.nextBool() ? 1.2 : 1.38,
            frameIndex: frameIndex,
            maxAge: 0.74 + rng.nextDouble() * 0.28,
            spinSpeed: 0,
            isRune: true,
            swayPhase: rng.nextDouble() * math.pi * 2,
          ),
        );
        continue;
      }

      final spreadAngle = isGentleFloat
          ? (-math.pi / 2) + (rng.nextDouble() - 0.5) * 1.5
          : (-math.pi / 2) + (rng.nextDouble() - 0.5) * 2.1;
      final speed = isGentleFloat
          ? 40 + rng.nextDouble() * 55
          : 95 + rng.nextDouble() * 145;

      _particles.add(
        _ActiveParticle(
          x: origin.dx + (rng.nextDouble() - 0.5) * 18,
          y: origin.dy + (rng.nextDouble() - 0.5) * 8,
          vx: math.cos(spreadAngle) * speed,
          vy: math.sin(spreadAngle) * speed,
          gravity: isGentleFloat ? 60 : 420,
          scale: rng.nextBool() ? 1.5 : 2.0,
          frameIndex: frameIndex,
          maxAge: isGentleFloat
              ? 0.65 + rng.nextDouble() * 0.35
              : 0.45 + rng.nextDouble() * 0.30,
          spinSpeed: isGentleFloat ? 0 : (rng.nextDouble() - 0.5) * 5.0,
          isRune: false,
          swayPhase: rng.nextDouble() * math.pi * 2,
        ),
      );
    }

    if (!_ticker.isActive) {
      _lastElapsed = Duration.zero;
      _ticker.start();
    }
    setState(() {});
  }

  void _onTick(Duration elapsed) {
    final dt = _lastElapsed == Duration.zero
        ? 1 / 60
        : ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;

    for (var i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.age += dt;
      if (p.age >= p.maxAge) {
        _particles.removeAt(i);
        continue;
      }
      if (p.isRune) {
        // Whisper-gentle radial deceleration + barely-there ambient shimmer.
        final drag = math.exp(-3.0 * dt);
        p.vx *= drag;
        p.vy *= drag;
        p.x += (p.vx + math.sin(p.age * 2.8 + p.swayPhase) * 2.2) * dt;
        p.y += (p.vy + math.cos(p.age * 2.4 + p.swayPhase) * 2.0) * dt;
      } else {
        p.vy += p.gravity * dt;
        p.vx *= (1.0 - 1.2 * dt).clamp(0.8, 1.0);
        p.x += p.vx * dt;
        p.y += p.vy * dt;
        p.rotation += p.spinSpeed * dt;
      }
    }

    for (var i = _blocks.length - 1; i >= 0; i--) {
      final b = _blocks[i];
      b.age += dt;
      if (b.age >= b.maxAge) {
        _blocks.removeAt(i);
      }
    }

    if (_particles.isEmpty && _blocks.isEmpty) {
      _ticker.stop();
      widget.onDrained();
      return;
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size.infinite,
          painter: _PixelBurstPainter(
            image: _sheet,
            runeImage: _runeSheet,
            grassImage: _grassSheet,
            particles: _particles,
            blocks: _blocks,
          ),
        ),
      ),
    );
  }
}

class _PixelBurstPainter extends CustomPainter {
  const _PixelBurstPainter({
    required this.image,
    required this.runeImage,
    required this.grassImage,
    required this.particles,
    required this.blocks,
  });

  final ui.Image? image;
  final ui.Image? runeImage;
  final ui.Image? grassImage;
  final List<_ActiveParticle> particles;
  final List<_ActiveBlockPop> blocks;

  @override
  void paint(Canvas canvas, Size size) {
    if (particles.isNotEmpty) {
      const fw = 12.0;
      const fh = 12.0;

      for (final p in particles) {
        final sheet = p.isRune ? runeImage : image;
        if (sheet == null) continue;

        final progress = (p.age / p.maxAge).clamp(0.0, 1.0);
        final double alpha;
        final double popScale;
        if (p.isRune) {
          // Soft fade-in -> calm matte peak -> slow whisper fade-out.
          const peakAlpha = 0.80;
          if (progress < 0.16) {
            alpha = peakAlpha * (progress / 0.16);
          } else if (progress < 0.44) {
            alpha = peakAlpha;
          } else {
            alpha =
                (peakAlpha * (1.0 - ((progress - 0.44) / 0.56))).clamp(0.0, 1.0);
          }
          popScale = progress < 0.18
              ? ui.lerpDouble(0.88, 1.0, progress / 0.18)!
              : ui.lerpDouble(1.0, 0.94, (progress - 0.18) / 0.82)!;
        } else {
          alpha = progress < 0.58
              ? 1.0
              : (1.0 - ((progress - 0.58) / 0.42)).clamp(0.0, 1.0);
          popScale = progress < 0.14
              ? ui.lerpDouble(0.55, 1.0, progress / 0.14)!
              : ui.lerpDouble(1.0, 0.72, progress)!;
        }

        final drawW = fw * p.scale * popScale;
        final drawH = fh * p.scale * popScale;

        final src = Rect.fromLTWH(p.frameIndex * fw, 0, fw, fh);
        final dst = Rect.fromCenter(
          center: Offset.zero,
          width: drawW,
          height: drawH,
        );

        final paint = Paint()
          ..filterQuality = FilterQuality.none
          ..isAntiAlias = false
          ..color = Color.fromRGBO(255, 255, 255, alpha);

        canvas.save();
        canvas.translate(p.x.roundToDouble(), p.y.roundToDouble());
        if (p.rotation != 0) {
          canvas.rotate(p.rotation);
        }
        canvas.drawImageRect(sheet, src, dst, paint);
        canvas.restore();
      }
    }

    final grass = grassImage;
    if (grass != null && blocks.isNotEmpty) {
      const bw = 32.0;
      const bh = 32.0;
      const frameCount = 6;

      for (final b in blocks) {
        final t = (b.age / b.maxAge).clamp(0.0, 1.0);
        final rise = Curves.easeOutCubic.transform(t) * 34.0;
        final popScale = t < 0.25
            ? Curves.easeOutBack.transform(t / 0.25).clamp(0.25, 1.25)
            : ui.lerpDouble(1.0, 0.86, (t - 0.25) / 0.75)!;
        final alpha = t < 0.60
            ? 1.0
            : (1.0 - ((t - 0.60) / 0.40)).clamp(0.0, 1.0);

        final frameIdx = (t * frameCount).floor().clamp(0, frameCount - 1);
        final drawSize = b.targetSize * popScale;
        final cx = (b.x + b.vx * t).roundToDouble();
        final cy = (b.y - rise).roundToDouble();

        final src = Rect.fromLTWH(frameIdx * bw, 0, bw, bh);
        final dst = Rect.fromCenter(
          center: Offset(cx, cy),
          width: drawSize,
          height: drawSize,
        );

        final paint = Paint()
          ..filterQuality = FilterQuality.none
          ..isAntiAlias = false
          ..color = Color.fromRGBO(255, 255, 255, alpha);

        canvas.drawImageRect(grass, src, dst, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PixelBurstPainter oldDelegate) => true;
}
