/// In-app products. The IDs must match Play Console > Monetize > In-app products.
enum ProductKind { consumable, nonConsumable }

class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.kind,
    required this.title,
    required this.description,
    required this.fallbackPrice,
    this.coins = 0,
    this.removesAds = false,
    this.grantsPro = false,
    this.badge,
  });

  final String id;
  final ProductKind kind;
  final String title;
  final String description;
  final String fallbackPrice; // shown until the store returns the real price
  final int coins;
  final bool removesAds;
  final bool grantsPro;
  final String? badge;
}

class Products {
  static const String removeAds = 'remove_ads';
  static const String proPass = 'pro_pass';
  static const String coins500 = 'coins_500';
  static const String coins1500 = 'coins_1500';
  static const String coins5000 = 'coins_5000';

  static const List<StoreProduct> all = <StoreProduct>[
    StoreProduct(
      id: removeAds,
      kind: ProductKind.nonConsumable,
      title: 'Remove Ads',
      description: 'No banners or forced videos. Optional reward videos stay.',
      fallbackPrice: '\u20B9149',
      removesAds: true,
    ),
    StoreProduct(
      id: proPass,
      kind: ProductKind.nonConsumable,
      title: 'PRO Pass',
      description: 'Everything in Remove Ads plus the PRO perks below.',
      fallbackPrice: '\u20B9349',
      removesAds: true,
      grantsPro: true,
      badge: 'Best value',
    ),
    StoreProduct(
      id: coins500,
      kind: ProductKind.consumable,
      title: '500 coins',
      description: 'A handful of coins',
      fallbackPrice: '\u20B929',
      coins: 500,
    ),
    StoreProduct(
      id: coins1500,
      kind: ProductKind.consumable,
      title: '1,500 coins',
      description: 'Great for a new style',
      fallbackPrice: '\u20B979',
      coins: 1500,
      badge: 'Popular',
    ),
    StoreProduct(
      id: coins5000,
      kind: ProductKind.consumable,
      title: '5,000 coins',
      description: 'Unlock a lot of styles',
      fallbackPrice: '\u20B9199',
      coins: 5000,
      badge: 'Best deal',
    ),
  ];

  static Set<String> get ids => all.map((p) => p.id).toSet();

  static StoreProduct? byId(String id) {
    for (final p in all) {
      if (p.id == id) return p;
    }
    return null;
  }
}

/// What PRO gives. The game reads the flag; these lines are for the Pro screen.
class ProPerks {
  static const List<(String, String)> list = <(String, String)>[
    ('No ads', 'No banners and no forced videos'),
    ('Unlimited undos', 'Undo as often as you like'),
    ('3 extra bottles per level', 'Instead of just 1'),
    ('1 free hint every level', 'No coins needed'),
    ('Double coins', 'On every level win and daily reward'),
    ('PRO-only styles', 'Obsidian bottles and Royal background'),
  ];
}
