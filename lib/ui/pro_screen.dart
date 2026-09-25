import 'dart:async';

import 'package:flutter/material.dart';
import 'package:water_sort/models/products.dart';
import 'package:water_sort/services/services.dart';
import 'package:water_sort/ui/routes.dart';
import 'package:water_sort/ui/theme.dart';
import 'package:water_sort/ui/widgets/game_button.dart';
import 'package:water_sort/ui/widgets/screen_scaffold.dart';

class ProScreen extends StatefulWidget {
  const ProScreen({super.key});

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  StreamSubscription<String>? _sub;

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

  @override
  Widget build(BuildContext context) {
    final product = Products.byId(Products.proPass)!;
    return ScreenScaffold(
      title: 'PRO',
      onCoinsTap: () => pushShop(context),
      child: ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[Services.state, Services.iap]),
        builder: (BuildContext context, Widget? _) {
          final iap = Services.iap;
          final isPro = Services.state.pro;
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: <Color>[Color(0xFF6A3FD8), Color(0xFFF472D0)]),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x66000000), offset: Offset(0, 10), blurRadius: 18)],
                ),
                child: Column(
                  children: <Widget>[
                    const Icon(Icons.workspace_premium_rounded, size: 64, color: AppColors.gold),
                    const SizedBox(height: 6),
                    Text(isPro ? 'You are PRO' : 'Water Sort PRO', style: kTitle.copyWith(fontSize: 30)),
                    const SizedBox(height: 4),
                    Text(isPro ? 'Thank you for supporting the game!' : 'One purchase. Yours forever.', style: kBody, textAlign: TextAlign.center),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: panelDecoration(),
                child: Column(
                  children: <Widget>[
                    for (final perk in ProPerks.list)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        child: Row(
                          children: <Widget>[
                            const Icon(Icons.check_circle_rounded, color: AppColors.green),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(perk.$1, style: kBody.copyWith(fontWeight: FontWeight.w700)),
                                  Text(perk.$2, style: kDim.copyWith(fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              if (!isPro) ...<Widget>[
                if (iap.isPending(product.id))
                  const Center(child: CircularProgressIndicator())
                else
                  GameButton(
                    label: 'Get PRO  ${iap.priceOf(product)}',
                    style: GameButtonStyle.gold,
                    height: 66,
                    fontSize: 26,
                    onPressed: iap.isBuyable(product.id) ? () => unawaited(iap.buy(product)) : null,
                  ),
                if (!iap.loading && !iap.storeAvailable)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text('The store is not available right now.', style: kDim, textAlign: TextAlign.center),
                  ),
                const SizedBox(height: 6),
                Center(
                  child: TextButton(
                    onPressed: iap.restore,
                    child: const Text('Restore purchases', style: TextStyle(fontFamily: 'Fredoka', color: Color(0xFF8FB6FF), decoration: TextDecoration.underline)),
                  ),
                ),
              ] else
                GameButton(label: 'Back to game', onPressed: () => Navigator.of(context).maybePop()),
            ],
          );
        },
      ),
    );
  }
}
