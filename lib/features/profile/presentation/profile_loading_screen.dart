import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/features/system/presentation/system_loading_screen.dart';

class ProfileLoadingScreen extends StatefulWidget {
  const ProfileLoadingScreen({
    required this.onCompleted,
    this.duration = const Duration(milliseconds: 650),
    super.key,
  });

  static const progressKey = SystemLoadingView.progressKey;

  final VoidCallback onCompleted;
  final Duration duration;

  @override
  State<ProfileLoadingScreen> createState() => _ProfileLoadingScreenState();
}

class _ProfileLoadingScreenState extends State<ProfileLoadingScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.duration, widget.onCompleted);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

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
