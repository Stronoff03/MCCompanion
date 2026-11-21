import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../design/design.dart';
import '../layout/bar_inset.dart';
import '../widgets/pixel_art/pixel_art.dart';

class DesktopGuideTopic {
  final String id;
  final String title;
  final String subtitle;
  final FaIconData icon;
  final IconData rowIcon;
  final int? pixelIconFrame;
  final Color color;
  final WidgetBuilder content;

  const DesktopGuideTopic({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.rowIcon,
    this.pixelIconFrame,
    required this.color,
    required this.content,
  });
}

class DesktopGuideScreen extends StatefulWidget {
  static const double splitWidth = 760;
  static const double listWidth = 280;
  static const double articleWidth = 720;

  final String title;
  final List<DesktopGuideTopic> topics;
  final String? selectedId;
  final Widget? listFooter;
  final WidgetBuilder narrow;

  const DesktopGuideScreen({
    super.key,
    required this.title,
    required this.topics,
    required this.narrow,
    this.selectedId,
    this.listFooter,
  });

  @override
  State<DesktopGuideScreen> createState() => _DesktopGuideScreenState();
}

class _DesktopGuideScreenState extends State<DesktopGuideScreen> {
  late String _selected = widget.selectedId ?? widget.topics.first.id;

  @override
  void didUpdateWidget(covariant DesktopGuideScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final id = widget.selectedId;
    if (id != null && id != oldWidget.selectedId) _selected = id;
  }

  DesktopGuideTopic get _topic => widget.topics.firstWhere(
    (topic) => topic.id == _selected,
    orElse: () => widget.topics.first,
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < DesktopGuideScreen.splitWidth) {
          return widget.narrow(context);
        }
        final topic = _topic;
        return Row(
          children: [
            Container(
              width: DesktopGuideScreen.listWidth,
              decoration: BoxDecoration(
                color: DsColor.bg.withValues(alpha: 0.68),
                border: Border(right: BorderSide(color: DsColor.line)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DsHeader(title: widget.title),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        DsSpace.md,
                        0,
                        DsSpace.md,
                        DsSpace.md,
                      ),
                      children: [
                        for (final item in widget.topics)
                          _TopicTile(
                            topic: item,
                            active: item.id == topic.id,
                            onTap: () => setState(() => _selected = item.id),
                          ),
                      ],
                    ),
                  ),
                  if (widget.listFooter != null)
                    Padding(
                      padding: const EdgeInsets.all(DsSpace.md),
                      child: widget.listFooter,
                    )
                  else
                    ValueListenableBuilder<bool>(
                      valueListenable: PixelArtSettings.instance.effectsEnabled,
                      builder: (_, effectsOn, _) {
                        if (!effectsOn) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.all(DsSpace.md),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DsSpace.md,
                              vertical: DsSpace.sm,
                            ),
                            decoration: BoxDecoration(
                              color: DsColor.surfaceQuiet.withValues(alpha: 0.72),
                              borderRadius: DsRadius.controlR,
                              border: Border.all(color: DsColor.line),
                            ),
                            child: Row(
                              children: [
                                const PixelSpriteAnimation(
                                  spec: PixelArtAssets.enchantedBook,
                                  scale: 0.85,
                                  playing: false,
                                  fixedFrame: 0,
                                ),
                                const SizedBox(width: DsSpace.sm),
                                Expanded(
                                  child: Text(
                                    widget.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: DsType.caption,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
            Expanded(child: _article(context, topic)),
          ],
        );
      },
    );
  }

  Widget _article(BuildContext context, DesktopGuideTopic topic) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DsHeader(
          title: topic.title,
          subtitle: topic.subtitle,
          actions: [
            SizedBox(
              width: 38,
              height: 38,
              child: PixelFrame(
                notch: 3.0,
                fillColor: topic.color.withValues(alpha: 0.14),
                borderColor: topic.color.withValues(alpha: 0.45),
                topHighlightColor: topic.color.withValues(alpha: 0.22),
                child: Center(
                  child: _GuideTopicIcon(topic: topic, scale: 1.4),
                ),
              ),
            ),
          ],
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              DsSpace.gutter,
              0,
              DsSpace.gutter,
              DsSpace.xxxl + BarInset.of(context),
            ),
            child: Align(
              alignment: Alignment.topLeft,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: DesktopGuideScreen.articleWidth,
                ),
                child: PixelFrame(
                  notch: 4.0,
                  showRivets: true,
                  fillColor: DsColor.surface.withValues(alpha: 0.90),
                  borderColor: DsColor.lineStrong,
                  topHighlightColor: Colors.white.withValues(alpha: 0.05),
                  bottomLipColor: Colors.black.withValues(alpha: 0.45),
                  bottomLipHeight: 2.5,
                  padding: const EdgeInsets.all(DsSpace.xl),
                  child: topic.content(context),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GuideTopicIcon extends StatelessWidget {
  final DesktopGuideTopic topic;
  final double scale;

  const _GuideTopicIcon({required this.topic, this.scale = 1.35});

  @override
  Widget build(BuildContext context) {
    final frame = topic.pixelIconFrame;
    if (frame == null) {
      return Icon(topic.rowIcon, size: 18, color: topic.color);
    }
    return ValueListenableBuilder<bool>(
      valueListenable: PixelArtSettings.instance.effectsEnabled,
      builder: (_, effectsOn, _) {
        if (!effectsOn) {
          return Icon(topic.rowIcon, size: 18, color: topic.color);
        }
        return PixelSpriteAnimation(
          spec: PixelArtAssets.guideIcons,
          fixedFrame: frame,
          playing: false,
          scale: scale,
        );
      },
    );
  }
}

class _TopicTile extends StatelessWidget {
  final DesktopGuideTopic topic;
  final bool active;
  final VoidCallback onTap;

  const _TopicTile({
    required this.topic,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpace.xs + 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const PixelNotchedBorder(notch: 3.0),
          child: PixelFrame(
            notch: 3.0,
            recessed: !active,
            fillColor: active
                ? DsColor.accent.withValues(alpha: 0.15)
                : DsColor.surfaceQuiet.withValues(alpha: 0.45),
            borderColor: active
                ? DsColor.accent.withValues(alpha: 0.48)
                : DsColor.line.withValues(alpha: 0.55),
            topHighlightColor: active
                ? DsColor.accent.withValues(alpha: 0.20)
                : null,
            bottomLipColor: active ? Colors.black.withValues(alpha: 0.35) : null,
            bottomLipHeight: active ? 2.0 : 0,
            padding: const EdgeInsets.all(DsSpace.md),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  height: 36,
                  child: PixelFrame(
                    notch: 2.5,
                    recessed: !active,
                    fillColor: topic.color.withValues(alpha: 0.14),
                    borderColor: topic.color.withValues(
                      alpha: active ? 0.52 : 0.28,
                    ),
                    child: Center(child: _GuideTopicIcon(topic: topic)),
                  ),
                ),
                const SizedBox(width: DsSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        topic.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DsType.heading.copyWith(
                          fontSize: 13.5,
                          color: active ? DsColor.text : DsColor.textSoft,
                        ),
                      ),
                      Text(
                        topic.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: DsType.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
