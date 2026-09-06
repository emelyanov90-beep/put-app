import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/core/utils/russian_date_labels.dart';
import 'package:vput/features/trips/application/driver_trips_controller.dart';
import 'package:vput/features/trips/data/preview_trip_publication_settings.dart';
import 'package:vput/features/trips/domain/driver_trip.dart';
import 'package:vput/features/trips/domain/passenger_trip.dart';
import 'package:vput/features/trips/domain/trip_extras.dart';
import 'package:vput/features/trips/domain/trip_publication_limits.dart';
import 'package:vput/features/trips/presentation/widgets/passenger_bottom_bar.dart';
import 'package:vput/features/trips/presentation/widgets/trip_route_timeline.dart';
import 'package:vput/features/vehicles/data/preview_driver_vehicle_repository.dart';

enum _DriverTripTab { active, completed }

class DriverTripsScreen extends ConsumerStatefulWidget {
  const DriverTripsScreen({
    required this.onBack,
    required this.onCreateTrip,
    required this.onEdit,
    required this.onPublish,
    required this.onCreateReturnTrip,
    this.onTripSelected,
    this.onPassengerProfile,
    this.onPassengerChat,
    this.onDriverBlocked,
    this.onTrips,
    this.onOrders,
    this.onChats,
    this.onProfile,
    this.now,
    super.key,
  });

  static const titleKey = Key('driver_trips_title');
  static const createButtonKey = Key('driver_trips_create');
  static const emptyStateKey = Key('driver_trips_empty');
  static const emptyImageKey = Key('driver_trips_empty_image');
  static const activeTabKey = Key('driver_trips_tab_active');
  static const completedTabKey = Key('driver_trips_tab_completed');
  static const limitNoticeKey = Key('driver_trips_limit');
  static const cancellationWarningDialogKey = Key(
    'driver_trip_cancel_warning_dialog',
  );
  static const cancellationLimitDialogKey = Key(
    'driver_trip_cancel_limit_dialog',
  );
  static const cancelKeepButtonKey = Key('driver_trip_cancel_keep');
  static const cancelConfirmButtonKey = Key('driver_trip_cancel_confirm');

  static Key tripKey(String id) => Key('driver_trip_$id');
  static Key editKey(String id) => Key('driver_trip_edit_$id');
  static Key publishKey(String id) => Key('driver_trip_publish_$id');
  static Key returnTripKey(String id) => Key('driver_trip_return_$id');
  static Key cancelKey(String id) => Key('driver_trip_cancel_$id');
  static Key seatDecreaseKey(String id) => Key('driver_trip_seats_minus_$id');
  static Key seatIncreaseKey(String id) => Key('driver_trip_seats_plus_$id');
  static Key passengerProfileKey(String id) =>
      Key('driver_trip_passenger_profile_$id');
  static Key passengerChatKey(String id) =>
      Key('driver_trip_passenger_chat_$id');

  final VoidCallback onBack;
  final VoidCallback onCreateTrip;
  final ValueChanged<DriverTrip> onEdit;
  final ValueChanged<DriverTrip> onPublish;
  final ValueChanged<DriverTrip> onCreateReturnTrip;
  final ValueChanged<DriverTrip>? onTripSelected;
  final ValueChanged<DriverTripPassengerBooking>? onPassengerProfile;
  final ValueChanged<DriverTripPassengerBooking>? onPassengerChat;
  final VoidCallback? onDriverBlocked;
  final VoidCallback? onTrips;
  final VoidCallback? onOrders;
  final VoidCallback? onChats;
  final VoidCallback? onProfile;
  final DateTime? now;

  @override
  ConsumerState<DriverTripsScreen> createState() => _DriverTripsScreenState();
}

class _DriverTripsScreenState extends ConsumerState<DriverTripsScreen> {
  var _tab = _DriverTripTab.active;

