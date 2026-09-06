import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/app/widgets/screen_header.dart';

/// Number of steps in the driver «Новый заказ» wizard, as in the design.
const createTripStepCount = 6;

/// Number of steps in the passenger «Новый заказ» wizard, as in the design.
const passengerOrderStepCount = 4;

/// Shared frame of a wizard step: «Новый заказ» header, right-aligned step
/// counter, scrollable content and a sticky primary action.
class CreateTripStepScaffold extends StatelessWidget {
  const CreateTripStepScaffold({
    required this.onBack,
    required this.primaryLabel,
    required this.onPrimary,
    required this.children,
    this.step,
    this.stepCount = createTripStepCount,
    this.title = 'Новый заказ',
    this.subtitle,
    this.secondaryLabel,
    this.onSecondary,
    this.sideBySideActions = false,
    this.footnote,
    super.key,
  });

  static const primaryButtonKey = Key('create_trip_primary');
  static const secondaryButtonKey = Key('create_trip_secondary');

  /// Step number shown as «Шаг N из [stepCount]»; omitted on screens outside
  /// the count.
  final int? step;

  /// Total steps of the wizard this screen belongs to.
  final int stepCount;
  final String title;
  final String? subtitle;
  final VoidCallback onBack;
  final String primaryLabel;

  /// `null` keeps the primary action disabled.
  final VoidCallback? onPrimary;
  final List<Widget> children;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// `true` puts the secondary action left of the primary one, as the editing
  /// screens do with «Сохранить» and «Далее».
  final bool sideBySideActions;

  final String? footnote;

  @override
  Widget build(BuildContext context) {
    final stepNumber = step;
    final footnoteText = footnote;
    final subtitleText = subtitle;
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ScreenHeader(title: title, onBack: onBack),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 12, bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (stepNumber != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Шаг $stepNumber из $stepCount',
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: AppColors.accentBlack,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            height: 1.33,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (subtitleText != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          subtitleText,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                            height: 1.33,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    ...children,
                  ],
                ),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (footnoteText != null) ...[
                    Text(
                      footnoteText,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.38,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (sideBySideActions && secondaryLabel != null)
                    Row(
                      children: [
                        Expanded(child: _secondaryAction()),
                        const SizedBox(width: 12),
                        Expanded(child: _primaryAction()),
                      ],
                    )
                  else ...[
                    _primaryAction(),
                    if (secondaryLabel != null) ...[
                      const SizedBox(height: 8),
                      _secondaryAction(),
                    ],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _primaryAction() {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: FilledButton(
        key: primaryButtonKey,
        onPressed: onPrimary,
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
        child: Text(primaryLabel),
      ),
    );
  }

  Widget _secondaryAction() {
    return SizedBox(
      height: 48,
      width: double.infinity,
      child: OutlinedButton(
        key: secondaryButtonKey,
        onPressed: onSecondary,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandGreen,
          disabledForegroundColor: AppColors.textSecondary,
          side: BorderSide(
            color: onSecondary == null
                ? AppColors.divider
                : AppColors.brandGreen,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        child: Text(secondaryLabel ?? ''),
      ),
    );
  }
}

/// Section label above a white card, as every block of the design is built.
class CreateTripSection extends StatelessWidget {
  const CreateTripSection({
    required this.title,
    required this.child,
    this.padded = true,
    this.action,
    super.key,
  });

  final String title;
  final Widget child;

  /// Optional control on the right of the section title, e.g. «Добавить авто».
  final Widget? action;

  /// `false` lets the card lay out its own padding (option lists).
  final bool padded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.accentBlack,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.33,
                    ),
                  ),
                ),
                ?action,
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: padded ? CreateTripCard(child: child) : child,
          ),
        ],
      ),
    );
  }
}

/// White rounded block used for every group of fields.
class CreateTripCard extends StatelessWidget {
  const CreateTripCard({
    required this.child,
    this.title,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.borderRadius = 12,
    this.border = false,
    super.key,
  });

  final Widget child;
  final String? title;
  final EdgeInsets padding;
  final double borderRadius;

  /// Hairline border of the smaller tiles in the design.
  final bool border;

  @override
  Widget build(BuildContext context) {
    final titleText = title;
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.accentWhite,
        borderRadius: BorderRadius.circular(borderRadius),
        border: border ? Border.all(color: AppColors.divider) : null,
      ),
      child: titleText == null
          ? child
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  titleText,
                  style: const TextStyle(
                    color: AppColors.accentBlack,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    height: 1.33,
                  ),
                ),
                const SizedBox(height: 12),
                child,
              ],
            ),
    );
  }
}

