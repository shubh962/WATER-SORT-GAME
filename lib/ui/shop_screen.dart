import 'dart:async';

import 'package:flutter/material.dart';
import 'package:water_sort/config/economy.dart';
import 'package:water_sort/models/products.dart';
import 'package:water_sort/services/services.dart';
import 'package:water_sort/ui/routes.dart';
import 'package:water_sort/ui/theme.dart';
import 'package:water_sort/ui/widgets/coin_pill.dart';
import 'package:water_sort/ui/widgets/game_button.dart';
import 'package:water_sort/ui/widgets/screen_scaffold.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  StreamSubscription<String>? _sub;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _sub = Services.iap.messages.listen((String m) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
    });
  }

  @override
  void dispose() {
    unawaited(_sub?.cancel());
    super.dispose();
  }

  Future<void> _watchForCoins() async {
    if (_busy) return;
    setState(() => _busy = true);
    final r = await Services.ads.showRewarded(placement: 'shop_free_coins');
    if (r.rewarded) {
      Services.state.addCoins(Economy.freeVideoCoins, reason: 'shop_video');
    }
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(r.rewarded
          ? '+${Economy.freeVideoCoins} coins!'
          : (r.reason == 'unavailable' ? 'No video available right now. Try again later.' : 'Watch the full video to get coins.')),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Shop',
      onCoinsTap: () {},
      child: ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[Services.state, Services.iap]),
        builder: (BuildContext context, Widget? _) {
          final s = Services.state;
          final iap = Services.iap;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: <Widget>[
              if (!iap.loading && !iap.storeAvailable)
                const _Notice('The store is not available right now. Install the app from Google Play and check your connection to buy items.'),
              _Row(
                leading: const _IconBox(child: Icon(Icons.ondemand_video_rounded, color: Colors.white)),
                title: 'Free coins',
                subtitle: 'Watch a short video',
                action: GameButton(
                  label: '+${Economy.freeVideoCoins}',
                  style: GameButtonStyle.purple,
                  height: 44,
                  fontSize: 18,
                  expand: false,
                  onPressed: _busy ? null : _watchForCoins,
                ),
              ),
              if (!s.pro) ...<Widget>[
                const _Section('Go PRO'),
                _ProductRow(product: Products.byId(Products.proPass)!, highlight: true, onDetails: () => pushPro(context)),
              ],
              if (!s.adsFree) ...<Widget>[
                const _Section('Remove ads'),
                _ProductRow(product: Products.byId(Products.removeAds)!),
              ],
              const _Section('Coin packs'),
              for (final p in Products.all.where((p) => p.kind == ProductKind.consumable)) _ProductRow(product: p),
              const _Section('What are coins for?'),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: panelDecoration(),
                child: Column(
                  children: <Widget>[
                    for (final u in Economy.uses)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: <Widget>[
                            const CoinIcon(size: 18),
                            const SizedBox(width: 10),
                            Expanded(child: Text(u.$1, style: kBody)),
                            Text(u.$2, style: kDim),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: iap.restore,
                  child: const Text('Restore purchases', style: TextStyle(fontFamily: 'Fredoka', color: Color(0xFF8FB6FF), decoration: TextDecoration.underline)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 18, 4, 6),
        child: Text(text, style: kTitle.copyWith(fontSize: 20)),
      );
}

class _Notice extends StatelessWidget {
  const _Notice(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppColors.red.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(14)),
        child: Text(text, style: kDim),
      );
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(color: AppColors.purple, borderRadius: BorderRadius.circular(13)),
        child: Center(child: child),
      );
}

class _Row extends StatelessWidget {
  const _Row({required this.leading, required this.title, required this.subtitle, required this.action, this.badge, this.highlight = false});
  final Widget leading;
  final String title;
  final String subtitle;
  final Widget action;
  final String? badge;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: highlight
          ? BoxDecoration(
              gradient: const LinearGradient(colors: <Color>[Color(0xFF4A2FA8), Color(0xFF8B3F9E)]),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.gold, width: 2),
            )
          : panelDecoration(radius: 18),
      child: Row(
        children: <Widget>[
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Flexible(child: Text(title, style: kBody.copyWith(fontWeight: FontWeight.w700, fontSize: 17))),
                    if (badge != null)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                        decoration: BoxDecoration(color: AppColors.gold, borderRadius: BorderRadius.circular(8)),
                        child: Text(badge!, style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w700, fontSize: 11, color: Color(0xFF3A2A00))),
                      ),
                  ],
                ),
                Text(subtitle, style: kDim.copyWith(fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          action,
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product, this.highlight = false, this.onDetails});
  final StoreProduct product;
  final bool highlight;
  final VoidCallback? onDetails;

  @override
  Widget build(BuildContext context) {
    final iap = Services.iap;
    final pending = iap.isPending(product.id);
    final buyable = iap.isBuyable(product.id);
    final Widget leading;
    if (product.grantsPro) {
      leading = const Icon(Icons.workspace_premium_rounded, size: 40, color: AppColors.gold);
    } else if (product.removesAds) {
      leading = Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(color: const Color(0xFFD63B3B), borderRadius: BorderRadius.circular(13)),
        child: const Icon(Icons.block_rounded, color: Colors.white),
      );
    } else {
      leading = const SizedBox(width: 46, height: 46, child: Center(child: CoinIcon(size: 36)));
    }
    return GestureDetector(
      onTap: onDetails,
      child: _Row(
        leading: leading,
        title: product.title,
        subtitle: product.description,
        badge: product.badge,
        highlight: highlight,
        action: pending
            ? const SizedBox(width: 32, height: 32, child: CircularProgressIndicator(strokeWidth: 3))
            : GameButton(
                label: iap.priceOf(product),
                height: 44,
                fontSize: 17,
                expand: false,
                style: product.kind == ProductKind.consumable ? GameButtonStyle.green : GameButtonStyle.gold,
                onPressed: buyable ? () => unawaited(iap.buy(product)) : null,
              ),
      ),
    );
  }
}
