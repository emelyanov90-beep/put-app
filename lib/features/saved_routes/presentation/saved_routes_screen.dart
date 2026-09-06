import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/features/profile/presentation/widgets/profile_section_scaffold.dart';
import 'package:vput/features/saved_routes/application/saved_routes_controller.dart';
import 'package:vput/features/saved_routes/domain/saved_route.dart';
import 'package:vput/features/system/presentation/system_loading_screen.dart';

/// «Сохраненные маршруты»: shortcuts into the trip search.
class SavedRoutesScreen extends ConsumerWidget {
  const SavedRoutesScreen({
    required this.onBack,
    required this.onRouteSelected,
    super.key,
  });

  static const addButtonKey = Key('saved_routes_add');
  static const originFieldKey = Key('saved_route_origin');
  static const destinationFieldKey = Key('saved_route_destination');
  static const saveButtonKey = Key('saved_route_save');

  static Key routeKey(String id) => Key('saved_route_$id');
  static Key removeKey(String id) => Key('saved_route_remove_$id');

  final VoidCallback onBack;
  final ValueChanged<SavedRoute> onRouteSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(savedRoutesProvider);

    return ProfileSectionScaffold(
      title: 'Сохраненные маршруты',
      onBack: onBack,
      footer: ProfilePrimaryAction(
        actionKey: addButtonKey,
        label: 'Добавить маршрут',
        onPressed: () => _openEditor(context, ref),
      ),
      children: [
        if (state.isLoading)
          const SizedBox(height: 240, child: SystemLoadingView())
        else ...[
          if ((state.value ?? const []).isEmpty)
            const ProfileEmptyState(
              icon: Icons.alt_route_rounded,
              title: 'Маршрутов пока нет',
              description:
                  'Сохраните часто повторяющийся маршрут, чтобы искать '
                  'поездки по нему в одно нажатие.',
            )
          else
            for (final route in state.value!) ...[
              _RouteCard(
                route: route,
                onTap: () => onRouteSelected(route),
                onRemove: () =>
                    ref.read(savedRoutesProvider.notifier).remove(route.id),
              ),
              const SizedBox(height: 10),
            ],
        ],
      ],
    );
  }

  Future<void> _openEditor(BuildContext context, WidgetRef ref) async {
    final result = await showModalBottomSheet<_RouteDraft>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _SavedRouteEditor(),
    );
    if (result == null) return;
    await ref
        .read(savedRoutesProvider.notifier)
        .add(
          title: result.title,
          origin: result.origin,
          destination: result.destination,
        );
  }
}

class _RouteCard extends StatelessWidget {
  const _RouteCard({
    required this.route,
    required this.onTap,
    required this.onRemove,
  });

  final SavedRoute route;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ProfileCard(
      padded: false,
      child: InkWell(
        key: SavedRoutesScreen.routeKey(route.id),
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Row(
            children: [
              const Icon(
                Icons.alt_route_rounded,
                size: 22,
                color: AppColors.brandGreen,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route.title,
                      style: const TextStyle(
                        color: AppColors.accentBlack,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: 1.33,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      route.routeLabel,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.38,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                key: SavedRoutesScreen.removeKey(route.id),
                onPressed: onRemove,
                tooltip: 'Удалить маршрут',
                icon: const Icon(
                  Icons.delete_outline_rounded,
                  size: 22,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RouteDraft {
  const _RouteDraft({
    required this.title,
    required this.origin,
    required this.destination,
  });

  final String title;
  final String origin;
  final String destination;
}

class _SavedRouteEditor extends StatefulWidget {
  const _SavedRouteEditor();

  @override
  State<_SavedRouteEditor> createState() => _SavedRouteEditorState();
}

class _SavedRouteEditorState extends State<_SavedRouteEditor> {
  final _title = TextEditingController();
  final _origin = TextEditingController();
  final _destination = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _origin.dispose();
    _destination.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _origin.text.trim().isNotEmpty && _destination.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Material(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Новый маршрут',
                  style: TextStyle(
                    color: AppColors.accentBlack,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 20),
                _Field(
                  fieldKey: SavedRoutesScreen.originFieldKey,
                  controller: _origin,
                  hint: 'Откуда',
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 10),
                _Field(
                  fieldKey: SavedRoutesScreen.destinationFieldKey,
                  controller: _destination,
                  hint: 'Куда',
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 10),
                _Field(
                  controller: _title,
                  hint: 'Название (необязательно)',
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 20),
                ProfilePrimaryAction(
                  actionKey: SavedRoutesScreen.saveButtonKey,
                  label: 'Сохранить',
                  onPressed: _canSave
                      ? () => Navigator.of(context).pop(
                          _RouteDraft(
                            title: _title.text,
                            origin: _origin.text,
                            destination: _destination.text,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    required this.onChanged,
    this.fieldKey,
  });

  final TextEditingController controller;
  final String hint;
  final VoidCallback onChanged;
  final Key? fieldKey;

  @override
  Widget build(BuildContext context) {
    return ProfileCard(
      child: TextField(
        key: fieldKey,
        controller: controller,
        onChanged: (_) => onChanged(),
        style: const TextStyle(
          color: AppColors.accentBlack,
          fontSize: 15,
          height: 1.33,
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          isDense: true,
          hintText: hint,
          hintStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            height: 1.33,
          ),
        ),
      ),
    );
  }
}
