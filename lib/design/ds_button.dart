import 'package:flutter/material.dart';

import '../widgets/pixel_art/pixel_art.dart';
import 'ds_hover.dart';
import 'ds_tokens.dart';
import 'pixel_chrome.dart';

enum DsButtonTone { accent, neutral, quiet, danger }

enum DsButtonSize { small, medium, large }

class DsButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final DsButtonTone tone;
  final DsButtonSize size;
  final bool expand;
  final bool busy;
  final Color? accent;
  final PixelParticlePreset? pixelBurst;
  final bool? popGrassBlock;
  final bool enablePixelEffects;

  const DsButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tone = DsButtonTone.accent,
    this.size = DsButtonSize.medium,
    this.expand = false,
    this.busy = false,
    this.accent,
    this.pixelBurst,
    this.popGrassBlock,
    this.enablePixelEffects = true,
  });

  @override
  State<DsButton> createState() => _DsButtonState();
}

class _DsButtonState extends State<DsButton> {
  bool _pressed = false;
  Offset? _lastTapGlobal;

  double get _height => switch (widget.size) {
    DsButtonSize.small => 36,
    DsButtonSize.medium => 46,
    DsButtonSize.large => 54,
  };

  double get _fontSize => switch (widget.size) {
    DsButtonSize.small => 13,
    DsButtonSize.medium => 14.5,
    DsButtonSize.large => 15.5,
  };

  void _triggerEffects() {
    if (!widget.enablePixelEffects) return;
    if (!PixelArtSettings.instance.effectsEnabled.value) return;

    final preset = widget.pixelBurst ??
        switch (widget.tone) {
          DsButtonTone.accent => PixelParticlePreset.grassBlock,
          DsButtonTone.neutral => PixelParticlePreset.grassBlock,
          DsButtonTone.quiet => null,
          DsButtonTone.danger => null,
        };
    if (preset == null) return;

    final popBlock =
        widget.popGrassBlock ?? (widget.tone == DsButtonTone.accent);
    final count = widget.tone == DsButtonTone.accent ? 6 : 4;

    final pos = _lastTapGlobal;
    if (pos != null) {
      PixelParticleOverlay.burst(
        context,
        pos,
        preset: preset,
        count: count,
        popGrassBlock: popBlock,
      );
    } else {
      PixelParticleOverlay.burstFromContext(
        context,
        preset: preset,
        count: count,
        popGrassBlock: popBlock,
      );
    }
  }

