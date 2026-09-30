import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Large cosmetic silhouette collection. The string names are mirrored in
/// assets/web/index.html for the actual HTML5 game renderer.
enum BottleShape {
  classic,
  slim,
  potion,
  tallFlask,
  corkFlask,
  perfume,
  square,
  round,
  bulb,
  decanter,
  wideFlask,
  beaker,
  doubleBubble,
  hex,
  diamond,
  twist,
  teardrop,
  cone,
  jar,
  amphora,
  spiral,
  crown,
  heart,
  star,
  capsule,
  jewel,
  grand,
  royale,
  crystal,
  obsidian,
  neon,
}

class BottleIcon extends StatelessWidget {
  const BottleIcon({
    super.key,
    required this.layers,
    this.glass = const Color(0xFF5BB8EA),
    this.glow,
    this.cork,
    this.shape = BottleShape.classic,
    this.width = 40,
    this.height = 120,
  });

  final List<Color> layers;
  final Color glass;
  final Color? glow;
  final Color? cork;
  final BottleShape shape;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size(width, height),
        painter: BottlePainter(
          layers: layers,
          glass: glass,
          glow: glow,
          cork: cork,
          shape: shape,
        ),
      );
}

Path _neckBody({
  required double w,
  required double h,
  required double neck,
  required double shoulderY,
  required double body,
  double bottomRadius = 0.12,
}) {
  final top = -h / 2;
  final bottom = h / 2;
  final br = w * bottomRadius;
  return Path()
    ..moveTo(-neck / 2, top)
    ..lineTo(neck / 2, top)
    ..lineTo(neck / 2, shoulderY)
    ..cubicTo(neck / 2, shoulderY + h * .03, body * .72, shoulderY, body, shoulderY + h * .09)
    ..lineTo(body, bottom - br)
    ..quadraticBezierTo(body, bottom, body - br, bottom)
    ..lineTo(-body + br, bottom)
    ..quadraticBezierTo(-body, bottom, -body, bottom - br)
    ..lineTo(-body, shoulderY + h * .09)
    ..cubicTo(-body * .72, shoulderY, -neck / 2, shoulderY + h * .03, -neck / 2, shoulderY)
    ..close();
}

