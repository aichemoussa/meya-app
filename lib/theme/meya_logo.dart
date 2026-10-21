import 'package:flutter/material.dart';

import 'meya_theme.dart';

/// The MEYA mark, "Keyhole M": an M whose valley closes into a keyhole ring
/// holding one Sky dot. Drawn from the 512 × 512 artwork
/// (assets/brand/meya-logo.svg) so it stays sharp at any size.
class MeyaLogo extends StatelessWidget {
  final double size;

  /// Defaults: Navy and Sky on light backgrounds; on dark backgrounds the
  /// light palette colour for the M and white for the dot.
  final Color? color;
  final Color? dotColor;

  const MeyaLogo({super.key, this.size = 96, this.color, this.dotColor});

  static const navy = Color(0xFF044D8C);
  static const sky = Color(0xFF49B1F2);

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: 'MEYA',
      image: true,
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: MeyaLogoPainter(
            color: color ?? (dark ? context.meya.navy : navy),
            dotColor: dotColor ?? (dark ? Colors.white : sky),
          ),
        ),
      ),
    );
  }
}

class MeyaLogoPainter extends CustomPainter {
  final Color color;
  final Color dotColor;

  const MeyaLogoPainter({
    this.color = MeyaLogo.navy,
    this.dotColor = MeyaLogo.sky,
  });

  /// The mark's outline in artwork units (0–512).
  static Path get outline => Path()
    ..moveTo(110.5, 401.5)
    ..lineTo(110.5, 110.5)
    ..lineTo(206.24, 250.62)
    ..arcToPoint(
      const Offset(305.76, 250.62),
      radius: const Radius.circular(64.96),
      largeArc: true,
      clockwise: false,
    )
    ..lineTo(401.5, 110.5)
    ..lineTo(401.5, 401.5);

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 512;
    canvas
      ..save()
      ..translate(
        (size.width - 512 * scale) / 2,
        (size.height - 512 * scale) / 2,
      )
      ..scale(scale);
    canvas.drawPath(
      outline,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 57.16
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
    canvas.drawCircle(
      const Offset(256, 292.37),
      19.75,
      Paint()..color = dotColor,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(MeyaLogoPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.dotColor != dotColor;
}
