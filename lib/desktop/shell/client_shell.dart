import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../design/design.dart';
import '../../widgets/pixel_art/pixel_art.dart';
import 'client_context_panel.dart';
import 'client_models.dart';
import 'client_rail.dart';
import 'client_shortcuts.dart';

class ClientShell extends StatelessWidget {
  static const double narrowWidth = 900;

  final List<ClientSection> sections;
  final List<ClientSection> footer;
  final String? activeSectionId;
  final String? activeItemId;
  final Widget content;
  final Widget rightDock;
  final Widget statusBar;
  final ValueListenable<bool>? broadcasting;
  final VoidCallback? onToggleConsole;
  final VoidCallback? onDismiss;

  const ClientShell({
    super.key,
    required this.sections,
    required this.footer,
    required this.activeSectionId,
    required this.activeItemId,
    required this.content,
    required this.rightDock,
    required this.statusBar,
    this.broadcasting,
    this.onToggleConsole,
    this.onDismiss,
  });

  ClientSection? get _active {
    for (final section in [...sections, ...footer]) {
      if (section.id == activeSectionId) return section;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final active = _active;
    final shell = ColoredBox(
      color: DsColor.bg,
      child: SafeArea(
        child: Column(
          children: [
            _LauncherTopBar(
              sectionLabel: active?.label,
              broadcasting: broadcasting,
            ),
            const DsDivider(),
            Expanded(
              child: AmbientMinecraftBeesHost(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final hasItems = active != null && active.items.isNotEmpty;
                    final narrow = constraints.maxWidth < narrowWidth;
                    return Row(
                      children: [
                        ClientRail(
                          sections: sections,
                          footer: footer,
                          activeSectionId: activeSectionId,
                        ),
                        if (hasItems && !narrow)
                          ClientContextPanel(
                            section: active,
                            activeItemId: activeItemId,
                          ),
                        Expanded(
                          child: NightHorizonBackdrop(
                            broadcasting: broadcasting,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (hasItems && narrow)
                                  ClientItemStrip(
                                    section: active,
                                    activeItemId: activeItemId,
                                  ),
                                Expanded(child: content),
                              ],
                            ),
                          ),
                        ),
                        rightDock,
                      ],
                    );
                  },
                ),
              ),
            ),
            statusBar,
          ],
        ),
      ),
    );

    return CallbackShortcuts(
      bindings: ClientShortcuts.bindings(
        sections: sections,
        footer: footer,
        onToggleConsole: onToggleConsole,
        onDismiss: onDismiss,
      ),
      child: Focus(autofocus: true, child: shell),
    );
  }
}

class _LauncherTopBar extends StatelessWidget {
  const _LauncherTopBar({
    required this.sectionLabel,
    required this.broadcasting,
  });

  final String? sectionLabel;
  final ValueListenable<bool>? broadcasting;

  @override
  Widget build(BuildContext context) {
    final barBg = Color.alphaBlend(
      Colors.black.withValues(alpha: 0.28),
      DsColor.bg,
    );
    return Container(
      height: 40,
      color: barBg,
      padding: const EdgeInsets.symmetric(horizontal: DsSpace.md + 2),
      child: Row(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: PixelArtSettings.instance.effectsEnabled,
            builder: (_, effectsOn, _) {
              if (!effectsOn) return const SizedBox.shrink();
              return const Padding(
                padding: EdgeInsets.only(right: DsSpace.sm + 2),
                child: PixelSpriteAnimation(
                  spec: PixelArtAssets.grassBlock,
                  width: 22,
                  height: 22,
                  playing: false,
                  fixedFrame: 0,
                ),
              );
            },
          ),
          Text('MCCOMPANION', style: DsType.pixelBrand),
          if (sectionLabel != null && sectionLabel!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: DsSpace.sm + 2),
              child: Text(
                '/',
                style: DsType.mono.copyWith(color: DsColor.textDisabled),
              ),
            ),
            Text(
              sectionLabel!,
              style: DsType.heading.copyWith(
                fontSize: 13.5,
                color: DsColor.textSoft,
              ),
            ),
          ],
          const Spacer(),
          if (broadcasting != null)
            PortalStatusBadge(broadcasting: broadcasting!),
        ],
      ),
    );
  }
}