Path bottlePath(double w, double h, {BottleShape shape = BottleShape.classic}) {
  final top = -h / 2;
  final bottom = h / 2;

  switch (shape) {
    case BottleShape.classic:
      return _neckBody(w: w, h: h, neck: w * .60, shoulderY: top + h * .14, body: w * .45, bottomRadius: .12);
    case BottleShape.slim:
      return _neckBody(w: w, h: h, neck: w * .42, shoulderY: top + h * .16, body: w * .32, bottomRadius: .09);
    case BottleShape.potion:
      return _neckBody(w: w, h: h, neck: w * .34, shoulderY: top + h * .24, body: w * .44, bottomRadius: .16);
    case BottleShape.tallFlask:
      return _neckBody(w: w, h: h, neck: w * .27, shoulderY: top + h * .30, body: w * .43, bottomRadius: .10);
    case BottleShape.corkFlask:
      return _neckBody(w: w, h: h, neck: w * .30, shoulderY: top + h * .22, body: w * .43, bottomRadius: .10);
    case BottleShape.perfume:
      return _neckBody(w: w, h: h, neck: w * .40, shoulderY: top + h * .18, body: w * .46, bottomRadius: .15);
    case BottleShape.square:
      return Path()
        ..moveTo(-w * .28, top)
        ..lineTo(w * .28, top)
        ..lineTo(w * .28, top + h * .18)
        ..lineTo(w * .46, top + h * .28)
        ..lineTo(w * .46, bottom - w * .08)
        ..quadraticBezierTo(w * .46, bottom, w * .38, bottom)
        ..lineTo(-w * .38, bottom)
        ..quadraticBezierTo(-w * .46, bottom, -w * .46, bottom - w * .08)
        ..lineTo(-w * .46, top + h * .28)
        ..lineTo(-w * .28, top + h * .18)
        ..close();
    case BottleShape.round:
      return Path()
        ..moveTo(-w * .18, top)
        ..lineTo(w * .18, top)
        ..lineTo(w * .18, top + h * .24)
        ..cubicTo(w * .48, top + h * .28, w * .50, top + h * .70, w * .34, bottom - w * .04)
        ..quadraticBezierTo(0, bottom + w * .03, -w * .34, bottom - w * .04)
        ..cubicTo(-w * .50, top + h * .70, -w * .48, top + h * .28, -w * .18, top + h * .24)
        ..close();
    case BottleShape.bulb:
      return _neckBody(w: w, h: h, neck: w * .24, shoulderY: top + h * .22, body: w * .47, bottomRadius: .22);
    case BottleShape.decanter:
      return Path()
        ..moveTo(-w * .15, top)
        ..lineTo(w * .15, top)
        ..lineTo(w * .15, top + h * .20)
        ..lineTo(w * .40, top + h * .28)
        ..lineTo(w * .48, top + h * .42)
        ..lineTo(w * .36, bottom - w * .08)
        ..quadraticBezierTo(w * .30, bottom, 0, bottom)
        ..quadraticBezierTo(-w * .30, bottom, -w * .36, bottom - w * .08)
        ..lineTo(-w * .48, top + h * .42)
        ..lineTo(-w * .40, top + h * .28)
        ..lineTo(-w * .15, top + h * .20)
        ..close();
    case BottleShape.wideFlask:
      return _neckBody(w: w, h: h, neck: w * .25, shoulderY: top + h * .26, body: w * .48, bottomRadius: .13);
    case BottleShape.beaker:
      return Path()
        ..moveTo(-w * .17, top)
        ..lineTo(w * .17, top)
        ..lineTo(w * .17, top + h * .15)
        ..lineTo(w * .44, bottom - w * .10)
        ..quadraticBezierTo(w * .44, bottom, w * .32, bottom)
        ..lineTo(-w * .32, bottom)
        ..quadraticBezierTo(-w * .44, bottom, -w * .44, bottom - w * .10)
        ..lineTo(-w * .17, top + h * .15)
        ..close();
    case BottleShape.doubleBubble:
      return Path()
        ..moveTo(-w * .15, top)
        ..lineTo(w * .15, top)
        ..lineTo(w * .15, top + h * .20)
        ..cubicTo(w * .42, top + h * .20, w * .42, top + h * .40, w * .22, top + h * .48)
        ..cubicTo(w * .48, top + h * .50, w * .48, bottom - h * .12, w * .22, bottom - h * .04)
        ..quadraticBezierTo(0, bottom, -w * .22, bottom - h * .04)
        ..cubicTo(-w * .48, bottom - h * .12, -w * .48, top + h * .50, -w * .22, top + h * .48)
        ..cubicTo(-w * .42, top + h * .40, -w * .42, top + h * .20, -w * .15, top + h * .20)
        ..close();
    case BottleShape.hex:
      return Path()
        ..moveTo(-w * .16, top)
        ..lineTo(w * .16, top)
        ..lineTo(w * .16, top + h * .19)
        ..lineTo(w * .46, top + h * .31)
        ..lineTo(w * .38, bottom - w * .04)
        ..lineTo(0, bottom)
        ..lineTo(-w * .38, bottom - w * .04)
        ..lineTo(-w * .46, top + h * .31)
        ..lineTo(-w * .16, top + h * .19)
        ..close();
    case BottleShape.diamond:
      return Path()
        ..moveTo(-w * .14, top)
        ..lineTo(w * .14, top)
        ..lineTo(w * .14, top + h * .17)
        ..lineTo(w * .48, top + h * .42)
        ..lineTo(0, bottom)
        ..lineTo(-w * .48, top + h * .42)
        ..lineTo(-w * .14, top + h * .17)
        ..close();
    case BottleShape.twist:
      return Path()
        ..moveTo(-w * .16, top)
        ..lineTo(w * .16, top)
        ..lineTo(w * .16, top + h * .18)
        ..cubicTo(w * .48, top + h * .27, w * .12, top + h * .40, w * .38, top + h * .53)
        ..cubicTo(w * .58, top + h * .64, w * .16, bottom - h * .10, w * .34, bottom)
        ..lineTo(-w * .34, bottom)
        ..cubicTo(-w * .16, bottom - h * .10, -w * .58, top + h * .64, -w * .38, top + h * .53)
        ..cubicTo(-w * .12, top + h * .40, -w * .48, top + h * .27, -w * .16, top + h * .18)
        ..close();
    case BottleShape.teardrop:
      return Path()
        ..moveTo(-w * .13, top)
        ..lineTo(w * .13, top)
        ..lineTo(w * .13, top + h * .25)
        ..cubicTo(w * .50, top + h * .40, w * .43, bottom - h * .02, 0, bottom)
        ..cubicTo(-w * .43, bottom - h * .02, -w * .50, top + h * .40, -w * .13, top + h * .25)
        ..close();
    case BottleShape.cone:
      return Path()
        ..moveTo(-w * .15, top)
        ..lineTo(w * .15, top)
        ..lineTo(w * .15, top + h * .18)
        ..lineTo(w * .45, bottom - w * .04)
        ..quadraticBezierTo(w * .45, bottom, w * .34, bottom)
        ..lineTo(-w * .34, bottom)
        ..quadraticBezierTo(-w * .45, bottom, -w * .45, bottom - w * .04)
        ..lineTo(-w * .15, top + h * .18)
        ..close();
    case BottleShape.jar:
      return Path()
        ..moveTo(-w * .20, top)
        ..lineTo(w * .20, top)
        ..lineTo(w * .20, top + h * .20)
        ..cubicTo(w * .50, top + h * .24, w * .50, bottom - h * .10, w * .36, bottom)
        ..lineTo(-w * .36, bottom)
        ..cubicTo(-w * .50, bottom - h * .10, -w * .50, top + h * .24, -w * .20, top + h * .20)
        ..close();
    case BottleShape.amphora:
      return Path()
        ..moveTo(-w * .13, top)
        ..lineTo(w * .13, top)
        ..lineTo(w * .13, top + h * .18)
        ..cubicTo(w * .48, top + h * .22, w * .20, top + h * .40, w * .40, top + h * .52)
        ..cubicTo(w * .52, top + h * .72, w * .36, bottom - h * .08, w * .20, bottom)
        ..lineTo(-w * .20, bottom)
        ..cubicTo(-w * .36, bottom - h * .08, -w * .52, top + h * .72, -w * .40, top + h * .52)
        ..cubicTo(-w * .20, top + h * .40, -w * .48, top + h * .22, -w * .13, top + h * .18)
        ..close();
    case BottleShape.spiral:
      return _neckBody(w: w, h: h, neck: w * .28, shoulderY: top + h * .20, body: w * .42, bottomRadius: .18);
    case BottleShape.crown:
      return Path()
        ..moveTo(-w * .15, top)
        ..lineTo(w * .15, top)
        ..lineTo(w * .15, top + h * .18)
        ..lineTo(w * .48, top + h * .31)
        ..lineTo(w * .36, top + h * .45)
        ..lineTo(w * .44, bottom - w * .08)
        ..quadraticBezierTo(w * .44, bottom, w * .32, bottom)
        ..lineTo(-w * .32, bottom)
        ..quadraticBezierTo(-w * .44, bottom, -w * .44, bottom - w * .08)
        ..lineTo(-w * .36, top + h * .45)
        ..lineTo(-w * .48, top + h * .31)
        ..lineTo(-w * .15, top + h * .18)
        ..close();
    case BottleShape.heart:
      final body = Path()
        ..moveTo(0, bottom)
        ..cubicTo(-w * .08, bottom - h * .10, -w * .46, top + h * .56, -w * .46, top + h * .40)
        ..cubicTo(-w * .46, top + h * .20, -w * .20, top + h * .17, 0, top + h * .34)
        ..cubicTo(w * .20, top + h * .17, w * .46, top + h * .20, w * .46, top + h * .40)
        ..cubicTo(w * .46, top + h * .56, w * .08, bottom - h * .10, 0, bottom)
        ..close();
      return Path()
        ..moveTo(-w * .14, top)
        ..lineTo(w * .14, top)
        ..lineTo(w * .14, top + h * .28)
        ..addPath(body, Offset.zero)
        ..close();
    case BottleShape.star:
      final points = <Offset>[];
      for (var i = 0; i < 10; i++) {
        final r = i.isEven ? w * .47 : w * .21;
        final a = -math.pi / 2 + i * math.pi / 5;
        points.add(Offset(math.cos(a) * r, top + h * .56 + math.sin(a) * r));
      }
      final star = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        star.lineTo(p.dx, p.dy);
      }
      star.close();
      return Path()
        ..moveTo(-w * .14, top)
        ..lineTo(w * .14, top)
        ..lineTo(w * .14, top + h * .25)
        ..addPath(star, Offset.zero)
        ..close();
    case BottleShape.capsule:
      return _neckBody(w: w, h: h, neck: w * .34, shoulderY: top + h * .20, body: w * .38, bottomRadius: .28);
    case BottleShape.jewel:
      return Path()
        ..moveTo(-w * .13, top)
        ..lineTo(w * .13, top)
        ..lineTo(w * .13, top + h * .18)
        ..lineTo(w * .46, top + h * .38)
        ..lineTo(w * .30, bottom - h * .08)
        ..lineTo(0, bottom)
        ..lineTo(-w * .30, bottom - h * .08)
        ..lineTo(-w * .46, top + h * .38)
        ..lineTo(-w * .13, top + h * .18)
        ..close();
    case BottleShape.grand:
      return Path()
        ..moveTo(-w * .17, top)
        ..lineTo(w * .17, top)
        ..lineTo(w * .17, top + h * .20)
        ..cubicTo(w * .50, top + h * .24, w * .52, top + h * .72, w * .30, bottom)
        ..lineTo(-w * .30, bottom)
        ..cubicTo(-w * .52, top + h * .72, -w * .50, top + h * .24, -w * .17, top + h * .20)
        ..close();
    case BottleShape.royale:
      return Path()
        ..moveTo(-w * .15, top)
        ..lineTo(w * .15, top)
        ..lineTo(w * .15, top + h * .18)
        ..cubicTo(w * .44, top + h * .22, w * .44, top + h * .36, w * .34, top + h * .44)
        ..lineTo(w * .44, bottom - w * .05)
        ..quadraticBezierTo(w * .44, bottom, w * .34, bottom)
        ..lineTo(-w * .34, bottom)
        ..quadraticBezierTo(-w * .44, bottom, -w * .44, bottom - w * .05)
        ..lineTo(-w * .34, top + h * .44)
        ..cubicTo(-w * .44, top + h * .36, -w * .44, top + h * .22, -w * .15, top + h * .18)
        ..close();
    case BottleShape.crystal:
      return Path()
        ..moveTo(-w * .17, top)
        ..lineTo(w * .17, top)
        ..lineTo(w * .17, top + h * .20)
        ..lineTo(w * .46, top + h * .34)
        ..lineTo(w * .36, bottom - w * .04)
        ..lineTo(0, bottom)
        ..lineTo(-w * .36, bottom - w * .04)
        ..lineTo(-w * .46, top + h * .34)
        ..lineTo(-w * .17, top + h * .20)
        ..close();
    case BottleShape.obsidian:
      return Path()
        ..moveTo(-w * .17, top)
        ..lineTo(w * .17, top)
        ..lineTo(w * .17, top + h * .22)
        ..lineTo(w * .44, top + h * .31)
        ..lineTo(w * .44, bottom - w * .12)
        ..lineTo(w * .31, bottom)
        ..lineTo(-w * .31, bottom)
        ..lineTo(-w * .44, bottom - w * .12)
        ..lineTo(-w * .44, top + h * .31)
        ..lineTo(-w * .17, top + h * .22)
        ..close();
    case BottleShape.neon:
      return Path()
        ..moveTo(-w * .16, top)
        ..lineTo(w * .16, top)
        ..lineTo(w * .16, top + h * .20)
        ..lineTo(w * .42, top + h * .28)
        ..lineTo(w * .42, bottom - w * .10)
        ..quadraticBezierTo(w * .42, bottom, w * .30, bottom)
        ..lineTo(-w * .30, bottom)
        ..quadraticBezierTo(-w * .42, bottom, -w * .42, bottom - w * .10)
        ..lineTo(-w * .42, top + h * .28)
        ..lineTo(-w * .16, top + h * .20)
        ..close();
  }
}

