import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../network/nethernet/nethernet_phase.dart';
import '../../theme/app_theme.dart';
import '../../util/user_servers.dart';
import '../../util/connector_prefs.dart';
import '../../util/partners_servers.dart';
import '../../services/navigation_controller.dart';
import '../../util/howto_prefs.dart';
import '../../widgets/dialogs/howto_dialogs.dart';
import '../../widgets/featured_server_banner.dart';
import '../../widgets/pixel_art/pixel_art.dart';
import '../../design/design.dart';
import 'link_panel.dart';

enum PanelMode { lan, friends }

class _ModeConfig {
  final PanelMode mode;
  final FaIconData icon;
  final Color color;
  const _ModeConfig({
    required this.mode,
    required this.icon,
    required this.color,
  });
}

class ConnectionPanel extends StatefulWidget {
  const ConnectionPanel({
    super.key,
    required this.ipController,
    required this.portController,
    required this.broadcastingNotifier,
    this.phaseNotifier,
    required this.onStartBroadcast,
    required this.onStopBroadcast,
    required this.savedServers,
    required this.onServerSelected,
    required this.onManageServers,
    required this.onResourcePack,
    required this.selectedRelayIp,
    required this.onRelayChanged,
    required this.friendsMode,
    required this.onFriendsModeChanged,
    required this.navigationController,
    required this.partnerServersFuture,
    required this.onOpenPartnerServers,
    this.bedrockAccounts = const [],
    this.selectedBedrockXuid,
    this.onBedrockAccountChanged,
    this.navChipsBuilder,
    this.resourcePackConfigured = false,
    this.resourcePackEnabled = false,
    this.resourcePackName,
    this.onResourcePackToggle,
    this.resourcePackLoading = false,
    this.onDeleteServer,
    this.availableHeight,
  });

  final TextEditingController ipController;
  final TextEditingController portController;
  final ValueNotifier<bool> broadcastingNotifier;
  final ValueNotifier<NetherNetPhase>? phaseNotifier;
  final Future<void> Function(PanelMode) onStartBroadcast;
  final VoidCallback onStopBroadcast;
  final List<UserServer> savedServers;
  final Function(UserServer) onServerSelected;
  final VoidCallback onManageServers;
  final VoidCallback onResourcePack;
  final String? selectedRelayIp;
  final void Function(String?) onRelayChanged;
  final bool friendsMode;
  final ValueChanged<bool> onFriendsModeChanged;
  final NavigationController navigationController;
  final Future<List<FeaturedServer>>? partnerServersFuture;
  final VoidCallback onOpenPartnerServers;
  final List<BedrockAccount> bedrockAccounts;
  final String? selectedBedrockXuid;
  final ValueChanged<String>? onBedrockAccountChanged;
  final Widget Function(bool consoleVisible)? navChipsBuilder;

  final bool resourcePackConfigured;
  final bool resourcePackEnabled;
  final String? resourcePackName;
  final ValueChanged<bool>? onResourcePackToggle;
  final bool resourcePackLoading;
  final Function(int index)? onDeleteServer;

  final double? availableHeight;

  @override
  State<ConnectionPanel> createState() => _ConnectionPanelState();
}

class _ConnectionPanelState extends State<ConnectionPanel> {
  PanelMode _mode = PanelMode.lan;

  bool _broadcasting = false;
  bool _starting = false;

