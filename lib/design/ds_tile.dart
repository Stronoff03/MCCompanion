import 'package:flutter/material.dart';

import '../widgets/pixel_art/pixel_art.dart';
import 'ds_surface.dart';
import 'ds_tokens.dart';
import 'pixel_chrome.dart';

class DsTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool selected;
  final bool dense;

  const DsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.leading,
    this.trailing,
    this.onTap,
    this.selected = false,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final tint = iconColor ?? DsColor.accent;
    final glyphSize = dense ? 36.0 : 42.0;

    final leadingWidget =
        leading ??
        (icon == null
            ? null
            : Container(
                width: glyphSize,
                height: glyphSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: tint.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(DsRadius.control - 2),
                ),
                child: Icon(icon, size: dense ? 17 : 19, color: tint),
              ));

    final row = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: DsSpace.lg,
        vertical: dense ? DsSpace.md : DsSpace.lg - 2,
      ),
      child: Row(
        children: [
          if (leadingWidget != null) ...[
            leadingWidget,
            const SizedBox(width: DsSpace.md),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: DsType.bodyStrong),
                if (subtitle != null) ...[
                  const SizedBox(height: DsSpace.xxs),
                  Text(subtitle!, style: DsType.caption),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: DsSpace.md),
            trailing!,
          ] else if (onTap != null) ...[
            const SizedBox(width: DsSpace.sm),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: DsColor.textFaint,
            ),
          ],
        ],
      ),
    );

    final content = onTap == null
        ? row
        : Material(
            color: Colors.transparent,
            child: InkWell(
              onTapDown: (details) {
                if (PixelArtSettings.instance.effectsEnabled.value) {
                  PixelParticleOverlay.burst(
                    context,
                    details.globalPosition,
                    preset: PixelParticlePreset.xpBurst,
                    count: 4,
                  );
                }
              },
              onTap: onTap,
              customBorder: const PixelNotchedBorder(notch: 4.0),
              child: row,
            ),
          );

    final isDark = DsColor.bg.computeLuminance() < 0.35;
    return PixelFrame(
      notch: 4.0,
      fillColor: isDark
          ? DsColor.surface.withValues(alpha: 0.93)
          : DsColor.surface,
      borderColor: selected
          ? DsColor.accent.withValues(alpha: 0.65)
          : (isDark
                ? Color.alphaBlend(
                    Colors.white.withValues(alpha: 0.11),
                    DsColor.surface,
                  )
                : DsColor.lineStrong),
      topHighlightColor: selected
          ? DsColor.accent.withValues(alpha: 0.25)
          : Colors.white.withValues(alpha: 0.06),
      bottomLipColor: Colors.black.withValues(alpha: 0.42),
      bottomLipHeight: 2.5,
      child: content,
    );
  }
}

class DsGroup extends StatelessWidget {
  final String? label;
  final List<Widget> children;

  const DsGroup({super.key, this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) rows.add(const DsDivider());
      rows.add(children[i]);
    }
    final isDark = DsColor.bg.computeLuminance() < 0.35;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) ...[
          Padding(
            padding: const EdgeInsets.only(
              left: DsSpace.xs,
              bottom: DsSpace.sm,
            ),
            child: Text(
              label!.toUpperCase(),
              style: DsType.pixelTag,
            ),
          ),
        ],
        PixelFrame(
          notch: 4.5,
          fillColor: isDark
              ? DsColor.surface.withValues(alpha: 0.93)
              : DsColor.surface,
          borderColor: isDark
              ? Color.alphaBlend(
                  Colors.white.withValues(alpha: 0.11),
                  DsColor.surface,
                )
              : DsColor.lineStrong,
          topHighlightColor: Colors.white.withValues(alpha: 0.07),
          bottomLipColor: Colors.black.withValues(alpha: 0.42),
          bottomLipHeight: 2.5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: rows,
          ),
        ),
      ],
    );
  }
}

class DsRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? customIcon;
  final Color? iconColor;
  final VoidCallback? onTap;

  const DsRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.customIcon,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tint = iconColor ?? DsColor.accent;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: DsSpace.lg,
            vertical: DsSpace.md + 2,
          ),
          child: Row(
            children: [
              if (customIcon != null)
                PixelFrame(
                  notch: 2.5,
                  recessed: true,
                  fillColor: tint.withValues(alpha: 0.14),
                  borderColor: tint.withValues(alpha: 0.36),
                  child: SizedBox(
                    width: 38,
                    height: 38,
                    child: Center(child: customIcon),
                  ),
                )
              else
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(DsRadius.control - 2),
                  ),
                  child: Icon(icon, size: 18, color: tint),
                ),
              const SizedBox(width: DsSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title, style: DsType.bodyStrong),
                    if (subtitle != null) ...[
                      const SizedBox(height: DsSpace.xxs),
                      Text(subtitle!, style: DsType.caption),
                    ],
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: DsSpace.sm),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: DsColor.textFaint,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
