import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/app/widgets/screen_header.dart';
import 'package:vput/features/trips/application/passenger_order_draft_controller.dart';
import 'package:vput/features/trips/domain/passenger_order_draft.dart';
import 'package:vput/features/trips/domain/trip_route_point.dart';
import 'package:vput/features/trips/presentation/widgets/create_trip_controls.dart';

class PassengerOrderScheduleScreen extends ConsumerStatefulWidget {
  const PassengerOrderScheduleScreen({
    required this.onBack,
    required this.onContinue,
    this.now,
    super.key,
  });

  static const dateFieldKey = Key('passenger_order_date');
  static const departureTimeFieldKey = Key('passenger_order_departure_time');
  static const arrivalTimeFieldKey = Key('passenger_order_arrival_time');
  static const addStopButtonKey = Key('passenger_order_add_stop');
  static const continueButtonKey = Key('passenger_order_schedule_continue');
  static const passengerDecreaseKey = Key('passenger_order_passenger_minus');
  static const passengerIncreaseKey = Key('passenger_order_passenger_plus');
  static const passengerCountKey = Key('passenger_order_passenger_count');

  static Key pointFieldKey(int index) => Key('passenger_order_point_$index');
  static Key clearPointKey(int index) => Key('passenger_order_clear_$index');

  final VoidCallback onBack;
  final VoidCallback onContinue;
  final DateTime? now;

  @override
  ConsumerState<PassengerOrderScheduleScreen> createState() =>
      _PassengerOrderScheduleScreenState();
}

