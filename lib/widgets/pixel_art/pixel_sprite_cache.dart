import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';

/// Metadata describing a horizontal pixel-art sprite sheet.
class PixelSpriteSheetSpec {
  const PixelSpriteSheetSpec({
    required this.assetPath,
    required this.frameWidth,
    required this.frameHeight,
    required this.frameCount,
    required this.frameDuration,
  });

  final String assetPath;
  final int frameWidth;
  final int frameHeight;
  final int frameCount;
  final Duration frameDuration;
}

/// Centralized sprite-sheet definitions for MCCompanion pixel art.
abstract final class PixelArtAssets {
  static const grassBlock = PixelSpriteSheetSpec(
    assetPath: 'assets/pixel_art/grass_block_sheet.png',
    frameWidth: 32,
    frameHeight: 32,
    frameCount: 6,
    frameDuration: Duration(milliseconds: 130),
  );

  static const mcBee = PixelSpriteSheetSpec(
    assetPath: 'assets/pixel_art/mc_bee_sheet.png',
    frameWidth: 32,
    frameHeight: 32,
    frameCount: 6,
    frameDuration: Duration(milliseconds: 80),
  );

  /// 4 particle frames in a horizontal strip:
  /// 0 = grass chunk, 1 = dirt chunk, 2 = XP orb, 3 = pink heart.
  static const particles = PixelSpriteSheetSpec(
    assetPath: 'assets/pixel_art/particles_sheet.png',
    frameWidth: 12,
    frameHeight: 12,
    frameCount: 4,
    frameDuration: Duration(milliseconds: 100),
  );

  /// 8 Minecraft Standard Galactic Alphabet (Enchantment Table) rune glyphs.
  static const enchantRunes = PixelSpriteSheetSpec(
    assetPath: 'assets/pixel_art/enchant_runes_sheet.png',
    frameWidth: 12,
    frameHeight: 12,
    frameCount: 8,
    frameDuration: Duration(milliseconds: 200),
  );

  static const campfire = PixelSpriteSheetSpec(
    assetPath: 'assets/pixel_art/campfire_sheet.png',
    frameWidth: 32,
    frameHeight: 32,
    frameCount: 6,
    frameDuration: Duration(milliseconds: 120),
  );

  static const compass = PixelSpriteSheetSpec(
    assetPath: 'assets/pixel_art/compass_sheet.png',
    frameWidth: 32,
    frameHeight: 32,
    frameCount: 8,
    frameDuration: Duration(milliseconds: 130),
  );

  static const lantern = PixelSpriteSheetSpec(
    assetPath: 'assets/pixel_art/lantern_sheet.png',
    frameWidth: 24,
    frameHeight: 24,
    frameCount: 4,
    frameDuration: Duration(milliseconds: 240),
  );

  static const chest = PixelSpriteSheetSpec(
    assetPath: 'assets/pixel_art/chest_sheet.png',
    frameWidth: 32,
    frameHeight: 32,
    frameCount: 4,
    frameDuration: Duration(milliseconds: 220),
  );

  static const floatingIsland = PixelSpriteSheetSpec(
    assetPath: 'assets/pixel_art/floating_island_sheet.png',
    frameWidth: 64,
    frameHeight: 48,
    frameCount: 4,
    frameDuration: Duration(milliseconds: 240),
  );

  /// 5 static 16x16 icons for the primary desktop navigation rail:
  /// 0 = connector (beacon), 1 = servers (campfire), 2 = tracker (redstone),
  /// 3 = skins (tunic), 4 = lookup (compass).
  static const railIcons = PixelSpriteSheetSpec(
    assetPath: 'assets/pixel_art/rail_icons_sheet.png',
    frameWidth: 16,
    frameHeight: 16,
    frameCount: 5,
    frameDuration: Duration(milliseconds: 200),
  );

  /// 5 static 16x16 icons for the footer utility navigation rail:
  /// 0 = relay (ender pearl), 1 = customize (crafting table),
  /// 2 = support (enchanted book), 3 = feedback (quill & scroll),
  /// 4 = profile (steve head).
  static const railFooterIcons = PixelSpriteSheetSpec(
    assetPath: 'assets/pixel_art/rail_footer_icons_sheet.png',
    frameWidth: 16,
    frameHeight: 16,
    frameCount: 5,
    frameDuration: Duration(milliseconds: 200),
  );

  /// 4 static 16x16 icons for Support & How-To guide topics:
  /// 0 = wifi/LAN signal, 1 = warning alert, 2 = friends, 3 = console gamepad.
  static const guideIcons = PixelSpriteSheetSpec(
    assetPath: 'assets/pixel_art/guide_icons_sheet.png',
    frameWidth: 16,
    frameHeight: 16,
    frameCount: 4,
    frameDuration: Duration(milliseconds: 200),
  );

