import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/core/storage/local_json_store.dart';
import 'package:vput/features/auth/application/preview_session_controller.dart';
import 'package:vput/features/saved_routes/domain/saved_route.dart';

/// Routes the user asked to keep. They live on the device: the backend has no
/// favourites collection, and a saved route is only a shortcut into search.
class SavedRoutesController extends AsyncNotifier<List<SavedRoute>> {
  LocalJsonStore get _store => LocalJsonStore(
    'vput_saved_routes_${ref.read(currentLocalAccountIdProvider)}',
  );

  @override
  Future<List<SavedRoute>> build() {
    ref.watch(currentLocalAccountIdProvider);
    return _load();
  }

  Future<List<SavedRoute>> _load() async {
    final rows = await _store.read();
    return rows
        .map(SavedRoute.fromJson)
        .whereType<SavedRoute>()
        .toList(growable: false);
  }

  Future<void> add({
    required String title,
    required String origin,
    required String destination,
  }) async {
    final current = state.value ?? const <SavedRoute>[];
    final route = SavedRoute(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title.trim().isEmpty
          ? '${origin.trim()} → ${destination.trim()}'
          : title.trim(),
      origin: origin.trim(),
      destination: destination.trim(),
    );
    final next = [...current, route];
    await _store.write([for (final item in next) item.toJson()]);
    state = AsyncData(next);
  }

  Future<void> remove(String id) async {
    final current = state.value ?? const <SavedRoute>[];
    final next = current
        .where((route) => route.id != id)
        .toList(growable: false);
    await _store.write([for (final item in next) item.toJson()]);
    state = AsyncData(next);
  }
}

final savedRoutesProvider =
    AsyncNotifierProvider<SavedRoutesController, List<SavedRoute>>(
      SavedRoutesController.new,
    );
