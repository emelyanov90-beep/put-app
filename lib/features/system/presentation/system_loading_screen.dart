import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vput/app/theme/app_colors.dart';

/// Centered progress indicator, sized to the Figma system "Загрузка" state.
/// Use inside an existing layout; see [SystemLoadingScreen] for the
/// full-screen variant.
class SystemLoadingView extends StatelessWidget {
  const SystemLoadingView({super.key});

  static const progressKey = Key('system_loading_progress');

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox.square(
        dimension: 48,
        child: CircularProgressIndicator(
          key: progressKey,
          color: AppColors.brandGreen,
          strokeWidth: 3,
          strokeCap: StrokeCap.round,
        ),
      ),
    );
  }
}

class SystemLoadingScreen extends StatelessWidget {
  const SystemLoadingScreen({super.key});

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

    return const AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(child: SystemLoadingView()),
      ),
    );
  }
}
