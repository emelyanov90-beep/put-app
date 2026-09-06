import 'package:flutter/material.dart';
import 'package:vput/app/theme/app_colors.dart';

/// Searchable picker of the vehicle catalogue: brands grouped by their first
/// letter, or the models of one brand.
class VehicleCatalogSheet extends StatefulWidget {
  const VehicleCatalogSheet({
    required this.title,
    required this.options,
    this.grouped = false,
    this.selected,
    super.key,
  });

  static const sheetKey = Key('vehicle_catalog_sheet');
  static const searchFieldKey = Key('vehicle_catalog_search');
  static const clearSearchKey = Key('vehicle_catalog_clear');

  static Key optionKey(String value) => Key('vehicle_catalog_option_$value');

  final String title;
  final List<String> options;

  /// `true` adds a letter header before each group, as the brand list does.
  final bool grouped;
  final String? selected;

  /// Returns the chosen value, or `null` when the sheet is dismissed.
  static Future<String?> show(
    BuildContext context, {
    required String title,
    required List<String> options,
    bool grouped = false,
    String? selected,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VehicleCatalogSheet(
        title: title,
        options: options,
        grouped: grouped,
        selected: selected,
      ),
    );
  }

  @override
  State<VehicleCatalogSheet> createState() => _VehicleCatalogSheetState();
}

class _VehicleCatalogSheetState extends State<VehicleCatalogSheet> {
  final _query = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_rebuild);
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_rebuild)
      ..dispose();
    _query.dispose();
    super.dispose();
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  /// The design filters by the beginning of the name: «i» leaves Infiniti,
  /// Isuzu and Iveco, not every brand with an «i» in it.
  List<String> get _matches {
    final query = _query.text.trim().toLowerCase();
    if (query.isEmpty) return widget.options;
    return [
      for (final option in widget.options)
        if (option.toLowerCase().startsWith(query)) option,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final matches = _matches;
    final hasQuery = _query.text.trim().isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Material(
        key: VehicleCatalogSheet.sheetKey,
        color: AppColors.accentWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * .75,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: AppColors.accentBlack,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _SearchField(
                    controller: _query,
                    focusNode: _focusNode,
                    hasQuery: hasQuery,
                    onChanged: (_) => setState(() {}),
                    onClear: () {
                      _query.clear();
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: matches.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 24,
                          ),
                          child: Text(
                            'Ничего не найдено',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 8),
                          itemCount: matches.length,
                          itemBuilder: (context, index) {
                            final option = matches[index];
                            final letter = option[0].toUpperCase();
                            final showHeader =
                                widget.grouped &&
                                (index == 0 ||
                                    matches[index - 1][0].toUpperCase() !=
                                        letter);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (showHeader) _GroupHeader(letter: letter),
                                _OptionRow(
                                  option: option,
                                  showIcon: widget.grouped,
                                  selected: option == widget.selected,
                                  onTap: () =>
                                      Navigator.of(context).pop(option),
                                ),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.hasQuery,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final active = focusNode.hasFocus || hasQuery;
    return Container(
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: active ? AppColors.brandGreen : AppColors.divider,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: 20,
            color: active ? AppColors.brandGreen : AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              key: VehicleCatalogSheet.searchFieldKey,
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              cursorColor: AppColors.accentBlack,
              style: const TextStyle(
                color: AppColors.accentBlack,
                fontSize: 15,
                height: 1.33,
              ),
              decoration: const InputDecoration(
                isDense: true,
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Марка автомобиля',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          if (hasQuery)
            SizedBox.square(
              dimension: 24,
              child: IconButton(
                key: VehicleCatalogSheet.clearSearchKey,
                onPressed: onClear,
                padding: EdgeInsets.zero,
                tooltip: 'Очистить',
                icon: const Icon(
                  Icons.cancel_rounded,
                  size: 20,
                  color: AppColors.accentBlack,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.letter});

  final String letter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        letter,
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

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.showIcon,
    required this.selected,
    required this.onTap,
  });

  final String option;
  final bool showIcon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: VehicleCatalogSheet.optionKey(option),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: [
            if (showIcon) ...[
              const Icon(
                Icons.directions_car_filled_rounded,
                size: 18,
                color: AppColors.accentBlack,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  color: AppColors.accentBlack,
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  height: 1.33,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_rounded,
                size: 18,
                color: AppColors.brandGreen,
              ),
          ],
        ),
      ),
    );
  }
}