/// Field of the design: a 52pt row with a floating label, the entered value,
/// an optional clear button and an optional trailing icon.
///
/// While the field is empty and unfocused only the label is shown, as the
/// placeholder; typing or focusing lifts it above the value. The bottom border
/// turns black while the field is focused.
class CreateTripField extends StatefulWidget {
  const CreateTripField({
    required this.label,
    this.controller,
    this.onChanged,
    this.keyboardType,
    this.inputFormatters,
    this.value,
    this.onTap,
    this.onClear,
    this.clearKey,
    this.trailing,
    this.fieldKey,
    this.floatLabel = true,
    super.key,
  });

  final String label;

  /// Editable variant: text input driven by [controller].
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  /// Read-only variant: the chosen [value] opens a picker on tap.
  final String? value;
  final VoidCallback? onTap;

  /// Shows the «×» button once the field holds something.
  final VoidCallback? onClear;
  final Key? clearKey;

  final Widget? trailing;
  final Key? fieldKey;

  /// `false` keeps the label as a plain placeholder that disappears on input,
  /// the way the price fields of the design behave.
  final bool floatLabel;

  @override
  State<CreateTripField> createState() => _CreateTripFieldState();
}

class _CreateTripFieldState extends State<CreateTripField> {
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_rebuild);
    widget.controller?.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(CreateTripField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_rebuild);
      widget.controller?.addListener(_rebuild);
    }
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_rebuild);
    _focusNode
      ..removeListener(_rebuild)
      ..dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.controller?.text ?? widget.value ?? '';
    final hasText = text.trim().isNotEmpty;
    final focused = _focusNode.hasFocus;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: focused ? AppColors.accentBlack : AppColors.divider,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: widget.controller != null
                ? _editable(focused: focused)
                : _readOnly(filled: hasText, focused: focused),
          ),
          if (widget.onClear != null && hasText)
            _ClearButton(
              buttonKey: widget.clearKey,
              onPressed: widget.onClear!,
            ),
          ?widget.trailing,
        ],
      ),
    );
  }

  /// Typed field: Material floats the label above the value once the field is
  /// focused or filled, which is exactly the behaviour of the design.
  Widget _editable({required bool focused}) {
    return TextField(
      key: widget.fieldKey,
      controller: widget.controller,
      focusNode: _focusNode,
      onChanged: widget.onChanged,
      keyboardType: widget.keyboardType,
      inputFormatters: widget.inputFormatters,
      textCapitalization: TextCapitalization.sentences,
      cursorColor: AppColors.accentBlack,
      style: _valueStyle,
      decoration: InputDecoration(
        labelText: widget.floatLabel ? widget.label : null,
        hintText: widget.floatLabel ? null : widget.label,
        labelStyle: _hintStyle,
        hintStyle: _hintStyle,
        floatingLabelStyle: TextStyle(
          color: focused ? AppColors.accentBlack : AppColors.textSecondary,
          fontSize: 12,
          height: 1.33,
        ),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 6),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
    );
  }

  /// Picker field: the label lifts the same way, but the value is chosen in a
  /// bottom sheet instead of typed.
  Widget _readOnly({required bool filled, required bool focused}) {
    return InkWell(
      key: widget.fieldKey,
      onTap: widget.onTap,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (filled) ...[
              SizedBox(
                height: 16,
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: focused
                        ? AppColors.accentBlack
                        : AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.33,
                  ),
                ),
              ),
              SizedBox(
                height: 20,
                child: Text(widget.value!, style: _valueStyle),
              ),
            ] else
              SizedBox(
                height: 20,
                child: Text(widget.label, style: _hintStyle),
              ),
          ],
        ),
      ),
    );
  }
}

const _valueStyle = TextStyle(
  color: AppColors.accentBlack,
  fontSize: 15,
  height: 1.33,
);

const _hintStyle = TextStyle(
  color: AppColors.textSecondary,
  fontSize: 15,
  height: 1.33,
);

class _ClearButton extends StatelessWidget {
  const _ClearButton({required this.onPressed, this.buttonKey});

  final VoidCallback onPressed;
  final Key? buttonKey;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 24,
      child: IconButton(
        key: buttonKey,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        tooltip: 'Очистить',
        icon: const Icon(
          Icons.close_rounded,
          size: 18,
          color: AppColors.accentBlack,
        ),
      ),
    );
  }
}

/// Ruble amount field of the design: a plain «Цена» placeholder and a ₽ suffix.
class CreateTripPriceField extends StatelessWidget {
  const CreateTripPriceField({
    required this.controller,
    required this.onChanged,
    this.label = 'Цена',
    this.fieldKey,
    super.key,
  });

  final TextEditingController controller;
  final ValueChanged<int?> onChanged;
  final String label;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    return CreateTripField(
      fieldKey: fieldKey,
      label: label,
      floatLabel: false,
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: createTripPriceFormatters,
      onChanged: (value) => onChanged(int.tryParse(value.trim())),
      trailing: const Text(
        '₽',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          height: 1.38,
        ),
      ),
    );
  }
}

/// Digits-only formatter shared by the price fields.
final createTripPriceFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.digitsOnly,
  LengthLimitingTextInputFormatter(6),
];

