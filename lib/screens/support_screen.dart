import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../design/design.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/components/swipe_back.dart';
import '../widgets/dialogs/howto_dialogs.dart';
import '../widgets/pixel_art/pixel_art.dart';
import '../layout/bar_inset.dart';

class SupportTopic {
  final FaIconData icon;
  final IconData rowIcon;
  final int pixelIconFrame;
  final Color color;
  final String title;
  final String subtitle;
  final String body;

  const SupportTopic({
    required this.icon,
    required this.rowIcon,
    required this.pixelIconFrame,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.body,
  });
}

List<SupportTopic> supportTopics(AppLocalizations l) => [
  SupportTopic(
    icon: FontAwesomeIcons.wifi,
    rowIcon: Icons.wifi_rounded,
    pixelIconFrame: 0,
    color: AppTheme.info,
    title: l.helpMCCompanionTitle,
    subtitle: l.helpMCCompanionSubtitle,
    body: l.helpMCCompanionBody,
  ),
  SupportTopic(
    icon: FontAwesomeIcons.triangleExclamation,
    rowIcon: Icons.warning_amber_rounded,
    pixelIconFrame: 1,
    color: AppTheme.warning,
    title: l.helpMultiplayerFailedTitle,
    subtitle: l.helpMultiplayerFailedSubtitle,
    body: l.helpMultiplayerFailedBody,
  ),
  SupportTopic(
    icon: FontAwesomeIcons.userGroup,
    rowIcon: Icons.group_rounded,
    pixelIconFrame: 2,
    color: AppTheme.modeFriends,
    title: l.helpFriendsModeTitle,
    subtitle: l.helpFriendsModeSubtitle,
    body: l.helpFriendsModeBody,
  ),
];

class SupportScreen extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback? onFeedback;

  const SupportScreen({super.key, required this.onBack, this.onFeedback});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  SupportTopic? _open;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final open = _open;

    return SwipeBack(
      onBack: open == null ? widget.onBack : () => setState(() => _open = null),
      child: open == null ? _list(l) : _article(l, open),
    );
  }

  Widget _list(AppLocalizations l) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DsHeader(
          title: l.support,
          leading: DsIconButton(
            icon: Icons.arrow_back_rounded,
            size: 36,
            onPressed: widget.onBack,
          ),
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              DsSpace.gutter,
              0,
              DsSpace.gutter,
              DsSpace.xxxl + BarInset.of(context),
            ),
            children: [
              DsGroup(
                label: l.sectionHelp,
                children: [
                  for (final topic in supportTopics(l))
                    ValueListenableBuilder<bool>(
                      valueListenable:
                          PixelArtSettings.instance.effectsEnabled,
                      builder: (_, effectsOn, _) => DsRow(
                        title: topic.title,
                        subtitle: topic.subtitle,
                        icon: topic.rowIcon,
                        customIcon: effectsOn
                            ? PixelSpriteAnimation(
                                spec: PixelArtAssets.guideIcons,
                                fixedFrame: topic.pixelIconFrame,
                                playing: false,
                                width: 22,
                                height: 22,
                              )
                            : null,
                        iconColor: topic.color,
                        onTap: () => setState(() => _open = topic),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: DsSpace.lg),
              if (widget.onFeedback != null)
                DsButton(
                  label: l.feedbackTileTitle,
                  icon: Icons.chat_bubble_outline_rounded,
                  tone: DsButtonTone.neutral,
                  expand: true,
                  onPressed: widget.onFeedback,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _article(AppLocalizations l, SupportTopic topic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DsHeader(
          title: topic.title,
          subtitle: topic.subtitle,
          leading: DsIconButton(
            icon: Icons.arrow_back_rounded,
            size: 36,
            onPressed: () => setState(() => _open = null),
          ),
          actions: [
            ValueListenableBuilder<bool>(
              valueListenable: PixelArtSettings.instance.effectsEnabled,
              builder: (_, effectsOn, _) {
                if (!effectsOn) {
                  return Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: topic.color.withValues(alpha: 0.14),
                      borderRadius: DsRadius.controlR,
                    ),
                    child: FaIcon(topic.icon, size: 15, color: topic.color),
                  );
                }
                return PixelFrame(
                  notch: 2.5,
                  recessed: true,
                  fillColor: topic.color.withValues(alpha: 0.14),
                  borderColor: topic.color.withValues(alpha: 0.36),
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: Center(
                      child: PixelSpriteAnimation(
                        spec: PixelArtAssets.guideIcons,
                        fixedFrame: topic.pixelIconFrame,
                        playing: false,
                        width: 22,
                        height: 22,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              DsSpace.gutter,
              0,
              DsSpace.gutter,
              DsSpace.xxxl + BarInset.of(context),
            ),
            children: [StepContent(body: topic.body, color: topic.color)],
          ),
        ),
      ],
    );
  }
}