  static const _modes = [
    _ModeConfig(
      mode: PanelMode.lan,
      icon: FontAwesomeIcons.xbox,
      color: AppTheme.modeXbox,
    ),
    _ModeConfig(
      mode: PanelMode.friends,
      icon: FontAwesomeIcons.userGroup,
      color: AppTheme.modeFriends,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _mode = widget.friendsMode ? PanelMode.friends : PanelMode.lan;
    unawaited(_restoreMode());
    _broadcasting = widget.broadcastingNotifier.value;

    widget.broadcastingNotifier.addListener(_onBroadcastingChanged);
    widget.ipController.addListener(_onControllerChanged);
    widget.portController.addListener(_onControllerChanged);
  }

  Future<void> _restoreMode() async {
    final saved = await ConnectorPrefs.loadMode();
    if (!mounted || saved == null) return;
    final mode = PanelMode.values.firstWhere(
      (m) => m.name == saved,
      orElse: () => _mode,
    );
    if (mode == _mode) return;
    setState(() => _mode = mode);
    widget.onFriendsModeChanged(mode == PanelMode.friends);
  }

  void _applyMode(PanelMode mode) {
    setState(() => _mode = mode);
    unawaited(ConnectorPrefs.saveMode(mode.name));
    widget.onFriendsModeChanged(mode == PanelMode.friends);
  }

  void _onBroadcastingChanged() {
    if (mounted) {
      setState(() => _broadcasting = widget.broadcastingNotifier.value);
    }
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.broadcastingNotifier.removeListener(_onBroadcastingChanged);
    widget.ipController.removeListener(_onControllerChanged);
    widget.portController.removeListener(_onControllerChanged);
    super.dispose();
  }

  Future<void> _handleStart() async {
    if (_starting || widget.resourcePackLoading) return;
    setState(() => _starting = true);

    try {
      await widget.onStartBroadcast(_mode);
    } finally {
      if (mounted) setState(() => _starting = false);
    }

    if (!mounted || !_broadcasting) return;

    if (!await HowToPrefs.isAutoShowEnabled(HowToTopic.xbox)) return;
    if (!mounted) return;

    switch (_mode) {
      case PanelMode.lan:
        await HowToDialogs.showXboxInstructions(context);
      case PanelMode.friends:
        break;
    }
  }

  String _modeLabel(PanelMode mode, AppLocalizations loc) => switch (mode) {
    PanelMode.lan => loc.labelXbox,
    PanelMode.friends => loc.labelFriends,
  };

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final broadcasting = _broadcasting;

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: wide ? 1180 : 720),
            child: wide
                ? _buildWideLayout(broadcasting, loc)
                : _buildNarrowLayout(broadcasting, loc),
          ),
        );
      },
    );
  }

  Widget _hero(bool broadcasting) => FeaturedServerBanner(
    partnerServersFuture: widget.partnerServersFuture,
    ipController: widget.ipController,
    portController: widget.portController,
    broadcasting: broadcasting,
  );

  Widget _buildNarrowLayout(bool broadcasting, AppLocalizations loc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _hero(broadcasting),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            DsSpace.gutter,
            DsSpace.xl,
            DsSpace.gutter,
            DsSpace.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLinkPanel(broadcasting, loc),
              if (_mode == PanelMode.lan &&
                  widget.bedrockAccounts.length > 1) ...[
                const SizedBox(height: DsSpace.md),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _BedrockAccountSelector(
                    accounts: widget.bedrockAccounts,
                    selectedXuid: widget.selectedBedrockXuid,
                    onChanged: widget.onBedrockAccountChanged,
                    color: _modes.firstWhere((c) => c.mode == _mode).color,
                    enabled: !broadcasting,
                  ),
                ),
              ],
              const SizedBox(height: DsSpace.lg),
              _buildStatus(broadcasting, loc),
              _buildStartButton(broadcasting, loc),
              const SizedBox(height: DsSpace.md),
              Align(
                alignment: Alignment.center,
                child: DsButton(
                  label: loc.console,
                  icon: Icons.terminal_rounded,
                  tone: DsButtonTone.quiet,
                  size: DsButtonSize.small,
                  onPressed: () =>
                      widget.navigationController.showConsole(context),
                ),
              ),
              if (widget.navChipsBuilder != null) ...[
                const SizedBox(height: DsSpace.section),
                widget.navChipsBuilder!(false),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _modeDescription(PanelMode mode, AppLocalizations loc) =>
      switch (mode) {
        PanelMode.lan => loc.howToXboxSubtitle,
        PanelMode.friends => loc.howToFriendsSubtitle,
      };

  IconData _modeIcon(PanelMode mode) => switch (mode) {
    PanelMode.lan => Icons.sports_esports_rounded,
    PanelMode.friends => Icons.group_rounded,
  };

  Widget _buildLinkPanel(bool broadcasting, AppLocalizations loc) {
    return LinkPanel<PanelMode>(
      consoleTitle: loc.modeLabel,
      serverTitle: loc.serversSection,
      manageLabel: loc.manageServers,
      changeLabel: loc.changeLabel,
      chooseLabel: loc.chooseServerTitle,
      modes: [
        for (final cfg in _modes)
          LinkOption(
            value: cfg.mode,
            label: _modeLabel(cfg.mode, loc),
            icon: _modeIcon(cfg.mode),
            description: _modeDescription(cfg.mode, loc),
          ),
      ],
      mode: _mode,
      onModeChanged: broadcasting ? null : _applyMode,
      servers: widget.savedServers,
      selectedAddress: widget.ipController.text.trim(),
      selectedPort: int.tryParse(widget.portController.text),
      onServerSelected: widget.onServerSelected,
      onManageServers: widget.onManageServers,
      broadcasting: broadcasting,
      packTitle: loc.rpScreenTitle,
      packLabel: widget.resourcePackConfigured
          ? (widget.resourcePackName ?? loc.rpScreenTitle)
          : loc.none,
      packStatus: widget.resourcePackConfigured
          ? (widget.resourcePackEnabled ? loc.active : loc.rpDisabled)
          : null,
      packEnabled: widget.resourcePackConfigured && widget.resourcePackEnabled,
      packConfigured: widget.resourcePackConfigured,
      packLoading: widget.resourcePackLoading,
      onPackChange: widget.onResourcePack,
    );
  }

  Widget _buildWideLayout(bool broadcasting, AppLocalizations loc) {
    final selected = _selectedServer;
    final address = widget.ipController.text.trim();
    final hasTarget = address.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DsSpace.xxl,
        DsSpace.xl,
        DsSpace.xxl,
        DsSpace.xl,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(width: 8, height: 8, color: DsColor.accent),
                    const SizedBox(width: DsSpace.sm + 2),
                    Expanded(
                      child: Text(
                        loc.featureLabelConnector,
                        style: DsType.display,
                      ),
                    ),
                    DsBadge(
                      label: broadcasting ? loc.statusOnline : 'BEDROCK',
                      color: broadcasting ? DsColor.success : DsColor.accent,
                      dot: true,
                    ),
                  ],
                ),
                const SizedBox(height: DsSpace.lg),
                DsCard(
                  showRivets: true,
                  highlighted: broadcasting,
                  padding: const EdgeInsets.all(DsSpace.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PixelFrame(
                        notch: 3.5,
                        recessed: true,
                        fillColor: DsColor.inset,
                        borderColor: broadcasting
                            ? DsColor.accent.withValues(alpha: 0.50)
                            : DsColor.lineStrong,
                        padding: const EdgeInsets.all(DsSpace.md + 2),
                        child: Row(
                          children: [
                            ValueListenableBuilder<bool>(
                              valueListenable:
                                  PixelArtSettings.instance.effectsEnabled,
                              builder: (_, effectsOn, _) {
                                if (!effectsOn) return const SizedBox.shrink();
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    right: DsSpace.md,
                                  ),
                                  child: PixelFrame(
                                    notch: 2.5,
                                    fillColor: DsColor.surfaceQuiet,
                                    borderColor: broadcasting
                                        ? DsColor.accent.withValues(alpha: 0.55)
                                        : DsColor.lineStrong,
                                    padding: const EdgeInsets.all(6),
                                    child: ValueListenableBuilder<int>(
                                      valueListenable: PixelArtSettings
                                          .instance
                                          .serverIconsRevision,
                                      builder: (_, _, _) {
                                        final port =
                                            int.tryParse(
                                              widget.portController.text,
                                            ) ??
                                            19132;
                                        final iconId = hasTarget
                                            ? PixelArtSettings.instance
                                                  .getServerIconId(
                                                    address,
                                                    port,
                                                  )
                                            : null;
                                        final spec =
                                            PixelArtAssets.serverIconFor(
                                              iconId,
                                            );
                                        return PixelSpriteAnimation(
                                          spec: spec,
                                          scale: spec == PixelArtAssets.lantern
                                              ? 1.25
                                              : 1.05,
                                          playing: broadcasting,
                                          fixedFrame: broadcasting ? null : 0,
                                        );
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    loc.serversSection.toUpperCase(),
                                    style: DsType.pixelTag.copyWith(
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: DsSpace.xxs),
                                  Text(
                                    selected?.name ??
                                        (hasTarget
                                            ? address
                                            : loc.chooseServerTitle),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: DsType.display.copyWith(fontSize: 23),
                                  ),
                                  if (hasTarget) ...[
                                    const SizedBox(height: DsSpace.xxs),
                                    Text(
                                      '$address:${widget.portController.text}',
                                      style: DsType.mono,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: DsSpace.lg),
                      Text(
                        loc.modeLabel.toUpperCase(),
                        style: DsType.pixelTag.copyWith(fontSize: 10),
                      ),
                      const SizedBox(height: DsSpace.sm),
                      Row(
                        children: [
                          for (final cfg in _modes) ...[
                            if (cfg != _modes.first)
                              const SizedBox(width: DsSpace.sm + 2),
                            Expanded(child: _modeChip(cfg, broadcasting, loc)),
                          ],
                        ],
                      ),
                      if (_mode == PanelMode.lan &&
                          widget.bedrockAccounts.length > 1) ...[
                        const SizedBox(height: DsSpace.md),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: _BedrockAccountSelector(
                            accounts: widget.bedrockAccounts,
                            selectedXuid: widget.selectedBedrockXuid,
                            onChanged: widget.onBedrockAccountChanged,
                            color: _modes
                                .firstWhere((c) => c.mode == _mode)
                                .color,
                            enabled: !broadcasting,
                          ),
                        ),
                      ],
                      const SizedBox(height: DsSpace.lg),
                      _packRow(loc, broadcasting),
                      const SizedBox(height: DsSpace.lg),
                      _buildStatus(broadcasting, loc),
                      _buildStartButton(broadcasting, loc),
                    ],
                  ),
                ),
                const SizedBox(height: DsSpace.lg),
                _hero(broadcasting),
              ],
            ),
          ),
          const SizedBox(width: DsSpace.xl),
          Expanded(flex: 2, child: _buildWideServerList(broadcasting, loc)),
        ],
      ),
    );
  }

  UserServer? get _selectedServer {
    final address = widget.ipController.text.trim();
    final port = int.tryParse(widget.portController.text);
    if (address.isEmpty) return null;
    for (final server in widget.savedServers) {
      if (server.address == address && server.port == port) return server;
    }
    return null;
  }

  Widget _modeChip(_ModeConfig cfg, bool broadcasting, AppLocalizations loc) {
    final active = cfg.mode == _mode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTapDown: broadcasting
            ? null
            : (details) {
                if (PixelArtSettings.instance.effectsEnabled.value) {
                  PixelParticleOverlay.burst(
                    context,
                    details.globalPosition,
                    preset: PixelParticlePreset.xpBurst,
                    count: 4,
                  );
                }
              },
        onTap: broadcasting ? null : () => _applyMode(cfg.mode),
        customBorder: const PixelNotchedBorder(notch: 3.5),
        child: PixelFrame(
          notch: 3.5,
          recessed: !active,
          fillColor: active
              ? DsColor.accent.withValues(alpha: 0.16)
              : DsColor.inset,
          borderColor: active
              ? DsColor.accent.withValues(alpha: 0.72)
              : DsColor.lineStrong,
          topHighlightColor: active
              ? DsColor.accent.withValues(alpha: 0.25)
              : null,
          bottomLipColor: active
              ? Colors.black.withValues(alpha: 0.36)
              : null,
          bottomLipHeight: active ? 2.5 : 0,
          padding: const EdgeInsets.symmetric(
            horizontal: DsSpace.md,
            vertical: DsSpace.md,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (active) ...[
                Container(width: 5, height: 5, color: DsColor.accent),
                const SizedBox(width: DsSpace.sm),
              ],
              Icon(
                _modeIcon(cfg.mode),
                size: 16,
                color: active ? DsColor.accent : DsColor.textFaint,
              ),
              const SizedBox(width: DsSpace.sm),
              Flexible(
                child: Text(
                  _modeLabel(cfg.mode, loc),
                  style: DsType.heading.copyWith(
                    fontSize: 13.5,
                    color: active ? DsColor.text : DsColor.textSoft,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _packRow(AppLocalizations loc, bool broadcasting) {
    final configured = widget.resourcePackConfigured;
    final on = configured && widget.resourcePackEnabled;

    return PixelFrame(
      notch: 3.5,
      recessed: true,
      fillColor: DsColor.inset,
      borderColor: on ? DsColor.accent.withValues(alpha: 0.45) : DsColor.line,
      padding: const EdgeInsets.symmetric(
        horizontal: DsSpace.md,
        vertical: DsSpace.sm + 2,
      ),
      child: Row(
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: PixelArtSettings.instance.effectsEnabled,
            builder: (_, effectsOn, _) {
              if (!effectsOn) {
                return Icon(
                  Icons.extension_rounded,
                  size: 18,
                  color: on ? DsColor.accent : DsColor.textFaint,
                );
              }
              return Opacity(
                opacity: on ? 1.0 : 0.72,
                child: PixelSpriteAnimation(
                  spec: PixelArtAssets.chest,
                  scale: 0.85,
                  playing: on,
                  fixedFrame: on ? null : 0,
                ),
              );
            },
          ),
          const SizedBox(width: DsSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loc.rpScreenTitle.toUpperCase(),
                  style: DsType.pixelTag.copyWith(fontSize: 10),
                ),
                const SizedBox(height: DsSpace.xxs),
                Text(
                  configured
                      ? (widget.resourcePackName ?? loc.rpScreenTitle)
                      : loc.none,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: DsType.bodyStrong,
                ),
              ],
            ),
          ),
          if (configured)
            DsSwitch(
              value: on,
              onChanged: broadcasting || widget.onResourcePackToggle == null
                  ? null
                  : (value) => widget.onResourcePackToggle!(value),
            ),
          const SizedBox(width: DsSpace.sm),
          DsButton(
            label: loc.changeLabel,
            tone: DsButtonTone.neutral,
            size: DsButtonSize.small,
            onPressed: broadcasting ? null : widget.onResourcePack,
          ),
        ],
      ),
    );
  }

  Widget _buildWideServerList(bool broadcasting, AppLocalizations loc) {
    final selectedAddress = widget.ipController.text.trim();
    final selectedPort = int.tryParse(widget.portController.text);
    final servers = widget.savedServers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              color: const Color(0xFFE08E45),
            ),
            const SizedBox(width: DsSpace.sm),
            Expanded(child: Text(loc.serversSection, style: DsType.heading)),
            DsButton(
              label: loc.manageServers,
              icon: Icons.tune_rounded,
              tone: DsButtonTone.neutral,
              size: DsButtonSize.small,
              onPressed: broadcasting ? null : widget.onManageServers,
            ),
          ],
        ),
        const SizedBox(height: DsSpace.md),
        if (servers.isEmpty) ...[
          DsCard(
            showRivets: true,
            padding: EdgeInsets.zero,
            child: CustomPaint(
              painter: _CampfireClearingPainter(baseColor: DsColor.surface),
              child: DsEmptyState(
                icon: Icons.dns_rounded,
                title: loc.chooseServerTitle,
                action: DsButton(
                  label: loc.addServer,
                  icon: Icons.add_rounded,
                  tone: DsButtonTone.accent,
                  size: DsButtonSize.small,
                  onPressed: broadcasting ? null : widget.onManageServers,
                ),
              ),
            ),
          ),
          const SizedBox(height: DsSpace.md),
          DsCard(
            padding: const EdgeInsets.symmetric(
              horizontal: DsSpace.md,
              vertical: DsSpace.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ValueListenableBuilder<bool>(
                  valueListenable: PixelArtSettings.instance.effectsEnabled,
                  builder: (_, effectsOn, _) {
                    if (!effectsOn) {
                      return Icon(
                        Icons.tips_and_updates_outlined,
                        size: 18,
                        color: DsColor.textFaint,
                      );
                    }
                    return const PixelSpriteAnimation(
                      spec: PixelArtAssets.lantern,
                      scale: 1.0,
                      playing: false,
                      fixedFrame: 0,
                    );
                  },
                ),
                const SizedBox(width: DsSpace.md),
                Expanded(
                  child: Text(
                    loc.consoleLanHint,
                    style: DsType.caption,
                  ),
                ),
              ],
            ),
          ),
        ] else
          for (var i = 0; i < servers.length; i++) ...[
            if (i > 0) const SizedBox(height: DsSpace.sm),
            Builder(
              builder: (_) {
                final server = servers[i];
                final isSelected =
                    server.address == selectedAddress &&
                    server.port == selectedPort;
                return DsTile(
                  title: server.name,
                  subtitle: '${server.address}:${server.port}',
                  leading: _SavedServerPixelIcon(
                    address: server.address,
                    port: server.port,
                    fallbackIndex: i,
                    selected: isSelected,
                  ),
                  dense: true,
                  selected: isSelected,
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle_rounded,
                          size: 20,
                          color: DsColor.accent,
                        )
                      : null,
                  onTap: broadcasting
                      ? null
                      : () => widget.onServerSelected(server),
                );
              },
            ),
          ],
      ],
    );
  }

  Widget _buildStatus(bool broadcasting, AppLocalizations loc) {
    final notifier = widget.phaseNotifier;
    if (!broadcasting || notifier == null) return const SizedBox.shrink();

    return ValueListenableBuilder<NetherNetPhase>(
      valueListenable: notifier,
      builder: (context, phase, _) {
        final (String title, String? hint) = switch (phase) {
          NetherNetPhase.waiting => (loc.waitingForConsole, loc.consoleLanHint),
          NetherNetPhase.consoleFound => (loc.consoleFound, null),
          NetherNetPhase.connecting => (loc.consoleConnecting, null),
          NetherNetPhase.connected => (
            loc.consoleHandedOver,
            loc.consoleHandedOverHint,
          ),
          NetherNetPhase.failed => (
            loc.consoleConnectFailed,
            loc.consoleConnectFailedHint,
          ),
        };
        final borderColor = switch (phase) {
          NetherNetPhase.consoleFound ||
          NetherNetPhase.connected => DsColor.success.withValues(alpha: 0.5),
          NetherNetPhase.failed => DsColor.danger.withValues(alpha: 0.5),
          _ => DsColor.line,
        };
        final Widget indicator = switch (phase) {
          NetherNetPhase.consoleFound || NetherNetPhase.connected => Icon(
            Icons.check_circle_rounded,
            size: 18,
            color: DsColor.success,
          ),
          NetherNetPhase.failed => Icon(
            Icons.error_rounded,
            size: 18,
            color: DsColor.danger,
          ),
          _ => SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: DsColor.accent,
            ),
          ),
        };

        return Padding(
          padding: const EdgeInsets.only(bottom: DsSpace.md),
          child: AnimatedContainer(
            duration: DsDuration.normal,
            padding: const EdgeInsets.all(DsSpace.md),
            decoration: BoxDecoration(
              color: DsColor.inset,
              borderRadius: DsRadius.controlR,
              border: Border.all(color: borderColor),
            ),
            child: AnimatedSwitcher(
              duration: DsDuration.normal,
              child: Row(
                key: ValueKey(phase),
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 1),
                    child: indicator,
                  ),
                  const SizedBox(width: DsSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title, style: DsType.bodyStrong),
                        if (hint != null) ...[
                          const SizedBox(height: DsSpace.xxs),
                          Text(hint, style: DsType.caption),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStartButton(bool broadcasting, AppLocalizations loc) {
    final hasServer = widget.ipController.text.trim().isNotEmpty;
    final busy = _starting || widget.resourcePackLoading;
    final enabled = !busy && (broadcasting || hasServer);

    final label = broadcasting
        ? loc.stopBroadcasting
        : switch (_mode) {
            PanelMode.lan => loc.startBroadcasting,
            PanelMode.friends => loc.startFriendsMode,
          };

    return DsButton(
      label: label,
      icon: broadcasting ? Icons.stop_rounded : Icons.play_arrow_rounded,
      tone: broadcasting ? DsButtonTone.danger : DsButtonTone.accent,
      size: DsButtonSize.large,
      busy: busy,
      expand: true,
      onPressed: enabled
          ? (broadcasting ? widget.onStopBroadcast : _handleStart)
          : null,
    );
  }
}

class _BedrockAccountSelector extends StatelessWidget {
  final List<BedrockAccount> accounts;
  final String? selectedXuid;
  final ValueChanged<String>? onChanged;
  final Color color;
  final bool enabled;

  const _BedrockAccountSelector({
    required this.accounts,
    required this.selectedXuid,
    required this.onChanged,
    required this.color,
    required this.enabled,
  });

  BedrockAccount get _selected => accounts.firstWhere(
    (a) => a.xboxXuid == selectedXuid,
    orElse: () => accounts.first,
  );

  @override
  Widget build(BuildContext context) {
    final account = _selected;
    final label = account.xboxGamertag ?? account.xboxXuid;

    return GestureDetector(
      onTap: enabled ? () => _showPicker(context) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.sports_esports_rounded,
            size: 10,
            color: enabled
                ? color.withValues(alpha: 0.70)
                : AppTheme.textDisabled,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: enabled ? AppTheme.textSecondary : AppTheme.textDisabled,
            ),
          ),
          const SizedBox(width: 3),
          Icon(
            Icons.arrow_drop_down_rounded,
            size: 13,
            color: enabled ? AppTheme.textMuted : AppTheme.textDisabled,
          ),
        ],
      ),
    );
  }

  void _showPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surfaceRaisedSolid,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.selectBedrockAccount,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              ...accounts.map((a) {
                final isSelected =
                    a.xboxXuid == selectedXuid ||
                    (selectedXuid == null && a == accounts.first);
                final name = a.xboxGamertag ?? a.xboxXuid;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.sports_esports_rounded,
                    color: isSelected ? AppTheme.accent : AppTheme.textMuted,
                    size: 20,
                  ),
                  title: Text(
                    name,
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.textPrimary
                          : AppTheme.textSecondary,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_rounded,
                          color: AppTheme.accent,
                          size: 18,
                        )
                      : null,
                  onTap: () {
                    onChanged?.call(a.xboxXuid);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _Hoverable extends StatefulWidget {
  final VoidCallback? onTap;
  final Widget Function(bool hovered) builder;

  const _Hoverable({required this.onTap, required this.builder});

  @override
  State<_Hoverable> createState() => _HoverableState();
}

class _HoverableState extends State<_Hoverable> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      onEnter: enabled ? (_) => setState(() => _hovered = true) : null,
      onExit: enabled ? (_) => setState(() => _hovered = false) : null,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: widget.builder(enabled && _hovered),
      ),
    );
  }
}

