import 'package:flutter/material.dart';
import 'package:water_sort/services/services.dart';
import 'package:water_sort/ui/theme.dart';
import 'package:water_sort/ui/widgets/bubble_background.dart';
import 'package:water_sort/ui/widgets/coin_pill.dart';

/// Shared frame for Shop / Themes / PRO / Settings: back button, title, coins.
class ScreenScaffold extends StatelessWidget {
  const ScreenScaffold({
    super.key,
    required this.title,
    required this.child,
    this.showCoins = true,
    this.onCoinsTap,
    this.bottom,
  });

  final String title;
  final Widget child;
  final bool showCoins;
  final VoidCallback? onCoinsTap;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BubbleBackground(
        child: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 14, 4),
                child: Row(
                  children: <Widget>[
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.22),
                        boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x59000000), offset: Offset(0, 3), blurRadius: 6)],
                      ),
                      child: IconButton(
                        style: IconButton.styleFrom(
                          foregroundColor: AppColors.text,
                          highlightColor: Colors.white.withValues(alpha: 0.18),
                        ),
                        tooltip: 'Back',
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded, size: 26, color: AppColors.text),
                      ),
                    ),
                    Expanded(child: Center(child: Text(title, style: kTitle))),
                    if (showCoins)
                      ListenableBuilder(
                        listenable: Services.state,
                        builder: (BuildContext context, Widget? _) => CoinPill(coins: Services.state.coins, onTap: onCoinsTap),
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(child: child),
              if (bottom != null) bottom!,
            ],
          ),
        ),
      ),
    );
  }
}
