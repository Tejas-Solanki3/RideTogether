import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../domain/models.dart';
import '../theme.dart';

/// A custom, self-contained campus illustration; not a GPS/navigation service.
class RouteMap extends StatelessWidget {
  final String originId, destinationId;
  final double height;
  final bool labels;
  const RouteMap({
    super.key,
    required this.originId,
    required this.destinationId,
    this.height = 230,
    this.labels = true,
  });
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(14),
    child: SizedBox(
      height: height,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          SvgPicture.asset('assets/svg/campus_map.svg', fit: BoxFit.fill),
          CustomPaint(
            painter: _RoutePainter(
              CampusPlace.byId(originId),
              CampusPlace.byId(destinationId),
              labels,
            ),
          ),
          Positioned(
            right: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.explore_outlined,
                size: 18,
                color: AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _RoutePainter extends CustomPainter {
  final CampusPlace origin, destination;
  final bool labels;
  _RoutePainter(this.origin, this.destination, this.labels);
  @override
  void paint(Canvas canvas, Size size) {
    final a = Offset(origin.x * size.width, origin.y * size.height);
    final b = Offset(destination.x * size.width, destination.y * size.height);
    final bendX = (a.dx + b.dx) / 2;
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(bendX - 16, a.dy)
      ..quadraticBezierTo(bendX, a.dy, bendX, a.dy - 16)
      ..lineTo(bendX, b.dy + 16)
      ..quadraticBezierTo(bendX, b.dy, bendX + 16, b.dy)
      ..lineTo(b.dx, b.dy);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.green
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    for (final point in [a, b]) {
      canvas.drawCircle(
        point,
        12,
        Paint()..color = AppColors.green.withValues(alpha: .12),
      );
      canvas.drawCircle(point, 7, Paint()..color = Colors.white);
      canvas.drawCircle(point, 4, Paint()..color = AppColors.ink);
    }
    if (labels) {
      _label(canvas, size, a, origin.name);
      _label(canvas, size, b, destination.name);
    }
  }

  void _label(Canvas canvas, Size size, Offset point, String label) {
    final p = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout(maxWidth: size.width - 24);
    final w = p.width + 18, h = p.height + 12;
    final x = (point.dx - w / 2).clamp(8.0, size.width - w - 8.0);
    final y = (point.dy + 17).clamp(8.0, size.height - h - 8.0);
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, w, h),
      const Radius.circular(7),
    );
    canvas.drawShadow(
      Path()..addRRect(rect),
      AppColors.ink.withValues(alpha: .1),
      3,
      false,
    );
    canvas.drawRRect(rect, Paint()..color = Colors.white);
    p.paint(canvas, Offset(x + 9, y + 6));
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) =>
      oldDelegate.origin != origin ||
      oldDelegate.destination != destination ||
      oldDelegate.labels != labels;
}
