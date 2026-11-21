import 'package:flutter/material.dart';

import '../widgets/pixel_art/pixel_art.dart';
import 'ds_hover.dart';
import 'ds_tokens.dart';
import 'pixel_chrome.dart';

class DsCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool highlighted;
  final Color? accent;
  final bool showRivets;

  const DsCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(DsSpace.lg),
    this.onTap,
    this.highlighted = false,
    this.accent,
    this.showRivets = false,
  });

  @override
  Widget build(BuildContext context) {
    final tint = accent ?? DsColor.accent;
    final isDark = DsColor.bg.computeLuminance() < 0.35;

    final body = PixelFrame(
      notch: 4.5,
      padding: padding,
      enableTexture: isDark,
      fillColor: isDark
          ? DsColor.surface.withValues(alpha: 0.93)
          : DsColor.surface,
      borderColor: highlighted
          ? tint.withValues(alpha: 0.62)
          : (isDark
                ? Color.alphaBlend(
                    Colors.white.withValues(alpha: 0.11),
                    DsColor.surface,
                  )
                : DsColor.lineStrong),
      topHighlightColor: isDark
          ? (highlighted
                ? tint.withValues(alpha: 0.30)
                : Colors.white.withValues(alpha: 0.08))
          : Colors.white.withValues(alpha: 0.55),
      bottomLipColor: isDark
          ? Colors.black.withValues(alpha: 0.45)
          : Colors.black.withValues(alpha: 0.08),
      bottomLipHeight: 3.0,
      showRivets: showRivets || highlighted,
      rivetColor: highlighted
          ? tint.withValues(alpha: 0.50)
          : Colors.white.withValues(alpha: 0.14),
      child: child,
    );

    if (onTap == null) return body;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const PixelNotchedBorder(notch: 4.5),
        child: DsHover(borderRadius: DsRadius.cardR, child: body),
      ),
    );
  }
}

class DsDivider extends StatelessWidget {
  final double indent;

  const DsDivider({super.key, this.indent = 0});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 1, color: Colors.black.withValues(alpha: 0.38)),
          Container(height: 1, color: Colors.white.withValues(alpha: 0.05)),
        ],
      ),
    );
  }
}

class DsEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final PixelSpriteSheetSpec? pixelSprite;

  const DsEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.pixelSprite,
  });

  PixelSpriteSheetSpec _resolveSprite() {
    if (pixelSprite != null) return pixelSprite!;
    if (icon == Icons.person_search_rounded ||
        icon == Icons.search ||
        icon == Icons.search_rounded ||
        icon == Icons.search_off_rounded) {
      return PixelArtAssets.compass;
    }
    if (icon == Icons.dns_rounded || icon == Icons.storage_rounded) {
      return PixelArtAssets.campfire;
    }
    if (icon == Icons.lock_outline_rounded || icon == Icons.radar_rounded) {
      return PixelArtAssets.floatingIsland;
    }
    if (icon == Icons.explore_off_rounded ||
        icon == Icons.cloud_off_rounded ||
        icon == Icons.inventory_2_rounded) {
      return PixelArtAssets.chest;
    }
    if (icon == Icons.terminal_rounded) {
      return PixelArtAssets.lantern;
    }
    if (icon == Icons.checkroom_rounded) {
      return PixelArtAssets.armorStand;
    }
    if (icon == Icons.menu_book_rounded || icon == Icons.help_outline_rounded) {
      return PixelArtAssets.enchantedBook;
    }
    return PixelArtAssets.grassBlock;
  }

  double _resolveScale(PixelSpriteSheetSpec spec) {
    if (spec == PixelArtAssets.floatingIsland) return 2.2;
    if (spec == PixelArtAssets.lantern) return 2.4;
    if (spec == PixelArtAssets.campfire) return 2.2;
    return 2.0;
  }

  Color _resolveAuraColor(PixelSpriteSheetSpec spec) {
    if (spec == PixelArtAssets.campfire || spec == PixelArtAssets.lantern) {
      return const Color(0xFFE08E45);
    }
    if (spec == PixelArtAssets.compass ||
        spec == PixelArtAssets.floatingIsland ||
        spec == PixelArtAssets.armorStand) {
      return const Color(0xFF39B5C2);
    }
    if (spec == PixelArtAssets.enchantedBook) {
      return const Color(0xFF9A6FD4);
    }
    if (spec == PixelArtAssets.chest) {
      return const Color(0xFFC7954B);
    }
    return const Color(0xFF66C93B);
  }

  PixelParticlePreset _resolveTapPreset(PixelSpriteSheetSpec spec) {
    if (spec == PixelArtAssets.compass) return PixelParticlePreset.xpBurst;
    if (spec == PixelArtAssets.campfire || spec == PixelArtAssets.lantern) {
      return PixelParticlePreset.beeLove;
    }
    return PixelParticlePreset.grassBlock;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpace.lg,
        vertical: DsSpace.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: PixelArtSettings.instance.effectsEnabled,
            builder: (context, effectsOn, _) {
              if (!effectsOn) {
                return Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: DsColor.surfaceQuiet,
                    borderRadius: DsRadius.controlR,
                    border: Border.all(color: DsColor.line),
                  ),
                  child: Icon(icon, size: 24, color: DsColor.textFaint),
                );
              }

              final spec = _resolveSprite();
              return _InteractivePixelBadge(
                spec: spec,
                scale: _resolveScale(spec),
                auraColor: _resolveAuraColor(spec),
                tapPreset: _resolveTapPreset(spec),
              );
            },
          ),
          const SizedBox(height: DsSpace.md),
          Text(title, style: DsType.bodyStrong, textAlign: TextAlign.center),
          if (message != null) ...[
            const SizedBox(height: DsSpace.xs),
            Text(message!, style: DsType.caption, textAlign: TextAlign.center),
          ],
          if (action != null) ...[const SizedBox(height: DsSpace.lg), action!],
        ],
      ),
    );
  }
}

class _InteractivePixelBadge extends StatefulWidget {
  const _InteractivePixelBadge({
    required this.spec,
    required this.scale,
    required this.auraColor,
    required this.tapPreset,
  });

  final PixelSpriteSheetSpec spec;
  final double scale;
  final Color auraColor;
  final PixelParticlePreset tapPreset;

  @override
  State<_InteractivePixelBadge> createState() => _InteractivePixelBadgeState();
}

class _InteractivePixelBadgeState extends State<_InteractivePixelBadge> {
  bool _bouncing = false;

  void _onTapUp(TapUpDetails details) {
    setState(() => _bouncing = true);
    PixelParticleOverlay.burst(
      context,
      details.globalPosition,
      preset: widget.tapPreset,
      count: 6,
      popGrassBlock: widget.spec == PixelArtAssets.grassBlock,
    );
    Future<void>.delayed(const Duration(milliseconds: 140), () {
      if (mounted) setState(() => _bouncing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.spec.frameWidth * widget.scale;
    final h = widget.spec.frameHeight * widget.scale;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTapUp: _onTapUp,
        child: AnimatedScale(
          scale: _bouncing ? 1.09 : 1.0,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutBack,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 0.62,
                colors: <Color>[
                  widget.auraColor.withValues(alpha: 0.14),
                  Colors.transparent,
                ],
              ),
            ),
            child: SizedBox(
              width: w,
              height: h,
              child: Center(
                child: PixelSpriteAnimation(
                  spec: widget.spec,
                  scale: widget.scale,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
