import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;

import '../../design/design.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/pixel_art/pixel_art.dart';

class AppSidebarEntry {
  final Widget icon;
  final PixelSpriteSheetSpec? pixelSpec;
  final int? pixelFrame;
  final String label;
  final VoidCallback? onTap;

  const AppSidebarEntry({
    required this.icon,
    required this.label,
    this.pixelSpec,
    this.pixelFrame,
    this.onTap,
  });
}

class AppSidebarSection {
  final String title;
  final List<AppSidebarEntry> entries;

  const AppSidebarSection({required this.title, required this.entries});
}

class AppSidebar extends StatelessWidget {
  final List<AppSidebarSection> sections;

  const AppSidebar({super.key, required this.sections});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PixelArtSettings.instance.effectsEnabled,
      builder: (context, effectsOn, _) {
        if (effectsOn) return _buildPixelDrawer(context);
        return _buildClassicDrawer(context);
      },
    );
  }

  Widget _buildPixelDrawer(BuildContext context) {
    final drawerBg = Color.alphaBlend(
      Colors.black.withValues(alpha: 0.22),
      DsColor.bg,
    );
    return Drawer(
      backgroundColor: drawerBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: DsColor.lineStrong, width: 1.5),
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
                child: Row(
                  children: [
                    const PixelSpriteAnimation(
                      spec: PixelArtAssets.grassBlock,
                      width: 24,
                      height: 24,
                      playing: false,
                      fixedFrame: 0,
                    ),
                    const SizedBox(width: DsSpace.sm + 2),
                    Text('MCCOMPANION', style: DsType.pixelBrand),
                  ],
                ),
              ),
              const DsDivider(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(top: 8, bottom: 20),
                  children: [
                    for (final section in sections) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
                        child: Text(
                          section.title.toUpperCase(),
                          style: DsType.pixelTag.copyWith(
                            color: DsColor.textFaint,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                      for (final entry in section.entries)
                        _pixelRow(context, entry),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pixelRow(BuildContext context, AppSidebarEntry entry) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: entry.onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop();
                entry.onTap!();
              },
        splashColor: DsColor.accent.withValues(alpha: 0.14),
        highlightColor: DsColor.surfaceQuiet.withValues(alpha: 0.6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Row(
            children: [
              PixelFrame(
                notch: 2.5,
                recessed: true,
                fillColor: DsColor.inset,
                borderColor: DsColor.line,
                padding: const EdgeInsets.all(6),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: Center(
                    child: entry.pixelSpec != null && entry.pixelFrame != null
                        ? PixelSpriteAnimation(
                            spec: entry.pixelSpec!,
                            fixedFrame: entry.pixelFrame,
                            playing: false,
                            width: 18,
                            height: 18,
                          )
                        : IconTheme(
                            data: IconThemeData(
                              size: 16,
                              color: DsColor.textSoft,
                            ),
                            child: entry.icon,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  entry.label,
                  style: DsType.heading.copyWith(
                    color: DsColor.text,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassicDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.surfaceRaisedSolid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(22),
          bottomRight: Radius.circular(22),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Image.asset(
                  'assets/images/logo.png',
                  height: 22,
                  errorBuilder: (_, _, _) => Text(
                    'MCCompanion',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
            ),
            Divider(height: 1, thickness: 1, color: AppTheme.borderDim),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(top: 6, bottom: 20),
                children: [
                  for (final section in sections) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
                      child: Text(
                        section.title,
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    for (final entry in section.entries) _row(context, entry),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, AppSidebarEntry entry) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: entry.onTap == null
            ? null
            : () {
                Navigator.of(context).pop();
                entry.onTap!();
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: IconTheme(
                  data: IconThemeData(size: 17, color: AppTheme.textSecondary),
                  child: entry.icon,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  entry.label,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppTopBar extends StatelessWidget {
  final VoidCallback onMenu;
  final VoidCallback? onProfile;
  final bool profileActive;
  final ValueListenable<bool>? broadcasting;

  const AppTopBar({
    super.key,
    required this.onMenu,
    this.onProfile,
    this.profileActive = false,
    this.broadcasting,
  });

  static const double height = 52;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PixelArtSettings.instance.effectsEnabled,
      builder: (context, effectsOn, _) {
        if (!effectsOn) return _buildClassicBar();
        return _buildPixelBar();
      },
    );
  }

  Widget _buildPixelBar() {
    final barBg = Color.alphaBlend(
      Colors.black.withValues(alpha: 0.30),
      DsColor.bg,
    ).withValues(alpha: 0.86);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: barBg,
        border: Border(bottom: BorderSide(color: DsColor.line)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: DsSpace.md),
      child: Row(
        children: [
          _PixelTopBarButton(
            onTap: onMenu,
            child: Icon(Icons.menu_rounded, size: 19, color: DsColor.text),
          ),
          const SizedBox(width: DsSpace.sm + 2),
          const PixelSpriteAnimation(
            spec: PixelArtAssets.grassBlock,
            width: 20,
            height: 20,
            playing: false,
            fixedFrame: 0,
          ),
          const SizedBox(width: DsSpace.sm),
          Expanded(
            child: Text(
              'MCCOMPANION',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DsType.pixelBrand.copyWith(fontSize: 13.5),
            ),
          ),
          if (broadcasting != null)
            Padding(
              padding: const EdgeInsets.only(right: DsSpace.sm),
              child: PortalStatusBadge(
                broadcasting: broadcasting!,
                showWhenIdle: false,
              ),
            ),
          if (onProfile != null)
            _PixelTopBarButton(
              active: profileActive,
              onTap: onProfile!,
              child: const PixelSpriteAnimation(
                spec: PixelArtAssets.railFooterIcons,
                fixedFrame: 4,
                playing: false,
                width: 20,
                height: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildClassicBar() {
    return SizedBox(
      height: height,
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onMenu,
              borderRadius: AppRadius.rounded,
              child: Padding(
                padding: const EdgeInsets.all(11),
                child: Icon(
                  Icons.menu_rounded,
                  size: 22,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
          const Spacer(),
          if (broadcasting != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: PortalStatusBadge(
                broadcasting: broadcasting!,
                showWhenIdle: false,
              ),
            ),
          if (onProfile != null)
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onProfile,
                borderRadius: AppRadius.rounded,
                child: Padding(
                  padding: const EdgeInsets.all(11),
                  child: Icon(
                    Icons.person_rounded,
                    size: 22,
                    color: profileActive
                        ? AppTheme.brand
                        : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PixelTopBarButton extends StatelessWidget {
  const _PixelTopBarButton({
    required this.onTap,
    required this.child,
    this.active = false,
  });

  final VoidCallback onTap;
  final Widget child;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: SizedBox(
        width: 38,
        height: 38,
        child: Center(
          child: PixelFrame(
            notch: 2.5,
            recessed: !active,
            fillColor: active
                ? DsColor.accent.withValues(alpha: 0.18)
                : DsColor.inset.withValues(alpha: 0.85),
            borderColor: active
                ? DsColor.accent.withValues(alpha: 0.82)
                : DsColor.lineStrong,
            topHighlightColor: active
                ? DsColor.accent.withValues(alpha: 0.30)
                : null,
            bottomLipColor: active ? Colors.black.withValues(alpha: 0.45) : null,
            bottomLipHeight: active ? 2.0 : 0,
            child: SizedBox(
              width: 34,
              height: 34,
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}
