import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/features/trips/application/driver_trips_controller.dart';
import 'package:vput/features/trips/presentation/widgets/new_booking_request_dialog.dart';
import 'package:vput/features/trips/presentation/widgets/passenger_paid_dialog.dart';

/// Wraps a driver screen and tells the driver what happened on their trips:
/// a passenger asked to join, or paid for a confirmed booking. Each notice is
/// shown once.
class NewBookingRequestWatcher extends ConsumerStatefulWidget {
  const NewBookingRequestWatcher({
    required this.child,
    required this.onOpenRequest,
    this.onOpenPaidTrip,
    super.key,
  });

  final Widget child;
  final ValueChanged<PendingBookingRequest> onOpenRequest;

  /// Opens the trip a passenger has just paid for.
  final ValueChanged<PendingBookingRequest>? onOpenPaidTrip;

  @override
  ConsumerState<NewBookingRequestWatcher> createState() =>
      _NewBookingRequestWatcherState();
}

class _NewBookingRequestWatcherState
    extends ConsumerState<NewBookingRequestWatcher> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _announceRequest());
  }

  Future<void> _announceRequest() async {
    if (!mounted) return;
    if (await _announcePendingRequest()) return;
    await _announcePaidBooking();
  }

  Future<bool> _announcePendingRequest() async {
    final request = ref.read(pendingBookingRequestProvider);
    if (request == null) return false;
    if (ref.read(seenBookingRequestsProvider).contains(request.booking.id)) {
      return false;
    }
    ref.read(seenBookingRequestsProvider.notifier).markSeen(request.booking.id);

    final open = await NewBookingRequestDialog.show(context);
    if (open && mounted) widget.onOpenRequest(request);
    return true;
  }

  Future<void> _announcePaidBooking() async {
    final paid = ref.read(paidBookingNoticeProvider);
    if (paid == null || widget.onOpenPaidTrip == null) return;
    final noticeId = 'paid_${paid.booking.id}';
    if (ref.read(seenBookingRequestsProvider).contains(noticeId)) return;
    ref.read(seenBookingRequestsProvider.notifier).markSeen(noticeId);

    final open = await PassengerPaidDialog.show(context);
    if (!open || !mounted) return;
    widget.onOpenPaidTrip!(paid);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
