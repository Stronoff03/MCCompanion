import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import '../../widgets/components/app_blur.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../l10n/app_localizations.dart';
import '../../services/navigation_controller.dart';
import '../../services/home_customization_service.dart';
import '../../constants/app_constants.dart';
import '../../design/design.dart';
import '../../theme/app_theme.dart';
import '../../widgets/pixel_art/pixel_art.dart';

class BottomGlassSimpleNavBar extends StatelessWidget {
  final VoidCallback? onConnectorTap;
  final String? activeItem;

  final AppFeature? navFarFeature;
  final AppFeature? navOuterFeature;
  final AppFeature? navLeftFeature;
  final AppFeature? navRightFeature;
  final VoidCallback? onNavFarTap;
  final VoidCallback? onNavOuterTap;
  final VoidCallback? onNavLeftTap;
  final VoidCallback? onNavRightTap;
  final bool navFarActive;
  final bool navOuterActive;
  final bool navLeftActive;
  final bool navRightActive;

  const BottomGlassSimpleNavBar({
    super.key,
    this.onConnectorTap,
    this.activeItem,
    this.navFarFeature,
    this.navOuterFeature,
    this.navLeftFeature,
    this.navRightFeature,
    this.onNavFarTap,
    this.onNavOuterTap,
    this.onNavLeftTap,
    this.onNavRightTap,
    this.navFarActive = false,
    this.navOuterActive = false,
    this.navLeftActive = false,
    this.navRightActive = false,
  });

  static FaIconData _iconFor(AppFeature feature) => switch (feature) {
    AppFeature.connector => FontAwesomeIcons.play,
    AppFeature.skins => FontAwesomeIcons.shirt,
    AppFeature.partners => FontAwesomeIcons.server,
    AppFeature.lookup => FontAwesomeIcons.magnifyingGlass,
    AppFeature.tracker => FontAwesomeIcons.heartPulse,
  };

  static const double _height = 52;
  static const double _gap = 16;

  static double insetOf(BuildContext context) {
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    return (safeBottom < 8 ? 8 : safeBottom) + 6 + _height + _gap;
  }

  static const double _radius = 26;
  static const double _bubbleInset = 5;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final items =
        <({FaIconData icon, String label, bool active, VoidCallback? onTap})>[
          if (navOuterFeature != null)
            (
              icon: _iconFor(navOuterFeature!),
              label: navOuterFeature!.label(l),
              active: navOuterActive,
              onTap: onNavOuterTap,
            ),
          if (navLeftFeature != null)
            (
              icon: _iconFor(navLeftFeature!),
              label: navLeftFeature!.label(l),
              active: navLeftActive,
              onTap: onNavLeftTap,
            ),
          (
            icon: FontAwesomeIcons.play,
            label: l.featureLabelConnector,
            active: activeItem == 'connector',
            onTap: onConnectorTap,
          ),
          if (navRightFeature != null)
            (
              icon: _iconFor(navRightFeature!),
              label: navRightFeature!.label(l),
              active: navRightActive,
              onTap: onNavRightTap,
            ),
          if (navFarFeature != null)
            (
              icon: _iconFor(navFarFeature!),
              label: navFarFeature!.label(l),
              active: navFarActive,
              onTap: onNavFarTap,
            ),
        ];
    final activeIndex = items.indexWhere((item) => item.active);
    final shape = BorderRadius.circular(_radius);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 6, 28, 0),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: shape,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: shape,
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: AppBlur.sigmaFor(24),
                sigmaY: AppBlur.sigmaFor(24),
              ),
              child: Container(
                height: _height,
                decoration: BoxDecoration(
                  borderRadius: shape,
                  color: AppTheme.surfaceRaised.withValues(alpha: 0.55),
                ),
                foregroundDecoration: BoxDecoration(
                  borderRadius: shape,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.14),
                      Colors.white.withValues(alpha: 0.03),
                    ],
                  ),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final slot = constraints.maxWidth / items.length;
                    return Stack(
                      children: [
                        if (activeIndex >= 0)
                          AnimatedPositioned(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            left: activeIndex * slot + _bubbleInset,
                            top: _bubbleInset,
                            bottom: _bubbleInset,
                            width: slot - _bubbleInset * 2,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  _radius - _bubbleInset,
                                ),
                                color: Colors.white.withValues(alpha: 0.14),
                              ),
                            ),
                          ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final item in items)
                              _NavItem(
                                icon: item.icon,
                                label: item.label,
                                isActive: item.active,
                                onTap: item.onTap,
                              ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final FaIconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive
        ? AppTheme.textPrimary
        : AppTheme.textPrimary.withValues(alpha: 0.6);

    return Expanded(
      child: Semantics(
        button: true,
        selected: isActive,
        label: label,
        child: GestureDetector(
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
          behavior: HitTestBehavior.opaque,
          child: Center(
            child: AnimatedScale(
              scale: isActive ? 1.1 : 1,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: FaIcon(icon, size: 20, color: color),
            ),
          ),
        ),
      ),
    );
  }
}

class MoreSheetContent extends StatelessWidget {
  final AppLocalizations loc;
  final NavigationController navigationController;
  final String? selectedRelayIp;
  final VoidCallback onClose;
  final void Function(String?) onRelayChanged;

