import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/features/onboarding/application/onboarding_draft_controller.dart';
import 'package:vput/features/profile/application/user_profile_controller.dart';
import 'package:vput/features/profile/domain/user_profile.dart';
import 'package:vput/features/trips/presentation/widgets/passenger_bottom_bar.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({
    required this.onSwitchRole,
    required this.onPersonalData,
    required this.onVehicles,
    required this.onSavedRoutes,
    required this.onOrderHistory,
    required this.onComplaints,
    required this.onNotifications,
    required this.onPaymentMethod,
    required this.onFaq,
    required this.onAbout,
    required this.onLogout,
    required this.onTrips,
    required this.onOrders,
    required this.onCreate,
    required this.onChats,
    super.key,
  });

  static const titleKey = Key('profile_title');
  static const avatarKey = Key('profile_avatar');
  static const nameKey = Key('profile_name');
  static const ratingKey = Key('profile_rating');
  static const switchRoleItemKey = Key('profile_switch_role');
  static const personalDataItemKey = Key('profile_personal_data');
  static const vehiclesItemKey = Key('profile_vehicles');
  static const savedRoutesItemKey = Key('profile_saved_routes');
  static const orderHistoryItemKey = Key('profile_order_history');
  static const complaintsItemKey = Key('profile_complaints');
  static const notificationsItemKey = Key('profile_notifications');
  static const notificationsBadgeKey = Key('profile_notifications_badge');
  static const paymentMethodItemKey = Key('profile_payment_method');
  static const faqItemKey = Key('profile_faq');
  static const aboutItemKey = Key('profile_about');
  static const logoutButtonKey = Key('profile_logout');
  static const logoutDialogKey = Key('profile_logout_dialog');
  static const logoutConfirmKey = Key('profile_logout_confirm');
  static const logoutCancelKey = Key('profile_logout_cancel');

  final VoidCallback onSwitchRole;
  final VoidCallback onPersonalData;
  final VoidCallback onVehicles;
  final VoidCallback onSavedRoutes;
  final VoidCallback onOrderHistory;
  final VoidCallback onComplaints;
  final VoidCallback onNotifications;
  final VoidCallback onPaymentMethod;
  final VoidCallback onFaq;
  final VoidCallback onAbout;
  final VoidCallback onLogout;
  final VoidCallback onTrips;
  final VoidCallback onOrders;
  final VoidCallback onCreate;
  final VoidCallback onChats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: AppColors.background,
    );

    final profile = ref.watch(userProfileProvider.select((s) => s.profile));
    final role = ref.watch(onboardingDraftProvider.select((d) => d.role));
    final isDriver = role == OnboardingRole.driver;
    final switchRoleLabel = isDriver
        ? 'Перейти в режим пассажира'
        : 'Перейти в режим водителя';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(
                height: 54,
                child: Center(
                  child: Text(
                    'Мой профиль',
                    key: titleKey,
                    style: TextStyle(
                      color: AppColors.accentBlack,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    children: [
                      _ProfileSummary(profile: profile),
                      const SizedBox(height: 20),
                      _MenuItem(
                        key: switchRoleItemKey,
                        icon: Icons.swap_horiz_rounded,
                        title: switchRoleLabel,
                        onTap: onSwitchRole,
                      ),
                      const SizedBox(height: 10),
                      _MenuItem(
                        key: personalDataItemKey,
                        icon: Icons.person_outline_rounded,
                        title: 'Личные данные',
                        subtitle: 'Имя, фото',
                        onTap: onPersonalData,
                      ),
                      if (isDriver) ...[
                        const SizedBox(height: 10),
                        _MenuItem(
                          key: vehiclesItemKey,
                          icon: Icons.directions_car_filled_rounded,
                          title: 'Транспортные средства',
                          subtitle: 'Информация о ТС пользователя',
                          onTap: onVehicles,
                        ),
                      ],
                      const SizedBox(height: 10),
                      _MenuItem(
                        key: savedRoutesItemKey,
                        icon: Icons.alt_route_rounded,
                        title: 'Сохраненные маршруты',
                        subtitle: 'Избранные адреса и поездки',
                        onTap: onSavedRoutes,
                      ),
                      const SizedBox(height: 10),
                      _MenuItem(
                        key: orderHistoryItemKey,
                        icon: Icons.receipt_long_rounded,
                        title: 'История заказов',
                        subtitle: 'Прошлые поездки и детали',
                        onTap: onOrderHistory,
                      ),
                      const SizedBox(height: 10),
                      _MenuItem(
                        key: complaintsItemKey,
                        icon: Icons.report_outlined,
                        title: 'Жалобы',
                        subtitle: 'Список жалоб',
                        onTap: onComplaints,
                      ),
                      const SizedBox(height: 10),
                      _MenuItem(
                        key: notificationsItemKey,
                        icon: Icons.notifications_none_rounded,
                        title: 'Уведомления',
                        subtitle: 'Push-уведомления',
                        badgeCount: profile.unreadNotifications,
                        badgeKey: notificationsBadgeKey,
                        onTap: onNotifications,
                      ),
                      const SizedBox(height: 10),
                      _MenuItem(
                        key: paymentMethodItemKey,
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Способ оплаты',
                        subtitle: 'Карты и способы оплаты',
                        onTap: onPaymentMethod,
                      ),
                      const SizedBox(height: 10),
                      _MenuItem(
                        key: faqItemKey,
                        icon: Icons.help_outline_rounded,
                        title: 'Частые вопросы',
                        onTap: onFaq,
                      ),
                      const SizedBox(height: 10),
                      _MenuItem(
                        key: aboutItemKey,
                        icon: Icons.info_outline_rounded,
                        title: 'О приложении',
                        subtitle: 'Версия, информация',
                        onTap: onAbout,
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          key: logoutButtonKey,
                          onPressed: () => _confirmLogout(context),
                          style: FilledButton.styleFrom(
                            foregroundColor: AppColors.accentWhite,
                            backgroundColor: AppColors.brandGreen,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.33,
                            ),
                          ),
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: const Text('Выйти из аккаунта'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: PassengerBottomBar(
          currentItem: PassengerNavigationItem.profile,
          onTrips: onTrips,
          onOrders: onOrders,
          onCreate: onCreate,
          onChats: onChats,
          onProfile: () {},
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _LogoutDialog(),
    );
    if (confirmed == true) onLogout();
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox.square(
          key: ProfileScreen.avatarKey,
          dimension: 96,
          child: ClipOval(
            child: profile.avatarBytes == null
                ? const ColoredBox(
                    color: AppColors.accentSurface,
                    child: Icon(
                      Icons.person_rounded,
                      color: Color(0xFF898A8D),
                      size: 54,
                    ),
                  )
                : Image.memory(profile.avatarBytes!, fit: BoxFit.cover),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          profile.name,
          key: ProfileScreen.nameKey,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.accentBlack,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Wrap(
          key: ProfileScreen.ratingKey,
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            const Icon(Icons.star_rounded, color: Color(0xFFF2C500), size: 16),
            const SizedBox(width: 4),
            Text(
              profile.ratingLabel,
              style: const TextStyle(
                color: AppColors.accentBlack,
                fontSize: 15,
                fontWeight: FontWeight.w400,
                height: 1.33,
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              '•',
              style: TextStyle(color: AppColors.accentBlack, fontSize: 15),
            ),
            const SizedBox(width: 4),
            Text(
              '${profile.completedTrips} поездок',
              style: const TextStyle(
                color: AppColors.accentBlack,
                fontSize: 15,
                fontWeight: FontWeight.w400,
                height: 1.33,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.badgeCount,
    this.badgeKey,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final int? badgeCount;
  final Key? badgeKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accentWhite,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.accentSurface,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: AppColors.accentBlack, size: 22),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.accentBlack,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.33,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          height: 1.33,
                        ),
                      ),
                  ],
                ),
              ),
              if (badgeCount != null && badgeCount! > 0) ...[
                Container(
                  key: badgeKey,
                  constraints: const BoxConstraints(minWidth: 20),
                  height: 20,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: AppColors.brandGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: AppColors.accentWhite,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      height: 1.33,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF898A8D)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutDialog extends StatelessWidget {
  const _LogoutDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      key: ProfileScreen.logoutDialogKey,
      backgroundColor: AppColors.accentWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Text(
              'Выйдите из аккаунта?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.accentBlack,
                fontSize: 17,
                fontWeight: FontWeight.w700,
                height: 1.29,
              ),
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          _DialogButton(
            key: ProfileScreen.logoutConfirmKey,
            label: 'Выйти',
            bold: true,
            onTap: () => Navigator.of(context).pop(true),
          ),
          const Divider(height: 1, color: AppColors.divider),
          _DialogButton(
            key: ProfileScreen.logoutCancelKey,
            label: 'Отмена',
            bold: false,
            onTap: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.label,
    required this.bold,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool bold;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: bold ? AppColors.accentBlack : AppColors.textSecondary,
                fontSize: 17,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                height: 1.29,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
