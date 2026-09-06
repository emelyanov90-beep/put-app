import 'package:flutter/material.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/features/trips/presentation/address_search_sheet.dart';

class TripFiltersSheet extends StatefulWidget {
  const TripFiltersSheet({
    required this.initialOrigin,
    required this.initialDestination,
    required this.onClear,
    required this.onApply,
    super.key,
  });

  static const sheetKey = Key('trip_filters_sheet');
  static const originFieldKey = Key('trip_filters_origin');
  static const destinationFieldKey = Key('trip_filters_destination');
  static const clearButtonKey = Key('trip_filters_clear');
  static const applyButtonKey = Key('trip_filters_apply');

  final String initialOrigin;
  final String initialDestination;
  final VoidCallback onClear;
  final void Function(String origin, String destination) onApply;

  @override
  State<TripFiltersSheet> createState() => _TripFiltersSheetState();
}

class _TripFiltersSheetState extends State<TripFiltersSheet> {
  late final TextEditingController _originController;
  late final TextEditingController _destinationController;
  late final FocusNode _originFocusNode;
  late final FocusNode _destinationFocusNode;

  @override
  void initState() {
    super.initState();
    _originController = TextEditingController(text: widget.initialOrigin);
    _destinationController = TextEditingController(
      text: widget.initialDestination,
    );
    _originFocusNode = FocusNode();
    _destinationFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _originFocusNode.dispose();
    _destinationFocusNode.dispose();
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  void _apply() {
    widget.onApply(
      _originController.text.trim(),
      _destinationController.text.trim(),
    );
  }

  void _clear() {
    _originController.clear();
    _destinationController.clear();
    widget.onClear();
    setState(() {});
  }

  Future<void> _pickAddress(TextEditingController controller) async {
    FocusScope.of(context).unfocus();
    final result = await showModalBottomSheet<AddressSearchResult>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.accentBlack.withValues(alpha: .42),
      builder: (_) => AddressSearchSheet(initialQuery: controller.text),
    );
    if (!mounted || result == null) return;

    controller.text = result.filterValue;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: Material(
        key: TripFiltersSheet.sheetKey,
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Center(child: _DragHandle()),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Фильтры',
                        style: TextStyle(
                          color: AppColors.accentBlack,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ),
                    TextButton(
                      key: TripFiltersSheet.clearButtonKey,
                      onPressed: _clear,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(64, 32),
                        alignment: Alignment.centerRight,
                        foregroundColor: AppColors.errorText,
                      ),
                      child: const Text(
                        'Очистить',
                        style: TextStyle(
                          color: AppColors.errorText,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Маршрут',
                  style: TextStyle(
                    color: AppColors.accentBlack,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 18,
                      height: 112,
                      child: _FilterRouteMarkers(),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        children: [
                          _RouteFilterField(
                            fieldKey: TripFiltersSheet.originFieldKey,
                            controller: _originController,
                            focusNode: _originFocusNode,
                            hintText: 'Откуда',
                            textInputAction: TextInputAction.next,
                            onTap: () => _pickAddress(_originController),
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (_) {
                              _destinationFocusNode.requestFocus();
                            },
                          ),
                          _RouteFilterField(
                            fieldKey: TripFiltersSheet.destinationFieldKey,
                            controller: _destinationController,
                            focusNode: _destinationFocusNode,
                            hintText: 'Куда',
                            textInputAction: TextInputAction.done,
                            onTap: () => _pickAddress(_destinationController),
                            onChanged: (_) => setState(() {}),
                            onSubmitted: (_) => _apply(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    key: TripFiltersSheet.applyButtonKey,
                    onPressed: _apply,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Применить',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

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

class _RouteFilterField extends StatelessWidget {
  const _RouteFilterField({
    required this.fieldKey,
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.textInputAction,
    required this.onTap,
    required this.onChanged,
    this.onSubmitted,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hintText;
  final TextInputAction textInputAction;
  final VoidCallback onTap;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: TextField(
        key: fieldKey,
        controller: controller,
        focusNode: focusNode,
        readOnly: true,
        onTap: onTap,
        textInputAction: textInputAction,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        cursorColor: AppColors.accentBlack,
        style: const TextStyle(
          color: AppColors.accentBlack,
          fontSize: 15,
          height: 1.25,
        ),
        decoration: InputDecoration(
          labelText: hintText,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          labelStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
          ),
          floatingLabelStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            height: 1.2,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          enabledBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.divider),
          ),
          focusedBorder: const UnderlineInputBorder(
            borderSide: BorderSide(color: AppColors.accentBlack),
          ),
        ),
      ),
    );
  }
}

class _FilterRouteMarkers extends StatelessWidget {
  const _FilterRouteMarkers();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _FilterRoutePainter());
  }
}

class _FilterRoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = const Color(0xFF898A8D)
      ..strokeWidth = 1;
    for (var y = 14.0; y < size.height - 14; y += 4) {
      canvas.drawLine(Offset(9, y), Offset(9, y + 2), linePaint);
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(4, 7, 10, 10),
        const Radius.circular(2),
      ),
      Paint()..color = AppColors.accentBlack,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, size.height - 17, 10, 10),
        const Radius.circular(2),
      ),
      Paint()
        ..color = AppColors.accentWhite
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(4, size.height - 17, 10, 10),
        const Radius.circular(2),
      ),
      Paint()
        ..color = AppColors.accentBlack
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