  @override
  Widget build(BuildContext context) {
    const overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: AppColors.background,
    );
    final groupedTrips = ref.watch(driverTripsByStatusProvider);
    final limits = ref.watch(tripPublicationLimitsProvider);
    final usage = ref.watch(tripPublicationUsageProvider);
    final block = usage.blockFor(limits);
    final now = widget.now ?? DateTime.now();
    final trips = <DriverTrip>[
      ...groupedTrips.drafts,
      ...groupedTrips.published,
    ];
    final visibleTrips = trips
        .where((trip) {
          final completed = trip.isCompleted(now);
          return switch (_tab) {
            _DriverTripTab.active => !completed,
            _DriverTripTab.completed => completed,
          };
        })
        .toList(growable: false);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const _OrdersHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _DriverTripTabs(
                  selected: _tab,
                  onSelected: (tab) => setState(() => _tab = tab),
                ),
              ),
              if (block != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: _LimitNotice(limits: limits, usage: usage),
                ),
              Expanded(
                child: visibleTrips.isEmpty
                    ? _EmptyState(
                        selectedTab: _tab,
                        hasAnyTrip: trips.isNotEmpty,
                        onCreateTrip: widget.onCreateTrip,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        itemCount: visibleTrips.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final trip = visibleTrips[index];
                          return _TripCard(
                            trip: trip,
                            now: now,
                            onTap: widget.onTripSelected == null
                                ? null
                                : () => widget.onTripSelected!(trip),
                            onEdit: () => widget.onEdit(trip),
                            onPublish: block == null && !trip.isPublished
                                ? () => widget.onPublish(trip)
                                : null,
                            onCreateReturnTrip: () =>
                                widget.onCreateReturnTrip(trip),
                            onPassengerProfile: widget.onPassengerProfile,
                            onPassengerChat: widget.onPassengerChat,
                            onDriverBlocked: widget.onDriverBlocked,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: PassengerBottomBar(
          currentItem: PassengerNavigationItem.orders,
          onTrips: widget.onTrips ?? widget.onBack,
          onOrders: widget.onOrders ?? () {},
          onCreate: widget.onCreateTrip,
          onChats: widget.onChats ?? () {},
          onProfile: widget.onProfile ?? () {},
        ),
      ),
    );
  }
}

class _OrdersHeader extends StatelessWidget {
  const _OrdersHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 102,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: const Padding(
        padding: EdgeInsets.only(top: 16),
        child: Text(
          'Мои заказы',
          key: DriverTripsScreen.titleKey,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.accentBlack,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

class _DriverTripTabs extends StatelessWidget {
  const _DriverTripTabs({required this.selected, required this.onSelected});

  final _DriverTripTab selected;
  final ValueChanged<_DriverTripTab> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        border: Border.all(color: const Color(0xFFC8C9CC)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              key: DriverTripsScreen.activeTabKey,
              label: 'Активные',
              selected: selected == _DriverTripTab.active,
              onTap: () => onSelected(_DriverTripTab.active),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              key: DriverTripsScreen.completedTabKey,
              label: 'Завершенные',
              selected: selected == _DriverTripTab.completed,
              onTap: () => onSelected(_DriverTripTab.completed),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
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
    return Material(
      color: selected ? AppColors.brandGreen : Colors.transparent,
      borderRadius: BorderRadius.circular(5),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? AppColors.accentWhite : AppColors.textSecondary,
              fontSize: 17,
              fontWeight: FontWeight.w400,
              height: 1.25,
            ),
          ),
        ),
      ),
    );
  }
}

class _LimitNotice extends StatelessWidget {
  const _LimitNotice({required this.limits, required this.usage});

  final TripPublicationLimits limits;
  final TripPublicationUsage usage;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: DriverTripsScreen.limitNoticeKey,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorText.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Лимит публикаций исчерпан: сегодня ${usage.publishedToday} из '
        '${limits.perDay}, за неделю ${usage.publishedThisWeek} из '
        '${limits.perWeek}. Черновики останутся на месте.',
        style: const TextStyle(
          color: AppColors.errorText,
          fontSize: 13,
          height: 1.38,
        ),
      ),
    );
  }
}

class _TripCard extends ConsumerWidget {
  const _TripCard({
    required this.trip,
    required this.now,
    required this.onTap,
    required this.onEdit,
    required this.onPublish,
    required this.onCreateReturnTrip,
    required this.onPassengerProfile,
    required this.onPassengerChat,
    required this.onDriverBlocked,
  });

