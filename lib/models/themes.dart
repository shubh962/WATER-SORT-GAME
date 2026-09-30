import 'dart:ui' show Color;

enum ThemeKind { skin, background }

/// Cosmetic catalog used by the Flutter Styles screen and mirrored by the
/// HTML5 renderer through the small `skin` / `bg` JSON payload.
///
/// Existing theme IDs are intentionally preserved so players who already
/// owned Classic/Emerald/Sunset/Rose/Neon/Gold/Obsidian/Crystal keep them.
class GameTheme {
  const GameTheme({
    required this.id,
    required this.kind,
    required this.name,
    required this.price,
    required this.colors,
    this.proOnly = false,
    this.unlockLevel,
    this.glow,
    this.cork,
    this.corkDark,
    this.shape = 'classic',
    this.effect = 'midnight',
    this.assetPath,
  });

  final String id;
  final ThemeKind kind;
  final String name;
  final int price;
  final bool proOnly;
  final int? unlockLevel;
  final List<Color> colors;
  final Color? glow;
  final Color? cork;
  final Color? corkDark;
  final String shape;
  final String effect;
  final String? assetPath;

  static String css(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';

  static String rgba(Color c, double a) =>
      'rgba(${(c.r * 255).round()},${(c.g * 255).round()},${(c.b * 255).round()},$a)';

  Map<String, Object?> toJs() {
    if (kind == ThemeKind.skin) {
      final glass = colors.first;
      return <String, Object?>{
        'glass': css(glass),
        'glow': css(glow ?? glass),
        'tint': rgba(glass, 0.08),
        'rim': rgba(glass, 0.55),
        'cork': css(cork ?? const Color(0xFFC98B4B)),
        'corkDark': css(corkDark ?? const Color(0xFFA56A30)),
        'shape': shape,
      };
    }

    return <String, Object?>{
      'c1': css(colors[0]),
      'c2': css(colors[1]),
      'c3': css(colors[2]),
      'bub': 'rgba(150,200,255,0.08)',
      'effect': effect,
      if (assetPath != null) 'assetPath': assetPath,
    };
  }
}

class ThemeCatalog {
  static const String defaultSkin = 'skin_classic';
  static const String defaultBg = 'bg_midnight';