  /// 4 static 12x12 inline pixel badges replacing OS emojis in guide text:
  /// 0 = check (✅), 1 = sync (🔄), 2 = warning (⚠️), 3 = device (📱).
  static const inlineBadges = PixelSpriteSheetSpec(
    assetPath: 'assets/pixel_art/inline_badges_sheet.png',
    frameWidth: 12,
    frameHeight: 12,
    frameCount: 4,
    frameDuration: Duration(milliseconds: 200),
  );

  static const armorStand = PixelSpriteSheetSpec(
    assetPath: 'assets/pixel_art/armor_stand_sheet.png',
    frameWidth: 32,
    frameHeight: 32,
    frameCount: 4,
    frameDuration: Duration(milliseconds: 220),
  );

  static const enchantedBook = PixelSpriteSheetSpec(
    assetPath: 'assets/pixel_art/enchanted_book_sheet.png',
    frameWidth: 32,
    frameHeight: 32,
    frameCount: 4,
    frameDuration: Duration(milliseconds: 220),
  );

  /// Animated 32x32 Minecraft adventurer bust for login/profile badges.
  static const playerAvatar = PixelSpriteSheetSpec(
    assetPath: 'assets/pixel_art/player_avatar_sheet.png',
    frameWidth: 32,
    frameHeight: 32,
    frameCount: 6,
    frameDuration: Duration(milliseconds: 260),
  );

  /// Crisp 16x16 pixel-art Google "G" emblem for the sign-in button.
  static const googlePixel = PixelSpriteSheetSpec(
    assetPath: 'assets/pixel_art/google_g_pixel.png',
    frameWidth: 16,
    frameHeight: 16,
    frameCount: 1,
    frameDuration: Duration(milliseconds: 200),
  );

  /// Handcrafted Aseprite animated biome landmarks & flora props.
  static const biomeBeacon = PixelSpriteSheetSpec(
    assetPath: 'assets/pixel_art/biome_beacon_sheet.png',
    frameWidth: 48,
    frameHeight: 48,
    frameCount: 6,
    frameDuration: Duration(milliseconds: 320),
  );

  static const biomeCottage = PixelSpriteSheetSpec(
    assetPath: 'assets/pixel_art/biome_cottage_sheet.png',
    frameWidth: 48,
    frameHeight: 44,
    frameCount: 6,
    frameDuration: Duration(milliseconds: 380),
  );

  static const biomeWindmill = PixelSpriteSheetSpec(
    assetPath: 'assets/pixel_art/biome_windmill_sheet.png',
    frameWidth: 56,
    frameHeight: 56,
    frameCount: 8,
    frameDuration: Duration(milliseconds: 260),
  );

  static const biomeRuinedPortal = PixelSpriteSheetSpec(
    assetPath: 'assets/pixel_art/biome_ruined_portal_sheet.png',
    frameWidth: 48,
    frameHeight: 52,
    frameCount: 6,
    frameDuration: Duration(milliseconds: 280),
  );

  static const biomeEndFountain = PixelSpriteSheetSpec(
    assetPath: 'assets/pixel_art/biome_end_fountain_sheet.png',
    frameWidth: 64,
    frameHeight: 48,
    frameCount: 6,
    frameDuration: Duration(milliseconds: 320),
  );

  /// 5 static 32x40 biome flora props:
  /// 0 = spruce pine, 1 = oak tree, 2 = crimson fungus,
  /// 3 = warped fungus, 4 = chorus fruit tree.
  static const biomeFoliage = PixelSpriteSheetSpec(
    assetPath: 'assets/pixel_art/biome_foliage_sheet.png',
    frameWidth: 32,
    frameHeight: 40,
    frameCount: 5,
    frameDuration: Duration(milliseconds: 200),
  );

  /// Arched oak & mossy cobblestone bridge spanning biome lakes/rivers.
  static const biomeBridge = PixelSpriteSheetSpec(
    assetPath: 'assets/pixel_art/biome_bridge_sheet.png',
    frameWidth: 64,
    frameHeight: 24,
    frameCount: 1,
    frameDuration: Duration(milliseconds: 200),
  );

  /// 6 handcrafted 32x36 biome architectural & scenic props:
  /// 0 = bell tower, 1 = mossy well, 2 = hay bales & barrel,
  /// 3 = campfire & lantern post, 4 = nether brazier totem, 5 = end city spire.
  static const biomeVillageProps = PixelSpriteSheetSpec(
    assetPath: 'assets/pixel_art/biome_village_props_sheet.png',
    frameWidth: 32,
    frameHeight: 36,
    frameCount: 6,
    frameDuration: Duration(milliseconds: 200),
  );

