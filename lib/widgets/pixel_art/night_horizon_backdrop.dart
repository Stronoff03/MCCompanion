import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../design/ds_tokens.dart';
import 'pixel_art_settings.dart';
import 'pixel_sprite_cache.dart';

class _StarSpec {
  const _StarSpec(this.nx, this.ny, this.phase, this.size);

  final double nx;
  final double ny;
  final double phase;
  final double size;
}

class _MoteSpec {
  _MoteSpec({
    required this.nx,
    required this.ny,
    required this.vx,
    required this.vy,
    required this.phase,
  });

  double nx;
  double ny;
  final double vx;
  final double vy;
  final double phase;
}

/// Calm, matte, richly populated Aseprite-crafted living Minecraft pixel-art
/// horizon rendered behind the desktop workspace. Defaults to [PixelBiome.autoTime]
/// which adapts to the local clock across Morning Dawn (06–10), Daylight Valley
/// (11–16), Sunset Village (17–20), and Night Forest (21–05), or locks to any
/// manual biome chosen in Customize (including Nether Crimson and End Void).
class NightHorizonBackdrop extends StatefulWidget {
  const NightHorizonBackdrop({
    super.key,
    required this.child,
    this.broadcasting,
    this.groundBottomInset = 0.0,
  });

  final Widget child;
  final ValueListenable<bool>? broadcasting;

  /// Extra bottom clearance (e.g. mobile floating nav bar height + safe inset)
  /// so the village horizon sits cleanly above the bottom bar while the deep
  /// underground layer fills all the way to the bottom edge.
  final double groundBottomInset;

  @override
  State<NightHorizonBackdrop> createState() => _NightHorizonBackdropState();
}