  /// 32 bottle silhouettes: 8 legacy skins + 19 coin skins + 5 level gifts.
  /// The legacy IDs/prices are kept unchanged for backward compatibility.
  static const List<GameTheme> skins = <GameTheme>[
    // ---- Existing skins: DO NOT rename/remove these IDs. ----
    GameTheme(
      id: 'skin_classic',
      kind: ThemeKind.skin,
      name: 'Classic',
      price: 0,
      colors: <Color>[Color(0xFF5BB8EA)],
      glow: Color(0xFFA8E8FF),
      shape: 'classic',
    ),
    GameTheme(
      id: 'skin_emerald',
      kind: ThemeKind.skin,
      name: 'Emerald',
      price: 400,
      colors: <Color>[Color(0xFF34D399)],
      glow: Color(0xFFA7F3D0),
      cork: Color(0xFF8B5A2B),
      corkDark: Color(0xFF5C3A1A),
      shape: 'potion',
    ),
    GameTheme(
      id: 'skin_sunset',
      kind: ThemeKind.skin,
      name: 'Sunset',
      price: 400,
      colors: <Color>[Color(0xFFFB923C)],
      glow: Color(0xFFFED7AA),
      shape: 'flask',
    ),
    GameTheme(
      id: 'skin_rose',
      kind: ThemeKind.skin,
      name: 'Rose',
      price: 600,
      colors: <Color>[Color(0xFFF472B6)],
      glow: Color(0xFFFBCFE8),
      shape: 'perfume',
    ),
    GameTheme(
      id: 'skin_neon',
      kind: ThemeKind.skin,
      name: 'Neon',
      price: 800,
      colors: <Color>[Color(0xFFA78BFA)],
      glow: Color(0xFFDDD6FE),
      cork: Color(0xFF6D28D9),
      corkDark: Color(0xFF4C1D95),
      shape: 'neon',
    ),
    GameTheme(
      id: 'skin_gold',
      kind: ThemeKind.skin,
      name: 'Gold',
      price: 1500,
      colors: <Color>[Color(0xFFFBBF24)],
      glow: Color(0xFFFDE68A),
      cork: Color(0xFFE5E7EB),
      corkDark: Color(0xFF9CA3AF),
      shape: 'royale',
    ),
    GameTheme(
      id: 'skin_obsidian',
      kind: ThemeKind.skin,
      name: 'Obsidian',
      price: 0,
      proOnly: true,
      colors: <Color>[Color(0xFFE5E7EB)],
      glow: Color(0xFFFFFFFF),
      cork: Color(0xFF111827),
      corkDark: Color(0xFF030712),
      shape: 'obsidian',
    ),
    GameTheme(
      id: 'skin_crystal',
      kind: ThemeKind.skin,
      name: 'Crystal',
      price: 1000,
      colors: <Color>[Color(0xFF67E8F9)],
      glow: Color(0xFFCFFAFE),
      shape: 'crystal',
    ),

    // ---- New coin skins ----
    GameTheme(
      id: 'skin_slim', kind: ThemeKind.skin, name: 'Slim Tube', price: 300,
      colors: <Color>[Color(0xFF60A5FA)], glow: Color(0xFFBFDBFE), shape: 'slim',
    ),
    GameTheme(
      id: 'skin_tall_flask', kind: ThemeKind.skin, name: 'Tall Flask', price: 700,
      colors: <Color>[Color(0xFF38BDF8)], glow: Color(0xFFBAE6FD), shape: 'tall_flask',
    ),
    GameTheme(
      id: 'skin_cork_flask', kind: ThemeKind.skin, name: 'Cork Flask', price: 900,
      colors: <Color>[Color(0xFFFB923C)], glow: Color(0xFFFED7AA),
      cork: Color(0xFF9A6338), corkDark: Color(0xFF5E351B), shape: 'cork_flask',
    ),
    GameTheme(
      id: 'skin_square', kind: ThemeKind.skin, name: 'Square', price: 1500,
      colors: <Color>[Color(0xFF22D3EE)], glow: Color(0xFFCFFAFE), shape: 'square',
    ),
    GameTheme(
      id: 'skin_round', kind: ThemeKind.skin, name: 'Round', price: 1800,
      colors: <Color>[Color(0xFFFB7185)], glow: Color(0xFFFFCBD5), shape: 'round',
    ),
    GameTheme(
      id: 'skin_bulb', kind: ThemeKind.skin, name: 'Bulb', price: 2200,
      colors: <Color>[Color(0xFFA78BFA)], glow: Color(0xFFE9D5FF), shape: 'bulb',
    ),
    GameTheme(
      id: 'skin_decanter', kind: ThemeKind.skin, name: 'Decanter', price: 2600,
      colors: <Color>[Color(0xFF60A5FA)], glow: Color(0xFFBFDBFE),
      cork: Color(0xFFD6A15D), corkDark: Color(0xFF8B5A2B), shape: 'decanter',
    ),
    GameTheme(
      id: 'skin_wide_flask', kind: ThemeKind.skin, name: 'Wide Flask', price: 3000,
      colors: <Color>[Color(0xFF34D399)], glow: Color(0xFFA7F3D0), shape: 'wide_flask',
    ),
    GameTheme(
      id: 'skin_beaker', kind: ThemeKind.skin, name: 'Beaker', price: 3400,
      colors: <Color>[Color(0xFF2DD4BF)], glow: Color(0xFF99F6E4), shape: 'beaker',
    ),
    GameTheme(
      id: 'skin_double_bubble', kind: ThemeKind.skin, name: 'Twin Bubble', price: 3800,
      colors: <Color>[Color(0xFF38BDF8)], glow: Color(0xFFBAE6FD), shape: 'double_bubble',
    ),
    GameTheme(
      id: 'skin_hex', kind: ThemeKind.skin, name: 'Hex Jewel', price: 4200,
      colors: <Color>[Color(0xFF818CF8)], glow: Color(0xFFC7D2FE), shape: 'hex',
    ),
    GameTheme(
      id: 'skin_diamond', kind: ThemeKind.skin, name: 'Diamond', price: 4600,
      colors: <Color>[Color(0xFF67E8F9)], glow: Color(0xFFCFFAFE), shape: 'diamond',
    ),
    GameTheme(
      id: 'skin_twist', kind: ThemeKind.skin, name: 'Twist', price: 5000,
      colors: <Color>[Color(0xFFF472B6)], glow: Color(0xFFFBCFE8), shape: 'twist',
    ),
    GameTheme(
      id: 'skin_teardrop', kind: ThemeKind.skin, name: 'Teardrop', price: 5500,
      colors: <Color>[Color(0xFF22D3EE)], glow: Color(0xFFCFFAFE), shape: 'teardrop',
    ),
    GameTheme(
      id: 'skin_cone', kind: ThemeKind.skin, name: 'Conical', price: 6000,
      colors: <Color>[Color(0xFFFBBF24)], glow: Color(0xFFFDE68A), shape: 'cone',
    ),
    GameTheme(
      id: 'skin_jar', kind: ThemeKind.skin, name: 'Jewel Jar', price: 6500,
      colors: <Color>[Color(0xFFA78BFA)], glow: Color(0xFFE9D5FF), shape: 'jar',
    ),
    GameTheme(
      id: 'skin_amphora', kind: ThemeKind.skin, name: 'Amphora', price: 7000,
      colors: <Color>[Color(0xFFFB923C)], glow: Color(0xFFFED7AA), shape: 'amphora',
    ),
    GameTheme(
      id: 'skin_spiral', kind: ThemeKind.skin, name: 'Spiral', price: 7500,
      colors: <Color>[Color(0xFFEC4899)], glow: Color(0xFFF9A8D4), shape: 'spiral',
    ),
    GameTheme(
      id: 'skin_crown', kind: ThemeKind.skin, name: 'Crown', price: 8000,
      colors: <Color>[Color(0xFFFBBF24)], glow: Color(0xFFFDE68A),
      cork: Color(0xFFE5E7EB), corkDark: Color(0xFF9CA3AF), shape: 'crown',
    ),

    // ---- Level gifts: no coins required; permanently unlocked by progress. ----
    GameTheme(
      id: 'skin_heart_gift', kind: ThemeKind.skin, name: 'Heart Gift', price: 0,
      unlockLevel: 20, colors: <Color>[Color(0xFFF43F5E)],
      glow: Color(0xFFFFA3B4), shape: 'heart',
    ),
    GameTheme(
      id: 'skin_star_gift', kind: ThemeKind.skin, name: 'Star Gift', price: 0,
      unlockLevel: 30, colors: <Color>[Color(0xFFFBBF24)],
      glow: Color(0xFFFDE68A), shape: 'star',
    ),
    GameTheme(
      id: 'skin_capsule_gift', kind: ThemeKind.skin, name: 'Capsule Gift', price: 0,
      unlockLevel: 40, colors: <Color>[Color(0xFF34D399)],
      glow: Color(0xFFA7F3D0), shape: 'capsule',
    ),
    GameTheme(
      id: 'skin_jewel_gift', kind: ThemeKind.skin, name: 'Jewel Gift', price: 0,
      unlockLevel: 50, colors: <Color>[Color(0xFFA855F7)],
      glow: Color(0xFFE9D5FF), shape: 'jewel',
    ),
    GameTheme(
      id: 'skin_grand_gift', kind: ThemeKind.skin, name: 'Grand Gift', price: 0,
      unlockLevel: 60, colors: <Color>[Color(0xFF06B6D4)],
      glow: Color(0xFFA5F3FC), shape: 'grand',
    ),
  ];

