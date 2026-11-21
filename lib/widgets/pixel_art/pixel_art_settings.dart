import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';

/// Selectable living Minecraft biome atmospheres rendered in the desktop
/// backdrop horizon. [autoTime] dynamically adapts to the local clock across
/// morning dawn, daylight valley, sunset village, and night forest.
enum PixelBiome {
  autoTime(Color(0xFF56D4C8)),
  morningDawn(Color(0xFFE6A37A)),
  daylightValley(Color(0xFF5FB8E6)),
  sunsetVillage(Color(0xFFE09243)),
  nightForest(Color(0xFF39B5C2)),
  netherCrimson(Color(0xFFD45B47)),
  endVoid(Color(0xFFA882E0));

  const PixelBiome(this.accent);

  final Color accent;

  String localizedLabel(AppLocalizations l) => switch (this) {
    PixelBiome.autoTime => l.pixelBiomeAutoLabel,
    PixelBiome.morningDawn => l.pixelBiomeMorningLabel,
    PixelBiome.daylightValley => l.pixelBiomeDaylightLabel,
    PixelBiome.sunsetVillage => l.pixelBiomeSunsetLabel,
    PixelBiome.nightForest => l.pixelBiomeNightLabel,
    PixelBiome.netherCrimson => l.pixelBiomeNetherLabel,
    PixelBiome.endVoid => l.pixelBiomeEndLabel,
  };

  String localizedSubtitle(AppLocalizations l) => switch (this) {
    PixelBiome.autoTime => l.pixelBiomeAutoSubtitle,
    PixelBiome.morningDawn => l.pixelBiomeMorningSubtitle,
    PixelBiome.daylightValley => l.pixelBiomeDaylightSubtitle,
    PixelBiome.sunsetVillage => l.pixelBiomeSunsetSubtitle,
    PixelBiome.nightForest => l.pixelBiomeNightSubtitle,
    PixelBiome.netherCrimson => l.pixelBiomeNetherSubtitle,
    PixelBiome.endVoid => l.pixelBiomeEndSubtitle,
  };

  /// Resolves [autoTime] to the concrete biome for the given local clock time;
  /// explicit biomes return themselves unchanged.
  PixelBiome resolveEffective([DateTime? now]) {
    if (this != PixelBiome.autoTime) return this;
    final hour = (now ?? DateTime.now()).hour;
    if (hour >= 6 && hour < 11) return PixelBiome.morningDawn;
    if (hour >= 11 && hour < 17) return PixelBiome.daylightValley;
    if (hour >= 17 && hour < 21) return PixelBiome.sunsetVillage;
    return PixelBiome.nightForest;
  }
}

/// Persisted preferences for MCCompanion's Minecraft pixel-art atmosphere,
/// biome selection, and custom server pixel icons.
class PixelArtSettings {
  PixelArtSettings._();

  static final PixelArtSettings instance = PixelArtSettings._();

  static const String _kEffectsKey = 'pixel_art_effects_enabled';
  static const String _kBeesKey = 'pixel_art_ambient_bees_enabled';
  static const String _kBiomeKey = 'pixel_art_biome_v2';
  static const String _kServerIconsKey = 'pixel_art_server_icons_v1';

  final ValueNotifier<bool> effectsEnabled = ValueNotifier<bool>(true);
  final ValueNotifier<bool> ambientBeesEnabled = ValueNotifier<bool>(true);
  final ValueNotifier<PixelBiome> biome = ValueNotifier<PixelBiome>(
    PixelBiome.autoTime,
  );
  final ValueNotifier<int> serverIconsRevision = ValueNotifier<int>(0);

  final Map<String, String> _serverIcons = <String, String>{};
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      effectsEnabled.value = prefs.getBool(_kEffectsKey) ?? true;
      ambientBeesEnabled.value = prefs.getBool(_kBeesKey) ?? true;

      final savedBiome = prefs.getString(_kBiomeKey);
      if (savedBiome != null) {
        biome.value = PixelBiome.values.firstWhere(
          (b) => b.name == savedBiome,
          orElse: () => PixelBiome.autoTime,
        );
      }

      final rawIcons = prefs.getString(_kServerIconsKey);
      if (rawIcons != null && rawIcons.isNotEmpty) {
        final decoded = jsonDecode(rawIcons);
        if (decoded is Map) {
          _serverIcons
            ..clear()
            ..addEntries(
              decoded.entries.map(
                (e) => MapEntry(e.key.toString(), e.value.toString()),
              ),
            );
        }
      }
    } catch (_) {
      // Keep defaults if preferences are unavailable.
    }
  }

  Future<void> setEffectsEnabled(bool value) async {
    effectsEnabled.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kEffectsKey, value);
    } catch (_) {}
  }

  Future<void> setAmbientBeesEnabled(bool value) async {
    ambientBeesEnabled.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kBeesKey, value);
    } catch (_) {}
  }

  Future<void> setBiome(PixelBiome next) async {
    if (biome.value == next) return;
    biome.value = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kBiomeKey, next.name);
    } catch (_) {}
  }

  Future<void> cycleBiome() async {
    final values = PixelBiome.values;
    final next = values[(values.indexOf(biome.value) + 1) % values.length];
    await setBiome(next);
  }

  String serverKey(String address, int port) =>
      '${address.trim().toLowerCase()}:$port';

  String? getServerIconId(String address, int port) =>
      _serverIcons[serverKey(address, port)];

  Future<void> setServerIconId(String address, int port, String iconId) async {
    final key = serverKey(address, port);
    _serverIcons[key] = iconId;
    serverIconsRevision.value++;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kServerIconsKey, jsonEncode(_serverIcons));
    } catch (_) {}
  }
}
