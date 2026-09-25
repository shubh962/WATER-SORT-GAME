import 'dart:ui' show Color;

enum ThemeKind { skin, background }

/// A cosmetic item bought with coins (or unlocked by PRO).
/// [toJs] is what the HTML game receives; the game has no theme list of its own.
class GameTheme {
  const GameTheme({
    required this.id,
    required this.kind,
    required this.name,
    required this.price,
    required this.colors,
    this.proOnly = false,
    this.glow,
    this.cork,
    this.corkDark,
  });

  final String id;
  final ThemeKind kind;
  final String name;
  final int price; // coins; 0 means free
  final bool proOnly;

  /// skin: [glass]. background: [c1, c2, c3].
  final List<Color> colors;
  final Color? glow;
  final Color? cork;
  final Color? corkDark;

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
      };
    }
    return <String, Object?>{
      'c1': css(colors[0]),
      'c2': css(colors[1]),
      'c3': css(colors[2]),
      'bub': 'rgba(150,200,255,0.08)',
    };
  }
}

class ThemeCatalog {
  static const String defaultSkin = 'skin_classic';
  static const String defaultBg = 'bg_midnight';

  static const List<GameTheme> skins = <GameTheme>[
    GameTheme(id: 'skin_classic', kind: ThemeKind.skin, name: 'Classic', price: 0,
        colors: <Color>[Color(0xFF5BB8EA)], glow: Color(0xFFA8E8FF)),
    GameTheme(id: 'skin_emerald', kind: ThemeKind.skin, name: 'Emerald', price: 400,
        colors: <Color>[Color(0xFF34D399)], glow: Color(0xFFA7F3D0), cork: Color(0xFF8B5A2B), corkDark: Color(0xFF5C3A1A)),
    GameTheme(id: 'skin_sunset', kind: ThemeKind.skin, name: 'Sunset', price: 400,
        colors: <Color>[Color(0xFFFB923C)], glow: Color(0xFFFED7AA)),
    GameTheme(id: 'skin_rose', kind: ThemeKind.skin, name: 'Rose', price: 600,
        colors: <Color>[Color(0xFFF472B6)], glow: Color(0xFFFBCFE8)),
    GameTheme(id: 'skin_neon', kind: ThemeKind.skin, name: 'Neon', price: 800,
        colors: <Color>[Color(0xFFA78BFA)], glow: Color(0xFFDDD6FE), cork: Color(0xFF6D28D9), corkDark: Color(0xFF4C1D95)),
    GameTheme(id: 'skin_gold', kind: ThemeKind.skin, name: 'Gold', price: 1500,
        colors: <Color>[Color(0xFFFBBF24)], glow: Color(0xFFFDE68A), cork: Color(0xFFE5E7EB), corkDark: Color(0xFF9CA3AF)),
    GameTheme(id: 'skin_obsidian', kind: ThemeKind.skin, name: 'Obsidian', price: 0, proOnly: true,
        colors: <Color>[Color(0xFFE5E7EB)], glow: Color(0xFFFFFFFF), cork: Color(0xFF111827), corkDark: Color(0xFF030712)),
  ];

  static const List<GameTheme> backgrounds = <GameTheme>[
    GameTheme(id: 'bg_midnight', kind: ThemeKind.background, name: 'Midnight', price: 0,
        colors: <Color>[Color(0xFF1B2350), Color(0xFF0C1024), Color(0xFF080A18)]),
    GameTheme(id: 'bg_ocean', kind: ThemeKind.background, name: 'Ocean', price: 500,
        colors: <Color>[Color(0xFF0F4C75), Color(0xFF0B2545), Color(0xFF061426)]),
    GameTheme(id: 'bg_forest', kind: ThemeKind.background, name: 'Forest', price: 500,
        colors: <Color>[Color(0xFF14532D), Color(0xFF0A2E1A), Color(0xFF04140B)]),
    GameTheme(id: 'bg_dusk', kind: ThemeKind.background, name: 'Dusk', price: 800,
        colors: <Color>[Color(0xFF7C2D5C), Color(0xFF3B1230), Color(0xFF14061A)]),
    GameTheme(id: 'bg_aurora', kind: ThemeKind.background, name: 'Aurora', price: 1000,
        colors: <Color>[Color(0xFF0F766E), Color(0xFF1E1B4B), Color(0xFF0B0720)]),
    GameTheme(id: 'bg_lava', kind: ThemeKind.background, name: 'Lava', price: 1200,
        colors: <Color>[Color(0xFF7F1D1D), Color(0xFF2A0A0A), Color(0xFF100404)]),
    GameTheme(id: 'bg_royal', kind: ThemeKind.background, name: 'Royal', price: 0, proOnly: true,
        colors: <Color>[Color(0xFF4C1D95), Color(0xFF1E1B4B), Color(0xFF09051A)]),
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