  const MoreSheetContent({
    super.key,
    required this.loc,
    required this.navigationController,
    required this.onClose,
    required this.onRelayChanged,
    this.selectedRelayIp,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          DsSpace.lg,
          DsSpace.lg,
          DsSpace.lg,
          DsSpace.lg + bottomInset,
        ),
        child: Center(
          heightFactor: 1.0,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: PixelFrame(
              notch: 5.0,
              showRivets: true,
              enableTexture: true,
              fillColor: DsColor.surface,
              borderColor: DsColor.accent.withValues(alpha: 0.48),
              topHighlightColor: DsColor.accent.withValues(alpha: 0.24),
              bottomLipColor: Colors.black.withValues(alpha: 0.55),
              bottomLipHeight: 3.5,
              rivetColor: DsColor.accent.withValues(alpha: 0.55),
              padding: const EdgeInsets.all(DsSpace.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      PixelFrame(
                        notch: 3.0,
                        recessed: true,
                        fillColor: DsColor.inset,
                        borderColor: DsColor.accent.withValues(alpha: 0.45),
                        padding: const EdgeInsets.all(7),
                        child: ValueListenableBuilder<bool>(
                          valueListenable:
                              PixelArtSettings.instance.effectsEnabled,
                          builder: (_, effectsOn, _) {
                            if (!effectsOn) {
                              return Icon(
                                Icons.settings_ethernet_rounded,
                                color: DsColor.accent,
                                size: 20,
                              );
                            }
                            return const PixelSpriteAnimation(
                              spec: PixelArtAssets.railFooterIcons,
                              fixedFrame: 0,
                              playing: false,
                              scale: 1.5,
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: DsSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(loc.relay, style: DsType.title),
                            const SizedBox(height: 2),
                            Text(
                              loc.nldServerLabelShort.toUpperCase(),
                              style: DsType.pixelTag.copyWith(fontSize: 10),
                            ),
                          ],
                        ),
                      ),
                      DsIconButton(
                        icon: Icons.close_rounded,
                        size: 34,
                        onPressed: onClose,
                      ),
                    ],
                  ),
                  const SizedBox(height: DsSpace.md),
                  const DsDivider(),
                  const SizedBox(height: DsSpace.lg),
                  _RegionSelector(
                    selectedIp: selectedRelayIp,
                    onChanged: onRelayChanged,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RegionSelector extends StatelessWidget {
  final String? selectedIp;
  final void Function(String?) onChanged;
  const _RegionSelector({required this.selectedIp, required this.onChanged});

  String _regionTag(String name, AppLocalizations loc) {
    final upper = name.toUpperCase();
    if (upper.contains('EU')) return loc.relayRegionEuropeTag;
    if (upper.contains('US')) return loc.relayRegionAmericaTag;
    return loc.relayRegionDefaultTag;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Row(
      children: [
        for (var i = 0; i < AppConstants.relayServers.length; i++) ...[
          if (i > 0) const SizedBox(width: DsSpace.md),
          Expanded(
            child: _RelayRegionCard(
              name: AppConstants.relayServers[i]['name'] as String,
              ip: AppConstants.relayServers[i]['ip'] as String,
              tag: _regionTag(
                AppConstants.relayServers[i]['name'] as String,
                loc,
              ),
              selected:
                  selectedIp == AppConstants.relayServers[i]['ip'] as String,
              onTap: () =>
                  onChanged(AppConstants.relayServers[i]['ip'] as String),
            ),
          ),
        ],
      ],
    );
  }
}

class _RelayRegionCard extends StatefulWidget {
  const _RelayRegionCard({
    required this.name,
    required this.ip,
    required this.tag,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String ip;
  final String tag;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_RelayRegionCard> createState() => _RelayRegionCardState();
}

class _RelayRegionCardState extends State<_RelayRegionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.selected;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTapUp: (details) {
          if (PixelArtSettings.instance.effectsEnabled.value) {
            PixelParticleOverlay.burst(
              context,
              details.globalPosition,
              preset: PixelParticlePreset.xpBurst,
              count: 6,
            );
          }
          widget.onTap();
        },
        child: PixelFrame(
          notch: 3.5,
          recessed: !active && !_hovered,
          showRivets: active,
          fillColor: active
              ? DsColor.accent.withValues(alpha: 0.16)
              : (_hovered
                    ? DsColor.surfaceQuiet
                    : DsColor.inset),
          borderColor: active
              ? DsColor.accent.withValues(alpha: 0.78)
              : (_hovered ? DsColor.lineStrong : DsColor.line),
          topHighlightColor: active
              ? DsColor.accent.withValues(alpha: 0.30)
              : null,
          bottomLipColor: active || _hovered
              ? Colors.black.withValues(alpha: 0.42)
              : null,
          bottomLipHeight: active ? 3.0 : (_hovered ? 2.0 : 0),
          rivetColor: DsColor.accent.withValues(alpha: 0.65),
          padding: const EdgeInsets.all(DsSpace.md + 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    color: active ? DsColor.accent : DsColor.textDisabled,
                  ),
                  const SizedBox(width: DsSpace.sm),
                  Expanded(
                    child: Text(
                      widget.tag,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: DsType.pixelTag.copyWith(
                        fontSize: 9.5,
                        color: active ? DsColor.accent : DsColor.textFaint,
                      ),
                    ),
                  ),
                  _RelaySignalBars(active: active),
                ],
              ),
              const SizedBox(height: DsSpace.sm),
              Text(
                widget.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DsType.heading.copyWith(
                  fontSize: 15,
                  color: active ? DsColor.text : DsColor.textSoft,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.ip,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: DsType.mono.copyWith(
                  fontSize: 11,
                  color: DsColor.textFaint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RelaySignalBars extends StatelessWidget {
  const _RelaySignalBars({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final barColor = active
        ? DsColor.success
        : DsColor.textDisabled.withValues(alpha: 0.55);
    return SizedBox(
      width: 15,
      height: 11,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (var i = 1; i <= 4; i++)
            Container(width: 2.5, height: 2.0 + i * 2.2, color: barColor),
        ],
      ),
    );
  }
}
