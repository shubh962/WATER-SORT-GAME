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
              margin: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
              child: TabBar(
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[
                      Color(0xFFA16BFF),
                      Color(0xFF8B5CF6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: AppColors.purple.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: kBody.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
                unselectedLabelStyle: kBody.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                tabs: const <Widget>[
                  Tab(text: 'Bottles'),
                  Tab(text: 'Backgrounds'),
                ],
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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 14,
          crossAxisSpacing: 14,
          childAspectRatio: 0.73,
        ),
        itemCount: items.length,
        itemBuilder: (BuildContext context, int i) =>
            _ThemeCard(theme: items[i]),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({required this.theme});

  final GameTheme theme;

  bool get _equipped =>
      Services.state.skinId == theme.id || Services.state.bgId == theme.id;

  BottleShape _shapeFor(GameTheme value) {
    switch (value.shape) {
      case 'slim': return BottleShape.slim;
      case 'potion': return BottleShape.potion;
      case 'tall_flask': return BottleShape.tallFlask;
      case 'cork_flask': return BottleShape.corkFlask;
      case 'perfume': return BottleShape.perfume;
      case 'square': return BottleShape.square;
      case 'round': return BottleShape.round;
      case 'bulb': return BottleShape.bulb;
      case 'decanter': return BottleShape.decanter;
      case 'wide_flask': return BottleShape.wideFlask;
      case 'beaker': return BottleShape.beaker;
      case 'double_bubble': return BottleShape.doubleBubble;
      case 'hex': return BottleShape.hex;
      case 'diamond': return BottleShape.diamond;
      case 'twist': return BottleShape.twist;
      case 'teardrop': return BottleShape.teardrop;
      case 'cone': return BottleShape.cone;
      case 'jar': return BottleShape.jar;
      case 'amphora': return BottleShape.amphora;
      case 'spiral': return BottleShape.spiral;
      case 'crown': return BottleShape.crown;
      case 'heart': return BottleShape.heart;
      case 'star': return BottleShape.star;
      case 'capsule': return BottleShape.capsule;
      case 'jewel': return BottleShape.jewel;
      case 'grand': return BottleShape.grand;
      case 'royale': return BottleShape.royale;
      case 'crystal': return BottleShape.crystal;
      case 'obsidian': return BottleShape.obsidian;
      case 'neon': return BottleShape.neon;
      case 'classic':
      default: return BottleShape.classic;
    }
  }

  Future<void> _tap(BuildContext context) async {
    final s = Services.state;
    final messenger = ScaffoldMessenger.of(context);

    if (s.owns(theme.id)) {
      s.equip(theme.id);
      messenger.showSnackBar(
        SnackBar(
          content: Text('${theme.name} equipped'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (theme.proOnly) {
      await pushPro(context);
      return;
    }

    if (theme.unlockLevel != null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Reach Level ${theme.unlockLevel} to unlock ${theme.name}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!context.mounted) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A2048),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
        title: Text(
          'Buy ${theme.name}?',
          style: kTitle.copyWith(fontSize: 22),
        ),
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const CoinIcon(size: 22),
            const SizedBox(width: 8),
            Text('${theme.price} coins', style: kBody),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Buy'),
          ),
        ],
      ),
    );

    if (ok != true || !context.mounted) return;

    switch (s.buyTheme(theme.id)) {
      case BuyThemeResult.ok:
        messenger.showSnackBar(
          SnackBar(
            content: Text('${theme.name} unlocked and equipped'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      case BuyThemeResult.notEnoughCoins:
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Not enough coins'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Get coins',
              onPressed: () => pushShop(context),
            ),
          ),
        );
      case BuyThemeResult.proRequired:
        await pushPro(context);
      case BuyThemeResult.levelRequired:
        messenger.showSnackBar(
          SnackBar(
            content: Text('Reach Level ${theme.unlockLevel} to unlock ${theme.name}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
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
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: equipped
                  ? <Color>[
                      const Color(0xFF2B386C),
                      const Color(0xFF182148),
                    ]
                  : <Color>[
                      const Color(0xFF202B5C),
                      const Color(0xFF151C40),
                    ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: equipped
                  ? AppColors.green
                  : Colors.white.withValues(alpha: 0.10),
              width: equipped ? 2.6 : 1.6,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: equipped
                    ? AppColors.green.withValues(alpha: 0.18)
                    : Colors.black.withValues(alpha: 0.24),
                blurRadius: equipped ? 18 : 10,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          padding: const EdgeInsets.all(9),
          child: Column(
            children: <Widget>[
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: _Preview(
                    theme: theme,
                    bottleShape: _shapeFor(theme),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      theme.name,
                      style: kBody.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (theme.proOnly)
                    const Icon(
                      Icons.workspace_premium_rounded,
                      color: AppColors.gold,
                      size: 18,
                    ),
                ],
              ),
              const SizedBox(height: 5),
              _Status(
                theme: theme,
                owned: owned,
                equipped: equipped,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({
    required this.theme,
    required this.bottleShape,
  });

  final GameTheme theme;
  final BottleShape bottleShape;

  @override
  Widget build(BuildContext context) {
    if (theme.kind == ThemeKind.background) {
      final image = theme.assetPath;
      return Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (image != null)
            Image.asset(
              image,
              fit: BoxFit.cover,
              errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
                  CustomPaint(
                painter: _BackgroundPreviewPainter(
                  colors: theme.colors,
                  effect: theme.effect,
                ),
              ),
            )
          else
            CustomPaint(
              painter: _BackgroundPreviewPainter(
                colors: theme.colors,
                effect: theme.effect,
              ),
            ),
          Container(color: Colors.black.withValues(alpha: .10)),
          Center(
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.05),
                    blurRadius: 24,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: const BottleIcon(
                layers: const <Color>[
                  Color(0xFFFF5C7A),
                  Color(0xFF7C5CFF),
                  Color(0xFFFFD23F),
                ],
                shape: BottleShape.classic,
                width: 34,
                height: 96,
              ),
            ),
          ),
        ],
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF0B112A),
            Color(0xFF090D20),
          ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned(
            top: 10,
            right: 11,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (theme.glow ?? theme.colors.first)
                    .withValues(alpha: 0.14),
              ),
            ),
          ),
          Center(
            child: BottleIcon(
              layers: const <Color>[
                Color(0xFFFF5C7A),
                Color(0xFF9B5CF6),
                Color(0xFFFFD23F),
              ],
              glass: theme.colors.first,
              glow: theme.glow,
              cork: theme.cork,
              shape: bottleShape,
              width: 42,
              height: 112,
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundPreviewPainter extends CustomPainter {
  const _BackgroundPreviewPainter({
    required this.colors,
    required this.effect,
  });

  final List<Color> colors;
  final String effect;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final gradient = RadialGradient(
      center: const Alignment(0, -0.30),
      radius: 1.25,
      colors: colors,
      stops: const <double>[0, 0.58, 1],
    );

    canvas.drawRect(
      rect,
      Paint()..shader = gradient.createShader(rect),
    );

    final p = Paint()..isAntiAlias = true;

    switch (effect) {
      case 'ocean':
        p.color = Colors.white.withValues(alpha: 0.09);
        for (var i = 0; i < 7; i++) {
          final x = (size.width * (0.08 + i * 0.15)) % size.width;
          final y = size.height * (0.18 + (i % 3) * 0.20);
          canvas.drawCircle(Offset(x, y), 5 + i % 2 * 2, p);
        }
        break;
      case 'forest':
        p.color = const Color(0xFFB8FF76).withValues(alpha: 0.12);
        for (var i = 0; i < 12; i++) {
          final x = (i * 31.0) % size.width;
          final y = 12 + ((i * 47.0) % size.height);
          canvas.drawCircle(Offset(x, y), i % 3 == 0 ? 2.8 : 1.8, p);
        }
        break;
      case 'aurora':
        final aurora = Paint()
          ..color = const Color(0xFF4DE2C5).withValues(alpha: 0.13)
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.14;
        final path = Path()
          ..moveTo(-20, size.height * 0.24)
          ..cubicTo(
            size.width * 0.26,
            size.height * 0.03,
            size.width * 0.55,
            size.height * 0.46,
            size.width + 20,
            size.height * 0.17,
          );
        canvas.drawPath(path, aurora);
        aurora.color = const Color(0xFF9A7BFF).withValues(alpha: 0.12);
        final path2 = Path()
          ..moveTo(-20, size.height * 0.42)
          ..cubicTo(
            size.width * 0.3,
            size.height * 0.18,
            size.width * 0.70,
            size.height * 0.62,
            size.width + 20,
            size.height * 0.30,
          );
        canvas.drawPath(path2, aurora);
        break;
      case 'lava':
        p.color = const Color(0xFFFFC04D).withValues(alpha: 0.16);
        for (var i = 0; i < 9; i++) {
          canvas.drawCircle(
            Offset(
              size.width * (0.08 + (i % 5) * 0.21),
              size.height * (0.16 + (i % 4) * 0.20),
            ),
            2 + i % 3,
            p,
          );
        }
        break;
      case 'royal':
        p.color = const Color(0xFFFFD45A).withValues(alpha: 0.16);
        for (var i = 0; i < 8; i++) {
          final x = size.width * (0.10 + (i % 4) * 0.27);
          final y = size.height * (0.16 + (i % 3) * 0.30);
          canvas.drawCircle(Offset(x, y), 2.2, p);
        }
        break;
      case 'sakura':
        p.color = const Color(0xFFFF9FCB).withValues(alpha: 0.14);
        for (var i = 0; i < 9; i++) {
          canvas.save();
          canvas.translate(
            size.width * (0.08 + (i % 5) * 0.21),
            size.height * (0.16 + (i % 4) * 0.19),
          );
          canvas.rotate(i * 0.4);
          final petal = Path()
            ..moveTo(0, -4)
            ..quadraticBezierTo(5, -2, 0, 4)
            ..quadraticBezierTo(-5, -2, 0, -4)
            ..close();
          canvas.drawPath(petal, p);
          canvas.restore();
        }
        break;
      case 'desert':
        p.color = const Color(0xFFFFD37D).withValues(alpha: 0.13);
        canvas.drawCircle(
          Offset(size.width * 0.72, size.height * 0.23),
          size.width * 0.17,
          p,
        );
        final dune = Path()
          ..moveTo(0, size.height * 0.80)
          ..quadraticBezierTo(
            size.width * 0.30,
            size.height * 0.62,
            size.width * 0.53,
            size.height * 0.80,
          )
          ..quadraticBezierTo(
            size.width * 0.76,
            size.height * 0.96,
            size.width,
            size.height * 0.76,
          )
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
        p.color = Colors.white.withValues(alpha: 0.05);
        canvas.drawPath(dune, p);
        break;
      case 'arctic':
        p.color = Colors.white.withValues(alpha: 0.16);
        for (var i = 0; i < 16; i++) {
          final x = (i * 23.0) % size.width;
          final y = (i * 37.0) % size.height;
          canvas.drawCircle(
            Offset(x, y),
            1.4 + (i % 3) * 0.7,
            p,
          );
        }
        break;
      case 'galaxy':
        p.color = Colors.white.withValues(alpha: 0.22);
        for (var i = 0; i < 20; i++) {
          final x = (i * 29.0) % size.width;
          final y = (i * 43.0) % size.height;
          canvas.drawCircle(
            Offset(x, y),
            0.8 + (i % 3) * 0.6,
            p,
          );
        }
        p.color = const Color(0xFF9E72FF).withValues(alpha: 0.08);
        canvas.drawCircle(
          Offset(size.width * 0.26, size.height * 0.48),
          size.width * 0.30,
          p,
        );
        break;
      case 'cyber':
        p.color = const Color(0xFF38E8FF).withValues(alpha: 0.07);
        for (var x = 0.0; x < size.width; x += 18) {
          canvas.drawRect(Rect.fromLTWH(x, 0, 1, size.height), p);
        }
        for (var y = 0.0; y < size.height; y += 18) {
          canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), p);
        }
        break;
      case 'dusk':
        p.color = const Color(0xFFFFA9D6).withValues(alpha: 0.08);
        canvas.drawCircle(
          Offset(size.width * 0.75, size.height * 0.28),
          size.width * 0.16,
          p,
        );
        break;
      case 'midnight':
      default:
        p.color = Colors.white.withValues(alpha: 0.12);
        for (var i = 0; i < 18; i++) {
          final x = (i * 31.0) % size.width;
          final y = (i * 53.0) % size.height;
          canvas.drawCircle(Offset(x, y), 0.8 + (i % 2), p);
        }
        break;
    }
  }

  @override
  bool shouldRepaint(_BackgroundPreviewPainter oldDelegate) =>
      oldDelegate.colors != colors || oldDelegate.effect != effect;
}

class _Status extends StatelessWidget {
  const _Status({required this.theme, required this.owned, required this.equipped});

  final GameTheme theme;
  final bool owned;
  final bool equipped;

  @override
  Widget build(BuildContext context) {
    if (equipped) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.check_circle_rounded, color: AppColors.green, size: 19),
          SizedBox(width: 4),
          Text(
            'Equipped',
            style: TextStyle(
              fontFamily: 'Fredoka',
              color: AppColors.green,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    if (owned) {
      return const Text('Tap to equip', style: kDim);
    }

    if (theme.unlockLevel != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Icon(Icons.card_giftcard_rounded, color: AppColors.gold, size: 19),
          const SizedBox(width: 4),
          Text(
            'Gift • Level ${theme.unlockLevel}',
            style: const TextStyle(
              fontFamily: 'Fredoka',
              color: AppColors.gold,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    if (theme.proOnly) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.workspace_premium_rounded, color: AppColors.gold, size: 19),
          SizedBox(width: 4),
          Text(
            'PRO only',
            style: TextStyle(
              fontFamily: 'Fredoka',
              color: AppColors.gold,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        const CoinIcon(size: 17),
        const SizedBox(width: 5),
        Text(
          '${theme.price}',
          style: kBody.copyWith(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}
