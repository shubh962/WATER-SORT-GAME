import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A glass bottle with colored layers (bottom to top). Used by the home logo and
/// the style previews so both match the in-game look.
class BottleIcon extends StatelessWidget {
  const BottleIcon({
    super.key,
    required this.layers,
    this.glass = const Color(0xFF5BB8EA),
    this.glow,
    this.cork,
    this.width = 40,
    this.height = 120,
  });

  final List<Color> layers;
  final Color glass;
  final Color? glow;
  final Color? cork;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: BottlePainter(layers: layers, glass: glass, glow: glow, cork: cork),
    );
  }
}

Path bottlePath(double w, double h) {
  final nw = w * 0.62, nk = h * 0.13, sh = w * 0.22, r = w * 0.32;
  return Path()
    ..moveTo(-nw / 2, -h / 2)
    ..lineTo(nw / 2, -h / 2)
    ..lineTo(nw / 2, -h / 2 + nk)
    ..quadraticBezierTo(w / 2, -h / 2 + nk + 2, w / 2, -h / 2 + nk + sh)
    ..lineTo(w / 2, h / 2 - r)
    ..quadraticBezierTo(w / 2, h / 2, w / 2 - r, h / 2)
    ..lineTo(-w / 2 + r, h / 2)
    ..quadraticBezierTo(-w / 2, h / 2, -w / 2, h / 2 - r)
    ..lineTo(-w / 2, -h / 2 + nk + sh)
    ..quadraticBezierTo(-w / 2, -h / 2 + nk + 2, -nw / 2, -h / 2 + nk)
    ..close();
}

class BottlePainter extends CustomPainter {
  BottlePainter({required this.layers, required this.glass, this.glow, this.cork});

  final List<Color> layers;
  final Color glass;
  final Color? glow;
  final Color? cork;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.save();
    canvas.translate(w / 2, h / 2);
    final path = bottlePath(w * 0.9, h * 0.9);

    canvas.drawPath(path, Paint()..color = glass.withValues(alpha: 0.10));

    // liquid layers
    canvas.save();
    canvas.clipPath(path);
    final top = -h * 0.9 / 2 + h * 0.9 * 0.13 + w * 0.9 * 0.22;
    final bottom = h * 0.9 / 2 - 3;
    final unit = (bottom - top) / math.max(layers.length, 4);
    for (var i = 0; i < layers.length; i++) {
      final y1 = bottom - i * unit;
      canvas.drawRect(Rect.fromLTRB(-w, y1 - unit, w, y1 + 0.6), Paint()..color = layers[i]);
    }
    canvas.restore();

    // glass outline + glow
    if (glow != null) {
      canvas.drawPath(path, Paint()
        ..color = glow!.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
    }
    canvas.drawPath(path, Paint()
      ..color = glass
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5);
    canvas.drawLine(
      Offset(-w * 0.9 * 0.27, top + 6),
      Offset(-w * 0.9 * 0.27, bottom - w * 0.9 * 0.3),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.32)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    if (cork != null) {
      final nw = w * 0.9 * 0.62;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(-nw / 2, -h * 0.9 / 2 - 9, nw, 12), const Radius.circular(3)),
        Paint()..color = cork!,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(BottlePainter old) =>
      old.layers != layers || old.glass != glass || old.glow != glow || old.cork != cork;
}