  void _handleTap() {
    _triggerEffects();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.busy;
    final tint = widget.accent ?? DsColor.accent;

    final Color background;
    final Color foreground;
    final Color borderColor;
    final Color? topHighlight;
    final Color? bottomLip;
    final bool isQuiet = widget.tone == DsButtonTone.quiet;

    switch (widget.tone) {
      case DsButtonTone.accent:
        background = enabled ? tint : DsColor.surfaceQuiet;
        foreground = enabled ? DsColor.onAccent : DsColor.textDisabled;
        borderColor = enabled
            ? Color.alphaBlend(Colors.white.withValues(alpha: 0.22), tint)
            : DsColor.line;
        topHighlight = enabled ? Colors.white.withValues(alpha: 0.32) : null;
        bottomLip = enabled
            ? Color.alphaBlend(Colors.black.withValues(alpha: 0.38), tint)
            : null;
      case DsButtonTone.neutral:
        background = DsColor.surfaceQuiet;
        foreground = enabled ? DsColor.text : DsColor.textDisabled;
        borderColor = Color.alphaBlend(
          Colors.white.withValues(alpha: 0.12),
          DsColor.surfaceQuiet,
        );
        topHighlight = enabled ? Colors.white.withValues(alpha: 0.09) : null;
        bottomLip = enabled ? Colors.black.withValues(alpha: 0.45) : null;
      case DsButtonTone.quiet:
        background = Colors.transparent;
        foreground = enabled ? DsColor.textSoft : DsColor.textDisabled;
        borderColor = Colors.transparent;
        topHighlight = null;
        bottomLip = null;
      case DsButtonTone.danger:
        background = DsColor.danger.withValues(alpha: enabled ? 0.18 : 0.08);
        foreground = enabled ? DsColor.danger : DsColor.textDisabled;
        borderColor = DsColor.danger.withValues(alpha: enabled ? 0.52 : 0.18);
        topHighlight = enabled ? DsColor.danger.withValues(alpha: 0.25) : null;
        bottomLip = enabled ? Colors.black.withValues(alpha: 0.42) : null;
    }

    final child = widget.busy
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: foreground),
          )
        : Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, size: _fontSize + 3, color: foreground),
                const SizedBox(width: DsSpace.sm),
              ],
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.label,
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'ChakraPetch',
                      color: foreground,
                      fontSize: _fontSize,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.35,
                    ),
                  ),
                ),
              ),
            ],
          );

    final Widget inner = isQuiet
        ? Container(
            height: _height,
            padding: const EdgeInsets.symmetric(horizontal: DsSpace.md),
            alignment: Alignment.center,
            child: child,
          )
        : SizedBox(
            height: _height,
            child: PixelFrame(
              notch: 3.5,
              fillColor: background,
              borderColor: borderColor,
              topHighlightColor: topHighlight,
              bottomLipColor: bottomLip,
              bottomLipHeight: (_pressed && enabled) ? 1.0 : 3.0,
              padding: EdgeInsets.fromLTRB(
                DsSpace.lg,
                0,
                DsSpace.lg,
                (_pressed && enabled) ? 0 : 1.5,
              ),
              child: Center(child: child),
            ),
          );

    return Semantics(
      button: true,
      enabled: enabled,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 70),
        transform: Matrix4.translationValues(0, (_pressed && enabled) ? 2.0 : 0, 0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: enabled ? _handleTap : null,
            onTapDown: enabled
                ? (details) {
                    _lastTapGlobal = details.globalPosition;
                    setState(() => _pressed = true);
                  }
                : null,
            onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
            onTapCancel: enabled
                ? () => setState(() => _pressed = false)
                : null,
            customBorder: const PixelNotchedBorder(notch: 3.5),
            child: DsHover(
              enabled: enabled,
              borderRadius: DsRadius.controlR,
              child: inner,
            ),
          ),
        ),
      ),
    );
  }
}

class DsIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final double size;
  final bool enablePixelEffects;

  const DsIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.color,
    this.size = 40,
    this.enablePixelEffects = true,
  });

  @override
  State<DsIconButton> createState() => _DsIconButtonState();
}

class _DsIconButtonState extends State<DsIconButton> {
  bool _pressed = false;
  Offset? _lastTapGlobal;

  void _handleTap() {
    if (widget.enablePixelEffects &&
        PixelArtSettings.instance.effectsEnabled.value) {
      final pos = _lastTapGlobal;
      if (pos != null) {
        PixelParticleOverlay.burst(
          context,
          pos,
          preset: PixelParticlePreset.xpBurst,
          count: 5,
        );
      } else {
        PixelParticleOverlay.burstFromContext(
          context,
          preset: PixelParticlePreset.xpBurst,
          count: 5,
        );
      }
    }
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final button = AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      transform: Matrix4.translationValues(0, (_pressed && enabled) ? 1.5 : 0, 0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? _handleTap : null,
          onTapDown: enabled
              ? (details) {
                  _lastTapGlobal = details.globalPosition;
                  setState(() => _pressed = true);
                }
              : null,
          onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
          customBorder: const PixelNotchedBorder(notch: 3.0),
          child: DsHover(
            enabled: enabled,
            borderRadius: DsRadius.controlR,
            child: SizedBox(
              width: widget.size,
              height: widget.size,
              child: PixelFrame(
                notch: 3.0,
                fillColor: DsColor.surfaceQuiet,
                borderColor: Color.alphaBlend(
                  Colors.white.withValues(alpha: 0.11),
                  DsColor.surfaceQuiet,
                ),
                topHighlightColor: enabled
                    ? Colors.white.withValues(alpha: 0.08)
                    : null,
                bottomLipColor: enabled
                    ? Colors.black.withValues(alpha: 0.44)
                    : null,
                bottomLipHeight: (_pressed && enabled) ? 1.0 : 2.5,
                child: Center(
                  child: Icon(
                    widget.icon,
                    size: widget.size * 0.45,
                    color: enabled
                        ? (widget.color ?? DsColor.textSoft)
                        : DsColor.textDisabled,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip == null) return button;
    return Tooltip(message: widget.tooltip!, child: button);
  }
}
