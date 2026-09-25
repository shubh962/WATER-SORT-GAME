import 'package:flutter/material.dart';
import 'package:water_sort/ui/theme.dart';

class CoinIcon extends StatelessWidget {
  const CoinIcon({super.key, this.size = 24});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment(-0.3, -0.4),
          colors: <Color>[Color(0xFFFFF3A8), Color(0xFFFFC21F), Color(0xFFC98500)],
          stops: <double>[0, 0.6, 1],
        ),
        boxShadow: <BoxShadow>[BoxShadow(color: Color(0x40000000), offset: Offset(0, 2))],
      ),
    );
  }
}

/// Coin balance. Tap to open the shop.
class CoinPill extends StatelessWidget {
  const CoinPill({super.key, required this.coins, this.onTap});
  final int coins;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$coins coins. Open shop',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 5, 6, 5),
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(22)),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const CoinIcon(),
              const SizedBox(width: 8),
              Text('$coins', style: const TextStyle(fontFamily: 'Fredoka', fontWeight: FontWeight.w700, fontSize: 18, color: AppColors.text)),
              const SizedBox(width: 8),
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(color: AppColors.green, shape: BoxShape.circle),
                child: const Icon(Icons.add_rounded, size: 18, color: Color(0xFF123322)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
