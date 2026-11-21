import 'package:flutter/material.dart';

import '../widgets/pixel_art/pixel_art.dart';
import 'ds_tokens.dart';
import 'pixel_chrome.dart';

class DsOption<T> {
  final T value;
  final String label;
  final IconData? icon;

  const DsOption({required this.value, required this.label, this.icon});
}

class DsSegmented<T> extends StatelessWidget {
  final List<DsOption<T>> options;
  final T value;
  final ValueChanged<T>? onChanged;

  const DsSegmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PixelFrame(
      notch: 3.5,
      recessed: true,
      fillColor: DsColor.inset,
      borderColor: DsColor.lineStrong,
      padding: const EdgeInsets.all(DsSpace.xs),
      child: Row(
        children: [
          for (final option in options)
            Expanded(child: _segment(context, option)),
        ],
      ),
    );
  }

  Widget _segment(BuildContext context, DsOption<T> option) {
    final selected = option.value == value;
    final enabled = onChanged != null;
    final foreground = selected
        ? DsColor.onAccent
        : enabled
        ? DsColor.textSoft
        : DsColor.textDisabled;

    final innerRow = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (option.icon != null) ...[
          Icon(option.icon, size: 15, color: foreground),
          const SizedBox(width: DsSpace.sm - 2),
        ],
        Flexible(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              option.label,
              maxLines: 1,
              style: TextStyle(
                fontFamily: 'ChakraPetch',
                color: foreground,
                fontSize: 13.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                letterSpacing: 0.25,
              ),
            ),
          ),
        ),
      ],
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTapDown: enabled && !selected
            ? (details) {
                if (PixelArtSettings.instance.effectsEnabled.value) {
                  PixelParticleOverlay.burst(
                    context,
                    details.globalPosition,
                    preset: PixelParticlePreset.xpBurst,
                    count: 4,
                  );
                }
              }
            : null,
        onTap: enabled && !selected ? () => onChanged!(option.value) : null,
        customBorder: const PixelNotchedBorder(notch: 2.5),
        child: SizedBox(
          height: 40,
          child: selected
              ? PixelFrame(
                  notch: 2.5,
                  fillColor: DsColor.accent,
                  borderColor: Color.alphaBlend(
                    Colors.white.withValues(alpha: 0.22),
                    DsColor.accent,
                  ),
                  topHighlightColor: Colors.white.withValues(alpha: 0.28),
                  bottomLipColor: Color.alphaBlend(
                    Colors.black.withValues(alpha: 0.35),
                    DsColor.accent,
                  ),
                  bottomLipHeight: 2.5,
                  padding: const EdgeInsets.symmetric(horizontal: DsSpace.sm),
                  child: Center(child: innerRow),
                )
              : Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: DsSpace.sm),
                  child: innerRow,
                ),
        ),
      ),
    );
  }
}

class DsSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const DsSwitch({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    final track = value
        ? DsColor.accent.withValues(alpha: enabled ? 0.88 : 0.32)
        : DsColor.inset;
    final thumb = value
        ? DsColor.onAccent
        : enabled
        ? DsColor.textSoft
        : DsColor.textDisabled;

    return Semantics(
      toggled: value,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          onTapUp: enabled
              ? (details) {
                  if (PixelArtSettings.instance.effectsEnabled.value) {
                    PixelParticleOverlay.burst(
                      context,
                      details.globalPosition,
                      preset: !value
                          ? PixelParticlePreset.grassBlock
                          : PixelParticlePreset.xpBurst,
                      count: 4,
                    );
                  }
                  onChanged!(!value);
                }
              : null,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 48,
            height: 26,
            child: PixelFrame(
              notch: 2.0,
              recessed: !value,
              fillColor: track,
              borderColor: value
                  ? Color.alphaBlend(
                      Colors.white.withValues(alpha: 0.22),
                      DsColor.accent,
                    )
                  : DsColor.lineStrong,
              padding: const EdgeInsets.all(3),
              child: AnimatedAlign(
                duration: DsDuration.fast,
                curve: Curves.easeOut,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: thumb,
                    border: Border(
                      top: BorderSide(
                        color: Colors.white.withValues(alpha: 0.28),
                        width: 1.5,
                      ),
                      bottom: BorderSide(
                        color: Colors.black.withValues(alpha: 0.35),
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DsField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final int maxLines;
  final bool autofocus;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction? textInputAction;
  final bool obscureText;

  const DsField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.icon,
    this.keyboardType,
    this.enabled = true,
    this.onChanged,
    this.errorText,
    this.maxLines = 1,
    this.autofocus = false,
    this.onSubmitted,
    this.textInputAction,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: DsType.label),
          const SizedBox(height: DsSpace.sm - 2),
        ],
        TextField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          onChanged: onChanged,
          maxLines: maxLines,
          autofocus: autofocus,
          onSubmitted: onSubmitted,
          textInputAction: textInputAction,
          obscureText: obscureText,
          style: DsType.body,
          cursorColor: DsColor.accent,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: DsType.body.copyWith(color: DsColor.textDisabled),
            prefixIcon: icon == null
                ? null
                : Icon(icon, size: 18, color: DsColor.textFaint),
            filled: true,
            fillColor: DsColor.inset,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: DsSpace.lg,
              vertical: DsSpace.md + 2,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: DsRadius.controlR,
              borderSide: BorderSide(color: DsColor.line),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: DsRadius.controlR,
              borderSide: BorderSide(color: DsColor.accent, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: DsRadius.controlR,
              borderSide: BorderSide(color: DsColor.line),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: DsRadius.controlR,
              borderSide: const BorderSide(color: DsColor.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: DsRadius.controlR,
              borderSide: const BorderSide(color: DsColor.danger, width: 1.5),
            ),
            errorText: errorText,
            errorStyle: DsType.caption.copyWith(color: DsColor.danger),
          ),
        ),
      ],
    );
  }
}

class DsBadge extends StatelessWidget {
  final String label;
  final Color color;
  final bool dot;

  const DsBadge({
    super.key,
    required this.label,
    required this.color,
    this.dot = false,
  });

  @override
  Widget build(BuildContext context) {
    return PixelFrame(
      notch: 2.0,
      fillColor: color.withValues(alpha: 0.14),
      borderColor: color.withValues(alpha: 0.38),
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpace.sm + 2,
        vertical: DsSpace.xs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(width: 5, height: 5, color: color),
            const SizedBox(width: DsSpace.sm - 2),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontFamily: 'JetBrainsMono',
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