class _NightHorizonBackdropState extends State<NightHorizonBackdrop>
    with SingleTickerProviderStateMixin {
  static final List<_StarSpec> _stars = List<_StarSpec>.generate(
    44,
    (i) => _StarSpec(
      ((i * 89 + 23) % 1000) / 1000.0,
      ((i * 53 + 17) % 520) / 1000.0,
      i * 1.1,
      i % 6 == 0 ? 3.0 : 2.0,
    ),
  );

  final List<_MoteSpec> _motes = <_MoteSpec>[
    _MoteSpec(nx: 0.09, ny: 0.78, vx: 0.0045, vy: -0.004, phase: 0.0),
    _MoteSpec(nx: 0.21, ny: 0.84, vx: -0.004, vy: -0.005, phase: 1.1),
    _MoteSpec(nx: 0.35, ny: 0.76, vx: 0.0042, vy: -0.0045, phase: 2.3),
    _MoteSpec(nx: 0.49, ny: 0.81, vx: -0.0036, vy: -0.0055, phase: 3.4),
    _MoteSpec(nx: 0.63, ny: 0.75, vx: 0.0044, vy: -0.0042, phase: 4.5),
    _MoteSpec(nx: 0.76, ny: 0.83, vx: -0.0042, vy: -0.0048, phase: 5.4),
    _MoteSpec(nx: 0.88, ny: 0.79, vx: -0.0038, vy: -0.0038, phase: 0.7),
    _MoteSpec(nx: 0.58, ny: 0.88, vx: 0.0032, vy: -0.006, phase: 1.9),
    _MoteSpec(nx: 0.94, ny: 0.85, vx: -0.0034, vy: -0.005, phase: 3.1),
  ];

  final ValueNotifier<int> _paintTick = ValueNotifier<int>(0);
  late final Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  double _time = 0;
  bool _disableSystemAnimations = false;

  bool get _animated => PixelArtSettings.instance.effectsEnabled.value;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    PixelArtSettings.instance.effectsEnabled.addListener(_syncTicker);
    PixelArtSettings.instance.biome.addListener(_onStateChanged);
    widget.broadcasting?.addListener(_onStateChanged);
    _ensureBiomeSpritesLoaded();
  }

  Future<void> _ensureBiomeSpritesLoaded() async {
    final cache = PixelSpriteCache.instance;
    await Future.wait<void>(<Future<void>>[
      cache.load(PixelArtAssets.biomeBeacon.assetPath).then((_) {}),
      cache.load(PixelArtAssets.biomeCottage.assetPath).then((_) {}),
      cache.load(PixelArtAssets.biomeWindmill.assetPath).then((_) {}),
      cache.load(PixelArtAssets.biomeRuinedPortal.assetPath).then((_) {}),
      cache.load(PixelArtAssets.biomeEndFountain.assetPath).then((_) {}),
      cache.load(PixelArtAssets.biomeFoliage.assetPath).then((_) {}),
      cache.load(PixelArtAssets.biomeBridge.assetPath).then((_) {}),
      cache.load(PixelArtAssets.biomeVillageProps.assetPath).then((_) {}),
      cache.load(PixelArtAssets.biomeClouds.assetPath).then((_) {}),
      cache.load(PixelArtAssets.biomeNetherGhast.assetPath).then((_) {}),
      cache.load(PixelArtAssets.biomeEndDragon.assetPath).then((_) {}),
      cache.load(PixelArtAssets.biomeEndNetherProps.assetPath).then((_) {}),
    ]);
    if (mounted) _paintTick.value++;
  }

  @override
  void didUpdateWidget(covariant NightHorizonBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.broadcasting != widget.broadcasting) {
      oldWidget.broadcasting?.removeListener(_onStateChanged);
      widget.broadcasting?.addListener(_onStateChanged);
      _paintTick.value++;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _disableSystemAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _syncTicker();
  }

  @override
  void dispose() {
    PixelArtSettings.instance.effectsEnabled.removeListener(_syncTicker);
    PixelArtSettings.instance.biome.removeListener(_onStateChanged);
    widget.broadcasting?.removeListener(_onStateChanged);
    _ticker.dispose();
    _paintTick.dispose();
    super.dispose();
  }

  void _onStateChanged() => _paintTick.value++;

  void _syncTicker() {
    if (!mounted) return;
    final shouldRun = _animated && !_disableSystemAnimations;
    if (shouldRun && !_ticker.isActive) {
      _lastElapsed = Duration.zero;
      _ticker.start();
    } else if (!shouldRun && _ticker.isActive) {
      _ticker.stop();
    }
    _paintTick.value++;
  }

  void _onTick(Duration elapsed) {
    const speedScale = 0.72;
    final rawDt = _lastElapsed == Duration.zero
        ? 1 / 60
        : ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _lastElapsed = elapsed;
    final dt = rawDt * speedScale;
    _time += dt;

    final biome = PixelArtSettings.instance.biome.value.resolveEffective();
    final rising =
        biome == PixelBiome.netherCrimson || biome == PixelBiome.endVoid;

    for (final m in _motes) {
      m.nx += m.vx * dt * 0.65;
      if (m.nx < 0.05) m.nx = 0.95;
      if (m.nx > 0.95) m.nx = 0.05;
      if (rising) {
        m.ny += m.vy * dt * 1.35;
        if (m.ny < 0.54) {
          m.ny = 0.96;
          m.nx = (m.nx + 0.19) % 0.88 + 0.06;
        }
      } else {
        m.ny += math.sin(_time * 0.55 + m.phase) * 0.004 * dt;
        m.ny = m.ny.clamp(0.68, 0.92);
      }
    }
    _paintTick.value++;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PixelArtSettings.instance.effectsEnabled,
      builder: (context, enabled, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        if (!enabled || !isDark) {
          return ColoredBox(color: DsColor.bg, child: widget.child);
        }
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Positioned.fill(
              child: IgnorePointer(
                child: RepaintBoundary(
                  child: ClipRect(
                    child: CustomPaint(
                      painter: _AsepriteBiomeHorizonPainter(
                        repaint: _paintTick,
                        stars: _stars,
                        motes: _motes,
                        biomeOf: () =>
                            PixelArtSettings.instance.biome.value
                                .resolveEffective(),
                        isAutoTimeOf: () =>
                            PixelArtSettings.instance.biome.value ==
                            PixelBiome.autoTime,
                        timeOf: () => _time,
                        broadcastingOf: () =>
                            widget.broadcasting?.value ?? false,
                        groundBottomInset: widget.groundBottomInset,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            widget.child,
          ],
        );
      },
    );
  }
}

class _AsepriteBiomeHorizonPainter extends CustomPainter {
  _AsepriteBiomeHorizonPainter({
    required super.repaint,
    required this.stars,
    required this.motes,
    required this.biomeOf,
    required this.isAutoTimeOf,
    required this.timeOf,
    required this.broadcastingOf,
    this.groundBottomInset = 0.0,
  });

  final List<_StarSpec> stars;
  final List<_MoteSpec> motes;
  final PixelBiome Function() biomeOf;
  final bool Function() isAutoTimeOf;
  final double Function() timeOf;
  final bool Function() broadcastingOf;
  final double groundBottomInset;

  static const double _p = 3.0;
  double _layoutScale = 1.0;

  double _snap(double v) => (v / _p).floorToDouble() * _p;

  double _groundY(double h) {
    const base = 22 * _p;
    final lifted = groundBottomInset > 0
        ? math.max(base, groundBottomInset + 18.0)
        : base;
    return _snap(h - lifted);
  }

  double _deepCellsFrom(double h, double startY) =>
      math.max(16.0, ((h - startY) / _p).ceilToDouble() + 2.0);

  /// Computes a smooth east→west celestial arc for the Sun (06:00–21:00)
  /// when [PixelBiome.autoTime] is active; returns the curated static position
  /// when the user manually locks a specific biome.
  (double, double) _sunPosition(
    double w,
    double h,
    double groundY, {
    required double fallbackX,
    required double fallbackY,
  }) {
    if (!isAutoTimeOf()) return (_snap(fallbackX), _snap(fallbackY));
    final now = DateTime.now();
    final hourFrac = now.hour + now.minute / 60.0 + now.second / 3600.0;
    final u = ((hourFrac - 6.0) / 15.0).clamp(0.0, 1.0);
    final lowY = (groundY - 22 * _p).clamp(h * 0.26, h * 0.62);
    final highY = (h * 0.10).clamp(16.0, lowY);
    final arc = math.sin(u * math.pi);
    final x = w * (0.10 + u * 0.80);
    final y = ui.lerpDouble(lowY, highY, arc)!;
    return (_snap(x), _snap(y));
  }

  /// Computes a smooth east→west celestial arc for the Moon (21:00–06:00)
  /// when [PixelBiome.autoTime] is active; returns the curated static position
  /// when Night Forest is manually locked.
  (double, double) _moonPosition(
    double w,
    double h,
    double groundY, {
    required double fallbackX,
    required double fallbackY,
  }) {
    if (!isAutoTimeOf()) return (_snap(fallbackX), _snap(fallbackY));
    final now = DateTime.now();
    final hourFrac = now.hour + now.minute / 60.0 + now.second / 3600.0;
    final nightHours = hourFrac >= 21.0 ? (hourFrac - 21.0) : (hourFrac + 3.0);
    final u = (nightHours / 9.0).clamp(0.0, 1.0);
    final lowY = (groundY - 26 * _p).clamp(h * 0.24, h * 0.56);
    final highY = (h * 0.11).clamp(16.0, lowY);
    final arc = math.sin(u * math.pi);
    final x = w * (0.12 + u * 0.76);
    final y = ui.lerpDouble(lowY, highY, arc)!;
    return (_snap(x), _snap(y));
  }

  void _px(Canvas canvas, double x, double y, double w, double h, Color color) {
    canvas.drawRect(
      Rect.fromLTWH(_snap(x), _snap(y), w * _p, h * _p),
      Paint()..color = color,
    );
  }

  Rect? _drawSpriteBottomCentered(
    Canvas canvas,
    PixelSpriteSheetSpec spec, {
    required double centerX,
    required double bottomY,
    required double scale,
    required int frameIndex,
    double opacity = 1.0,
    bool flipH = false,
  }) {
    final ui.Image? img = PixelSpriteCache.instance.getCached(spec.assetPath);
    if (img == null) return null;

    final safeFrame = frameIndex % spec.frameCount;
    final src = Rect.fromLTWH(
      (safeFrame * spec.frameWidth).toDouble(),
      0,
      spec.frameWidth.toDouble(),
      spec.frameHeight.toDouble(),
    );
    final effectiveScale = scale * _layoutScale;
    final dw = spec.frameWidth * effectiveScale;
    final dh = spec.frameHeight * effectiveScale;
    final dst = Rect.fromLTWH(
      (centerX - dw / 2).roundToDouble(),
      (bottomY - dh).roundToDouble(),
      dw,
      dh,
    );

    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;
    if (opacity < 1.0) {
      paint.color = Color.fromRGBO(255, 255, 255, opacity);
    }

    if (flipH) {
      canvas.save();
      canvas.translate(dst.center.dx, 0);
      canvas.scale(-1, 1);
      canvas.translate(-dst.center.dx, 0);
      canvas.drawImageRect(img, src, dst, paint);
      canvas.restore();
    } else {
      canvas.drawImageRect(img, src, dst, paint);
    }
    return dst;
  }

  int _animFrame(PixelSpriteSheetSpec spec, double t, {double speed = 1.0}) {
    final frameSec = spec.frameDuration.inMilliseconds / 1000.0;
    return ((t * speed) / frameSec).floor() % spec.frameCount;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    // Proportionally scale horizon sprites on narrow phone widths so landmarks
    // stay crisp and balanced without crowding.
    _layoutScale = (size.width / 760.0).clamp(0.62, 1.0);

    final biome = biomeOf();
    final t = timeOf();
    final broadcasting = broadcastingOf();

    switch (biome) {
      case PixelBiome.autoTime:
      case PixelBiome.nightForest:
        _paintNightForest(canvas, size, t, broadcasting);
      case PixelBiome.morningDawn:
        _paintMorningDawn(canvas, size, t, broadcasting);
      case PixelBiome.daylightValley:
        _paintDaylightValley(canvas, size, t, broadcasting);
      case PixelBiome.sunsetVillage:
        _paintSunsetVillage(canvas, size, t, broadcasting);
      case PixelBiome.netherCrimson:
        _paintNetherCrimson(canvas, size, t, broadcasting);
      case PixelBiome.endVoid:
        _paintEndVoid(canvas, size, t, broadcasting);
    }
    canvas.restore();
  }

  // ===========================================================================
  // 1. SABAH ŞAFAĞI (06:00–10:59) — Misty Dawn Sunrise, Bridge, Well & Windmill
  // ===========================================================================
  void _paintMorningDawn(
    Canvas canvas,
    Size size,
    double t,
    bool broadcasting,
  ) {
    final w = size.width;
    final h = size.height;
    final groundY = _groundY(h);

    // Distinct calm morning dawn palette: cool slate top -> dusty rose -> peach mist.
    final sky = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: const <double>[0.0, 0.46, 0.72, 0.90, 1.0],
      colors: <Color>[
        const Color(0xFF0E1721),
        const Color(0xFF1A2838),
        const Color(0xFF36384C),
        const Color(0xFF6B4A4A),
        const Color(0xFF281F22),
      ],
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..shader = sky);

    _paintStars(canvas, size, t, const Color(0xFFE8DCE6), 0.12);
    _paintAsepriteCloudDeck(
      canvas,
      size,
      t,
      farTint: const Color(0xFFD69EA8),
      nearTint: const Color(0xFFFFCBA8),
      farOpacity: 0.18,
      nearOpacity: 0.28,
    );

    // Rising golden-peach eastern morning sun (follows live clock in auto mode).
    final (sunX, sunY) = _sunPosition(
      w,
      h,
      groundY,
      fallbackX: w * 0.28,
      fallbackY: groundY - 22 * _p,
    );
    final sunHalo = Rect.fromCircle(
      center: Offset(sunX + 4.5 * _p, sunY + 4.5 * _p),
      radius: 28 * _p,
    );
    canvas.drawRect(
      sunHalo,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0xFFF5B886).withValues(alpha: 0.26),
            const Color(0xFFC9787E).withValues(alpha: 0.10),
            Colors.transparent,
          ],
        ).createShader(sunHalo),
    );
    _px(canvas, sunX, sunY, 9, 9, const Color(0xFFE8A472));
    _px(canvas, sunX + _p, sunY + _p, 7, 7, const Color(0xFFF7C992));
    _px(canvas, sunX + 2 * _p, sunY + 2 * _p, 5, 5, const Color(0xFFFFE5B8));

    _paintBirds(canvas, w, groundY, t, count: 2, color: const Color(0xFF2A202D));

    // Distant snow-capped peaks & misty morning hills.
    _paintMountainRange(
      canvas,
      w,
      groundY,
      peaks: const <(double, int)>[
        (0.08, 30),
        (0.24, 24),
        (0.47, 32),
        (0.69, 26),
        (0.88, 29),
      ],
      bodyColor: const Color(0xFF242F40),
      shadeColor: const Color(0xFF1B2433),
      snowColor: const Color(0xFF7A7082),
    );
    _paintHillBand(
      canvas,
      w,
      groundY,
      baseHeightCells: 11,
      ampCells: 4,
      freq: 0.008,
      phase: 1.4,
      color: const Color(0xFF203235),
    );

    // Left bank (0.04..0.38): Trees, Cottage, Hay Bales, Wheat strictly before water!
    _paintFoliageRow(canvas, w, groundY, const <(double, double, int, bool)>[
      (0.04, 2.3, 0, false),
      (0.10, 2.5, 1, true),
      (0.29, 2.1, 0, false),
      (0.62, 2.2, 1, true),
      (0.88, 2.5, 0, false),
      (0.95, 2.3, 1, true),
    ]);
    _drawSpriteBottomCentered(
      canvas,
      PixelArtAssets.biomeCottage,
      centerX: w * 0.17,
      bottomY: groundY + 3,
      scale: 2.6,
      frameIndex: _animFrame(PixelArtAssets.biomeCottage, t),
    );
    _drawSpriteBottomCentered(
      canvas,
      PixelArtAssets.biomeVillageProps,
      centerX: w * 0.25,
      bottomY: groundY + 2,
      scale: 2.0,
      frameIndex: 2, // Hay bales & barrel
    );
    _paintWheatPatch(
      canvas,
      startX: w * 0.30,
      endX: w * 0.385,
      groundY: groundY,
      t: t,
      fenceColor: const Color(0xFF3B2B22),
    );

    // Right bank (0.61..0.95): Mossy Well + Animated Windmill!
    _drawSpriteBottomCentered(
      canvas,
      PixelArtAssets.biomeVillageProps,
      centerX: w * 0.67,
      bottomY: groundY + 3,
      scale: 2.2,
      frameIndex: 1, // Mossy village well
    );
    _drawSpriteBottomCentered(
      canvas,
      PixelArtAssets.biomeWindmill,
      centerX: w * 0.79,
      bottomY: groundY + 3,
      scale: 2.9,
      frameIndex: _animFrame(
        PixelArtAssets.biomeWindmill,
        t,
        speed: broadcasting ? 1.35 : 0.78,
      ),
    );

    // Terrain + wildflowers + underground ore strata + clean lake + Arched Bridge!
    _paintGrassTerrain(
      canvas,
      w,
      h,
      groundY,
      topColor: const Color(0xFF345E45),
      edgeColor: const Color(0xFF254534),
      dirtColor: const Color(0xFF241D1B),
      deepColor: const Color(0xFF161416),
      lakeStartFrac: 0.40,
      lakeEndFrac: 0.58,
      wildflowers: true,
    );
    _paintWaterWithBridge(
      canvas,
      w,
      groundY,
      startFrac: 0.40,
      widthFrac: 0.18,
      t: t,
      waterDark: const Color(0xFF1F3042),
      waterMid: const Color(0xFF2D4357),
      glintColor: const Color(0xFFF5BF96),
      lilyPads: true,
    );

    _paintMotes(
      canvas,
      size,
      t,
      const Color(0xFFFFD8B0),
      const Color(0xFFB8E8D8),
    );
  }

  // ===========================================================================
  // 2. GÜNDÜZ VADİSİ (11:00–16:59) — Clear Daytime Blue Sky, Clouds, Bridge!
  // ===========================================================================
  void _paintDaylightValley(
    Canvas canvas,
    Size size,
    double t,
    bool broadcasting,
  ) {
    final w = size.width;
    final h = size.height;
    final groundY = _groundY(h);

    // Unmistakably clear, calm matte daytime sky (steel-navy top -> sky cerulean horizon).
    final sky = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: const <double>[0.0, 0.42, 0.72, 0.92, 1.0],
      colors: <Color>[
        const Color(0xFF0E1B29),
        const Color(0xFF16314A),
        const Color(0xFF234E70),
        const Color(0xFF336D94),
        const Color(0xFF1E3847),
      ],
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..shader = sky);

    // High bright square midday sun (arcs smoothly across the sky by local clock).
    final (sunX, sunY) = _sunPosition(
      w,
      h,
      groundY,
      fallbackX: w * 0.84,
      fallbackY: h * 0.12,
    );
    final sunHalo = Rect.fromCircle(
      center: Offset(sunX + 4.5 * _p, sunY + 4.5 * _p),
      radius: 26 * _p,
    );
    canvas.drawRect(
      sunHalo,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0xFFFFE699).withValues(alpha: 0.28),
            const Color(0xFF9CD8FA).withValues(alpha: 0.10),
            Colors.transparent,
          ],
        ).createShader(sunHalo),
    );
    _px(canvas, sunX, sunY, 9, 9, const Color(0xFFF2CC68));
    _px(canvas, sunX + _p, sunY + _p, 7, 7, const Color(0xFFFFE48F));
    _px(canvas, sunX + 2 * _p, sunY + 2 * _p, 5, 5, const Color(0xFFFFF8D6));

    // Rich multi-layer handcrafted Aseprite billowing daytime cumulus clouds!
    _paintAsepriteCloudDeck(
      canvas,
      size,
      t,
      farTint: const Color(0xFFA8D3ED),
      nearTint: const Color(0xFFEBF7FF),
      farOpacity: 0.24,
      nearOpacity: 0.36,
    );

    _paintBirds(canvas, w, groundY, t, count: 3, color: const Color(0xFF162A3B));

    // Layered sunlit snow-capped peaks & lush emerald valley hills.
    _paintMountainRange(
      canvas,
      w,
      groundY,
      peaks: const <(double, int)>[
        (0.08, 34),
        (0.26, 27),
        (0.46, 36),
        (0.66, 29),
        (0.84, 32),
        (0.97, 23),
      ],
      bodyColor: const Color(0xFF25475E),
      shadeColor: const Color(0xFF1C374A),
      snowColor: const Color(0xFF7FAAC2),
    );
    _paintHillBand(
      canvas,
      w,
      groundY,
      baseHeightCells: 12,
      ampCells: 4,
      freq: 0.008,
      phase: 0.8,
      color: const Color(0xFF214A3C),
    );

    // Left bank (0.04..0.38): Valley trees, Cottage, Hay Bales, Wheat strictly on land!
    _paintFoliageRow(canvas, w, groundY, const <(double, double, int, bool)>[
      (0.04, 2.4, 1, false),
      (0.10, 2.3, 0, true),
      (0.29, 2.2, 1, true),
      (0.61, 2.3, 0, false),
      (0.92, 2.6, 1, true),
      (0.97, 2.2, 0, false),
    ]);
    _drawSpriteBottomCentered(
      canvas,
      PixelArtAssets.biomeCottage,
      centerX: w * 0.17,
      bottomY: groundY + 3,
      scale: 2.6,
      frameIndex: _animFrame(PixelArtAssets.biomeCottage, t),
    );
    _drawSpriteBottomCentered(
      canvas,
      PixelArtAssets.biomeVillageProps,
      centerX: w * 0.25,
      bottomY: groundY + 2,
      scale: 2.0,
      frameIndex: 2, // Hay bales & barrel
    );
    _paintWheatPatch(
      canvas,
      startX: w * 0.30,
      endX: w * 0.385,
      groundY: groundY,
      t: t,
      fenceColor: const Color(0xFF473326),
    );

    // Right bank (0.61..0.95): Cobblestone Bell Tower + Rotating Windmill + Mossy Well!
    _drawSpriteBottomCentered(
      canvas,
      PixelArtAssets.biomeVillageProps,
      centerX: w * 0.67,
      bottomY: groundY + 3,
      scale: 2.4,
      frameIndex: 0, // Aseprite Cobblestone Bell Tower
    );
    _drawSpriteBottomCentered(
      canvas,
      PixelArtAssets.biomeWindmill,
      centerX: w * 0.78,
      bottomY: groundY + 3,
      scale: 2.9,
      frameIndex: _animFrame(
        PixelArtAssets.biomeWindmill,
        t,
        speed: broadcasting ? 1.4 : 0.85,
      ),
    );
    _drawSpriteBottomCentered(
      canvas,
      PixelArtAssets.biomeVillageProps,
      centerX: w * 0.87,
      bottomY: groundY + 3,
      scale: 2.1,
      frameIndex: 1, // Mossy Village Well
    );

    // Lush daytime grass + wildflowers + underground ores + cerulean river & Arched Bridge!
    _paintGrassTerrain(
      canvas,
      w,
      h,
      groundY,
      topColor: const Color(0xFF3E7D4E),
      edgeColor: const Color(0xFF2B5B3A),
      dirtColor: const Color(0xFF2D221C),
      deepColor: const Color(0xFF1A1514),
      lakeStartFrac: 0.40,
      lakeEndFrac: 0.58,
      wildflowers: true,
    );
    _paintWaterWithBridge(
      canvas,
      w,
      groundY,
      startFrac: 0.40,
      widthFrac: 0.18,
      t: t,
      waterDark: const Color(0xFF1E5273),
      waterMid: const Color(0xFF2B6F99),
      glintColor: const Color(0xFFC9F2FF),
      lilyPads: true,
    );

    _paintMotes(
      canvas,
      size,
      t,
      const Color(0xFFFFF2C2),
      const Color(0xFFC2EEFF),
    );
  }

  // ===========================================================================
  // 3. GÜN BATIMI KÖYÜ (17:00–20:59) — Dusk Sunset, Bridge, Bell Tower, Windmill
  // ===========================================================================
  void _paintSunsetVillage(
    Canvas canvas,
    Size size,
    double t,
    bool broadcasting,
  ) {
    final w = size.width;
    final h = size.height;
    final groundY = _groundY(h);

    final sky = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: const <double>[0.0, 0.50, 0.74, 0.92, 1.0],
      colors: <Color>[
        DsColor.bg,
        const Color(0xFF191626),
        const Color(0xFF332030),
        const Color(0xFF5C312D),
        const Color(0xFF221819),
      ],
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..shader = sky);

    _paintStars(canvas, size, t, const Color(0xFFF0D4B8), 0.18);
    _paintAsepriteCloudDeck(
      canvas,
      size,
      t,
      farTint: const Color(0xFFC47A80),
      nearTint: const Color(0xFFFFB978),
      farOpacity: 0.18,
      nearOpacity: 0.28,
    );
    _paintBirds(canvas, w, groundY, t, count: 3, color: const Color(0xFF21141C));

    // Setting square sun glowing above the horizon (follows live clock in auto mode).
    final (sunX, sunY) = _sunPosition(
      w,
      h,
      groundY,
      fallbackX: w * 0.49,
      fallbackY: groundY - 20 * _p,
    );
    final sunHalo = Rect.fromCircle(
      center: Offset(sunX + 5 * _p, sunY + 5 * _p),
      radius: 28 * _p,
    );
    canvas.drawRect(
      sunHalo,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0xFFE8984C).withValues(alpha: 0.25),
            const Color(0xFF9C4B3B).withValues(alpha: 0.10),
            Colors.transparent,
          ],
        ).createShader(sunHalo),
    );
    _px(canvas, sunX, sunY, 10, 10, const Color(0xFFD98445));
    _px(canvas, sunX + _p, sunY + _p, 8, 8, const Color(0xFFEFA95A));
    _px(canvas, sunX + 2 * _p, sunY + 2 * _p, 6, 6, const Color(0xFFF6C67A));

    _paintHillBand(
      canvas,
      w,
      groundY,
      baseHeightCells: 14,
      ampCells: 5,
      freq: 0.007,
      phase: 0.5,
      color: const Color(0xFF2B1E26),
    );
    _paintHillBand(
      canvas,
      w,
      groundY,
      baseHeightCells: 8,
      ampCells: 3,
      freq: 0.011,
      phase: 2.3,
      color: const Color(0xFF211A1E),
    );

    // Left & right bank Aseprite Oak Trees (zero trees over river 0.40..0.58!).
    _paintFoliageRow(canvas, w, groundY, const <(double, double, int, bool)>[
      (0.05, 2.3, 1, false),
      (0.11, 2.6, 1, true),
      (0.29, 2.1, 1, false),
      (0.61, 2.3, 1, true),
      (0.92, 2.5, 1, false),
      (0.97, 2.1, 1, true),
    ]);
    _drawSpriteBottomCentered(
      canvas,
      PixelArtAssets.biomeCottage,
      centerX: w * 0.17,
      bottomY: groundY + 3,
      scale: 2.6,
      frameIndex: _animFrame(PixelArtAssets.biomeCottage, t),
    );
    _drawSpriteBottomCentered(
      canvas,
      PixelArtAssets.biomeVillageProps,
      centerX: w * 0.25,
      bottomY: groundY + 2,
      scale: 2.0,
      frameIndex: 2, // Hay bales & barrel
    );
    _paintWheatPatch(
      canvas,
      startX: w * 0.30,
      endX: w * 0.385,
      groundY: groundY,
      t: t,
      fenceColor: const Color(0xFF3B2B22),
    );

    // Right bank: Aseprite Bell Tower + Rotating Windmill + Mossy Well!
    _drawSpriteBottomCentered(
      canvas,
      PixelArtAssets.biomeVillageProps,
      centerX: w * 0.67,
      bottomY: groundY + 3,
      scale: 2.4,
      frameIndex: 0, // Aseprite Cobblestone Bell Tower
    );
    _drawSpriteBottomCentered(
      canvas,
      PixelArtAssets.biomeWindmill,
      centerX: w * 0.79,
      bottomY: groundY + 3,
      scale: 2.9,
      frameIndex: _animFrame(
        PixelArtAssets.biomeWindmill,
        t,
        speed: broadcasting ? 1.35 : 0.82,
      ),
    );
    _drawSpriteBottomCentered(
      canvas,
      PixelArtAssets.biomeVillageProps,
      centerX: w * 0.87,
      bottomY: groundY + 3,
      scale: 2.1,
      frameIndex: 1, // Mossy Village Well
    );

    _paintGrassTerrain(
      canvas,
      w,
      h,
      groundY,
      topColor: const Color(0xFF3A5230),
      edgeColor: const Color(0xFF2A3D23),
      dirtColor: const Color(0xFF261D19),
      deepColor: const Color(0xFF181312),
      lakeStartFrac: 0.40,
      lakeEndFrac: 0.58,
      wildflowers: true,
    );
    _paintWaterWithBridge(
      canvas,
      w,
      groundY,
      startFrac: 0.40,
      widthFrac: 0.18,
      t: t,
      waterDark: const Color(0xFF232533),
      waterMid: const Color(0xFF2E2C3B),
      glintColor: const Color(0xFFEFA95A),
      lilyPads: false,
    );

    _paintMotes(
      canvas,
      size,
      t,
      const Color(0xFFF6C67A),
      const Color(0xFFE09250),
    );
  }

  // ===========================================================================
  // 4. GECE ORMANI (21:00–05:59) — Starry Night, Campfire, Bridge & Beacon!
  // ===========================================================================
  void _paintNightForest(
    Canvas canvas,
    Size size,
    double t,
    bool broadcasting,
  ) {
    final w = size.width;
    final h = size.height;
    final groundY = _groundY(h);

    final sky = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: const <double>[0.0, 0.56, 0.84, 1.0],
      colors: <Color>[
        DsColor.bg,
        const Color(0xFF0E1820),
        const Color(0xFF142630),
        const Color(0xFF101C24),
      ],
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..shader = sky);

    _paintStars(canvas, size, t, const Color(0xFFC8E3EC), 0.36);
    _paintShootingStar(canvas, size, t, 8.8, const Color(0xFFD9F6FF));
    _paintAsepriteCloudDeck(
      canvas,
      size,
      t,
      farTint: const Color(0xFF4A7387),
      nearTint: const Color(0xFF8CBCD1),
      farOpacity: 0.12,
      nearOpacity: 0.18,
    );

    // Cratered blocky Moon (glides across the night sky by local clock in auto mode).
    final (moonX, moonY) = _moonPosition(
      w,
      h,
      groundY,
      fallbackX: w * 0.87,
      fallbackY: h * 0.14,
    );
    final moonGlow = Rect.fromCircle(
      center: Offset(moonX + 4.5 * _p, moonY + 4.5 * _p),
      radius: 16 * _p,
    );
    canvas.drawRect(
      moonGlow,
      Paint()
        ..shader = RadialGradient(
          colors: <Color>[
            const Color(0xFFAEDCE8).withValues(alpha: 0.13),
            Colors.transparent,
          ],
        ).createShader(moonGlow),
    );
    _px(canvas, moonX, moonY, 9, 9, const Color(0xFFCDE2E8));
    _px(canvas, moonX + _p, moonY + _p, 7, 7, const Color(0xFFDFEFF4));
    _px(canvas, moonX + 2 * _p, moonY + 2 * _p, 2, 2, const Color(0xFFB3CBD4));
    _px(canvas, moonX + 5 * _p, moonY + 5 * _p, 2, 2, const Color(0xFFBACFD7));
    _px(canvas, moonX + 6 * _p, moonY + 2 * _p, 1, 1, const Color(0xFFBACFD7));

    _paintMountainRange(
      canvas,
      w,
      groundY,
      peaks: const <(double, int)>[
        (0.08, 32),
        (0.26, 25),
        (0.46, 34),
        (0.65, 26),
        (0.82, 30),
        (0.96, 22),
      ],
      bodyColor: const Color(0xFF14232C),
      shadeColor: const Color(0xFF101B22),
      snowColor: const Color(0xFF2F4A59),
    );
    _paintHillBand(
      canvas,
      w,
      groundY,
      baseHeightCells: 11,
      ampCells: 4,
      freq: 0.0085,
      phase: 1.2,
      color: const Color(0xFF12232B),
    );

    // Rich snow-dusted Aseprite Spruce Forest (zero overlap over lake 0.40..0.58!).
    _paintFoliageRow(canvas, w, groundY, const <(double, double, int, bool)>[
      (0.04, 2.3, 0, false),
      (0.10, 2.6, 0, true),
      (0.34, 2.4, 0, false),
      (0.61, 2.2, 0, true),
      (0.88, 2.6, 0, true),
      (0.95, 2.3, 0, false),
    ]);

    // Left bank: Animated Cottage + Cozy Roadside Campfire & Lantern Post!
    _drawSpriteBottomCentered(
      canvas,
      PixelArtAssets.biomeCottage,
      centerX: w * 0.17,
      bottomY: groundY + 3,
      scale: 2.6,
      frameIndex: _animFrame(PixelArtAssets.biomeCottage, t),
    );
    final campRect = _drawSpriteBottomCentered(
      canvas,
      PixelArtAssets.biomeVillageProps,
      centerX: w * 0.27,
      bottomY: groundY + 3,
      scale: 2.2,
      frameIndex: 3, // Campfire & Lantern Post
    );
    if (campRect != null) {
      final flick = 0.7 + 0.3 * math.sin(t * 4.5);
      final glow = Rect.fromCircle(
        center: Offset(campRect.center.dx - 8, campRect.bottom - 14),
        radius: 26,
      );
      canvas.drawRect(
        glow,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              const Color(0xFFFFA844).withValues(alpha: 0.24 * flick),
              Colors.transparent,
            ],
          ).createShader(glow),
      );
    }

    // Right bank: Mossy Well + Animated Emerald Beacon Pyramid!
    _drawSpriteBottomCentered(
      canvas,
      PixelArtAssets.biomeVillageProps,
      centerX: w * 0.65,
      bottomY: groundY + 3,
      scale: 2.1,
      frameIndex: 1, // Mossy Village Well
    );
    final beaconRect = _drawSpriteBottomCentered(
      canvas,
      PixelArtAssets.biomeBeacon,
      centerX: w * 0.77,
      bottomY: groundY + 3,
      scale: 3.0,
      frameIndex: _animFrame(
        PixelArtAssets.biomeBeacon,
        t,
        speed: broadcasting ? 1.35 : 1.0,
      ),
    );
    if (beaconRect != null) {
      final coreCenter = Offset(
        beaconRect.center.dx,
        beaconRect.top + beaconRect.height * 0.30,
      );
      final pulse = 0.5 + 0.5 * math.sin(t * 2.4);
      final auraRect = Rect.fromCircle(
        center: coreCenter,
        radius: broadcasting ? 38.0 : 22.0,
      );
      canvas.drawRect(
        auraRect,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              const Color(0xFF5CE8DE).withValues(
                alpha: (broadcasting ? 0.34 : 0.16) + 0.08 * pulse,
              ),
              Colors.transparent,
            ],
          ).createShader(auraRect),
      );
      if (broadcasting) {
        final beamRect = Rect.fromLTRB(
          coreCenter.dx - 7,
          0,
          coreCenter.dx + 7,
          coreCenter.dy,
        );
        canvas.drawRect(
          beamRect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: <Color>[
                const Color(0xFF66F2E8).withValues(alpha: 0.44 + 0.10 * pulse),
                const Color(0xFF66F2E8).withValues(alpha: 0.16),
                Colors.transparent,
              ],
            ).createShader(beamRect),
        );
        final coreRect = Rect.fromLTRB(
          coreCenter.dx - 2,
          0,
          coreCenter.dx + 2,
          coreCenter.dy,
        );
        canvas.drawRect(
          coreRect,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: <Color>[
                const Color(0xFFE8FFFF).withValues(alpha: 0.78),
                const Color(0xFFA8FAF4).withValues(alpha: 0.25),
                Colors.transparent,
              ],
            ).createShader(coreRect),
        );
      }
    }

    _paintGrassTerrain(
      canvas,
      w,
      h,
      groundY,
      topColor: const Color(0xFF23473D),
      edgeColor: const Color(0xFF1B362F),
      dirtColor: const Color(0xFF1A1718),
      deepColor: const Color(0xFF121215),
      lakeStartFrac: 0.40,
      lakeEndFrac: 0.58,
      wildflowers: false,
    );
    _paintWaterWithBridge(
      canvas,
      w,
      groundY,
      startFrac: 0.40,
      widthFrac: 0.18,
      t: t,
      waterDark: const Color(0xFF132A38),
      waterMid: const Color(0xFF18384A),
      glintColor: const Color(0xFF8CD5E6),
      lilyPads: true,
    );

    _paintMotes(
      canvas,
      size,
      t,
      const Color(0xFF9AF0D4),
      const Color(0xFFE4F5B8),
    );
  }

  // ===========================================================================
  // 5. NETHER KIZILI — Cavern Roof, Lavafalls, Ghasts, Fortress, Striders & Portal
  //    (Zero clouds — authentic underground volcanic Nether cavern!)
  // ===========================================================================
  void _paintNetherCrimson(
    Canvas canvas,
    Size size,
    double t,
    bool broadcasting,
  ) {
    final w = size.width;
    final h = size.height;
    final groundY = _groundY(h);

    // Deep volcanic Nether cavern atmosphere (NO clouds!).
    final sky = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: const <double>[0.0, 0.36, 0.72, 0.90, 1.0],
      colors: <Color>[
        const Color(0xFF0C070B),
        const Color(0xFF170C12),
        const Color(0xFF281218),
        const Color(0xFF38191A),
        const Color(0xFF1C0C0F),
      ],
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..shader = sky);

    // Soft distant lava haze glow rising from the cavern floor.
    final lavaHaze = LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: <Color>[
        const Color(0xFFD95B24).withValues(alpha: 0.16),
        const Color(0xFF8C2824).withValues(alpha: 0.06),
        Colors.transparent,
      ],
    ).createShader(Rect.fromLTWH(0, h * 0.48, w, h * 0.52));
    canvas.drawRect(Rect.fromLTWH(0, h * 0.48, w, h * 0.52), Paint()..shader = lavaHaze);

    // Full-width jagged Netherrack cavern ceiling, glowstone clusters & weeping vines!
    final cols = (w / _p).ceil();
    for (var cx = 0; cx < cols; cx += 2) {
      final nx = cx / cols;
      final arch = (math.sin(nx * math.pi * 3.0 + 0.6) * 2.2 +
              math.cos(nx * math.pi * 7.0) * 1.4)
          .round();
      final roofH = (4 + arch + ((cx * 7) % 3)).clamp(2, 11);
      final x = cx * _p;
      _px(canvas, x, 0, 2, roofH.toDouble(), const Color(0xFF1B0E13));
      _px(canvas, x, (roofH - 1) * _p, 2, 1, const Color(0xFF2B141A));
      if (cx % 6 == 0) {
        _px(canvas, x, roofH * _p, 1, 2, const Color(0xFF160B0F));
      }
    }

    // Embedded glowing Glowstone clusters + gently swaying crimson weeping vines.
    for (var i = 0; i < 12; i++) {
      final nx = 0.05 + i * 0.084;
      final sx = _snap(w * nx);
      final roofBase = (5 + ((i * 5) % 4)) * _p;

      if (i % 2 == 0) {
        final glow = 0.62 + 0.30 * math.sin(t * 1.4 + i * 1.3).abs();
        final gsHalo = Rect.fromCircle(
          center: Offset(sx + 2 * _p, roofBase),
          radius: 16 * _p,
        );
        canvas.drawRect(
          gsHalo,
          Paint()
            ..shader = RadialGradient(
              colors: <Color>[
                const Color(0xFFF0AD4E).withValues(alpha: 0.14 * glow),
                Colors.transparent,
              ],
            ).createShader(gsHalo),
        );
        _px(canvas, sx, roofBase - 2 * _p, 4, 2, const Color(0xFF9C6628));
        _px(
          canvas,
          sx + _p,
          roofBase - _p,
          2,
          2,
          const Color(0xFFF4C462).withValues(alpha: 0.78 + 0.2 * glow),
        );
        _px(canvas, sx + _p, roofBase - _p, 1, 1, const Color(0xFFFFEAB0));
      }

      // Hanging crimson weeping vines swaying gently from ceiling cracks.
      if (i % 3 != 1) {
        final vineLen = 4 + (i * 3) % 7;
        for (var v = 0; v < vineLen; v++) {
          final sway = (v >= 3 && math.sin(t * 0.9 + i * 1.7 + v * 0.5) > 0.35)
              ? _p
              : 0.0;
          _px(
            canvas,
            sx + 3 * _p + sway,
            roofBase + v * _p,
            1,
            1,
            v.isEven ? const Color(0xFF7D212A) : const Color(0xFFA82F38),
          );
        }
      }
    }

    // 2 Animated Cascading Lavafalls pouring from ceiling cracks to the lava sea!
    for (final (nx, widthCells) in const <(double, int)>[(0.13, 2), (0.86, 2)]) {
      final lx = _snap(w * nx);
      final topY = 5 * _p;
      final fallH = ((groundY - topY) / _p).ceil();
      // Soft volcanic column glow
      canvas.drawRect(
        Rect.fromLTWH(lx - 4 * _p, topY, (widthCells + 8) * _p, groundY - topY),
        Paint()
          ..shader = LinearGradient(
            colors: <Color>[
              Colors.transparent,
              const Color(0xFFE06022).withValues(alpha: 0.14),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromLTWH(lx - 4 * _p, topY, (widthCells + 8) * _p, groundY - topY),
          ),
      );
      _px(
        canvas,
        lx,
        topY,
        widthCells.toDouble(),
        fallH.toDouble(),
        const Color(0xFFB54119),
      );
      final scroll = (t * 8.0).floor();
      for (var row = 0; row < fallH; row += 3) {
        final r = (row + scroll) % fallH;
        _px(
          canvas,
          lx + ((row % 2 == 0) ? 0 : _p),
          topY + r * _p,
          1,
          2,
          (row % 6 == 0) ? const Color(0xFFF7CE65) : const Color(0xFFE6772E),
        );
      }
    }

    // 2 Handcrafted Aseprite Ghasts drifting lazily across the upper cavern!
    final ghastFarX = ((1.0 - (t * 0.0085 + 0.18) % 1.0) * (w + 90)) - 45;
    final ghastFarY = h * 0.28 + math.sin(t * 0.75 + 1.2) * 3 * _p;
    _drawSpriteBottomCentered(
      canvas,
      PixelArtAssets.biomeNetherGhast,
      centerX: ghastFarX,
      bottomY: ghastFarY,
      scale: 1.55,
      frameIndex: _animFrame(PixelArtAssets.biomeNetherGhast, t + 0.6),
      opacity: 0.56,
      flipH: true,
    );

    final ghastNearX = (((t * 0.0115 + 0.35) % 1.0) * (w + 110)) - 55;
    final ghastNearY = h * 0.42 + math.sin(t * 0.9) * 3.5 * _p;
    _drawSpriteBottomCentered(
      canvas,
      PixelArtAssets.biomeNetherGhast,
      centerX: ghastNearX,
      bottomY: ghastNearY,
      scale: 2.15,
      frameIndex: _animFrame(PixelArtAssets.biomeNetherGhast, t),
      opacity: 0.86,
    );

    // Grand Nether Fortress viaduct bridge + left Bastion keep silhouette!
    final fortY = groundY - 23 * _p;
    final fortStart = _snap(w * 0.17);
    final fortW = ((w * 0.50) / _p).floor();
    // Left Bastion turret rising behind bridge
    final keepX = _snap(w * 0.19);
    _px(canvas, keepX, fortY - 12 * _p, 11, 35, const Color(0xFF1D1016));
    _px(canvas, keepX - _p, fortY - 14 * _p, 13, 3, const Color(0xFF28151C));
    for (var c = 0; c < 13; c += 3) {
      _px(canvas, keepX - _p + c * _p, fortY - 16 * _p, 2, 2, const Color(0xFF28151C));
    }
    // Glowing fortress slit windows
    _px(canvas, keepX + 3 * _p, fortY - 8 * _p, 2, 4, const Color(0xFFE07A2F).withValues(alpha: 0.62));
    _px(canvas, keepX + 7 * _p, fortY - 8 * _p, 2, 4, const Color(0xFFE07A2F).withValues(alpha: 0.48));

    // Arched Nether Brick viaduct deck + crenellations + Blaze braziers
    _px(canvas, fortStart, fortY, fortW.toDouble(), 3, const Color(0xFF26141B));
    _px(canvas, fortStart, fortY, fortW.toDouble(), 1, const Color(0xFF341C24));
    for (var x = 0; x < fortW; x += 10) {
      _px(canvas, fortStart + x * _p, fortY + 3 * _p, 3, 20, const Color(0xFF1E1016));
      // Arch shoulders
      _px(canvas, fortStart + (x + 3) * _p, fortY + 3 * _p, 1, 2, const Color(0xFF221218));
      if (x >= 10) {
        _px(canvas, fortStart + (x - 1) * _p, fortY + 3 * _p, 1, 2, const Color(0xFF221218));
      }
      if (x % 20 == 10) {
        _px(canvas, fortStart + x * _p, fortY - 2 * _p, 3, 2, const Color(0xFF2F1921));
        final flameH = 1.0 + (math.sin(t * 3.8 + x) > 0 ? 1.0 : 0.0);
        _px(
          canvas,
          fortStart + (x + 1) * _p,
          fortY - (2 + flameH) * _p,
          1,
          flameH,
          const Color(0xFFF5AC47),
        );
      }
    }

    // Distant volcanic ridge + jagged Basalt Delta columns.
    _paintHillBand(
      canvas,
      w,
      groundY,
      baseHeightCells: 11,
      ampCells: 5,
      freq: 0.009,
      phase: 0.9,
      color: const Color(0xFF241319),
    );
    _paintHillBand(
      canvas,
      w,
      groundY,
      baseHeightCells: 6,
      ampCells: 3,
      freq: 0.014,
      phase: 2.6,
      color: const Color(0xFF1C0E13),
    );
    for (final (bx, bh) in const <(double, double)>[
      (0.03, 15),
      (0.24, 12),
      (0.27, 16),
      (0.55, 11),
      (0.91, 17),
      (0.95, 13),
    ]) {
      _px(canvas, w * bx, groundY - bh * _p, 3, bh, const Color(0xFF24232B));
      _px(canvas, w * bx, groundY - bh * _p, 1, bh, const Color(0xFF33313D));
    }

    // Handcrafted Aseprite Crimson & Warped Giant Fungi forest!
    _paintFoliageRow(canvas, w, groundY, const <(double, double, int, bool)>[
      (0.06, 2.8, 2, false),
      (0.16, 2.3, 3, true),
      (0.42, 2.5, 2, true),
      (0.89, 2.6, 3, false),
      (0.96, 2.2, 2, true),
    ]);

    // 2 Handcrafted Aseprite Soul-Fire Blackstone Shrines (turquoise Soul Fire!)
    for (final sx in <double>[0.29, 0.59]) {
      final sRect = _drawSpriteBottomCentered(
        canvas,
        PixelArtAssets.biomeEndNetherProps,
        centerX: w * sx,
        bottomY: groundY + 3,
        scale: 1.9,
        frameIndex: 3, // Blackstone Soul-Fire Shrine Pillar
      );
      if (sRect != null) {
        final flick = 0.75 + 0.25 * math.sin(t * 3.4 + sx * 12);
        final soulGlow = Rect.fromCircle(
          center: Offset(sRect.center.dx, sRect.top + sRect.height * 0.26),
          radius: 30,
        );
        canvas.drawRect(
          soulGlow,
          Paint()
            ..shader = RadialGradient(
              colors: <Color>[
                const Color(0xFF4CE5D8).withValues(alpha: 0.22 * flick),
                Colors.transparent,
              ],
            ).createShader(soulGlow),
        );
      }
    }

    // Gilded Blackstone Brazier Totem near center.
    final bRect = _drawSpriteBottomCentered(
      canvas,
      PixelArtAssets.biomeVillageProps,
      centerX: w * 0.49,
      bottomY: groundY + 3,
      scale: 2.1,
      frameIndex: 4,
    );
    if (bRect != null) {
      final flick = 0.72 + 0.28 * math.sin(t * 4.0);
      final glow = Rect.fromCircle(
        center: Offset(bRect.center.dx, bRect.top + bRect.height * 0.35),
        radius: 26,
      );
      canvas.drawRect(
        glow,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              const Color(0xFFFF9638).withValues(alpha: 0.24 * flick),
              Colors.transparent,
            ],
          ).createShader(glow),
      );
    }

    // Animated 6-frame Aseprite Ruined Nether Portal (hero landmark — ONLY HERE)!
    final portalRect = _drawSpriteBottomCentered(
      canvas,
      PixelArtAssets.biomeRuinedPortal,
      centerX: w * 0.74,
      bottomY: groundY + 4,
      scale: 2.95,
      frameIndex: _animFrame(
        PixelArtAssets.biomeRuinedPortal,
        t,
        speed: broadcasting ? 1.4 : 1.0,
      ),
    );
    if (portalRect != null) {
      final pulse = 0.5 + 0.5 * math.sin(t * (broadcasting ? 3.5 : 2.0));
      final aura = Rect.fromCircle(
        center: Offset(
          portalRect.center.dx,
          portalRect.top + portalRect.height * 0.54,
        ),
        radius: broadcasting ? 66.0 : 42.0,
      );
      canvas.drawRect(
        aura,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              const Color(0xFFA854F0).withValues(
                alpha: (broadcasting ? 0.32 : 0.16) + 0.08 * pulse,
              ),
              Colors.transparent,
            ],
          ).createShader(aura),
      );
    }

    // Foreground Crimson Nylium & Basalt cliff + bubbling molten lava sea.
    _px(canvas, 0, groundY, w / _p + 1, 3, const Color(0xFF63222B));
    _px(canvas, 0, groundY + 3 * _p, w / _p + 1, 5, const Color(0xFF2B1318));
    _px(
      canvas,
      0,
      groundY + 8 * _p,
      w / _p + 1,
      _deepCellsFrom(h, groundY + 8 * _p),
      const Color(0xFF1A0D10),
    );

    final lavaY = groundY + 10 * _p;
    _px(canvas, 0, lavaY, w / _p + 1, 7, const Color(0xFFBA451B));
    _px(canvas, 0, lavaY + _p, w / _p + 1, 5, const Color(0xFFD96523));
    for (var i = 0; i < 9; i++) {
      final lx = _snap(
        w * (0.04 + i * 0.11) + math.sin(t * 0.65 + i * 1.3) * 2 * _p,
      );
      _px(canvas, lx, lavaY + 2 * _p, 5, 2, const Color(0xFF28191D));
      final glint = 0.38 + 0.45 * math.sin(t * 1.9 + i * 1.5).abs();
      _px(
        canvas,
        lx + 6 * _p,
        lavaY + (1 + (i % 3)) * _p,
        3,
        1,
        const Color(0xFFF7C95B).withValues(alpha: glint),
      );
    }

    // 2 Cute Handcrafted Aseprite Nether Striders bobbing happily on the lava!
    final strider1X = w * 0.34 + math.sin(t * 0.45) * 10 * _p;
    final strider1Bob = math.sin(t * 2.2) * 1.5;
    _drawSpriteBottomCentered(
      canvas,
      PixelArtAssets.biomeEndNetherProps,
      centerX: strider1X,
      bottomY: lavaY + 5 * _p + strider1Bob,
      scale: 1.25,
      frameIndex: 2, // Nether Strider
    );
    final strider2X = w * 0.83 + math.cos(t * 0.38 + 1.1) * 9 * _p;
    final strider2Bob = math.sin(t * 2.0 + 1.7) * 1.5;
    _drawSpriteBottomCentered(
      canvas,
      PixelArtAssets.biomeEndNetherProps,
      centerX: strider2X,
      bottomY: lavaY + 5 * _p + strider2Bob,
      scale: 1.15,
      frameIndex: 2,
      flipH: true,
    );

    _paintMotes(
      canvas,
      size,
      t,
      const Color(0xFFF28B3C),
      const Color(0xFF4CE5D8),
    );
  }

  // ===========================================================================
  // 6. END BOŞLUĞU — Cosmic End Abyss, Ender Dragon, Obsidian Pillars, End City,
  //    Endermen, Floating Chorus Islands & End Exit Fountain (ZERO clouds!)
  // ===========================================================================
  void _paintEndVoid(
    Canvas canvas,
    Size size,
    double t,
    bool broadcasting,
  ) {
    final w = size.width;
    final h = size.height;
    final groundY = _groundY(h);

    // Authentic deep End Void cosmic abyss (NO clouds!).
    final sky = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: const <double>[0.0, 0.45, 0.80, 1.0],
      colors: <Color>[
        const Color(0xFF07060E),
        const Color(0xFF100C1E),
        const Color(0xFF1B1432),
        const Color(0xFF0C0A16),
      ],
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..shader = sky);

    // Authentic Minecraft End Sky cosmic static grain / distant starlight flecks!
    for (var i = 0; i < 64; i++) {
      final sx = _snap(w * (((i * 137 + 19) % 1000) / 1000.0));
      final sy = _snap(h * (((i * 83 + 11) % 720) / 1000.0));
      final shimmer = 0.08 + 0.14 * math.sin(t * 0.9 + i * 0.7).abs();
      final col = (i % 3 == 0)
          ? const Color(0xFF7B52B8)
          : (i % 3 == 1 ? const Color(0xFF3E6B8C) : const Color(0xFFA678E6));
      _px(canvas, sx, sy, (i % 5 == 0) ? 2 : 1, 1, col.withValues(alpha: shimmer));
    }

    _paintStars(canvas, size, t, const Color(0xFFDCC8FA), 0.44);
    _paintShootingStar(canvas, size, t, 9.6, const Color(0xFFE7B8FF));

    // Distant cosmic horizon glow behind the End islands (no cloud shapes).
    final voidGlow = RadialGradient(
      center: const Alignment(0.15, 0.78),
      radius: 0.85,
      colors: <Color>[
        const Color(0xFF6B3AA8).withValues(alpha: 0.16),
        const Color(0xFF3B1F6B).withValues(alpha: 0.06),
        Colors.transparent,
      ],
    ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, Paint()..shader = voidGlow);

    // Animated 6-frame Handcrafted Aseprite Ender Dragon gliding across the Void!
    final dragonU = (t * 0.024 + 0.15) % 1.0;
    final dragonX = dragonU * (w + 220) - 110;
    final dragonY = h * 0.24 + math.sin(dragonU * math.pi * 2) * 14 * _p;
    _drawSpriteBottomCentered(
      canvas,
      PixelArtAssets.biomeEndDragon,
      centerX: dragonX,
      bottomY: dragonY,
      scale: 2.1,
      frameIndex: _animFrame(PixelArtAssets.biomeEndDragon, t, speed: 1.05),
      opacity: 0.88,
    );

    // Upper-left Floating End Gateway Island (bedrock mini-portal glowing in sky!).
    final gwBob = math.sin(t * 0.7 + 1.8) * 2 * _p;
    final gwY = _snap(h * 0.36 + gwBob);
    final gwX = _snap(w * 0.13);
    _paintEndIsland(canvas, gwX, gwY, widthCells: 18);
    // Tiny End Gateway bedrock portal + starry violet core
    _px(canvas, gwX - 2 * _p, gwY - 8 * _p, 4, 1, const Color(0xFF4C4C56));
    _px(canvas, gwX - 2 * _p, gwY - 4 * _p, 4, 1, const Color(0xFF4C4C56));
    _px(canvas, gwX - _p, gwY - 9 * _p, 2, 1, const Color(0xFF373740));
    _px(canvas, gwX - _p, gwY - 3 * _p, 2, 1, const Color(0xFF373740));
    final gwPulse = 0.65 + 0.35 * math.sin(t * 2.2);
    _px(canvas, gwX - _p, gwY - 7 * _p, 2, 3, const Color(0xFF1A0F30));
    _px(
      canvas,
      gwX - _p,
      gwY - 6 * _p,
      1,
      1,
      const Color(0xFF88F2E8).withValues(alpha: gwPulse),
    );
    _px(
      canvas,
      gwX,
      gwY - 7 * _p,
      1,
      1,
      const Color(0xFFD580FF).withValues(alpha: gwPulse),
    );
    _drawSpriteBottomCentered(
      canvas,
      PixelArtAssets.biomeFoliage,
      centerX: gwX + 6 * _p,
      bottomY: gwY + 2,
      scale: 1.5,
      frameIndex: 4,
    );

    // Upper-Right Multi-Spire Purpur End City + Bridge + Floating End Ship!
    final cityBob = math.sin(t * 0.78) * 2 * _p;
    final cityBaseY = groundY - 24 * _p + cityBob;
    _paintEndIsland(canvas, w * 0.89, cityBaseY, widthCells: 26);
    // Purpur bridge connecting twin spires with glowing End Rods
    final brX = _snap(w * 0.83);
    _px(canvas, brX, cityBaseY - 12 * _p, 14, 2, const Color(0xFF7B508E));
    _px(canvas, brX, cityBaseY - 13 * _p, 14, 1, const Color(0xFFA572BA));
    _px(canvas, brX + 3 * _p, cityBaseY - 15 * _p, 1, 2, const Color(0xFFF5ECFF));
    _px(canvas, brX + 10 * _p, cityBaseY - 15 * _p, 1, 2, const Color(0xFFF5ECFF));
    _drawSpriteBottomCentered(
      canvas,
      PixelArtAssets.biomeVillageProps,
      centerX: w * 0.84,
      bottomY: cityBaseY + 1,
      scale: 2.0,
      frameIndex: 5, // Purpur End City Spire
    );
    _drawSpriteBottomCentered(
      canvas,
      PixelArtAssets.biomeVillageProps,
      centerX: w * 0.92,
      bottomY: cityBaseY - 2 * _p,
      scale: 2.55,
      frameIndex: 5,
      flipH: true,
    );
    _paintEndShip(canvas, w * 0.74, groundY - 40 * _p - cityBob * 0.8);

    // Iconic End Boss Arena: Distant towering Obsidian Pillars w/ pulsing Crystals!
    for (final (pxNorm, pillarH) in const <(double, double)>[
      (0.28, 34),
      (0.55, 38),
    ]) {
      final ox = _snap(w * pxNorm);
      final topY = groundY - pillarH * _p;
      _px(canvas, ox - 2 * _p, topY, 5, pillarH, const Color(0xFF141022));
      _px(canvas, ox - 2 * _p, topY, 1, pillarH, const Color(0xFF281E42));
      _px(canvas, ox - _p, topY - _p, 3, 1, const Color(0xFF474754));
      final cryBob = math.sin(t * 2.0 + pxNorm * 9) * _p;
      final cryY = topY - 4 * _p + cryBob;
      final cryHalo = Rect.fromCircle(
        center: Offset(ox + 0.5 * _p, cryY + _p),
        radius: 13 * _p,
      );
      canvas.drawRect(
        cryHalo,
        Paint()
          ..shader = RadialGradient(
            colors: <Color>[
              const Color(0xFFDF66FF).withValues(alpha: 0.22),
              Colors.transparent,
            ],
          ).createShader(cryHalo),
      );
      _px(canvas, ox - _p, cryY, 3, 3, const Color(0xFFBA4AE8));
      _px(canvas, ox, cryY + _p, 1, 1, const Color(0xFFFFE5FF));
    }

    // Mid-void bobbing floating End-Stone islands topped with Chorus Trees!
    final bob1 = math.sin(t * 0.72 + 0.5) * 2 * _p;
    final bob2 = math.sin(t * 0.68 + 2.4) * 2.5 * _p;

    final isl1Y = groundY - 12 * _p + bob1;
    _paintEndIsland(canvas, w * 0.10, isl1Y, widthCells: 26);
    _drawSpriteBottomCentered(
      canvas,
      PixelArtAssets.biomeFoliage,
      centerX: w * 0.06,
      bottomY: isl1Y + 2,
      scale: 2.2,
      frameIndex: 4,
    );
    _drawSpriteBottomCentered(
      canvas,
      PixelArtAssets.biomeFoliage,
      centerX: w * 0.14,
      bottomY: isl1Y + 2,
      scale: 1.85,
      frameIndex: 4,
      flipH: true,
    );

    final isl2Y = groundY - 9 * _p + bob2;
    _paintEndIsland(canvas, w * 0.40, isl2Y, widthCells: 24);
    _drawSpriteBottomCentered(
      canvas,
      PixelArtAssets.biomeFoliage,
      centerX: w * 0.37,
      bottomY: isl2Y + 2,
      scale: 2.25,
      frameIndex: 4,
      flipH: true,
    );

    // Foreground main End-Stone island ground.
    _paintEndMainGround(canvas, w, h, groundY);

    // 2 Handcrafted Aseprite Caged Obsidian Pillars framing the main island!
    for (final (ox, sc) in const <(double, double)>[(0.21, 2.3), (0.83, 2.15)]) {
      final pRect = _drawSpriteBottomCentered(
        canvas,
        PixelArtAssets.biomeEndNetherProps,
        centerX: w * ox,
        bottomY: groundY + 4,
        scale: sc,
        frameIndex: 0, // Caged Obsidian Pillar w/ End Crystal
      );
      if (pRect != null) {
        final pulse = 0.65 + 0.35 * math.sin(t * 2.1 + ox * 7);
        final cGlow = Rect.fromCircle(
          center: Offset(pRect.center.dx, pRect.top + pRect.height * 0.16),
          radius: 26,
        );
        canvas.drawRect(
          cGlow,
          Paint()
            ..shader = RadialGradient(
              colors: <Color>[
                const Color(0xFFE86CFF).withValues(alpha: 0.24 * pulse),
                Colors.transparent,
              ],
            ).createShader(cGlow),
        );
      }
    }

    // Chorus flora along the main island edges.
    _drawSpriteBottomCentered(
      canvas,
      PixelArtAssets.biomeFoliage,
      centerX: w * 0.04,
      bottomY: groundY + 3,
      scale: 2.1,
      frameIndex: 4,
    );
    _drawSpriteBottomCentered(
      canvas,
      PixelArtAssets.biomeFoliage,
      centerX: w * 0.94,
      bottomY: groundY + 3,
      scale: 2.25,
      frameIndex: 4,
      flipH: true,
    );

    // 2 Handcrafted Aseprite Endermen standing silently with glowing eyes!
    _drawSpriteBottomCentered(
      canvas,
      PixelArtAssets.biomeEndNetherProps,
      centerX: w * 0.48,
      bottomY: groundY + 4,
      scale: 1.75,
      frameIndex: 1, // Enderman holding End Stone
    );
    _drawSpriteBottomCentered(
      canvas,
      PixelArtAssets.biomeEndNetherProps,
      centerX: w * 0.89,
      bottomY: groundY + 4,
      scale: 1.65,
      frameIndex: 1,
      flipH: true,
    );

    // Animated 6-frame Aseprite End Exit Fountain (Dragon Egg + 4 torches + 2 End Crystals)!
    final fountainRect = _drawSpriteBottomCentered(
      canvas,
      PixelArtAssets.biomeEndFountain,
      centerX: w * 0.68,
      bottomY: groundY + 4,
      scale: 2.95,
      frameIndex: _animFrame(
        PixelArtAssets.biomeEndFountain,
        t,
        speed: broadcasting ? 1.35 : 1.0,
      ),
    );
    if (fountainRect != null) {
      final leftCrystal = Offset(
        fountainRect.left + fountainRect.width * 0.125,
        fountainRect.top + fountainRect.height * 0.21,
      );
      final rightCrystal = Offset(
        fountainRect.left + fountainRect.width * 0.875,
        fountainRect.top + fountainRect.height * 0.21,
      );
      final eggTop = Offset(
        fountainRect.center.dx,
        fountainRect.top + fountainRect.height * 0.35,
      );
      final pulse = 0.5 + 0.5 * math.sin(t * (broadcasting ? 3.2 : 1.8));
      for (final c in <Offset>[leftCrystal, rightCrystal]) {
        final glow = Rect.fromCircle(
          center: c,
          radius: broadcasting ? 28.0 : 18.0,
        );
        canvas.drawRect(
          glow,
          Paint()
            ..shader = RadialGradient(
              colors: <Color>[
                const Color(0xFFE86CFF).withValues(
                  alpha: (broadcasting ? 0.38 : 0.22) + 0.10 * pulse,
                ),
                Colors.transparent,
              ],
            ).createShader(glow),
        );
      }
      if (broadcasting) {
        for (final c in <Offset>[leftCrystal, rightCrystal]) {
          const steps = 14;
          for (var s = 0; s <= steps; s++) {
            final frac = s / steps;
            final bx = c.dx + (eggTop.dx - c.dx) * frac;
            final by =
                c.dy +
                (eggTop.dy - c.dy) * frac +
                math.sin(frac * math.pi * 2 - t * 5.0) * _p * 0.7;
            final a =
                0.28 + 0.42 * math.sin((frac - t * 1.6) * math.pi * 2).abs();
            _px(
              canvas,
              bx,
              by,
              1,
              1,
              const Color(0xFFF39EFF).withValues(alpha: a),
            );
          }
        }
      }
    }

    _paintMotes(
      canvas,
      size,
      t,
      const Color(0xFFC896F5),
      const Color(0xFFF0C4FF),
    );
  }

  // ===========================================================================
  // SHARED SCENIC & ENVIRONMENT HELPERS
  // ===========================================================================

  void _paintFoliageRow(
    Canvas canvas,
    double w,
    double groundY,
    List<(double, double, int, bool)> specs,
  ) {
    for (final (nx, sc, idx, flip) in specs) {
      _drawSpriteBottomCentered(
        canvas,
        PixelArtAssets.biomeFoliage,
        centerX: w * nx,
        bottomY: groundY + 3,
        scale: sc,
        frameIndex: idx,
        flipH: flip,
      );
    }
  }

  /// Swaying golden wheat patch + fence kept strictly inside `[startX, endX]`.
  void _paintWheatPatch(
    Canvas canvas, {
    required double startX,
    required double endX,
    required double groundY,
    required double t,
    required Color fenceColor,
  }) {
    final x0 = _snap(startX);
    final count = (((endX - startX) / (2 * _p)).floor()).clamp(4, 24);
    for (var i = 0; i < count; i++) {
      final sway = math.sin(t * 1.2 + i * 0.45) > 0.35 ? 1.0 : 0.0;
      final wx = x0 + i * 2 * _p;
      _px(
        canvas,
        wx,
        groundY - (2 + sway) * _p,
        1,
        2 + sway,
        i.isEven ? const Color(0xFFD1AA4A) : const Color(0xFFE6BF5C),
      );
      _px(canvas, wx + _p, groundY - 2 * _p, 1, 2, const Color(0xFFA88332));
    }
    final posts = ((count * 2) / 3).floor().clamp(3, 18);
    for (var i = 0; i < posts; i++) {
      _px(canvas, x0 + i * 3 * _p, groundY - 3 * _p, 1, 3, fenceColor);
    }
    _px(canvas, x0, groundY - 2 * _p, (posts * 3 - 2).toDouble(), 1, fenceColor);
  }

  /// Renders a clean recessed reflective river/lake with shore reeds, lily pads,
  /// and our handcrafted Aseprite Arched Oak & Mossy Stone Bridge spanning it!
  void _paintWaterWithBridge(
    Canvas canvas,
    double w,
    double groundY, {
    required double startFrac,
    required double widthFrac,
    required double t,
    required Color waterDark,
    required Color waterMid,
    required Color glintColor,
    required bool lilyPads,
  }) {
    // Derive water opening strictly from the bridge's inner mossy stone piers
    // (sprite 64x24: left pier x=4..13, open arch x=14..49, right pier x=50..59)
    // so both bridge approaches always rest cleanly on grassy banks at any width!
    final bridgeCenter = _snap(w * (startFrac + widthFrac * 0.5));
    final bridgeScale = ((w * widthFrac) / 54.0).clamp(1.6, 3.1);
    final effectiveBridgeScale = bridgeScale * _layoutScale;
    final x0 = _snap(bridgeCenter - 19.0 * effectiveBridgeScale);
    final x1 = _snap(bridgeCenter + 19.0 * effectiveBridgeScale);
    final cells = (((x1 - x0) / _p).round()).clamp(8, 64);

    _px(canvas, x0, groundY, cells.toDouble(), 3, waterDark);
    _px(canvas, x0 + _p, groundY + _p, (cells - 2).toDouble(), 2, waterMid);

    for (var i = 0; i < 6; i++) {
      final span = (cells - 5).clamp(1, 64);
      final rx =
          x0 + ((i * 11 + (math.sin(t * 0.9 + i) * 2).round()) % span + 2) * _p;
      _px(
        canvas,
        rx,
        groundY + (i % 2 + 1) * _p,
        3,
        1,
        glintColor.withValues(alpha: 0.28 + 0.20 * math.sin(t * 1.6 + i).abs()),
      );
    }
    if (lilyPads && cells >= 14) {
      _px(canvas, x0 + 3 * _p, groundY + _p, 2, 1, const Color(0xFF2C6B4B));
      _px(
        canvas,
        x0 + (cells - 6) * _p,
        groundY + 2 * _p,
        2,
        1,
        const Color(0xFF2C6B4B),
      );
    }

    // Reeds tucked neatly on the grassy shores just outside the bridge ramps.
    const reedDark = Color(0xFF214A34);
    const reedTip = Color(0xFF427D52);
    for (final rx in <double>[
      _snap(bridgeCenter - 32.5 * effectiveBridgeScale),
      _snap(bridgeCenter + 31.5 * effectiveBridgeScale),
    ]) {
      _px(canvas, rx, groundY - 4 * _p, 1, 4, reedDark);
      _px(canvas, rx, groundY - 5 * _p, 1, 1, reedTip);
      _px(canvas, rx + _p, groundY - 3 * _p, 1, 3, reedDark);
    }

    // Handcrafted Aseprite Arched Oak & Mossy Cobblestone Bridge spanning bank-to-bank!
    final bridgeRect = _drawSpriteBottomCentered(
      canvas,
      PixelArtAssets.biomeBridge,
      centerX: bridgeCenter,
      bottomY: groundY + 3 * _p,
      scale: bridgeScale,
      frameIndex: 0,
    );

    // Soft warm glow halos on the two bridge post lanterns!
    if (bridgeRect != null) {
      final flick = 0.78 + 0.22 * math.sin(t * 4.0);
      for (final frac in <double>[0.24, 0.76]) {
        final lanternPt = Offset(
          bridgeRect.left + bridgeRect.width * frac,
          bridgeRect.top + bridgeRect.height * 0.34,
        );
        final halo = Rect.fromCircle(center: lanternPt, radius: 14);
        canvas.drawRect(
          halo,
          Paint()
            ..shader = RadialGradient(
              colors: <Color>[
                const Color(0xFFFFCA6B).withValues(alpha: 0.24 * flick),
                Colors.transparent,
              ],
            ).createShader(halo),
        );
      }
    }
  }

  void _paintBirds(
    Canvas canvas,
    double w,
    double groundY,
    double t, {
    required int count,
    required Color color,
  }) {
    for (var i = 0; i < count; i++) {
      final bx = _snap(((t * 0.011 + 0.14 + i * 0.045) % 1.15 - 0.08) * w);
      final by = _snap(
        groundY - (30 - i * 3) * _p + math.sin(t * 0.9 + i) * 2 * _p,
      );
      final wingUp = math.sin(t * 3.8 + i * 1.8) > 0;
      _px(canvas, bx, by, 1, 1, color);
      _px(canvas, bx - _p, by + (wingUp ? -_p : 0), 1, 1, color);
      _px(canvas, bx + _p, by + (wingUp ? -_p : 0), 1, 1, color);
    }
  }

  void _paintEndShip(Canvas canvas, double cx, double y) {
    final sx = _snap(cx);
    _px(canvas, sx, y, 10, 2, const Color(0xFF5B3B6E));
    _px(canvas, sx + _p, y - _p, 8, 1, const Color(0xFF8B7994));
    _px(canvas, sx + 4 * _p, y - 5 * _p, 1, 4, const Color(0xFF5B3B6E));
    _px(canvas, sx + 3 * _p, y - 4 * _p, 3, 1, const Color(0xFFC9A6E0));
  }

  void _paintEndIsland(
    Canvas canvas,
    double cx,
    double y, {
    required int widthCells,
  }) {
    final x = _snap(cx - widthCells * _p / 2);
    _px(canvas, x, y, widthCells.toDouble(), 2, const Color(0xFF6B6652));
    _px(
      canvas,
      x + 2 * _p,
      y + 2 * _p,
      (widthCells - 4).toDouble(),
      2,
      const Color(0xFF47433A),
    );
    _px(
      canvas,
      x + 5 * _p,
      y + 4 * _p,
      (widthCells - 10).toDouble(),
      2,
      const Color(0xFF28232E),
    );
  }

  void _paintEndMainGround(Canvas canvas, double w, double h, double groundY) {
    _px(canvas, 0, groundY, w / _p + 1, 3, const Color(0xFF66614D));
    _px(canvas, 0, groundY + 3 * _p, w / _p + 1, 5, const Color(0xFF4A463B));
    _px(
      canvas,
      0,
      groundY + 8 * _p,
      w / _p + 1,
      _deepCellsFrom(h, groundY + 8 * _p),
      const Color(0xFF26222B),
    );
    for (var i = 0; i < 30; i++) {
      final sx = _snap(((i * 73 + 17) % 100) / 100.0 * w);
      _px(
        canvas,
        sx,
        groundY + (i % 3) * _p,
        2,
        1,
        const Color(0xFF7B765E).withValues(alpha: 0.45),
      );
    }
  }

  void _paintMountainRange(
    Canvas canvas,
    double w,
    double groundY, {
    required List<(double, int)> peaks,
    required Color bodyColor,
    required Color shadeColor,
    required Color snowColor,
  }) {
    for (final (nx, heightCells) in peaks) {
      final cx = _snap(w * nx);
      for (var row = 0; row < heightCells; row++) {
        final halfW = (heightCells - row);
        final y = groundY - (row + 1) * _p;
        final isSnow = row >= heightCells - 6;
        _px(
          canvas,
          cx - halfW * _p,
          y,
          halfW.toDouble(),
          1,
          isSnow ? snowColor : bodyColor,
        );
        _px(
          canvas,
          cx,
          y,
          halfW.toDouble(),
          1,
          isSnow ? snowColor.withValues(alpha: 0.72) : shadeColor,
        );
      }
    }
  }

  void _paintHillBand(
    Canvas canvas,
    double w,
    double groundY, {
    required int baseHeightCells,
    required int ampCells,
    required double freq,
    required double phase,
    required Color color,
  }) {
    final paint = Paint()..color = color;
    final step = _p * 3;
    for (var x = 0.0; x < w; x += step) {
      final hCells =
          baseHeightCells +
          (math.sin(x * freq + phase) * ampCells).round() +
          (math.cos(x * freq * 1.9 + phase) * (ampCells ~/ 2)).round();
      final rectH = math.max(2, hCells) * _p;
      canvas.drawRect(
        Rect.fromLTWH(x, groundY - rectH, step + 0.5, rectH + _p),
        paint,
      );
    }
  }

  /// Layered grass, dirt, stone, tiny wildflowers & deep underground Minecraft
  /// ore specks (coal / iron / emerald) while keeping the lake zone clean.
  void _paintGrassTerrain(
    Canvas canvas,
    double w,
    double h,
    double groundY, {
    required Color topColor,
    required Color edgeColor,
    required Color dirtColor,
    required Color deepColor,
    required double lakeStartFrac,
    required double lakeEndFrac,
    required bool wildflowers,
  }) {
    final cols = w / _p + 1;
    _px(canvas, 0, groundY, cols, 2, topColor);
    _px(canvas, 0, groundY + 2 * _p, cols, 1, edgeColor);
    _px(canvas, 0, groundY + 3 * _p, cols, 5, dirtColor);
    _px(
      canvas,
      0,
      groundY + 8 * _p,
      cols,
      _deepCellsFrom(h, groundY + 8 * _p),
      deepColor,
    );

    // Subtle grass tufts & tiny Minecraft wildflowers strictly on solid grass!
    const flowerColors = <Color>[
      Color(0xFFD95757), // poppy red
      Color(0xFFF0C859), // dandelion yellow
      Color(0xFF66B2F0), // cornflower blue
    ];
    for (var i = 0; i < 24; i++) {
      final frac = ((i * 41 + 7) % 94 + 3) / 100.0;
      if (frac > lakeStartFrac - 0.02 && frac < lakeEndFrac + 0.02) continue;
      final fx = _snap(w * frac);
      _px(canvas, fx, groundY - _p, 1, 1, topColor);
      if (wildflowers && i % 3 == 0) {
        _px(canvas, fx, groundY - 2 * _p, 1, 1, flowerColors[i % 3]);
      }
    }

    // Deep underground subtle stone & Minecraft ore specks below groundY + 9*_p.
    for (var i = 0; i < 20; i++) {
      final ox = _snap(((i * 67 + 13) % 96 + 2) / 100.0 * w);
      final oy = groundY + (10 + (i * 5) % 9) * _p;
      final oreColor = switch (i % 7) {
        0 => const Color(0xFF39B5C2).withValues(alpha: 0.42), // diamond/prismarine glint
        2 => const Color(0xFF42A86E).withValues(alpha: 0.38), // emerald glint
        4 => const Color(0xFF9C846E).withValues(alpha: 0.34), // iron ore
        _ => const Color(0xFF282B33).withValues(alpha: 0.55), // stone pebble
      };
      _px(canvas, ox, oy, 2, 1, oreColor);
    }
  }

  /// Renders a rich two-depth parallax deck of handcrafted Aseprite billowing
  /// cumulus & stratus clouds filling the upper sky calmly with biome tinting.
  void _paintAsepriteCloudDeck(
    Canvas canvas,
    Size size,
    double t, {
    required Color farTint,
    required Color nearTint,
    required double farOpacity,
    required double nearOpacity,
  }) {
    final ui.Image? img = PixelSpriteCache.instance.getCached(
      PixelArtAssets.biomeClouds.assetPath,
    );
    if (img == null) return;

    // 7 staggered clouds across 2 parallax altitude layers (far slow, near rich).
    const specs = <(int frame, double seed, double ny, double scale, double speed, bool near, bool flip)>[
      (3, 0.06, 0.12, 2.2, 0.0038, false, false),
      (1, 0.42, 0.17, 2.4, 0.0044, false, true),
      (2, 0.78, 0.13, 2.1, 0.0040, false, false),
      (3, 0.24, 0.33, 2.5, 0.0050, false, true),
      (0, 0.14, 0.24, 2.9, 0.0064, true, false),
      (1, 0.58, 0.29, 3.0, 0.0070, true, false),
      (2, 0.88, 0.41, 2.7, 0.0060, true, true),
    ];

    const spec = PixelArtAssets.biomeClouds;
    for (final (frame, seed, ny, scale, speed, near, flip) in specs) {
      final dw = spec.frameWidth * scale;
      final dh = spec.frameHeight * scale;
      final span = size.width + dw * 1.4;
      final x = ((t * speed + seed) % 1.0) * span - dw * 0.7;
      final y = size.height * ny;

      final src = Rect.fromLTWH(
        (frame * spec.frameWidth).toDouble(),
        0,
        spec.frameWidth.toDouble(),
        spec.frameHeight.toDouble(),
      );
      final dst = Rect.fromLTWH(x.roundToDouble(), y.roundToDouble(), dw, dh);
      final tint = near ? nearTint : farTint;
      final alpha = near ? nearOpacity : farOpacity;
      final paint = Paint()
        ..filterQuality = FilterQuality.none
        ..isAntiAlias = false
        ..colorFilter = ColorFilter.mode(
          tint.withValues(alpha: alpha),
          BlendMode.modulate,
        );

      if (flip) {
        canvas.save();
        canvas.translate(dst.center.dx, 0);
        canvas.scale(-1, 1);
        canvas.translate(-dst.center.dx, 0);
        canvas.drawImageRect(img, src, dst, paint);
        canvas.restore();
      } else {
        canvas.drawImageRect(img, src, dst, paint);
      }
    }
  }

  void _paintShootingStar(
    Canvas canvas,
    Size size,
    double t,
    double period,
    Color color,
  ) {
    final cyc = (t % period) / period;
    if (cyc > 0.07) return;
    final frac = cyc / 0.07;
    final startX = size.width * (0.20 + ((t ~/ period) * 17 % 45) / 100.0);
    final startY = size.height * (0.10 + ((t ~/ period) * 11 % 14) / 100.0);
    final hx = startX + frac * size.width * 0.14;
    final hy = startY + frac * size.height * 0.08;
    final fade = math.sin(frac * math.pi);
    for (var s = 0; s < 4; s++) {
      _px(
        canvas,
        hx - s * 2 * _p,
        hy - s * _p,
        1,
        1,
        color.withValues(alpha: (fade * (1 - s * 0.24) * 0.72).clamp(0.0, 1.0)),
      );
    }
  }

  void _paintStars(
    Canvas canvas,
    Size size,
    double t,
    Color color,
    double maxAlpha,
  ) {
    final paint = Paint();
    for (final s in stars) {
      final twinkle = 0.30 + 0.70 * math.sin(t * 1.2 + s.phase).abs();
      paint.color = color.withValues(alpha: maxAlpha * twinkle);
      canvas.drawRect(
        Rect.fromLTWH(
          _snap(s.nx * size.width),
          _snap(s.ny * size.height),
          s.size,
          s.size,
        ),
        paint,
      );
    }
  }

  void _paintMotes(
    Canvas canvas,
    Size size,
    double t,
    Color c1,
    Color c2,
  ) {
    final paint = Paint();
    for (var i = 0; i < motes.length; i++) {
      final m = motes[i];
      final pulse = 0.35 + 0.65 * math.sin(t * 1.9 + m.phase).abs();
      paint.color = (i % 3 == 0 ? c2 : c1).withValues(alpha: 0.48 * pulse);
      canvas.drawRect(
        Rect.fromLTWH(
          _snap(m.nx * size.width),
          _snap(m.ny * size.height),
          _p,
          _p,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _AsepriteBiomeHorizonPainter oldDelegate) =>
      oldDelegate.groundBottomInset != groundBottomInset;
}