  final DriverTrip trip;
  final DateTime now;
  final VoidCallback? onTap;
  final VoidCallback onEdit;
  final VoidCallback? onPublish;
  final VoidCallback onCreateReturnTrip;
  final ValueChanged<DriverTripPassengerBooking>? onPassengerProfile;
  final ValueChanged<DriverTripPassengerBooking>? onPassengerChat;
  final VoidCallback? onDriverBlocked;

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final confirmed = await _showDriverCancelDialog(context, trip);
    if (!confirmed || !context.mounted) return;
    final outcome = ref.read(driverTripsProvider.notifier).cancel(trip.id);
    if (!context.mounted) return;
    switch (outcome) {
      case DriverTripCancellationOutcome.removed:
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Поездка удалена')));
      case DriverTripCancellationOutcome.warningIssued:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Поездка отменена. Отмена с пассажирами засчитана за 30 дней.',
            ),
          ),
        );
      case DriverTripCancellationOutcome.blocked:
        onDriverBlocked?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Аккаунт водителя временно заблокирован на 30 дней'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = trip.draft;
    final departure = draft.departureAt;
    final arrival = draft.arrivalAt;
    final price = draft.fullRoutePrice;
    final bookings = trip.passengerBookings;
    final canEdit = !trip.hasJoinedPassengers;

    return Material(
      key: DriverTripsScreen.tripKey(trip.id),
      color: AppColors.accentWhite,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      'Заказ №${_orderNumber(trip.id)}',
                      style: const TextStyle(
                        color: AppColors.accentBlack,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        height: 1.33,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusPill(label: trip.statusLabel(now)),
                ],
              ),
              const SizedBox(height: 14),
              TripRouteTimeline(
                origin: draft.origin.address,
                destination: draft.destination.address,
                intermediateStopCount: 0,
              ),
              if (arrival != null) ...[
                const SizedBox(height: 14),
                _IconText(
                  icon: Icons.schedule_rounded,
                  text: 'Прибытие ~${RussianDateLabels.time(arrival)}',
                ),
              ],
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (draft.seatCount > 0)
                    _IconText(
                      icon: Icons.person_rounded,
                      text:
                          '${trip.freeSeatCount} ${_seatWord(trip.freeSeatCount)}',
                    ),
                  for (final extra in draft.extras)
                    if (extra.enabled) _ServiceLabel(service: extra.service),
                  if (draft.parcel.enabled)
                    _IconText(
                      icon: Icons.inventory_2_rounded,
                      text: 'Посылка ${_parcelSizesLabel(draft.parcel)}',
                    ),
                ],
              ),
              if (bookings.isNotEmpty) ...[
                const SizedBox(height: 14),
                _ResponsesPreview(
                  bookings: bookings,
                  onProfile: onPassengerProfile,
                  onChat: onPassengerChat,
                ),
              ],
              const SizedBox(height: 14),
              _PriceLine(
                date: departure == null
                    ? 'Время не указано'
                    : _dateAndTimeRange(departure, arrival),
                price: price,
              ),
              const SizedBox(height: 12),
              if (trip.isPublished) ...[
                _SeatCapacityRow(trip: trip),
                const SizedBox(height: 12),
              ],
              _CardActions(
                trip: trip,
                canEdit: canEdit,
                onEdit: onEdit,
                onPublish: onPublish,
                onCreateReturnTrip: onCreateReturnTrip,
                onCancel: () => _cancel(context, ref),
              ),
              if (!canEdit) ...[
                const SizedBox(height: 8),
                const Text(
                  'Изменить или отменить без предупреждения уже нельзя: '
                  'к поездке присоединился пассажир.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.33,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _orderNumber(String id) {
    final digits = RegExp(r'\d+').allMatches(id).map((match) => match.group(0));
    final number = digits.join();
    return number.isEmpty ? id : number;
  }

  String _seatWord(int count) {
    final mod100 = count % 100;
    final mod10 = count % 10;
    if (mod100 >= 11 && mod100 <= 14) return 'мест';
    if (mod10 == 1) return 'место';
    if (mod10 >= 2 && mod10 <= 4) return 'места';
    return 'мест';
  }

  String _dateAndTimeRange(DateTime departure, DateTime? arrival) {
    if (arrival == null || !RussianDateLabels.isSameDay(departure, arrival)) {
      return RussianDateLabels.dateAndTime(departure);
    }
    return '${RussianDateLabels.dayAndMonth(departure)}, '
        '${RussianDateLabels.time(departure)}–${RussianDateLabels.time(arrival)}';
  }

  String _parcelSizesLabel(TripParcelOffer parcel) {
    final labels = parcel.priceBySize.keys
        .map((size) {
          return switch (size) {
            ParcelSize.small => 'S',
            ParcelSize.medium => 'M',
            ParcelSize.large => 'L',
          };
        })
        .toList(growable: false);
    return labels.isEmpty ? '—' : labels.join(', ');
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.brandGreen),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.accentBlack,
          fontSize: 13,
          height: 1.25,
        ),
      ),
    );
  }
}

