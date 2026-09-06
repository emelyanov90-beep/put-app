import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/features/trips/domain/passenger_order.dart';
import 'package:vput/features/trips/domain/passenger_trip.dart';
import 'package:vput/features/trips/presentation/widgets/passenger_bottom_bar.dart';
import 'package:vput/features/trips/presentation/widgets/trip_route_timeline.dart';

class PassengerOrdersScreen extends StatefulWidget {
  const PassengerOrdersScreen({
    required this.onTrips,
    required this.onCreate,
    required this.onChats,
    required this.onProfile,
    required this.onOrderSelected,
    required this.orders,
    super.key,
  });

  static const titleKey = Key('passenger_orders_title');
  static const emptyStateKey = Key('passenger_orders_empty');
  static const emptyImageKey = Key('passenger_orders_empty_image');
  static const createOrderButtonKey = Key('passenger_orders_create_order');
  static const allFilterKey = Key('passenger_orders_filter_all');
  static const createdFilterKey = Key('passenger_orders_filter_created');
  static const activeFilterKey = Key('passenger_orders_filter_active');
  static const completedFilterKey = Key('passenger_orders_filter_completed');

  static Key orderCardKey(String id) => ValueKey('passenger_order_card_$id');

  final VoidCallback onTrips;
  final VoidCallback onCreate;
  final VoidCallback onChats;
  final VoidCallback onProfile;
  final ValueChanged<PassengerOrder> onOrderSelected;
  final List<PassengerOrder> orders;

  @override
  State<PassengerOrdersScreen> createState() => _PassengerOrdersScreenState();
}

class _PassengerOrdersScreenState extends State<PassengerOrdersScreen> {
  PassengerOrderFilter _filter = PassengerOrderFilter.all;

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
    final visibleOrders = widget.orders
        .where((order) => _matchesFilter(order, _filter))
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
                child: _OrderFilters(
                  selected: _filter,
                  onSelected: (filter) => setState(() => _filter = filter),
                ),
              ),
              Expanded(
                child: visibleOrders.isEmpty
                    ? _EmptyOrdersState(onCreate: widget.onCreate)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        itemCount: visibleOrders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final order = visibleOrders[index];
                          return _PassengerOrderCard(
                            order: order,
                            onTap: () => widget.onOrderSelected(order),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: PassengerBottomBar(
          currentItem: PassengerNavigationItem.orders,
          onTrips: widget.onTrips,
          onOrders: () {},
          onCreate: widget.onCreate,
          onChats: widget.onChats,
          onProfile: widget.onProfile,
        ),
      ),
    );
  }

  bool _matchesFilter(PassengerOrder order, PassengerOrderFilter filter) {
    return switch (filter) {
      PassengerOrderFilter.all => true,
      PassengerOrderFilter.created =>
        order.status == PassengerOrderStatus.created,
      PassengerOrderFilter.active => order.isActive,
      PassengerOrderFilter.completed => order.isCompleted,
    };
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
          key: PassengerOrdersScreen.titleKey,
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

class _OrderFilters extends StatelessWidget {
  const _OrderFilters({required this.selected, required this.onSelected});

  final PassengerOrderFilter selected;
  final ValueChanged<PassengerOrderFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            key: PassengerOrdersScreen.allFilterKey,
            label: 'Все',
            selected: selected == PassengerOrderFilter.all,
            onTap: () => onSelected(PassengerOrderFilter.all),
          ),
          _FilterChip(
            key: PassengerOrdersScreen.createdFilterKey,
            label: 'Созданные',
            selected: selected == PassengerOrderFilter.created,
            onTap: () => onSelected(PassengerOrderFilter.created),
          ),
          _FilterChip(
            key: PassengerOrdersScreen.activeFilterKey,
            label: 'Активные',
            selected: selected == PassengerOrderFilter.active,
            onTap: () => onSelected(PassengerOrderFilter.active),
          ),
          _FilterChip(
            key: PassengerOrdersScreen.completedFilterKey,
            label: 'Завершенные',
            selected: selected == PassengerOrderFilter.completed,
            onTap: () => onSelected(PassengerOrderFilter.completed),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Material(
        color: AppColors.surfaceMuted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected ? AppColors.brandGreen : AppColors.divider,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(
              label,
              style: TextStyle(
                color: AppColors.accentBlack,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PassengerOrderCard extends StatelessWidget {
  const _PassengerOrderCard({required this.order, required this.onTap});

  final PassengerOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: PassengerOrdersScreen.orderCardKey(order.id),
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
                children: [
                  Expanded(
                    child: Text(
                      'Заказ №${order.id}',
                      style: const TextStyle(
                        color: AppColors.accentBlack,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.33,
                      ),
                    ),
                  ),
                  _StatusPill(order.statusLabel),
                ],
              ),
              const SizedBox(height: 14),
              TripRouteTimeline(
                origin: order.trip.origin.address,
                destination: order.trip.destination.address,
                intermediateStopCount: 0,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (order.hasPassengerSeat)
                    _IconText(
                      icon: Icons.person_rounded,
                      text:
                          '${order.passengerSeatCount} ${order.passengerSeatCount == 1 ? 'место' : 'места'}',
                    ),
                  for (final service in order.trip.services)
                    if (service != TripExtraService.parcel)
                      _ServiceLabel(service: service),
                  if (order.hasParcel)
                    _IconText(
                      icon: Icons.inventory_2_rounded,
                      text: 'Посылка ${order.parcelSizes.join(', ')}',
                    ),
                  if (order.driverFound) const _DriverFoundLabel(),
                ],
              ),
              const SizedBox(height: 14),
              _PriceLine(
                date: order.departureWindowLabel,
                price: order.priceRubles,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.label);

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

class _PriceLine extends StatelessWidget {
  const _PriceLine({required this.date, required this.price});

  final String date;
  final int price;

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
            '$price ₽',
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

class _EmptyOrdersState extends StatelessWidget {
  const _EmptyOrdersState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.translate(
        offset: const Offset(0, -12),
        child: Padding(
          key: PassengerOrdersScreen.emptyStateKey,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'docs/imgs/order.png',
                key: PassengerOrdersScreen.emptyImageKey,
                width: 92,
                height: 82,
                fit: BoxFit.fill,
                color: const Color(0xFFB8B9BD),
              ),
              const SizedBox(height: 10),
              const Text(
                'У вас пока нет заказов',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.accentBlack,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  height: 1.29,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Создайте заказ — водители смогут откликнуться',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                  height: 1.33,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 44,
                child: FilledButton.icon(
                  key: PassengerOrdersScreen.createOrderButtonKey,
                  onPressed: onCreate,
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

class _DriverFoundLabel extends StatelessWidget {
  const _DriverFoundLabel();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: AppColors.accentBlack,
          child: Icon(Icons.person_rounded, size: 15, color: Colors.white),
        ),
        SizedBox(width: 6),
        Text('Найден водитель', style: TextStyle(fontSize: 15, height: 1.33)),
      ],
    );
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
