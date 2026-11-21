import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../../widgets/pixel_art/pixel_art.dart';
import 'client_models.dart';
import 'client_shortcuts.dart';

class ClientRail extends StatelessWidget {
  static const double width = 64;

  final List<ClientSection> sections;
  final List<ClientSection> footer;
  final String? activeSectionId;

  const ClientRail({
    super.key,
    required this.sections,
    required this.footer,
    required this.activeSectionId,
  });

  @override
  Widget build(BuildContext context) {
    final railBg = Color.alphaBlend(
      Colors.black.withValues(alpha: 0.24),
      DsColor.bg,
    );
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: railBg,
        border: Border(right: BorderSide(color: DsColor.lineStrong)),
      ),
      padding: const EdgeInsets.symmetric(vertical: DsSpace.md),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (var i = 0; i < sections.length; i++)
                    _RailButton(
                      section: sections[i],
                      active: sections[i].id == activeSectionId,
                      hint: ClientShortcuts.sectionHint(i),
                    ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: DsSpace.md,
              vertical: DsSpace.sm,
            ),
            child: DsDivider(),
          ),
          for (final section in footer)
            _RailButton(
              section: section,
              active: section.id == activeSectionId,
              hint: section.id == 'customize'
                  ? ClientShortcuts.settingsHint
                  : null,
            ),
        ],
      ),
    );
  }
}

class _RailButton extends StatefulWidget {
  final ClientSection section;
  final bool active;
  final String? hint;

  const _RailButton({required this.section, required this.active, this.hint});

  @override
  State<_RailButton> createState() => _RailButtonState();
}

class _RailButtonState extends State<_RailButton>
    with SingleTickerProviderStateMixin {
  Offset? _lastTapGlobal;
  bool _hovered = false;
  late final AnimationController _hoverAnim;

  @override
  void initState() {
    super.initState();
    _hoverAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void dispose() {
    _hoverAnim.dispose();
    super.dispose();
  }

  void _setHovered(bool value) {
    if (_hovered == value) return;
    setState(() => _hovered = value);
    if (value && PixelArtSettings.instance.effectsEnabled.value) {
      _hoverAnim.forward(from: 0.0);
    } else {
      _hoverAnim.stop();
      _hoverAnim.value = 0.0;
    }
  }

  (PixelSpriteSheetSpec, int)? get _pixelIcon => switch (widget.section.id) {
    'connector' => (PixelArtAssets.railIcons, 0),
    'servers' => (PixelArtAssets.railIcons, 1),
    'tracker' => (PixelArtAssets.railIcons, 2),
    'skins' => (PixelArtAssets.railIcons, 3),
    'lookup' => (PixelArtAssets.railIcons, 4),
    'relay' => (PixelArtAssets.railFooterIcons, 0),
    'customize' => (PixelArtAssets.railFooterIcons, 1),
    'support' => (PixelArtAssets.railFooterIcons, 2),
    'feedback' => (PixelArtAssets.railFooterIcons, 3),
    'profile' => (PixelArtAssets.railFooterIcons, 4),
    _ => null,
  };

  void _handleTap() {
    if (PixelArtSettings.instance.effectsEnabled.value &&
        _lastTapGlobal != null) {
      PixelParticleOverlay.burst(
        context,
        _lastTapGlobal!,
        preset: PixelParticlePreset.xpBurst,
        count: 4,
      );
    }
    widget.section.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    final section = widget.section;
    final hint = widget.hint;
    final pixelIcon = _pixelIcon;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Tooltip(
        message: hint == null ? section.label : '${section.label}  ($hint)',
        waitDuration: const Duration(milliseconds: 350),
        child: MouseRegion(
          onEnter: (_) => _setHovered(true),
          onExit: (_) => _setHovered(false),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              AnimatedContainer(
                duration: DsDuration.fast,
                width: 3,
                height: active ? 22 : (_hovered ? 12 : 0),
                color: active
                    ? DsColor.accent
                    : DsColor.accent.withValues(alpha: 0.55),
              ),
              Center(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTapDown: (d) => _lastTapGlobal = d.globalPosition,
                    onTap: _handleTap,
                    customBorder: const PixelNotchedBorder(notch: 3.0),
                    child: SizedBox(
                      width: 42,
                      height: 42,
                      child: PixelFrame(
                        notch: 3.0,
                        recessed: !active && !_hovered,
                        fillColor: active
                            ? DsColor.accent.withValues(alpha: 0.18)
                            : (_hovered
                                  ? DsColor.surface.withValues(alpha: 0.85)
                                  : DsColor.inset.withValues(alpha: 0.52)),
                        borderColor: active
                            ? DsColor.accent.withValues(alpha: 0.62)
                            : (_hovered
                                  ? DsColor.accent.withValues(alpha: 0.42)
                                  : DsColor.line),
                        topHighlightColor: active || _hovered
                            ? DsColor.accent.withValues(
                                alpha: active ? 0.30 : 0.18,
                              )
                            : null,
                        bottomLipColor: active || _hovered
                            ? Colors.black.withValues(alpha: 0.40)
                            : null,
                        bottomLipHeight: active || _hovered ? 2.0 : 0,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            AnimatedBuilder(
                              animation: _hoverAnim,
                              builder: (_, child) {
                                final t = _hoverAnim.value;
                                final playing = _hovered && t > 0.0 && t < 1.0;
                                final bobY = playing
                                    ? -3.0 *
                                          math.sin(t * math.pi) *
                                          (1.0 - 0.2 * t)
                                    : 0.0;
                                final tilt = playing
                                    ? 0.14 *
                                          math.sin(t * math.pi * 2.0) *
                                          (1.0 - t)
                                    : 0.0;
                                final scale = _hovered ? 1.09 : 1.0;
                                return Transform.translate(
                                  offset: Offset(0, bobY),
                                  child: Transform.rotate(
                                    angle: tilt,
                                    child: AnimatedScale(
                                      scale: scale,
                                      duration: const Duration(milliseconds: 140),
                                      curve: Curves.easeOutBack,
                                      child: child,
                                    ),
                                  ),
                                );
                              },
                              child: pixelIcon != null
                                  ? ValueListenableBuilder<bool>(
                                      valueListenable: PixelArtSettings
                                          .instance
                                          .effectsEnabled,
                                      builder: (_, effectsOn, _) {
                                        if (!effectsOn) {
                                          return Icon(
                                            section.icon,
                                            size: 20,
                                            color: active
                                                ? DsColor.accent
                                                : DsColor.textFaint,
                                          );
                                        }
                                        return AnimatedOpacity(
                                          duration: DsDuration.fast,
                                          opacity: active
                                              ? 1.0
                                              : (_hovered ? 1.0 : 0.76),
                                          child: PixelSpriteAnimation(
                                            spec: pixelIcon.$1,
                                            fixedFrame: pixelIcon.$2,
                                            playing: false,
                                            scale: 1.45,
                                          ),
                                        );
                                      },
                                    )
                                  : Icon(
                                      section.icon,
                                      size: 20,
                                      color: active
                                          ? DsColor.accent
                                          : DsColor.textFaint,
                                    ),
                            ),
                            if (section.badge > 0)
                              Positioned(
                                top: 5,
                                right: 5,
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  color: DsColor.danger,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
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
