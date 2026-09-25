/// One place for every coin price and reward, so balancing is easy.
/// The game (HTML) receives [prices] at boot, so it never hard-codes them.
class Economy {
  // ---- coin SINKS (what coins are for) ----
  static const int hint = 30;
  static const int undoPack = 40; // +3 undos
  static const int extraBottle = 60;
  static const int extraTime = 50; // +30 s on timed levels
  static const int skipLevel = 150;
  // Themes have their own prices in themes.dart (400 to 1500 coins).

  // ---- coin SOURCES ----
  static const int freeVideoCoins = 200; // rewarded video in the shop
  static const List<int> dailyRewards = <int>[50, 75, 100, 150, 200, 300, 500];
  // Level wins pay 40 to 120+ coins (computed in the game), doubled for PRO.

  static Map<String, int> get prices => <String, int>{
        'hint': hint,
        'undo': undoPack,
        'bottle': extraBottle,
        'time': extraTime,
        'skip': skipLevel,
      };

  /// Text for the "What are coins for?" card.
  static const List<(String, String)> uses = <(String, String)>[
    ('Hints', '$hint coins'),
    ('+3 undos', '$undoPack coins'),
    ('Extra bottle', '$extraBottle coins'),
    ('+30 seconds (timed levels)', '$extraTime coins'),
    ('Skip a level', '$skipLevel coins'),
    ('Bottle styles and backgrounds', '400 to 1,500 coins'),
  ];
}