  static const List<GameTheme> backgrounds = <GameTheme>[
    // Existing background IDs/prices are preserved.
    GameTheme(
      id: 'bg_midnight', kind: ThemeKind.background, name: 'Midnight', price: 0,
      colors: <Color>[Color(0xFF1B2350), Color(0xFF0C1024), Color(0xFF080A18)],
      effect: 'midnight',
    ),
    GameTheme(
      id: 'bg_ocean', kind: ThemeKind.background, name: 'Ocean', price: 500,
      colors: <Color>[Color(0xFF0F4C75), Color(0xFF0B2545), Color(0xFF061426)],
      effect: 'ocean',
    ),
    GameTheme(
      id: 'bg_forest', kind: ThemeKind.background, name: 'Forest', price: 500,
      colors: <Color>[Color(0xFF14532D), Color(0xFF0A2E1A), Color(0xFF04140B)],
      effect: 'forest',
    ),
    GameTheme(
      id: 'bg_dusk', kind: ThemeKind.background, name: 'Dusk', price: 800,
      colors: <Color>[Color(0xFF7C2D5C), Color(0xFF3B1230), Color(0xFF14061A)],
      effect: 'dusk',
    ),
    GameTheme(
      id: 'bg_aurora', kind: ThemeKind.background, name: 'Aurora', price: 1000,
      colors: <Color>[Color(0xFF0F766E), Color(0xFF1E1B4B), Color(0xFF0B0720)],
      effect: 'aurora',
    ),
    GameTheme(
      id: 'bg_lava', kind: ThemeKind.background, name: 'Lava', price: 1200,
      colors: <Color>[Color(0xFF7F1D1D), Color(0xFF2A0A0A), Color(0xFF100404)],
      effect: 'lava',
    ),
    GameTheme(
      id: 'bg_royal', kind: ThemeKind.background, name: 'Royal', price: 0,
      proOnly: true,
      colors: <Color>[Color(0xFF4C1D95), Color(0xFF1E1B4B), Color(0xFF09051A)],
      effect: 'royal',
    ),
    GameTheme(
      id: 'bg_sakura', kind: ThemeKind.background, name: 'Sakura', price: 900,
      colors: <Color>[Color(0xFF7A315B), Color(0xFF32152C), Color(0xFF100814)],
      effect: 'sakura',
    ),
    GameTheme(
      id: 'bg_desert', kind: ThemeKind.background, name: 'Desert', price: 900,
      colors: <Color>[Color(0xFF8B4A2F), Color(0xFF3B1F1A), Color(0xFF140C0C)],
      effect: 'desert',
    ),
    GameTheme(
      id: 'bg_arctic', kind: ThemeKind.background, name: 'Arctic', price: 1100,
      colors: <Color>[Color(0xFF2C6A8A), Color(0xFF102E45), Color(0xFF07131F)],
      effect: 'arctic',
    ),
    GameTheme(
      id: 'bg_galaxy', kind: ThemeKind.background, name: 'Galaxy', price: 1500,
      colors: <Color>[Color(0xFF422A75), Color(0xFF120B2D), Color(0xFF05030F)],
      effect: 'galaxy',
    ),
    GameTheme(
      id: 'bg_cyber', kind: ThemeKind.background, name: 'Cyber', price: 1400,
      colors: <Color>[Color(0xFF153E55), Color(0xFF07151E), Color(0xFF02070D)],
      effect: 'cyber',
    ),

    // Optimized WebP backgrounds already generated for the project.
    GameTheme(
      id: 'bg_crystal_falls', kind: ThemeKind.background, name: 'Crystal Falls', price: 0,
      assetPath: 'assets/web/backgrounds/crystal_falls.webp',
      colors: <Color>[Color(0xFF2E9AD0), Color(0xFF0D4772), Color(0xFF061A2C)],
      effect: 'crystal_falls',
    ),
    GameTheme(
      id: 'bg_cosmic_galaxy', kind: ThemeKind.background, name: 'Cosmic Galaxy', price: 1000,
      assetPath: 'assets/web/backgrounds/cosmic_galaxy.webp',
      colors: <Color>[Color(0xFF5B2A9D), Color(0xFF16104A), Color(0xFF05030F)],
      effect: 'cosmic_galaxy',
    ),
    GameTheme(
      id: 'bg_golden_sunset', kind: ThemeKind.background, name: 'Golden Sunset', price: 2500,
      assetPath: 'assets/web/backgrounds/golden_sunset.webp',
      colors: <Color>[Color(0xFFFF9A3D), Color(0xFF9B315E), Color(0xFF180A24)],
      effect: 'golden_sunset',
    ),
    GameTheme(
      id: 'bg_candy_dreams', kind: ThemeKind.background, name: 'Candy Dreams', price: 5000,
      assetPath: 'assets/web/backgrounds/candy_dreams.webp',
      colors: <Color>[Color(0xFFFF8ED8), Color(0xFF9B5DE5), Color(0xFF32104F)],
      effect: 'candy_dreams',
    ),
    GameTheme(
      id: 'bg_moonlit_haven', kind: ThemeKind.background, name: 'Moonlit Haven', price: 0,
      unlockLevel: 40,
      assetPath: 'assets/web/backgrounds/moonlit_haven.webp',
      colors: <Color>[Color(0xFF173D72), Color(0xFF0A1C3A), Color(0xFF040A18)],
      effect: 'moonlit_haven',
    ),
  ];

  static List<GameTheme> get all => <GameTheme>[...skins, ...backgrounds];

  static GameTheme? byId(String id) {
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }

  static GameTheme skin(String id) =>
      skins.firstWhere((t) => t.id == id, orElse: () => skins.first);

  static GameTheme background(String id) =>
      backgrounds.firstWhere((t) => t.id == id, orElse: () => backgrounds.first);
}