class _SeatCapacityRow extends ConsumerWidget {
  const _SeatCapacityRow({required this.trip});

  final DriverTrip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicle = trip.draft.vehicleId == null
        ? null
        : ref
              .watch(driverVehicleRepositoryProvider)
              .findById(trip.draft.vehicleId!);
    final maxSeatCapacity = [
      vehicle?.seatCount ?? 8,
      trip.draft.seatCount,
      trip.bookedSeatCount,
    ].reduce((a, b) => a > b ? a : b);
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Свободно мест: ${trip.freeSeatCount} из ${trip.draft.seatCount}',
              style: const TextStyle(
                color: AppColors.accentBlack,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _MiniCounterButton(
            buttonKey: DriverTripsScreen.seatDecreaseKey(trip.id),
            icon: Icons.remove_rounded,
            onPressed: trip.draft.seatCount > trip.bookedSeatCount
                ? () => ref
                      .read(driverTripsProvider.notifier)
                      .setSeatCapacity(trip.id, trip.draft.seatCount - 1)
                : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '${trip.draft.seatCount}',
              style: const TextStyle(
                color: AppColors.accentBlack,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _MiniCounterButton(
            buttonKey: DriverTripsScreen.seatIncreaseKey(trip.id),
            icon: Icons.add_rounded,
            onPressed: trip.draft.seatCount < maxSeatCapacity
                ? () => ref
                      .read(driverTripsProvider.notifier)
                      .setSeatCapacity(
                        trip.id,
                        trip.draft.seatCount + 1,
                        maxValue: maxSeatCapacity,
                      )
                : null,
          ),
        ],
      ),
    );
  }
}

class _MiniCounterButton extends StatelessWidget {
  const _MiniCounterButton({
    required this.buttonKey,
    required this.icon,
    required this.onPressed,
  });

  final Key buttonKey;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 28,
      child: IconButton.filled(
        key: buttonKey,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.accentBlack,
          foregroundColor: AppColors.accentWhite,
          disabledBackgroundColor: AppColors.divider,
          disabledForegroundColor: AppColors.accentWhite,
          shape: const CircleBorder(),
        ),
        icon: Icon(icon, size: 16),
      ),
    );
  }
}

class _ResponsesPreview extends StatelessWidget {
  const _ResponsesPreview({
    required this.bookings,
    required this.onProfile,
    required this.onChat,
  });

  final List<DriverTripPassengerBooking> bookings;
  final ValueChanged<DriverTripPassengerBooking>? onProfile;
  final ValueChanged<DriverTripPassengerBooking>? onChat;

  @override
  Widget build(BuildContext context) {
    final visible = bookings.take(2).toList(growable: false);
    final hidden = bookings.length - visible.length;
    final avatarWidth = visible.length <= 1 ? 30.0 : 48.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: avatarWidth,
              height: 30,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var index = 0; index < visible.length; index++)
                    Positioned(
                      left: index * 18,
                      child: _PassengerAvatar(
                        asset: visible[index].passengerAvatarAsset,
                        radius: 15,
                      ),
                    ),
                ],
              ),
            ),
            if (hidden > 0) ...[
              const SizedBox(width: 6),
              Text(
                '+$hidden',
                style: const TextStyle(fontSize: 15, height: 1.33),
              ),
            ],
            const SizedBox(width: 10),
            Text(
              '${bookings.length} ${_responsesWord(bookings.length)}',
              style: const TextStyle(
                color: AppColors.accentBlack,
                fontSize: 15,
                height: 1.33,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        for (final booking in bookings) ...[
          if (booking != bookings.first) const SizedBox(height: 8),
          _PassengerBookingRow(
            booking: booking,
            onProfile: onProfile,
            onChat: onChat,
          ),
        ],
      ],
    );
  }

  String _responsesWord(int count) {
    final mod100 = count % 100;
    final mod10 = count % 10;
    if (mod100 >= 11 && mod100 <= 14) return 'откликов';
    if (mod10 == 1) return 'отклик';
    if (mod10 >= 2 && mod10 <= 4) return 'отклика';
    return 'откликов';
  }
}

