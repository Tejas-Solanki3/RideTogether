import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/models.dart';

/// An original illustrative campus map. No live GPS or navigation claim.
class RouteMap extends StatelessWidget {
  final String originId, destinationId;
  final double height;
  const RouteMap({
    super.key,
    required this.originId,
    required this.destinationId,
    this.height = 160,
  });
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _MapPainter(
          CampusPlace.byId(originId),
          CampusPlace.byId(destinationId),
        ),
      ),
    ),
  );
}

class _MapPainter extends CustomPainter {
  final CampusPlace a, b;
  _MapPainter(this.a, this.b);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFEDEDED),
    );
    final gap = math.min(9.0, math.min(size.width / 6, size.height / 3) * .18);
    final block = Paint()..color = const Color(0xFFE1E1E1);
    for (var x = 0; x < 7; x++) {
      for (var y = 0; y < 4; y++) {
        final rect = Rect.fromLTWH(
          x * size.width / 6 + gap,
          y * size.height / 3 + gap,
          size.width / 6 - gap * 2,
          size.height / 3 - gap * 2,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)),
          block,
        );
      }
    }
    final roads = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawLine(
      Offset(0, size.height * .49),
      Offset(size.width, size.height * .49),
      roads,
    );
    canvas.drawLine(
      Offset(size.width * .48, 0),
      Offset(size.width * .48, size.height),
      roads,
    );
    final from = Offset(a.x * size.width, a.y * size.height);
    final to = Offset(b.x * size.width, b.y * size.height);
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..lineTo(size.width * .48, from.dy)
      ..lineTo(size.width * .48, to.dy)
      ..lineTo(to.dx, to.dy);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..strokeWidth = 8
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.black
        ..strokeWidth = 3.5
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    for (final point in [from, to]) {
      canvas.drawCircle(point, 8, Paint()..color = Colors.white);
      canvas.drawCircle(point, 4, Paint()..color = Colors.black);
    }
    void label(String text, Offset point) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width * .38);
      final x = (point.dx - painter.width / 2)
          .clamp(8.0, math.max(8.0, size.width - painter.width - 8))
          .toDouble();
      final y = (point.dy + 14)
          .clamp(7.0, math.max(7.0, size.height - painter.height - 9))
          .toDouble();
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 6, y - 4, painter.width + 12, painter.height + 8),
          const Radius.circular(5),
        ),
        Paint()..color = Colors.white,
      );
      painter.paint(canvas, Offset(x, y));
    }

    if (size.height >= 90 && size.width >= 180) {
      label(a.name, from);
      label(b.name, to);
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) =>
      old.a.id != a.id || old.b.id != b.id;
}