  /// 4 handcrafted 80x28 volumetric pixel-art cumulus & stratus cloud sprites.
  static const biomeClouds = PixelSpriteSheetSpec(
    assetPath: 'assets/pixel_art/biome_clouds_sheet.png',
    frameWidth: 80,
    frameHeight: 28,
    frameCount: 4,
    frameDuration: Duration(milliseconds: 200),
  );

  /// 4-frame handcrafted 32x32 Aseprite drifting Nether Ghast.
  static const biomeNetherGhast = PixelSpriteSheetSpec(
    assetPath: 'assets/pixel_art/biome_nether_ghast_sheet.png',
    frameWidth: 32,
    frameHeight: 32,
    frameCount: 4,
    frameDuration: Duration(milliseconds: 320),
  );

  /// 6-frame handcrafted 64x36 Aseprite gliding Ender Dragon.
  static const biomeEndDragon = PixelSpriteSheetSpec(
    assetPath: 'assets/pixel_art/biome_end_dragon_sheet.png',
    frameWidth: 64,
    frameHeight: 36,
    frameCount: 6,
    frameDuration: Duration(milliseconds: 220),
  );

  /// 4 handcrafted 32x48 Nether & End scenic props:
  /// 0 = caged obsidian pillar w/ end crystal, 1 = enderman holding end stone,
  /// 2 = nether strider on lava, 3 = blackstone soul-fire shrine pillar.
  static const biomeEndNetherProps = PixelSpriteSheetSpec(
    assetPath: 'assets/pixel_art/biome_end_nether_props_sheet.png',
    frameWidth: 32,
    frameHeight: 48,
    frameCount: 4,
    frameDuration: Duration(milliseconds: 240),
  );

  /// 18-frame handcrafted 96x20 carved deepslate & sliding diamond splash loading bar.
  static const splashLoader = PixelSpriteSheetSpec(
    assetPath: 'assets/pixel_art/splash_loader_sheet.png',
    frameWidth: 96,
    frameHeight: 20,
    frameCount: 18,
    frameDuration: Duration(milliseconds: 75),
  );

  /// 5 additional handcrafted 32x32 Aseprite selectable server icons.
  static const serverSword = PixelSpriteSheetSpec(
    assetPath: 'assets/pixel_art/server_sword_sheet.png',
    frameWidth: 32,
    frameHeight: 32,
    frameCount: 4,
    frameDuration: Duration(milliseconds: 220),
  );

  static const serverPickaxe = PixelSpriteSheetSpec(
    assetPath: 'assets/pixel_art/server_pickaxe_sheet.png',
    frameWidth: 32,
    frameHeight: 32,
    frameCount: 4,
    frameDuration: Duration(milliseconds: 220),
  );

  static const serverCrown = PixelSpriteSheetSpec(
    assetPath: 'assets/pixel_art/server_crown_sheet.png',
    frameWidth: 32,
    frameHeight: 32,
    frameCount: 4,
    frameDuration: Duration(milliseconds: 220),
  );

  static const serverPortal = PixelSpriteSheetSpec(
    assetPath: 'assets/pixel_art/server_portal_sheet.png',
    frameWidth: 32,
    frameHeight: 32,
    frameCount: 4,
    frameDuration: Duration(milliseconds: 200),
  );

  static const serverCreeper = PixelSpriteSheetSpec(
    assetPath: 'assets/pixel_art/server_creeper_sheet.png',
    frameWidth: 32,
    frameHeight: 32,
    frameCount: 4,
    frameDuration: Duration(milliseconds: 240),
  );

  /// Curated selectable pixel-art server icons for saved servers (10 choices).
  static const List<(String id, PixelSpriteSheetSpec spec)> serverIconChoices =
      <(String, PixelSpriteSheetSpec)>[
        ('grass', grassBlock),
        ('campfire', campfire),
        ('lantern', lantern),
        ('chest', chest),
        ('book', enchantedBook),
        ('sword', serverSword),
        ('pickaxe', serverPickaxe),
        ('crown', serverCrown),
        ('portal', serverPortal),
        ('creeper', serverCreeper),
      ];

