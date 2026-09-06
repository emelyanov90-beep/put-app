import 'package:flutter/material.dart';
import 'package:vput/app/theme/app_colors.dart';

/// Building blocks shared by the passenger booking sheets — «Откликнуться на
/// заказ» for a seat and «Отправить посылку» for a parcel — so both read as one
/// surface instead of two look-alikes.
class BookingSheetDragHandle extends StatelessWidget {
  const BookingSheetDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 43,
      height: 5,
      decoration: BoxDecoration(
        color: const Color(0xFFCACBCE),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class BookingSheetSectionTitle extends StatelessWidget {
  const BookingSheetSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.accentBlack,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
    );
  }
}

class BookingSheetRouteCard extends StatelessWidget {
  const BookingSheetRouteCard({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.accentWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: BookingSheetRoadWatermark()),
          Column(children: children),
        ],
      ),
    );
  }
}

class BookingSheetRouteTile extends StatelessWidget {
  const BookingSheetRouteTile({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            BookingSheetRadioMark(selected: selected),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.accentBlack,
                  fontSize: 15,
                  height: 1.33,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BookingSheetRadioMark extends StatelessWidget {
  const BookingSheetRadioMark({required this.selected, super.key});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.brandGreen, width: 2),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: AppColors.brandGreen,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}

class BookingSheetSwitch extends StatelessWidget {
  const BookingSheetSwitch({required this.value, super.key});

  final bool value;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 42,
      height: 26,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: value ? AppColors.brandGreen : AppColors.accentWhite,
        border: Border.all(color: AppColors.brandGreen, width: 2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Align(
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
            color: value ? AppColors.accentWhite : AppColors.brandGreen,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class BookingSheetCounterButton extends StatelessWidget {
  const BookingSheetCounterButton({
    required this.icon,
    required this.enabled,
    required this.primary,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final bool enabled;
  final bool primary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final background = primary
        ? AppColors.accentBlack
        : const Color(0xFF898A8D);
    return IconButton.outlined(
      onPressed: enabled ? onTap : null,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        fixedSize: const Size(40, 40),
        backgroundColor: enabled ? background : AppColors.surfaceMuted,
        foregroundColor: AppColors.accentWhite,
        disabledForegroundColor: AppColors.accentWhite,
        side: const BorderSide(color: AppColors.divider),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class BookingSheetRoadWatermark extends StatelessWidget {
  const BookingSheetRoadWatermark({super.key});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(painter: BookingSheetRoadWatermarkPainter()),
    );
  }
}

class BookingSheetRoadWatermarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width * .54, -14)
      ..cubicTo(
        size.width * 1.02,
        size.height * .14,
        size.width * .5,
        size.height * .38,
        size.width * .68,
        size.height * .64,
      )
      ..cubicTo(
        size.width * .84,
        size.height * .86,
        size.width * .95,
        size.height * .82,
        size.width * 1.05,
        size.height * 1.08,
      );
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFF1F2F3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 48
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
