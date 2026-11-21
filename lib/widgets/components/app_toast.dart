import 'dart:async';
import 'package:flutter/material.dart';
import '../../design/design.dart';
import '../../theme/app_theme.dart';
import '../pixel_art/pixel_art.dart';

class AppToast {
  static OverlayEntry? _current;

  static void show(
    BuildContext context, {
    required String message,
    IconData? icon,
    Color? color,
    Duration duration = const Duration(seconds: 3),
  }) {
    _current?.remove();
    _current = null;

    final entry = OverlayEntry(
      builder: (_) => _AppToastWidget(
        message: message,
        icon: icon,
        color: color ?? AppTheme.accent,
        onDone: () {
          _current?.remove();
          _current = null;
        },
        duration: duration,
      ),
    );

    _current = entry;
    Overlay.of(context).insert(entry);
  }
}

class _AppToastWidget extends StatefulWidget {
  const _AppToastWidget({
    required this.message,
    required this.icon,
    required this.color,
    required this.onDone,
    required this.duration,
  });

  final String message;
  final IconData? icon;
  final Color color;
  final VoidCallback onDone;
  final Duration duration;

  @override
  State<_AppToastWidget> createState() => _AppToastWidgetState();
}

class _AppToastWidgetState extends State<_AppToastWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..forward();

    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    Future.delayed(widget.duration, () async {
      if (!mounted) return;
      await _ctrl.reverse();
      widget.onDone();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectsOn = PixelArtSettings.instance.effectsEnabled.value;
    return Positioned(
      bottom: 24,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Material(
            color: Colors.transparent,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: PixelFrame(
                  notch: 4.0,
                  showRivets: true,
                  enableTexture: true,
                  fillColor: DsColor.surface,
                  borderColor: widget.color.withValues(alpha: 0.62),
                  topHighlightColor: widget.color.withValues(alpha: 0.28),
                  bottomLipColor: Colors.black.withValues(alpha: 0.50),
                  bottomLipHeight: 3.0,
                  rivetColor: widget.color.withValues(alpha: 0.55),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PixelFrame(
                        notch: 2.0,
                        recessed: true,
                        fillColor: DsColor.inset,
                        borderColor: widget.color.withValues(alpha: 0.42),
                        padding: const EdgeInsets.all(6),
                        child: effectsOn
                            ? const PixelSpriteAnimation(
                                spec: PixelArtAssets.grassBlock,
                                width: 22,
                                height: 22,
                                playing: false,
                                fixedFrame: 0,
                              )
                            : Icon(
                                widget.icon ?? Icons.check_rounded,
                                size: 16,
                                color: widget.color,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'MCCOMPANION',
                              style: DsType.pixelTag.copyWith(
                                fontSize: 9.5,
                                color: widget.color,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.message,
                              style: DsType.heading.copyWith(
                                fontSize: 13.5,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