class BottlePainter extends CustomPainter {
  BottlePainter({
    required this.layers,
    required this.glass,
    this.glow,
    this.cork,
    this.shape = BottleShape.classic,
  });

  final List<Color> layers;
  final Color glass;
  final Color? glow;
  final Color? cork;
  final BottleShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.save();
    canvas.translate(w / 2, h / 2);

    final bottleW = w * .88;
    final bottleH = h * .88;
    final path = bottlePath(bottleW, bottleH, shape: shape);

    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, bottleH / 2 + 4), width: bottleW * .56, height: 8),
      Paint()
        ..color = Colors.black.withValues(alpha: .24)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    if (glow != null) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = shape == BottleShape.neon ? 7 : 5
          ..color = glow!.withValues(alpha: shape == BottleShape.neon ? .34 : .24)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
    }

    final glassGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: <Color>[
        Colors.white.withValues(alpha: .14),
        glass.withValues(alpha: shape == BottleShape.obsidian ? .10 : .16),
        Colors.black.withValues(alpha: .08),
      ],
    );
    canvas.drawPath(path, Paint()..shader = glassGradient.createShader(Rect.fromLTWH(-w / 2, -h / 2, w, h)));

    canvas.save();
    canvas.clipPath(path);

    final liquidTop = -bottleH * .34;
    final liquidBottom = bottleH * .46;
    final usable = liquidBottom - liquidTop;
    final unit = usable / math.max(layers.length, 4);

    for (var i = 0; i < layers.length; i++) {
      final yBottom = liquidBottom - i * unit;
      final yTop = yBottom - unit;
      final c = layers[i];
      final shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: <Color>[
          c.withValues(alpha: .92),
          Color.lerp(c, Colors.white, .12)!.withValues(alpha: .97),
          Color.lerp(c, Colors.black, .10)!.withValues(alpha: .94),
        ],
      ).createShader(Rect.fromLTWH(-w, yTop, w * 2, unit));
      canvas.drawRect(Rect.fromLTRB(-w, yTop, w, yBottom + .8), Paint()..shader = shader);
      canvas.drawRect(Rect.fromLTRB(-w, yTop, w, yTop + 1.2), Paint()..color = Colors.white.withValues(alpha: .12));
    }

    if (layers.isNotEmpty) {
      final surface = liquidTop + math.max(0, layers.length - 1) * unit;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(-w, surface, w * 2, 4), const Radius.circular(3)),
        Paint()..color = Colors.white.withValues(alpha: .18),
      );
    }

    final bubblePaint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.2;
    for (var i = 0; i < math.min(3, layers.length); i++) {
      bubblePaint.color = Colors.white.withValues(alpha: .18);
      canvas.drawCircle(Offset(-w * .22 + i * w * .18, bottleH * .28 - i * 8), 2.4 + i * .5, bubblePaint);
    }
    canvas.restore();

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = <BottleShape>{BottleShape.crystal, BottleShape.obsidian, BottleShape.diamond, BottleShape.jewel}.contains(shape) ? 2.8 : 2.4
      ..color = glow ?? glass.withValues(alpha: .9);
    canvas.drawPath(path, outline);

    canvas.save();
    canvas.clipPath(path);
    final highlight = Path()
      ..moveTo(-bottleW * .23, -bottleH * .30)
      ..cubicTo(-bottleW * .34, -bottleH * .05, -bottleW * .20, bottleH * .16, -bottleW * .27, bottleH * .30);
    canvas.drawPath(
      highlight,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(2.0, w * .045)
        ..color = Colors.white.withValues(alpha: .30),
    );
    canvas.drawRect(
      Rect.fromLTWH(-w / 2, -h / 2, w, h),
      Paint()
        ..shader = LinearGradient(colors: <Color>[Colors.transparent, Colors.white.withValues(alpha: .22), Colors.transparent]).createShader(Rect.fromLTWH(-w / 2, -h / 2, w, h)),
    );
    canvas.restore();

    if (cork != null) {
      final neckWidth = switch (shape) {
        BottleShape.classic => w * .53,
        BottleShape.slim => w * .36,
        BottleShape.potion => w * .29,
        BottleShape.tallFlask => w * .24,
        BottleShape.corkFlask => w * .27,
        BottleShape.perfume => w * .34,
        BottleShape.square => w * .25,
        BottleShape.round => w * .25,
        BottleShape.bulb => w * .22,
        BottleShape.decanter => w * .22,
        BottleShape.wideFlask => w * .22,
        BottleShape.beaker => w * .22,
        BottleShape.doubleBubble => w * .23,
        BottleShape.hex => w * .23,
        BottleShape.diamond => w * .23,
        BottleShape.twist => w * .23,
        BottleShape.teardrop => w * .21,
        BottleShape.cone => w * .22,
        BottleShape.jar => w * .28,
        BottleShape.amphora => w * .21,
        BottleShape.spiral => w * .23,
        BottleShape.crown => w * .23,
        BottleShape.heart => w * .23,
        BottleShape.star => w * .23,
        BottleShape.capsule => w * .27,
        BottleShape.jewel => w * .23,
        BottleShape.grand => w * .25,
        BottleShape.royale => w * .25,
        BottleShape.crystal => w * .29,
        BottleShape.obsidian => w * .29,
        BottleShape.neon => w * .27,
      };
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(0, -bottleH / 2 - 4), width: neckWidth, height: 8),
          const Radius.circular(3),
        ),
        Paint()..color = cork!,
      );
    }

    // A few silhouettes benefit from a simple decorative band or seam.
    if ({BottleShape.twist, BottleShape.spiral, BottleShape.neon}.contains(shape)) {
      final band = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.white.withValues(alpha: .18);
      canvas.drawArc(Rect.fromCenter(center: Offset.zero, width: bottleW * .72, height: bottleH * .50), -.6, 1.2, false, band);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(BottlePainter old) =>
      old.layers != layers || old.glass != glass || old.glow != glow || old.cork != cork || old.shape != shape;
}
