import 'package:flutter/material.dart';
import 'package:vput/app/theme/app_colors.dart';

class TripRouteTimeline extends StatelessWidget {
  const TripRouteTimeline({
    required this.origin,
    required this.destination,
    required this.intermediateStopCount,
    this.expandedStopButton = false,
    this.intermediateStops = const [],
    this.showIntermediateStops = false,
    super.key,
  });

  final String origin;
  final String destination;
  final int intermediateStopCount;
  final bool expandedStopButton;
  final List<String> intermediateStops;
  final bool showIntermediateStops;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StopRow(text: origin, marker: const _OriginMarker()),
        const _Connector(),
        if (intermediateStopCount > 0) ...[
          _StopRow(
            text: '$intermediateStopCount ${_stopsWord(intermediateStopCount)}',
            textColor: expandedStopButton
                ? AppColors.brandGreen
                : const Color(0xFF898A8D),
            marker: const _IntermediateMarker(),
            outlined: expandedStopButton,
          ),
          const _Connector(),
          if (showIntermediateStops)
            for (final stop in intermediateStops) ...[
              _StopRow(text: stop, marker: const _IntermediateMarker()),
              const _Connector(),
            ],
        ],
        _StopRow(text: destination, marker: const _DestinationMarker()),
      ],
    );
  }

  String _stopsWord(int count) {
    final mod100 = count % 100;
    final mod10 = count % 10;
    if (mod100 >= 11 && mod100 <= 14) return 'остановок';
    if (mod10 == 1) return 'остановка';
    if (mod10 >= 2 && mod10 <= 4) return 'остановки';
    return 'остановок';
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.text,
    required this.marker,
    this.textColor = AppColors.accentBlack,
    this.outlined = false,
  });

  final String text;
  final Widget marker;
  final Color textColor;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 14, height: 18, child: Center(child: marker)),
        const SizedBox(width: 7),
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: outlined
                  ? const EdgeInsets.symmetric(horizontal: 8, vertical: 5)
                  : EdgeInsets.zero,
              decoration: outlined
                  ? BoxDecoration(
                      border: Border.all(color: AppColors.brandGreen),
                      borderRadius: BorderRadius.circular(8),
                    )
                  : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      text,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        height: 1.2,
                      ),
                    ),
                  ),
                  if (outlined) ...[
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: AppColors.brandGreen,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Connector extends StatelessWidget {
  const _Connector();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 14,
      height: 12,
      child: Center(child: _DottedVerticalLine()),
    );
  }
}

class _OriginMarker extends StatelessWidget {
  const _OriginMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: AppColors.accentBlack,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _DestinationMarker extends StatelessWidget {
  const _DestinationMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        border: Border.all(width: 2, color: AppColors.accentBlack),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _IntermediateMarker extends StatelessWidget {
  const _IntermediateMarker();

  @override
  Widget build(BuildContext context) {
    return const SizedBox.square(
      dimension: 6,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.accentBlack,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _DottedVerticalLine extends StatelessWidget {
  const _DottedVerticalLine();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1,
      height: 12,
      child: CustomPaint(painter: _DottedLinePainter()),
    );
  }
}

class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF898A8D)
      ..strokeWidth = 1;
    for (var y = 0.0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(0, y + 1.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