/// «Количество мест: − N +» row of the design.
class CreateTripSeatCounter extends StatelessWidget {
  const CreateTripSeatCounter({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.minValue,
    required this.maxValue,
    super.key,
  });

  static const decreaseKey = Key('create_trip_counter_decrease');
  static const increaseKey = Key('create_trip_counter_increase');

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int minValue;
  final int maxValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.accentBlack,
              fontSize: 15,
              height: 1.33,
            ),
          ),
        ),
        _CounterButton(
          buttonKey: decreaseKey,
          icon: Icons.remove_rounded,
          filled: false,
          onPressed: value > minValue ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 48,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.accentBlack,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.29,
            ),
          ),
        ),
        _CounterButton(
          buttonKey: increaseKey,
          icon: Icons.add_rounded,
          filled: true,
          onPressed: value < maxValue ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class CreateTripCounter extends StatelessWidget {
  const CreateTripCounter({
    required this.value,
    required this.onChanged,
    required this.minValue,
    required this.maxValue,
    super.key,
  });

  static const decreaseKey = CreateTripSeatCounter.decreaseKey;
  static const increaseKey = CreateTripSeatCounter.increaseKey;

  final int value;
  final ValueChanged<int> onChanged;
  final int minValue;
  final int maxValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CounterButton(
          buttonKey: decreaseKey,
          icon: Icons.remove_rounded,
          filled: false,
          onPressed: value > minValue ? () => onChanged(value - 1) : null,
        ),
        SizedBox(
          width: 48,
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.accentBlack,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.29,
            ),
          ),
        ),
        _CounterButton(
          buttonKey: increaseKey,
          icon: Icons.add_rounded,
          filled: true,
          onPressed: value < maxValue ? () => onChanged(value + 1) : null,
        ),
      ],
    );
  }
}

class _CounterButton extends StatelessWidget {
  const _CounterButton({
    required this.buttonKey,
    required this.icon,
    required this.filled,
    required this.onPressed,
  });

  final Key buttonKey;
  final IconData icon;
  final bool filled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final background = filled ? AppColors.accentBlack : const Color(0xFF9A9B9E);
    return SizedBox.square(
      dimension: 40,
      child: IconButton.filled(
        key: buttonKey,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: background,
          foregroundColor: AppColors.accentWhite,
          disabledBackgroundColor: AppColors.divider,
          disabledForegroundColor: AppColors.accentWhite,
          shape: const CircleBorder(),
        ),
        icon: Icon(icon, size: 20),
      ),
    );
  }
}

/// Green outlined action of the design, e.g. «+ Добавить остановку».
class CreateTripOutlinedAction extends StatelessWidget {
  const CreateTripOutlinedAction({
    required this.label,
    required this.onPressed,
    this.actionKey,
    this.showIcon = true,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final Key? actionKey;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        key: actionKey,
        onPressed: onPressed,
        iconAlignment: IconAlignment.start,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 32),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          foregroundColor: AppColors.brandGreen,
          side: const BorderSide(color: AppColors.brandGreen),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
        icon: showIcon ? const Icon(Icons.add_rounded, size: 14) : null,
        label: Text(label),
      ),
    );
  }
}

/// Selectable card with a radio marker, a title, an explanation and an
/// optional illustration on the right.
class CreateTripOptionCard extends StatelessWidget {
  const CreateTripOptionCard({
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
    this.illustration,
    this.trailing,
    this.enabled = true,
    super.key,
  });

  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;
  final Widget? illustration;
  final Widget? trailing;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: enabled ? AppColors.accentWhite : AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.brandGreen : Colors.transparent,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RadioMarker(selected: selected, enabled: enabled),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: enabled
                            ? AppColors.accentBlack
                            : AppColors.textSecondary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.29,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        height: 1.33,
                      ),
                    ),
                  ],
                ),
              ),
              ?illustration,
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _RadioMarker extends StatelessWidget {
  const _RadioMarker({required this.selected, required this.enabled});

  final bool selected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.brandGreen : AppColors.textSecondary;
    return SizedBox.square(
      dimension: 20,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(width: 2, color: color),
        ),
        child: selected
            ? Padding(
                padding: const EdgeInsets.all(3.5),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

/// Small pill switch of the design: 39×24 track with a green outline.
class CreateTripSwitch extends StatelessWidget {
  const CreateTripSwitch({
    required this.value,
    required this.onChanged,
    this.switchKey,
    super.key,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final Key? switchKey;

  @override
  Widget build(BuildContext context) {
    final color = value ? AppColors.brandGreen : const Color(0xFF95969C);
    return Semantics(
      toggled: value,
      button: true,
      child: GestureDetector(
        key: switchKey,
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: Container(
          width: 39,
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1.5),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(75),
            border: Border.all(width: 1.5, color: color),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 120),
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: SizedBox.square(
              dimension: 18,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
