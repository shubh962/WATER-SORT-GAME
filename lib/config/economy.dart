/// One place for every coin price and reward, so balancing is easy.
/// The game (HTML) receives [prices] at boot, so it never hard-codes them.
class Economy {
  // ---- coin SINKS ----
  static const int hint = 100;
  static const int undoPack = 40; // +3 undos
  static const int extraBottle = 100;
  static const int extraTime = 50; // +30 s on timed levels
  static const int skipLevel = 150;

  // ---- coin SOURCES ----
  static const int freeVideoCoins = 200;
  static const List<int> dailyRewards = <int>[
    50,
    75,
    100,
    150,
    200,
    300,
    500,
  ];

  static Map<String, int> get prices => <String, int>{
        'hint': hint,
        'undo': undoPack,
        'bottle': extraBottle,
        'time': extraTime,
        'skip': skipLevel,
      };

  static const List<(String, String)> uses = <(String, String)>[
    ('Hints', '$hint coins each (max 2 per level)'),
    ('Extra bottle', '$extraBottle coins each (max 2 per level)'),
    ('+3 undos', '$undoPack coins'),
    ('+30 seconds (timed levels)', '$extraTime coins'),
    ('Skip a level', '$skipLevel coins'),
    ('Bottle shapes and backgrounds', '300 to 8,000 coins + level gifts + PRO'),
  ];
}
