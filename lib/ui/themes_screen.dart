import 'package:flutter/material.dart';
import 'package:water_sort/models/themes.dart';
import 'package:water_sort/services/app_state.dart';
import 'package:water_sort/services/services.dart';
import 'package:water_sort/ui/routes.dart';
import 'package:water_sort/ui/theme.dart';
import 'package:water_sort/ui/widgets/bottle_painter.dart';
import 'package:water_sort/ui/widgets/coin_pill.dart';
import 'package:water_sort/ui/widgets/screen_scaffold.dart';

/// Coins are spent here: bottle styles and backgrounds.
class ThemesScreen extends StatelessWidget {
  const ThemesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: ScreenScaffold(
        title: 'Styles',
        onCoinsTap: () => pushShop(context),
        child: Column(
          children: <Widget>[
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(16)),
              child: TabBar(
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(color: AppColors.purple, borderRadius: BorderRadius.circular(14)),
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: kBody.copyWith(fontWeight: FontWeight.w700),
                tabs: const <Widget>[Tab(text: 'Bottles'), Tab(text: 'Backgrounds')],
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: <Widget>[
                  _ThemeGrid(items: ThemeCatalog.skins),
                  _ThemeGrid(items: ThemeCatalog.backgrounds),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeGrid extends StatelessWidget {
  const _ThemeGrid({required this.items});
  final List<GameTheme> items;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Services.state,
      builder: (BuildContext context, Widget? _) => GridView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 14, crossAxisSpacing: 14, childAspectRatio: 0.78),
        itemCount: items.length,
        itemBuilder: (BuildContext context, int i) => _ThemeCard(theme: items[i]),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({required this.theme});
  final GameTheme theme;

  bool get _equipped => Services.state.skinId == theme.id || Services.state.bgId == theme.id;

  Future<void> _tap(BuildContext context) async {
    final s = Services.state;
    final messenger = ScaffoldMessenger.of(context);
    if (s.owns(theme.id)) {
      s.equip(theme.id);
      messenger.showSnackBar(SnackBar(content: Text('${theme.name} equipped')));
      return;
    }
    if (theme.proOnly) {
      await pushPro(context);
      return;
    }
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Text('Buy ${theme.name}?', style: kTitle.copyWith(fontSize: 22)),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[const CoinIcon(size: 22), const SizedBox(width: 8), Text('${theme.price} coins', style: kBody)],
        ),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Buy')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    switch (s.buyTheme(theme.id)) {
      case BuyThemeResult.ok:
        messenger.showSnackBar(SnackBar(content: Text('${theme.name} unlocked and equipped')));
      case BuyThemeResult.notEnoughCoins:
        messenger.showSnackBar(SnackBar(
          content: const Text('Not enough coins'),
          action: SnackBarAction(label: 'Get coins', onPressed: () => pushShop(context)),
        ));
      case BuyThemeResult.proRequired:
        await pushPro(context);
      case BuyThemeResult.alreadyOwned:
      case BuyThemeResult.unknown:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Services.state;
    final owned = s.owns(theme.id);
    final equipped = _equipped;
    return Semantics(
      button: true,
      label: theme.name,
      child: GestureDetector(
        onTap: () => _tap(context),
        child: Container(
          decoration: panelDecoration().copyWith(
            border: Border.all(color: equipped ? AppColors.green : AppColors.panelBorder, width: equipped ? 3 : 2),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            children: <Widget>[
              Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(14), child: _Preview(theme: theme))),
              const SizedBox(height: 8),
              Text(theme.name, style: kBody.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              _Status(theme: theme, owned: owned, equipped: equipped),
            ],
          ),
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.theme});
  final GameTheme theme;

  @override
  Widget build(BuildContext context) {
    if (theme.kind == ThemeKind.background) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(center: const Alignment(0, -0.3), radius: 1.1, colors: theme.colors, stops: const <double>[0, 0.62, 1]),
        ),
        child: Center(
          child: BottleIcon(
            layers: const <Color>[Color(0xFFFF5C7A), Color(0xFF4D7CFF), Color(0xFFFFD23F)],
            width: 34,
            height: 96,
          ),
        ),
      );
    }
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFF0C1024)),
      child: Center(
        child: BottleIcon(
          layers: const <Color>[Color(0xFFFF5C7A), Color(0xFF9B5CF6), Color(0xFFFFD23F)],
          glass: theme.colors.first,
          glow: theme.glow,
          cork: theme.cork,
          width: 40,
          height: 110,
        ),
      ),
    );
  }
}

class _Status extends StatelessWidget {
  const _Status({required this.theme, required this.owned, required this.equipped});
  final GameTheme theme;
  final bool owned;
  final bool equipped;

  @override
  Widget build(BuildContext context) {
    if (equipped) {
      return const Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
        Icon(Icons.check_circle_rounded, color: AppColors.green, size: 20),
        SizedBox(width: 4),
        Text('Equipped', style: TextStyle(fontFamily: 'Fredoka', color: AppColors.green)),
      ]);
    }
    if (owned) return const Text('Tap to equip', style: kDim);
    if (theme.proOnly) {
      return const Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
        Icon(Icons.workspace_premium_rounded, color: AppColors.gold, size: 20),
        SizedBox(width: 4),
        Text('PRO only', style: TextStyle(fontFamily: 'Fredoka', color: AppColors.gold)),
      ]);
    }
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
      const CoinIcon(size: 18),
      const SizedBox(width: 6),
      Text('${theme.price}', style: kBody.copyWith(fontWeight: FontWeight.w700)),
    ]);
  }
}