class _PassengerBookingRow extends StatelessWidget {
  const _PassengerBookingRow({
    required this.booking,
    required this.onProfile,
    required this.onChat,
  });

  final DriverTripPassengerBooking booking;
  final ValueChanged<DriverTripPassengerBooking>? onProfile;
  final ValueChanged<DriverTripPassengerBooking>? onChat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _PassengerAvatar(asset: booking.passengerAvatarAsset, radius: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.passengerName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.accentBlack,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.29,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: Color(0xFFE0A800),
                      size: 15,
                    ),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        booking.passengerRatingLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        booking.shortLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _InlineIconAction(
            actionKey: DriverTripsScreen.passengerProfileKey(booking.id),
            icon: Icons.person_rounded,
            onPressed: onProfile == null ? null : () => onProfile!(booking),
          ),
          const SizedBox(width: 4),
          _InlineIconAction(
            actionKey: DriverTripsScreen.passengerChatKey(booking.id),
            icon: Icons.chat_bubble_rounded,
            onPressed: onChat == null ? null : () => onChat!(booking),
          ),
        ],
      ),
    );
  }
}

class _PassengerAvatar extends StatelessWidget {
  const _PassengerAvatar({required this.radius, this.asset});

  final double radius;
  final String? asset;

  @override
  Widget build(BuildContext context) {
    final assetPath = asset;
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.divider,
      foregroundImage: assetPath == null ? null : AssetImage(assetPath),
      child: assetPath == null
          ? Icon(
              Icons.person_rounded,
              color: AppColors.textSecondary,
              size: radius,
            )
          : null,
    );
  }
}

class _InlineIconAction extends StatelessWidget {
  const _InlineIconAction({
    required this.actionKey,
    required this.icon,
    required this.onPressed,
  });

  final Key actionKey;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 30,
      child: IconButton(
        key: actionKey,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          foregroundColor: AppColors.brandGreen,
          disabledForegroundColor: AppColors.textSecondary,
        ),
        icon: Icon(icon, size: 18),
      ),
    );
  }
}

class _CardActions extends StatelessWidget {
  const _CardActions({
    required this.trip,
    required this.canEdit,
    required this.onEdit,
    required this.onPublish,
    required this.onCreateReturnTrip,
    required this.onCancel,
  });

  final DriverTrip trip;
  final bool canEdit;
  final VoidCallback onEdit;
  final VoidCallback? onPublish;
  final VoidCallback onCreateReturnTrip;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _CardAction(
          actionKey: DriverTripsScreen.editKey(trip.id),
          label: 'Изменить',
          onPressed: canEdit ? onEdit : null,
        ),
        if (!trip.isPublished)
          _CardAction(
            actionKey: DriverTripsScreen.publishKey(trip.id),
            label: 'Опубликовать',
            onPressed: onPublish,
            primary: true,
          ),
        if (trip.isPublished)
          _CardAction(
            actionKey: DriverTripsScreen.returnTripKey(trip.id),
            label: 'Обратный маршрут',
            onPressed: onCreateReturnTrip,
          ),
        _CardAction(
          actionKey: DriverTripsScreen.cancelKey(trip.id),
          label: trip.isPublished ? 'Отменить' : 'Удалить',
          onPressed: onCancel,
          danger: true,
        ),
      ],
    );
  }
}

class _CardAction extends StatelessWidget {
  const _CardAction({
    required this.actionKey,
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.danger = false,
  });

  final Key actionKey;
  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger
        ? AppColors.errorText
        : primary
        ? AppColors.brandGreen
        : AppColors.accentBlack;
    return OutlinedButton(
      key: actionKey,
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: color,
        disabledForegroundColor: AppColors.textSecondary,
        side: BorderSide(color: onPressed == null ? AppColors.divider : color),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
      child: Text(label),
    );
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({required this.date, required this.price});