class _PassengerOrderScheduleScreenState
    extends ConsumerState<PassengerOrderScheduleScreen> {
  late final DateTime _now = widget.now ?? DateTime.now();
  final _controllers = <TextEditingController>[];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _syncControllers(List<TripRoutePoint> points) {
    while (_controllers.length < points.length) {
      _controllers.add(TextEditingController());
    }
    while (_controllers.length > points.length) {
      _controllers.removeLast().dispose();
    }
    for (var index = 0; index < points.length; index++) {
      final address = points[index].address;
      if (_controllers[index].text != address) {
        _controllers[index].text = address;
      }
    }
  }

  Future<void> _pickDate(PassengerOrderDraft draft) async {
    final day = await PassengerOrderDatePickerSheet.show(
      context,
      now: _now,
      selectedDay: draft.departureAt,
    );
    if (day == null || !mounted) return;
    ref
        .read(passengerOrderDraftProvider.notifier)
        .setDepartureDay(day, now: _now);
  }

  Future<void> _pickDepartureTime(PassengerOrderDraft draft) async {
    if (draft.departureAt == null) return;
    final time = await PassengerOrderTimePickerSheet.show(
      context,
      selected: TimeOfDay.fromDateTime(draft.departureAt!),
    );
    if (time == null || !mounted) return;
    ref
        .read(passengerOrderDraftProvider.notifier)
        .setDepartureTime(hour: time.hour, minute: time.minute);
  }

  Future<void> _pickArrivalTime(PassengerOrderDraft draft) async {
    if (draft.departureAt == null) return;
    final selected = draft.arrivalAt == null
        ? TimeOfDay.fromDateTime(draft.departureAt!)
        : TimeOfDay.fromDateTime(draft.arrivalAt!);
    final time = await PassengerOrderTimePickerSheet.show(
      context,
      selected: selected,
    );
    if (time == null || !mounted) return;
    ref
        .read(passengerOrderDraftProvider.notifier)
        .setArrivalTime(hour: time.hour, minute: time.minute);
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(passengerOrderDraftProvider);
    final controller = ref.read(passengerOrderDraftProvider.notifier);
    final points = draft.points;
    _syncControllers(points);
    final canContinue = draft.canContinue(now: _now);

    const overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: AppColors.background,
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ScreenHeader(
                  title: 'Новый заказ',
                  onBack: widget.onBack,
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Шаг 2 из $passengerOrderStepCount',
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          color: AppColors.accentBlack,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.33,
                        ),
                      ),
                      const SizedBox(height: 28),
                      _SectionTitle('Маршрут'),
                      const SizedBox(height: 12),
                      _RouteCard(
                        pointCount: points.length,
                        children: [
                          for (var index = 0; index < points.length; index++)
                            CreateTripField(
                              fieldKey:
                                  PassengerOrderScheduleScreen.pointFieldKey(
                                    index,
                                  ),
                              clearKey:
                                  PassengerOrderScheduleScreen.clearPointKey(
                                    index,
                                  ),
                              label: index == points.length - 1
                                  ? 'Пункт назначения'
                                  : 'Точка посадки',
                              controller: _controllers[index],
                              onChanged: (value) => controller.setPointAt(
                                index,
                                points[index].copyWith(address: value),
                              ),
                              onClear: () {
                                if (index == 0 || index == points.length - 1) {
                                  controller.setPointAt(
                                    index,
                                    const TripRoutePoint(address: ''),
                                  );
                                  return;
                                }
                                controller.removeStopAt(index);
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 11),
                      CreateTripOutlinedAction(
                        actionKey:
                            PassengerOrderScheduleScreen.addStopButtonKey,
                        label: 'Добавить остановку',
                        onPressed: controller.addStop,
                      ),
                      const SizedBox(height: 28),
                      _SectionTitle('Дата и время выезда'),
                      const SizedBox(height: 12),
                      CreateTripCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: CreateTripField(
                                fieldKey:
                                    PassengerOrderScheduleScreen.dateFieldKey,
                                label: 'Дата',
                                value: draft.departureAt == null
                                    ? null
                                    : _numericDate(draft.departureAt!),
                                onTap: () => _pickDate(draft),
                                trailing: const _FieldIcon(
                                  Icons.calendar_today_rounded,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: CreateTripField(
                                fieldKey: PassengerOrderScheduleScreen
                                    .departureTimeFieldKey,
                                label: 'Время',
                                value: draft.departureAt == null
                                    ? null
                                    : _timeLabel(draft.departureAt!),
                                onTap: draft.departureAt == null
                                    ? null
                                    : () => _pickDepartureTime(draft),
                                trailing: const _FieldIcon(
                                  Icons.schedule_rounded,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      _SectionTitle('Примерное время прибытия'),
                      const SizedBox(height: 12),
                      CreateTripCard(
                        child: CreateTripField(
                          fieldKey:
                              PassengerOrderScheduleScreen.arrivalTimeFieldKey,
                          label: 'Время',
                          value: draft.arrivalAt == null
                              ? null
                              : _timeLabel(draft.arrivalAt!),
                          onTap: draft.departureAt == null
                              ? null
                              : () => _pickArrivalTime(draft),
                          trailing: const _FieldIcon(Icons.schedule_rounded),
                        ),
                      ),
                      const SizedBox(height: 28),
                      _SectionTitle('Пассажиры'),
                      const SizedBox(height: 12),
                      CreateTripCard(
                        child: _PassengerCounter(
                          value: draft.passengerCount,
                          onChanged: controller.setPassengerCount,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      key: PassengerOrderScheduleScreen.continueButtonKey,
                      onPressed: canContinue ? widget.onContinue : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.brandGreen,
                        foregroundColor: AppColors.accentWhite,
                        disabledBackgroundColor: AppColors.divider,
                        disabledForegroundColor: AppColors.textSecondary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.33,
                        ),
                      ),
                      child: const Text('Далее'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PassengerOrderDatePickerSheet extends StatefulWidget {
  const PassengerOrderDatePickerSheet({
    required this.now,
    this.selectedDay,
    super.key,
  });

  static const sheetKey = Key('passenger_order_date_sheet');
  static const confirmButtonKey = Key('passenger_order_date_confirm');

  static Key dayKey(DateTime day) =>
      Key('passenger_order_date_${day.year}_${day.month}_${day.day}');

  final DateTime now;
  final DateTime? selectedDay;

  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime now,
    DateTime? selectedDay,
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) =>
          PassengerOrderDatePickerSheet(now: now, selectedDay: selectedDay),
    );
  }

  @override
  State<PassengerOrderDatePickerSheet> createState() =>
      _PassengerOrderDatePickerSheetState();
}

class _PassengerOrderDatePickerSheetState
    extends State<PassengerOrderDatePickerSheet> {
  late DateTime _visibleMonth = DateTime(
    (widget.selectedDay ?? widget.now).year,
    (widget.selectedDay ?? widget.now).month,
  );
  late DateTime _selected = _stripTime(widget.selectedDay ?? widget.now);

  @override
  Widget build(BuildContext context) {
    return _BottomSheetFrame(
      sheetKey: PassengerOrderDatePickerSheet.sheetKey,
      title: 'Выбрать дату',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.accentWhite,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      '${_monthName(_visibleMonth.month)} ${_visibleMonth.year}',
                      style: const TextStyle(
                        color: AppColors.accentBlack,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 24),
                    const Spacer(),
                    IconButton(
                      onPressed: _canGoPrevious ? _previousMonth : null,
                      icon: const Icon(Icons.chevron_left_rounded, size: 32),
                      color: const Color(0xFF898A8D),
                    ),
                    IconButton(
                      onPressed: _nextMonth,
                      icon: const Icon(Icons.chevron_right_rounded, size: 32),
                      color: const Color(0xFF898A8D),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (final day in const [
                      'ПН',
                      'ВТ',
                      'СР',
                      'ЧТ',
                      'ПТ',
                      'СБ',
                      'ВС',
                    ])
                      Expanded(
                        child: Text(
                          day,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF898A8D),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.33,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                _CalendarGrid(
                  month: _visibleMonth,
                  now: widget.now,
                  selected: _selected,
                  onSelected: (day) => setState(() => _selected = day),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              key: PassengerOrderDatePickerSheet.confirmButtonKey,
              onPressed: () => Navigator.of(context).pop(_selected),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                foregroundColor: AppColors.accentWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Выбрать дату'),
            ),
          ),
        ],
      ),
    );
  }

  bool get _canGoPrevious {
    final current = DateTime(widget.now.year, widget.now.month);
    return _visibleMonth.isAfter(current);
  }

  void _previousMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    });
  }
}

class PassengerOrderTimePickerSheet extends StatefulWidget {
  const PassengerOrderTimePickerSheet({this.selected, super.key});

  static const sheetKey = Key('passenger_order_time_sheet');
  static const confirmButtonKey = Key('passenger_order_time_confirm');

  final TimeOfDay? selected;

  static Future<TimeOfDay?> show(BuildContext context, {TimeOfDay? selected}) {
    return showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => PassengerOrderTimePickerSheet(selected: selected),
    );
  }

  @override
  State<PassengerOrderTimePickerSheet> createState() =>
      _PassengerOrderTimePickerSheetState();
}

class _PassengerOrderTimePickerSheetState
    extends State<PassengerOrderTimePickerSheet> {
  late int _hour = widget.selected?.hour ?? 8;
  late int _minute = widget.selected?.minute == 30 ? 30 : 0;
  late final FixedExtentScrollController _hourController =
      FixedExtentScrollController(initialItem: _hour);
  late final FixedExtentScrollController _minuteController =
      FixedExtentScrollController(initialItem: _minute == 30 ? 1 : 0);

  @override
  void dispose() {
    _hourController.dispose();
    _minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetFrame(
      sheetKey: PassengerOrderTimePickerSheet.sheetKey,
      title: 'Выбрать время',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 178,
            decoration: BoxDecoration(
              color: AppColors.accentWhite,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0x14747480),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 72,
                      child: CupertinoPicker(
                        scrollController: _hourController,
                        itemExtent: 36,
                        magnification: 1.05,
                        selectionOverlay: const SizedBox.shrink(),
                        onSelectedItemChanged: (index) {
                          setState(() => _hour = index);
                        },
                        children: [
                          for (var hour = 0; hour < 24; hour++)
                            Center(
                              child: Text(
                                '$hour',
                                style: const TextStyle(
                                  color: Color(0x993C3C43),
                                  fontSize: 23,
                                  height: 1.22,
                                  letterSpacing: 1.8,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: 72,
                      child: CupertinoPicker(
                        scrollController: _minuteController,
                        itemExtent: 36,
                        magnification: 1.05,
                        selectionOverlay: const SizedBox.shrink(),
                        onSelectedItemChanged: (index) {
                          setState(() => _minute = index == 0 ? 0 : 30);
                        },
                        children: const [
                          Center(
                            child: Text(
                              '00',
                              style: TextStyle(
                                color: Color(0x993C3C43),
                                fontSize: 23,
                                height: 1.22,
                                letterSpacing: 1.8,
                              ),
                            ),
                          ),
                          Center(
                            child: Text(
                              '30',
                              style: TextStyle(
                                color: Color(0x993C3C43),
                                fontSize: 23,
                                height: 1.22,
                                letterSpacing: 1.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              key: PassengerOrderTimePickerSheet.confirmButtonKey,
              onPressed: () =>
                  Navigator.of(context)
                      .pop(TimeOfDay(hour: _hour, minute: _minute)),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandGreen,
                foregroundColor: AppColors.accentWhite,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Выбрать время'),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomSheetFrame extends StatelessWidget {
  const _BottomSheetFrame({
    required this.sheetKey,
    required this.title,
    required this.child,
  });

  final Key sheetKey;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: sheetKey,
      color: AppColors.background,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 43,
                  height: 5,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCACBCE),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.accentBlack,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.29,
                ),
              ),
              const SizedBox(height: 20),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.month,
    required this.now,
    required this.selected,
    required this.onSelected,
  });

  final DateTime month;
  final DateTime now;
  final DateTime selected;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month);
    final emptyPrefix = first.weekday - 1;
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final cells = emptyPrefix + daysInMonth;
    final rows = (cells / 7).ceil();
    final today = _stripTime(now);

    return Column(
      children: [
        for (var row = 0; row < rows; row++)
          Row(
            children: [
              for (var column = 0; column < 7; column++)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final dayNumber = row * 7 + column - emptyPrefix + 1;
                      if (dayNumber < 1 || dayNumber > daysInMonth) {
                        return const SizedBox(height: 48);
                      }
                      final day = DateTime(month.year, month.month, dayNumber);
                      final disabled = day.isBefore(today);
                      final isSelected = _isSameDay(day, selected);
                      return SizedBox(
                        height: 48,
                        child: Center(
                          child: InkWell(
                            key: PassengerOrderDatePickerSheet.dayKey(day),
                            onTap: disabled ? null : () => onSelected(day),
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              width: 40,
                              height: 40,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.brandGreen
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$dayNumber',
                                style: TextStyle(
                                  color: isSelected
                                      ? AppColors.accentWhite
                                      : disabled
                                      ? const Color(0xFFB8B9BD)
                                      : AppColors.accentBlack,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: AppColors.accentBlack,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.33,
      ),
    );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({required this.pointCount, required this.children});

  final int pointCount;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return CreateTripCard(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Stack(
        children: [
          const Positioned.fill(child: _RoadBackground()),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 10,
                height: pointCount * 52 + (pointCount - 1) * 2,
                child: CustomPaint(
                  painter: _RouteMarkersPainter(pointCount: pointCount),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    for (var index = 0; index < children.length; index++) ...[
                      if (index > 0) const SizedBox(height: 2),
                      children[index],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoadBackground extends StatelessWidget {
  const _RoadBackground();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: SizedBox(
        width: 238,
        height: 190,
        child: CustomPaint(painter: _RoadPainter()),
      ),
    );
  }
}

class _RoadPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final road = Paint()
      ..color = AppColors.background
      ..style = PaintingStyle.stroke
      ..strokeWidth = 58
      ..strokeCap = StrokeCap.round;
    final edge = Paint()
      ..color = AppColors.accentWhite.withValues(alpha: .85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final dash = Paint()
      ..color = AppColors.accentWhite.withValues(alpha: .9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final path = Path()
      ..moveTo(size.width * .98, size.height * .12)
      ..cubicTo(
        size.width * .54,
        size.height * .02,
        size.width * .31,
        size.height * .42,
        size.width * .64,
        size.height * .62,
      )
      ..cubicTo(
        size.width * .82,
        size.height * .72,
        size.width * .9,
        size.height * .88,
        size.width * .82,
        size.height * .98,
      );
    canvas.drawPath(path, road);
    canvas.drawPath(path, edge);
    for (var i = 0; i < 5; i++) {
      final y = size.height * (.28 + i * .12);
      canvas.drawLine(
        Offset(size.width * (.36 + i * .04), y),
        Offset(size.width * (.43 + i * .04), y + 18),
        dash,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RouteMarkersPainter extends CustomPainter {
  const _RouteMarkersPainter({required this.pointCount});

  final int pointCount;

  @override
  void paint(Canvas canvas, Size size) {
    const rowHeight = 52.0;
    const rowSpacing = 2.0;
    const stride = rowHeight + rowSpacing;
    const radius = 5.0;
    final centerX = size.width / 2;
    final fill = Paint()..color = AppColors.accentBlack;
    final stroke = Paint()
      ..color = AppColors.accentBlack
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final dash = Paint()
      ..color = const Color(0xFF898A8D)
      ..strokeWidth = 1;

    double centerOf(int index) => rowHeight / 2 + index * stride;

    for (var index = 0; index < pointCount - 1; index++) {
      final from = centerOf(index) + radius + 2;
      final to = centerOf(index + 1) - radius - 2;
      for (var y = from; y < to; y += 4) {
        canvas.drawLine(
          Offset(centerX, y),
          Offset(centerX, (y + 2).clamp(y, to)),
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
            Rect.fromCenter(center: center, width: 10, height: 10),
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

class _FieldIcon extends StatelessWidget {
  const _FieldIcon(this.icon);

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Icon(icon, size: 18, color: const Color(0xFF898A8D));
  }
}

class _PassengerCounter extends StatelessWidget {
  const _PassengerCounter({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Количество мест:',
            style: TextStyle(
              color: AppColors.accentBlack,
              fontSize: 15,
              height: 1.33,
            ),
          ),
        ),
        _RoundCounterButton(
          key: PassengerOrderScheduleScreen.passengerDecreaseKey,
          icon: Icons.remove_rounded,
          background: AppColors.accentBlack,
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 56,
          child: Text(
            '$value',
            key: PassengerOrderScheduleScreen.passengerCountKey,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.accentBlack,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.29,
            ),
          ),
        ),
        _RoundCounterButton(
          key: PassengerOrderScheduleScreen.passengerIncreaseKey,
          icon: Icons.add_rounded,
          background: AppColors.accentBlack,
          onPressed: value < 8 ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class _RoundCounterButton extends StatelessWidget {
  const _RoundCounterButton({
    required super.key,
    required this.icon,
    required this.background,
    required this.onPressed,
  });

  final IconData icon;
  final Color background;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 40,
      child: IconButton.filled(
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: background,
          foregroundColor: AppColors.accentWhite,
          disabledBackgroundColor: const Color(0xFFCACBCE),
          disabledForegroundColor: AppColors.accentWhite,
          shape: const CircleBorder(),
        ),
        icon: Icon(icon, size: 20),
      ),
    );
  }
}

String _numericDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}

String _timeLabel(DateTime date) {
  final minute = date.minute.toString().padLeft(2, '0');
  return '${date.hour}:$minute';
}

DateTime _stripTime(DateTime date) => DateTime(date.year, date.month, date.day);

bool _isSameDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;

String _monthName(int month) => const [
  'Январь',
  'Февраль',
  'Март',
  'Апрель',
  'Май',
  'Июнь',
  'Июль',
  'Август',
  'Сентябрь',
  'Октябрь',
  'Ноябрь',
  'Декабрь',
][month - 1];
