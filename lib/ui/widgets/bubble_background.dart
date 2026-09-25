import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:water_sort/ui/theme.dart';

/// Dark gradient with slowly rising bubbles. Cheap: one painter, one controller.
class BubbleBackground extends StatefulWidget {
  const BubbleBackground({super.key, required this.child});
  final Widget child;

  @override
  State<BubbleBackground> createState() => _BubbleBackgroundState();
}

class _BubbleBackgroundState extends State<BubbleBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 24))..repeat();
  late final List<_Bubble> _bubbles = () {
    final r = math.Random(7);
    return List<_Bubble>.generate(
      22,
      (_) => _Bubble(r.nextDouble(), r.nextDouble(), 2 + r.nextDouble() * 6, 0.4 + r.nextDouble() * 0.9, r.nextDouble() * 6.28),
    );
  }();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.3),
          radius: 1.1,
          colors: <Color>[AppColors.bgTop, AppColors.bgMid, AppColors.bgBottom],
          stops: <double>[0, 0.62, 1],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          RepaintBoundary(
            child: AnimatedBuilder(
              animation: _c,
              builder: (BuildContext context, Widget? _) => CustomPaint(painter: _BubblePainter(_bubbles, _c.value)),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _Bubble {
  _Bubble(this.x, this.y, this.r, this.speed, this.phase);
  final double x, y, r, speed, phase;
}

class _BubblePainter extends CustomPainter {
  _BubblePainter(this.bubbles, this.t);
  final List<_Bubble> bubbles;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x12789EFF);
    for (final b in bubbles) {
      final y = ((b.y - t * b.speed) % 1.0 + 1.0) % 1.0;
      final x = b.x * size.width + math.sin(t * 6.28 * 2 + b.phase) * 10;
      canvas.drawCircle(Offset(x, y * size.height), b.r, paint);
    }
  }

  @override
  bool shouldRepaint(_BubblePainter old) => old.t != t;
}
