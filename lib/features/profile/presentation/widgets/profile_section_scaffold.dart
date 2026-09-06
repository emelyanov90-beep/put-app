import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/app/widgets/screen_header.dart';

/// Shared frame of a profile section: back-arrow header and scrollable content
/// on the application background, so every section of «Профиль» reads the same.
class ProfileSectionScaffold extends StatelessWidget {
  const ProfileSectionScaffold({
    required this.title,
    required this.onBack,
    required this.children,
    this.footer,
    super.key,
  });

  final String title;
  final VoidCallback onBack;
  final List<Widget> children;

  /// Optional action pinned under the content, e.g. «Добавить карту».
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ScreenHeader(title: title, onBack: onBack),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: children,
                  ),
                ),
              ),
              if (footer != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: footer,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// White rounded card used for every group of rows inside a profile section.
class ProfileCard extends StatelessWidget {
  const ProfileCard({required this.child, this.padded = true, super.key});

  final Widget child;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padded
          ? const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
          : EdgeInsets.zero,
      decoration: BoxDecoration(
        color: AppColors.accentWhite,
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

/// Section caption above a [ProfileCard].
class ProfileSectionTitle extends StatelessWidget {
  const ProfileSectionTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.accentBlack,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          height: 1.33,
        ),
      ),
    );
  }
}

/// Centred «nothing here yet» state inside a profile section.
class ProfileEmptyState extends StatelessWidget {
  const ProfileEmptyState({
    required this.icon,
    required this.title,
    required this.description,
    super.key,
  });

  static const emptyStateKey = Key('profile_empty_state');

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: emptyStateKey,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(icon, size: 44, color: AppColors.textSecondary),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.accentBlack,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.29,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 15,
              height: 1.33,
            ),
          ),
        ],
      ),
    );
  }
}

/// Primary green action used at the bottom of a profile section.
class ProfilePrimaryAction extends StatelessWidget {
  const ProfilePrimaryAction({
    required this.label,
    required this.onPressed,
    this.actionKey,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        key: actionKey,
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandGreen,
          disabledBackgroundColor: AppColors.divider,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