  static String serverIconLabel(String id, AppLocalizations l) => switch (id) {
    'grass' => l.serverIconGrass,
    'campfire' => l.serverIconCampfire,
    'lantern' => l.serverIconLantern,
    'chest' => l.serverIconChest,
    'book' => l.serverIconBook,
    'sword' => l.serverIconSword,
    'pickaxe' => l.serverIconPickaxe,
    'crown' => l.serverIconCrown,
    'portal' => l.serverIconPortal,
    'creeper' => l.serverIconCreeper,
    _ => l.serverIconGrass,
  };

  static PixelSpriteSheetSpec serverIconFor(
    String? id, {
    int fallbackIndex = 0,
  }) {
    if (id != null) {
      for (final item in serverIconChoices) {
        if (item.$1 == id) return item.$2;
      }
    }
    return fallbackIndex.isEven ? grassBlock : lantern;
  }
}

/// Decodes each pixel-art sprite sheet once and shares the [ui.Image]
/// across all sprite widgets, particle bursts, and ambient mobs.
class PixelSpriteCache {
  PixelSpriteCache._();

  static final PixelSpriteCache instance = PixelSpriteCache._();

  final Map<String, ui.Image> _images = <String, ui.Image>{};
  final Map<String, Future<ui.Image>> _inFlight = <String, Future<ui.Image>>{};

  ui.Image? getCached(String assetPath) => _images[assetPath];

  Future<ui.Image> load(String assetPath) {
    final existing = _images[assetPath];
    if (existing != null) {
      return SynchronousFuture<ui.Image>(existing);
    }
    return _inFlight.putIfAbsent(assetPath, () async {
      try {
        final data = await rootBundle.load(assetPath);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        final image = frame.image;
        _images[assetPath] = image;
        return image;
      } finally {
        _inFlight.remove(assetPath);
      }
    });
  }

  /// Warm up core sprite sheets so first interactions have zero frame delay.
  Future<void> preloadCoreAssets() async {
    await Future.wait<void>(<Future<void>>[
      load(PixelArtAssets.grassBlock.assetPath).then((_) {}),
      load(PixelArtAssets.mcBee.assetPath).then((_) {}),
      load(PixelArtAssets.particles.assetPath).then((_) {}),
      load(PixelArtAssets.enchantRunes.assetPath).then((_) {}),
      load(PixelArtAssets.campfire.assetPath).then((_) {}),
      load(PixelArtAssets.compass.assetPath).then((_) {}),
      load(PixelArtAssets.lantern.assetPath).then((_) {}),
      load(PixelArtAssets.chest.assetPath).then((_) {}),
      load(PixelArtAssets.floatingIsland.assetPath).then((_) {}),
      load(PixelArtAssets.railIcons.assetPath).then((_) {}),
      load(PixelArtAssets.railFooterIcons.assetPath).then((_) {}),
      load(PixelArtAssets.guideIcons.assetPath).then((_) {}),
      load(PixelArtAssets.inlineBadges.assetPath).then((_) {}),
      load(PixelArtAssets.armorStand.assetPath).then((_) {}),
      load(PixelArtAssets.enchantedBook.assetPath).then((_) {}),
      load(PixelArtAssets.biomeBeacon.assetPath).then((_) {}),
      load(PixelArtAssets.biomeCottage.assetPath).then((_) {}),
      load(PixelArtAssets.biomeWindmill.assetPath).then((_) {}),
      load(PixelArtAssets.biomeRuinedPortal.assetPath).then((_) {}),
      load(PixelArtAssets.biomeEndFountain.assetPath).then((_) {}),
      load(PixelArtAssets.biomeFoliage.assetPath).then((_) {}),
      load(PixelArtAssets.biomeBridge.assetPath).then((_) {}),
      load(PixelArtAssets.biomeVillageProps.assetPath).then((_) {}),
      load(PixelArtAssets.biomeClouds.assetPath).then((_) {}),
      load(PixelArtAssets.biomeNetherGhast.assetPath).then((_) {}),
      load(PixelArtAssets.biomeEndDragon.assetPath).then((_) {}),
      load(PixelArtAssets.biomeEndNetherProps.assetPath).then((_) {}),
      load(PixelArtAssets.splashLoader.assetPath).then((_) {}),
      load(PixelArtAssets.serverSword.assetPath).then((_) {}),
      load(PixelArtAssets.serverPickaxe.assetPath).then((_) {}),
      load(PixelArtAssets.serverCrown.assetPath).then((_) {}),
      load(PixelArtAssets.serverPortal.assetPath).then((_) {}),
      load(PixelArtAssets.serverCreeper.assetPath).then((_) {}),
      load(PixelArtAssets.playerAvatar.assetPath).then((_) {}),
      load(PixelArtAssets.googlePixel.assetPath).then((_) {}),
    ]);
  }
}
