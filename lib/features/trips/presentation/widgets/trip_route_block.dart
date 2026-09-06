import 'package:flutter/material.dart';
import 'package:vput/app/theme/app_colors.dart';

/// Route fields with the marker timeline of the design drawn next to them:
/// a filled square for the pick-up point, a dot for every planned stop and an
/// outlined square for the destination, joined by a dashed line.
class TripRouteBlock extends StatelessWidget {
  const TripRouteBlock({
    required this.pointCount,
    required this.fields,
    super.key,
  });

  static const rowHeight = 52.0;
  static const rowSpacing = 2.0;

  final int pointCount;
  final List<Widget> fields;

  @override
  Widget build(BuildContext context) {
    final height = pointCount * rowHeight + (pointCount - 1) * rowSpacing;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 10,
          height: height,
          child: CustomPaint(
            painter: _RouteMarkersPainter(pointCount: pointCount),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < fields.length; index++) ...[
                if (index > 0) const SizedBox(height: rowSpacing),
                fields[index],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RouteMarkersPainter extends CustomPainter {
  const _RouteMarkersPainter({required this.pointCount});

  final int pointCount;

  static const _rowStride =
      TripRouteBlock.rowHeight + TripRouteBlock.rowSpacing;
  static const _markerRadius = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final fill = Paint()..color = AppColors.accentBlack;
    final stroke = Paint()
      ..color = AppColors.accentBlack
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final dash = Paint()
      ..color = const Color(0xFF898A8D)
      ..strokeWidth = 1;

    double centerOf(int index) =>
        TripRouteBlock.rowHeight / 2 + index * _rowStride;

    for (var index = 0; index < pointCount - 1; index++) {
      final from = centerOf(index) + _markerRadius + 2;
      final to = centerOf(index + 1) - _markerRadius - 2;
      for (var y = from; y < to; y += 4) {
        canvas.drawLine(
          Offset(centerX, y),
          Offset(centerX, (y + 2).clamp(from, to)),
          dash,
        );
      }
    }

    for (var index = 0; index < pointCount; index++) {
      final center = Offset(centerX, centerOf(index));
      if (index == 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: 10, height: 10),
            const Radius.circular(2),
          ),
          fill,
        );
      } else if (index == pointCount - 1) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: center, width: 8, height: 8),
            const Radius.circular(2),
          ),
          stroke,
        );
      } else {
        canvas.drawCircle(center, 4, fill);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RouteMarkersPainter oldDelegate) =>
      oldDelegate.pointCount != pointCount;
}