class _SavedServerPixelIcon extends StatelessWidget {
  const _SavedServerPixelIcon({
    required this.address,
    required this.port,
    required this.fallbackIndex,
    required this.selected,
  });

  final String address;
  final int port;
  final int fallbackIndex;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected
            ? DsColor.accent.withValues(alpha: 0.18)
            : DsColor.inset,
        borderRadius: BorderRadius.circular(DsRadius.control - 2),
        border: Border.all(
          color: selected
              ? DsColor.accent.withValues(alpha: 0.45)
              : DsColor.line,
        ),
      ),
      child: ValueListenableBuilder<bool>(
        valueListenable: PixelArtSettings.instance.effectsEnabled,
        builder: (_, effectsOn, _) {
          if (!effectsOn) {
            return Icon(Icons.dns_rounded, size: 17, color: DsColor.accent);
          }
          return ValueListenableBuilder<int>(
            valueListenable: PixelArtSettings.instance.serverIconsRevision,
            builder: (_, _, _) {
              final iconId = PixelArtSettings.instance.getServerIconId(
                address,
                port,
              );
              final spec = PixelArtAssets.serverIconFor(
                iconId,
                fallbackIndex: fallbackIndex,
              );
              return PixelSpriteAnimation(
                spec: spec,
                scale: spec == PixelArtAssets.lantern ? 1.0 : 0.82,
                playing: false,
                fixedFrame: 0,
              );
            },
          );
        },
      ),
    );
  }
}

