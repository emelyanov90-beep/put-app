import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocationPromptController extends Notifier<bool> {
  @override
  bool build() => false;

  void markHandled() => state = true;
}

final locationPromptHandledProvider =
    NotifierProvider<LocationPromptController, bool>(
      LocationPromptController.new,
    );