  final String date;
  final int? price;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_month_rounded,
            size: 18,
            color: Color(0xFF898A8D),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              date,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, height: 1.33),
            ),
          ),
          Text(
            price == null ? '—' : '$price ₽',
            style: const TextStyle(
              color: AppColors.accentBlack,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceLabel extends StatelessWidget {
  const _ServiceLabel({required this.service});

  final TripExtraService service;

  @override
  Widget build(BuildContext context) {
    final (icon, text) = switch (service) {
      TripExtraService.pets => (Icons.pets_rounded, 'С животными'),
      TripExtraService.luggage => (Icons.work_rounded, 'С багажом'),
      TripExtraService.childSeat => (
        Icons.child_friendly_rounded,
        'Дет. кресло',
      ),
      TripExtraService.parcel => (Icons.inventory_2_rounded, 'Посылка'),
    };
    return _IconText(icon: icon, text: text);
  }
}

class _IconText extends StatelessWidget {
  const _IconText({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 17, color: const Color(0xFF898A8D)),
        const SizedBox(width: 5),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.accentBlack,
            fontSize: 15,
            height: 1.33,
          ),
        ),
      ],
    );
  }
}

Future<bool> _showDriverCancelDialog(
  BuildContext context,
  DriverTrip trip,
) async {
  final hasPassengers = trip.hasJoinedPassengers;
  final isLimitRisk = hasPassengers && trip.recentCancellations30d >= 1;
  final result = await showDialog<bool>(
    context: context,
    barrierColor: AppColors.accentBlack.withValues(alpha: .45),
    builder: (context) => AlertDialog(
      key: isLimitRisk
          ? DriverTripsScreen.cancellationLimitDialogKey
          : hasPassengers
          ? DriverTripsScreen.cancellationWarningDialogKey
          : null,
      backgroundColor: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        hasPassengers
            ? isLimitRisk
                  ? 'Это может повлиять на ваш аккаунт'
                  : 'Отменить поездку?'
            : trip.isPublished
            ? 'Отменить поездку?'
            : 'Удалить черновик?',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: AppColors.accentBlack,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            hasPassengers
                ? isLimitRisk
                      ? 'Вы уже отменяли поездку с пассажирами за последние '
                            '30 дней. Повторная отмена временно заблокирует '
                            'аккаунт на 30 дней.'
                      : 'К поездке уже присоединился пассажир. Такая отмена '
                            'считается нарушением правил сообщества.'
                : 'Пассажиры ещё не присоединились, поэтому действие не '
                      'повлияет на лимит отмен.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.33,
            ),
          ),
          if (hasPassengers) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.accentWhite,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Отмен за 30 дней',
                      style: TextStyle(fontSize: 13, height: 1.38),
                    ),
                  ),
                  Text(
                    '${trip.recentCancellations30d.clamp(0, 2)} / 2',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      height: 1.33,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        SizedBox(
          width: double.infinity,
          height: 44,
          child: FilledButton(
            key: DriverTripsScreen.cancelKeepButtonKey,
            onPressed: () => Navigator.of(context).pop(false),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.brandGreen,
              foregroundColor: AppColors.accentWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Не отменять'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: FilledButton(
            key: DriverTripsScreen.cancelConfirmButtonKey,
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.errorBackground,
              foregroundColor: AppColors.accentWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(hasPassengers ? 'Всё равно отменить' : 'Удалить'),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.selectedTab,
    required this.hasAnyTrip,
    required this.onCreateTrip,
  });

  final _DriverTripTab selectedTab;
  final bool hasAnyTrip;
  final VoidCallback onCreateTrip;

  @override
  Widget build(BuildContext context) {
    final title = hasAnyTrip
        ? selectedTab == _DriverTripTab.active
              ? 'Активных поездок нет'
              : 'Завершенных поездок нет'
        : 'У вас пока нет поездок';
    final subtitle = hasAnyTrip
        ? selectedTab == _DriverTripTab.active
              ? 'Создайте поездку, чтобы пассажиры могли найти ваш маршрут'
              : 'Завершенные поездки появятся здесь после времени прибытия'
        : 'Создайте поездку, чтобы пассажиры могли найти ваш маршрут';

    return Center(
      child: Transform.translate(
        offset: const Offset(0, -12),
        child: Padding(
          key: DriverTripsScreen.emptyStateKey,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'docs/imgs/order.png',
                key: DriverTripsScreen.emptyImageKey,
                width: 92,
                height: 82,
                fit: BoxFit.fill,
                color: const Color(0xFFB8B9BD),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.accentBlack,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.29,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.33,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 44,
                child: FilledButton.icon(
                  key: DriverTripsScreen.createButtonKey,
                  onPressed: onCreateTrip,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandGreen,
                    foregroundColor: AppColors.accentWhite,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text(
                    'Создать заказ',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
