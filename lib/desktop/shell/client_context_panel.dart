import 'package:flutter/material.dart';

import '../../design/design.dart';
import 'client_models.dart';

class ClientContextPanel extends StatelessWidget {
  static const double width = 220;

  final ClientSection section;
  final String? activeItemId;

  const ClientContextPanel({
    super.key,
    required this.section,
    required this.activeItemId,
  });

  @override
  Widget build(BuildContext context) {
    final panelBg = Color.alphaBlend(
      Colors.black.withValues(alpha: 0.14),
      DsColor.bg,
    );
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: panelBg,
        border: Border(right: BorderSide(color: DsColor.lineStrong)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DsSpace.md + 2,
              DsSpace.lg,
              DsSpace.md + 2,
              DsSpace.sm,
            ),
            child: Row(
              children: [
                Container(width: 6, height: 6, color: DsColor.accent),
                const SizedBox(width: DsSpace.sm),
                Expanded(
                  child: Text(
                    section.label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: DsType.pixelTag.copyWith(color: DsColor.textSoft),
                  ),
                ),
              ],
            ),
          ),
          const DsDivider(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(DsSpace.md),
              children: [
                for (final item in section.items)
                  _ItemTile(item: item, active: item.id == activeItemId),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final ClientSectionItem item;
  final bool active;

  const _ItemTile({required this.item, required this.active});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DsSpace.xs + 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: item.onTap,
          customBorder: const PixelNotchedBorder(notch: 3.0),
          child: active
              ? PixelFrame(
                  notch: 3.0,
                  fillColor: DsColor.accent.withValues(alpha: 0.16),
                  borderColor: DsColor.accent.withValues(alpha: 0.52),
                  topHighlightColor: DsColor.accent.withValues(alpha: 0.22),
                  bottomLipColor: Colors.black.withValues(alpha: 0.36),
                  bottomLipHeight: 2.0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: DsSpace.md,
                    vertical: DsSpace.sm + 3,
                  ),
                  child: Row(
                    children: [
                      Container(width: 5, height: 5, color: DsColor.accent),
                      const SizedBox(width: DsSpace.sm + 2),
                      Expanded(
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DsType.heading.copyWith(
                            fontSize: 13.5,
                            color: DsColor.text,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DsSpace.md,
                    vertical: DsSpace.sm + 3,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 4,
                        color: DsColor.textDisabled,
                      ),
                      const SizedBox(width: DsSpace.sm + 3),
                      Expanded(
                        child: Text(
                          item.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: DsType.body.copyWith(
                            fontSize: 13.5,
                            color: DsColor.textSoft,
                          ),
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

class ClientItemStrip extends StatelessWidget {
  final ClientSection section;
  final String? activeItemId;

  const ClientItemStrip({
    super.key,
    required this.section,
    required this.activeItemId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: DsColor.line)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: DsSpace.md,
          vertical: DsSpace.sm,
        ),
        children: [
          for (final item in section.items)
            Padding(
              padding: const EdgeInsets.only(right: DsSpace.sm),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: item.onTap,
                  borderRadius: DsRadius.controlR,
                  child: Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: DsSpace.md),
                    decoration: BoxDecoration(
                      color: item.id == activeItemId
                          ? DsColor.accent.withValues(alpha: 0.14)
                          : Colors.transparent,
                      borderRadius: DsRadius.controlR,
                    ),
                    child: Text(
                      item.label,
                      maxLines: 1,
                      style: DsType.label.copyWith(
                        color: item.id == activeItemId
                            ? DsColor.text
                            : DsColor.textSoft,
                        fontWeight: item.id == activeItemId
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
