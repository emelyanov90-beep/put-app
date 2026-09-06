import 'package:flutter/material.dart';
import 'package:vput/app/theme/app_colors.dart';

/// Back-arrow + centered title header shared by secondary screens (legal
/// documents, SMS code entry, etc).
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    required this.title,
    required this.onBack,
    this.trailing,
    super.key,
  });

  static const backButtonKey = Key('screen_header_back');

  final String title;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            height: 48,
            child: Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceMuted,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    key: backButtonKey,
                    onPressed: onBack,
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: AppColors.accentBlack,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.accentBlack,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ),
          SizedBox(width: 56, height: 48, child: trailing),
        ],
      ),
    );
  }
}

/// Decorative "•••" badge some header variants show on the trailing side.
/// It carries no behavior yet — no menu is specified for it.
class ScreenHeaderOverflowBadge extends StatelessWidget {
  const ScreenHeaderOverflowBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox.square(
        dimension: 40,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surfaceMuted,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.more_horiz_rounded,
            size: 20,
            color: AppColors.accentBlack.withValues(alpha: .6),
          ),
        ),
      ),
    );
  }
}
