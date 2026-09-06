import 'package:flutter/material.dart';
import 'package:vput/app/theme/app_colors.dart';

enum PassengerNavigationItem { trips, orders, chats, profile }

class PassengerBottomBar extends StatelessWidget {
  const PassengerBottomBar({
    required this.currentItem,
    required this.onTrips,
    required this.onOrders,
    required this.onCreate,
    required this.onChats,
    required this.onProfile,
    super.key,
  });

  static const tripsButtonKey = Key('passenger_nav_trips');
  static const ordersButtonKey = Key('passenger_nav_orders');
  static const createButtonKey = Key('passenger_nav_create');
  static const chatsButtonKey = Key('passenger_nav_chats');
  static const profileButtonKey = Key('passenger_nav_profile');

  final PassengerNavigationItem currentItem;
  final VoidCallback onTrips;
  final VoidCallback onOrders;
  final VoidCallback onCreate;
  final VoidCallback onChats;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: 8),
        child: SizedBox(
          height: 56,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _NavigationButton(
                  key: tripsButtonKey,
                  label: 'Поездки',
                  assetPath: 'docs/imgs/tapbar/poezdki.png',
                  selected: currentItem == PassengerNavigationItem.trips,
                  onTap: onTrips,
                ),
              ),
              Expanded(
                child: _NavigationButton(
                  key: ordersButtonKey,
                  label: 'Мои заказы',
                  assetPath: 'docs/imgs/tapbar/orders.png',
                  selected: currentItem == PassengerNavigationItem.orders,
                  onTap: onOrders,
                ),
              ),
              SizedBox(
                width: 56,
                child: Center(
                  child: SizedBox.square(
                    dimension: 48,
                    child: IconButton.filled(
                      key: createButtonKey,
                      tooltip: 'Создать заказ',
                      onPressed: onCreate,
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.brandGreen,
                        foregroundColor: AppColors.accentWhite,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(
                            width: 3,
                            color: AppColors.background,
                            strokeAlign: BorderSide.strokeAlignOutside,
                          ),
                        ),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 26),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _NavigationButton(
                  key: chatsButtonKey,
                  label: 'Чаты',
                  assetPath: 'docs/imgs/tapbar/chats.png',
                  selected: currentItem == PassengerNavigationItem.chats,
                  onTap: onChats,
                ),
              ),
              Expanded(
                child: _NavigationButton(
                  key: profileButtonKey,
                  label: 'Профиль',
                  assetPath: 'docs/imgs/tapbar/profile.png',
                  selected: currentItem == PassengerNavigationItem.profile,
                  onTap: onProfile,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationButton extends StatelessWidget {
  const _NavigationButton({
    required this.label,
    required this.assetPath,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final String assetPath;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        child: Center(
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              selected ? AppColors.accentBlack : AppColors.textSecondary,
              BlendMode.srcIn,
            ),
            child: Image.asset(
              assetPath,
              width: 70,
              height: 34,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
          ),
        ),
      ),
    );
  }
}
