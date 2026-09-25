import 'dart:async';

import 'package:flutter/material.dart';
import 'package:water_sort/config/app_config.dart';
import 'package:water_sort/services/services.dart';
import 'package:water_sort/ui/daily_reward_dialog.dart';
import 'package:water_sort/ui/routes.dart';
import 'package:water_sort/ui/theme.dart';
import 'package:water_sort/ui/widgets/banner_ad_view.dart';
import 'package:water_sort/ui/widgets/bottle_painter.dart';
import 'package:water_sort/ui/widgets/bubble_background.dart';
import 'package:water_sort/ui/widgets/coin_pill.dart';
import 'package:water_sort/ui/widgets/game_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _bob = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_autoDaily()));
  }

  Future<void> _autoDaily() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted || !Services.state.daily.canClaim) return;
    await showDailyRewardDialog(context);
  }

  @override
  void dispose() {
    _bob.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BubbleBackground(
        child: SafeArea(
          child: ListenableBuilder(
            listenable: Services.state,
            builder: (BuildContext context, Widget? _) {
              final s = Services.state;
              return Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 8, 0),
                    child: Row(
                      children: <Widget>[
                        CoinPill(coins: s.coins, onTap: () => pushShop(context)),
                        const Spacer(),
                        if (s.pro) const _ProChip(),
                        IconButton(
                          tooltip: 'Settings',
                          onPressed: () => pushSettings(context),
                          icon: const Icon(Icons.settings_rounded, size: 28),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        children: <Widget>[
                          const Spacer(flex: 2),
                          SizedBox(
                            height: 170,
                            child: AnimatedBuilder(
                              animation: _bob,
                              builder: (BuildContext context, Widget? _) => _Logo(t: _bob.value),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'WATER SORT',
                            style: TextStyle(
                              fontFamily: 'Fredoka',
                              fontWeight: FontWeight.w700,
                              fontSize: 46,
                              height: 1,
                              color: AppColors.gold,
                              shadows: <Shadow>[Shadow(color: Color(0xFFB3541A), offset: Offset(0, 4))],
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text('Sort the colors. Clear the levels.', style: kDim),
                          const Spacer(),
                          GameButton(
                            label: 'PLAY',
                            sublabel: 'Level ${s.level}',
                            icon: Icons.play_arrow_rounded,
                            height: 74,
                            fontSize: 34,
                            onPressed: () async {
                              await pushGame(context);
                            },
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _Tile(
                                  icon: Icons.card_giftcard_rounded,
                                  label: 'Daily',
                                  dot: s.daily.canClaim,
                                  onTap: () => showDailyRewardDialog(context),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: _Tile(icon: Icons.palette_rounded, label: 'Styles', onTap: () => pushThemes(context))),
                              const SizedBox(width: 12),
                              Expanded(child: _Tile(icon: Icons.shopping_bag_rounded, label: 'Shop', onTap: () => pushShop(context))),
                            ],
                          ),
                          const SizedBox(height: 14),
                          if (!s.pro) _ProCard(onTap: () => pushPro(context)),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                  if (AppConfig.bannerOnHome) const BannerAdView(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    // three bobbing bottles
    const sets = <List<Color>>[
      <Color>[Color(0xFFFF5C7A), Color(0xFFFF9A3D), Color(0xFFFFD23F)],
      <Color>[Color(0xFF4D7CFF), Color(0xFF22C1D6), Color(0xFF2ECC8F), Color(0xFF9BE564)],
      <Color>[Color(0xFF9B5CF6), Color(0xFFF472D0), Color(0xFFFF5C7A)],
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Transform.translate(
              offset: Offset(0, -6 * _wave(t + i * 0.22) - (i == 1 ? 14 : 0)),
              child: BottleIcon(layers: sets[i], width: i == 1 ? 62 : 54, height: i == 1 ? 150 : 128, glow: i == 1 ? const Color(0xFFA8E8FF) : null),
            ),
          ),
      ],
    );
  }

  double _wave(double x) => (1 - (x * 2 % 2 - 1).abs()) * 2 - 1; // triangle wave -1..1
}

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.onTap, this.dot = false});
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 84,
          decoration: panelDecoration(radius: 18),
          child: Stack(
            children: <Widget>[
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(icon, size: 30, color: AppColors.teal),
                    const SizedBox(height: 4),
                    Text(label, style: kBody),
                  ],
                ),
              ),
              if (dot)
                Positioned(
                  top: 8,
                  right: 10,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(color: AppColors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProCard extends StatelessWidget {
  const _ProCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: <Color>[Color(0xFF6A3FD8), Color(0xFFF472D0)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const <BoxShadow>[BoxShadow(color: Color(0x59000000), offset: Offset(0, 6), blurRadius: 12)],
        ),
        child: const Row(
          children: <Widget>[
            Icon(Icons.workspace_premium_rounded, size: 34, color: AppColors.gold),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Go PRO', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w700, fontSize: 20)),
                  Text('No ads, unlimited undos, double coins', style: TextStyle(fontFamily: 'Fredoka', fontSize: 13, color: Color(0xE6FFFFFF))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 28),
          ],
        ),
      ),
    );
  }
}

class _ProChip extends StatelessWidget {
  const _ProChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(gradient: const LinearGradient(colors: <Color>[AppColors.gold, Color(0xFFFF9A3D)]), borderRadius: BorderRadius.circular(14)),
      child: const Text('PRO', style: TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w700, color: Color(0xFF3A2000))),
    );
  }
}