/// Subtle, blocky Minecraft night campsite clearing painted behind the
/// crackling Aseprite campfire in the empty Servers dock card.
class _CampfireClearingPainter extends CustomPainter {
  const _CampfireClearingPainter({required this.baseColor});

  final Color baseColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 120 || size.height < 120) return;
    final cx = size.width * 0.5;
    final fireY = 74.0;
    final paint = Paint()..isAntiAlias = false;

    // Soft warm campfire radial light
    final glowRect = Rect.fromCenter(
      center: Offset(cx, fireY),
      width: size.width * 0.85,
      height: 160,
    );
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: <Color>[
          const Color(0xFFE08E45).withValues(alpha: 0.14),
          const Color(0xFFE08E45).withValues(alpha: 0.04),
          Colors.transparent,
        ],
        stops: const <double>[0.0, 0.52, 1.0],
      ).createShader(glowRect);
    canvas.drawRect(glowRect, glowPaint);

    // Subtle pixel stars in upper clearing sky
    paint.color = const Color(0xFFB4CFD9).withValues(alpha: 0.24);
    for (final pt in <Offset>[
      Offset(size.width * 0.16, 26),
      Offset(size.width * 0.28, 18),
      Offset(size.width * 0.76, 22),
      Offset(size.width * 0.85, 34),
      Offset(size.width * 0.64, 15),
    ]) {
      canvas.drawRect(Rect.fromLTWH(pt.dx.roundToDouble(), pt.dy, 2, 2), paint);
    }

    // Distant blocky spruce pines flanking the clearing
    void drawPine(double x, double baseY, double scale) {
      paint.color = Color.alphaBlend(
        const Color(0xFF1A4240).withValues(alpha: 0.65),
        baseColor,
      );
      canvas.drawRect(
        Rect.fromLTWH(x - 10 * scale, baseY - 12 * scale, 20 * scale, 10 * scale),
        paint,
      );
      canvas.drawRect(
        Rect.fromLTWH(x - 6 * scale, baseY - 21 * scale, 12 * scale, 9 * scale),
        paint,
      );
      canvas.drawRect(
        Rect.fromLTWH(x - 2 * scale, baseY - 27 * scale, 4 * scale, 6 * scale),
        paint,
      );
    }

    final groundY = 104.0;
    drawPine(size.width * 0.16, groundY, 1.0);
    drawPine(size.width * 0.25, groundY + 2, 0.78);
    drawPine(size.width * 0.84, groundY, 0.95);
    drawPine(size.width * 0.75, groundY + 2, 0.72);

    // Blocky mossy clearing platform beneath the campfire
    final platW = (size.width * 0.66).clamp(120.0, 230.0);
    final px = (cx - platW / 2).roundToDouble();
    paint.color = const Color(0xFF285936).withValues(alpha: 0.55);
    canvas.drawRect(Rect.fromLTWH(px, groundY, platW, 6), paint);
    paint.color = const Color(0xFF3E8248).withValues(alpha: 0.55);
    canvas.drawRect(Rect.fromLTWH(px + 10, groundY - 2, platW - 20, 3), paint);
    paint.color = const Color(0xFF473022).withValues(alpha: 0.45);
    canvas.drawRect(Rect.fromLTWH(px + 8, groundY + 6, platW - 16, 8), paint);
  }

  @override
  bool shouldRepaint(covariant _CampfireClearingPainter old) =>
      old.baseColor != baseColor;
}
