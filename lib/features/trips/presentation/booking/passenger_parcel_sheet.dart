import 'package:flutter/material.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/features/trips/data/preview_parcel_size_specs.dart';
import 'package:vput/features/trips/domain/passenger_booking_request.dart';
import 'package:vput/features/trips/domain/passenger_trip.dart';
import 'package:vput/features/trips/domain/trip_extras.dart';
import 'package:vput/features/trips/presentation/booking/booking_sheet_parts.dart';

/// «Отправить посылку» on a trip that carries parcels.
///
/// A parcel books no seat: the passenger picks where it is handed over and
/// collected, its size, and an optional note for the driver. The price of a
/// size is set by the platform, so the sheet only shows it.
class PassengerParcelSheet extends StatefulWidget {
  const PassengerParcelSheet({required this.trip, super.key});

  static const sheetKey = Key('passenger_parcel_sheet');
  static const submitButtonKey = Key('passenger_parcel_submit');
  static const commentFieldKey = Key('passenger_parcel_comment');

  static Key pickupKey(int index) => ValueKey('passenger_parcel_pickup_$index');
  static Key dropoffKey(int index) =>
      ValueKey('passenger_parcel_dropoff_$index');
  static Key sizeKey(ParcelSize size) =>
      ValueKey('passenger_parcel_size_${size.name}');

  final PassengerTrip trip;

  @override
  State<PassengerParcelSheet> createState() => _PassengerParcelSheetState();
}

class _PassengerParcelSheetState extends State<PassengerParcelSheet> {
  late int _pickupIndex;
  late int _dropoffIndex;
  ParcelSize? _size;
  final _commentController = TextEditingController();

  PassengerTrip get _trip => widget.trip;

  @override
  void initState() {
    super.initState();
    _pickupIndex = 0;
    _dropoffIndex = _trip.stops.length - 1;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _setPickup(int index) {
    setState(() {
      _pickupIndex = index;
      if (_dropoffIndex <= _pickupIndex) {
        _dropoffIndex = _pickupIndex + 1;
      }
    });
  }

  bool get _canSubmit => _size != null && _trip.stops.length >= 2;

  void _submit() {
    final size = _size;
    if (size == null) return;
    Navigator.of(context).pop(
      PassengerParcelRequest(
        tripId: _trip.id,
        pickupIndex: _pickupIndex,
        dropoffIndex: _dropoffIndex,
        size: size,
        comment: _commentController.text.trim(),
        amountRubles: previewParcelSizeSpec(size).priceRubles,
        status: _trip.bookingMode == PassengerTripBookingMode.instant
            ? PassengerBookingStatus.awaitingPayment
            : PassengerBookingStatus.pendingDriver,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: .94,
      child: Material(
        key: PassengerParcelSheet.sheetKey,
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 10),
              const BookingSheetDragHandle(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Отправить посылку',
                        style: TextStyle(
                          color: AppColors.accentBlack,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 26),
                      const BookingSheetSectionTitle('Откуда забрать'),
                      const SizedBox(height: 12),
                      BookingSheetRouteCard(
                        children: [
                          for (
                            var index = 0;
                            index < _trip.stops.length - 1;
                            index++
                          )
                            BookingSheetRouteTile(
                              key: PassengerParcelSheet.pickupKey(index),
                              label: _trip.stops[index].address,
                              selected: _pickupIndex == index,
                              onTap: () => _setPickup(index),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      const BookingSheetSectionTitle('Куда доставить'),
                      const SizedBox(height: 12),
                      BookingSheetRouteCard(
                        children: [
                          for (
                            var index = _pickupIndex + 1;
                            index < _trip.stops.length;
                            index++
                          )
                            BookingSheetRouteTile(
                              key: PassengerParcelSheet.dropoffKey(index),
                              label: _trip.stops[index].address,
                              selected: _dropoffIndex == index,
                              onTap: () =>
                                  setState(() => _dropoffIndex = index),
                            ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      const BookingSheetSectionTitle('Размер посылки'),
                      const SizedBox(height: 12),
                      _SizeCard(
                        selected: _size,
                        onSelected: (size) => setState(() => _size = size),
                      ),
                      const SizedBox(height: 22),
                      const BookingSheetSectionTitle('Комментарий водителю'),
                      const SizedBox(height: 12),
                      _CommentCard(controller: _commentController),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: FilledButton(
                          key: PassengerParcelSheet.submitButtonKey,
                          onPressed: _canSubmit ? _submit : null,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.brandGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Отправить заявку',
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
            ],
          ),
        ),
      ),
    );
  }
}

class _SizeCard extends StatelessWidget {
  const _SizeCard({required this.selected, required this.onSelected});

  final ParcelSize? selected;
  final ValueChanged<ParcelSize> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (final spec in previewParcelSizeSpecs) ...[
            if (spec != previewParcelSizeSpecs.first)
              const Divider(height: 1, color: AppColors.divider),
            InkWell(
              key: PassengerParcelSheet.sizeKey(spec.size),
              onTap: () => onSelected(spec.size),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Row(
                  children: [
                    BookingSheetRadioMark(selected: selected == spec.size),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            spec.title,
                            style: const TextStyle(
                              color: AppColors.accentBlack,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.33,
                            ),
                          ),
                          Text(
                            spec.dimensionsLabel,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.38,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${spec.priceRubles}₽',
                      style: const TextStyle(
                        color: AppColors.accentBlack,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.33,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CommentCard extends StatelessWidget {
  const _CommentCard({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        key: PassengerParcelSheet.commentFieldKey,
        controller: controller,
        maxLines: 3,
        maxLength: 300,
        style: const TextStyle(
          color: AppColors.accentBlack,
          fontSize: 15,
          height: 1.33,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
          hintText: 'Что внутри, как связаться при передаче',
          hintStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            height: 1.33,
          ),
        ),
      ),
    );
  }
}
