import 'package:flutter/material.dart';
import 'package:vput/app/theme/app_colors.dart';

class AddressSearchResult {
  const AddressSearchResult({
    required this.title,
    required this.subtitle,
    this.isCurrentLocation = false,
  });

  const AddressSearchResult.currentLocation()
    : title = 'Моё местоположение',
      subtitle = '',
      isCurrentLocation = true;

  final String title;
  final String subtitle;
  final bool isCurrentLocation;

  String get filterValue => title;
}

const previewAddressSuggestions = <AddressSearchResult>[
  AddressSearchResult(title: 'Московский, 56', subtitle: 'Москва'),
  AddressSearchResult(
    title: 'Улица Солнечная, дом 1',
    subtitle: 'Москва, Московская область',
  ),
  AddressSearchResult(
    title: 'Улица Лунная, дом 2',
    subtitle: 'Москва, Московская область',
  ),
  AddressSearchResult(
    title: 'Улица Солнечная, дом 5',
    subtitle: 'Москва, Московская область',
  ),
  AddressSearchResult(
    title: 'Проспект Мечты, дом 12',
    subtitle: 'Москва, Московская область',
  ),
  AddressSearchResult(
    title: 'Улица Ленина, дом 5',
    subtitle: 'Москва, Московская область',
  ),
  AddressSearchResult(
    title: 'Улица Пушкина, дом 10',
    subtitle: 'Москва, Московская область',
  ),
  AddressSearchResult(title: 'Адрес', subtitle: 'Москва, Московская область'),
  AddressSearchResult(title: 'Адрес', subtitle: 'Москва, Московская область'),
  AddressSearchResult(title: 'Адрес', subtitle: 'Москва, Московская область'),
];

class AddressSearchSheet extends StatefulWidget {
  const AddressSearchSheet({
    this.initialQuery = '',
    this.suggestions = previewAddressSuggestions,
    super.key,
  });

  static const sheetKey = Key('address_search_sheet');
  static const queryFieldKey = Key('address_search_query');
  static const currentLocationKey = Key('address_search_current_location');
  static const emptyStateKey = Key('address_search_empty');

  static Key suggestionKey(int index) => ValueKey('address_suggestion_$index');

  final String initialQuery;
  final List<AddressSearchResult> suggestions;

  @override
  State<AddressSearchSheet> createState() => _AddressSearchSheetState();
}

class _AddressSearchSheetState extends State<AddressSearchSheet> {
  late final TextEditingController _queryController;

  List<AddressSearchResult> get _filteredSuggestions {
    final query = _queryController.text.trim().toLowerCase();
    if (query.isEmpty) return widget.suggestions;

    return widget.suggestions
        .where((suggestion) {
          final title = suggestion.title.toLowerCase();
          final subtitle = suggestion.subtitle.toLowerCase();
          return title.contains(query) || subtitle.contains(query);
        })
        .toList(growable: false);
  }

  @override
  void initState() {
    super.initState();
    _queryController = TextEditingController(text: widget.initialQuery);
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _select(AddressSearchResult result) {
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final suggestions = _filteredSuggestions;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: FractionallySizedBox(
        heightFactor: .93,
        child: Material(
          key: AddressSearchSheet.sheetKey,
          color: AppColors.accentWhite,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          clipBehavior: Clip.antiAlias,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
                const SizedBox(height: 14),
                const _DragHandle(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                  child: _AddressSearchField(
                    controller: _queryController,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    children: [
                      _AddressSuggestionTile(
                        key: AddressSearchSheet.currentLocationKey,
                        result: const AddressSearchResult.currentLocation(),
                        onTap: () => _select(
                          const AddressSearchResult.currentLocation(),
                        ),
                      ),
                      if (suggestions.isEmpty)
                        const _AddressEmptyState()
                      else
                        for (final (index, suggestion) in suggestions.indexed)
                          _AddressSuggestionTile(
                            key: AddressSearchSheet.suggestionKey(index),
                            result: suggestion,
                            onTap: () => _select(suggestion),
                          ),
                    ],
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

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 43,
      height: 5,
      decoration: BoxDecoration(
        color: const Color(0xFFCACBCE),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _AddressSearchField extends StatelessWidget {
  const _AddressSearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        key: AddressSearchSheet.queryFieldKey,
        controller: controller,
        autofocus: true,
        cursorColor: AppColors.accentBlack,
        textInputAction: TextInputAction.search,
        onChanged: onChanged,
        style: const TextStyle(
          color: AppColors.accentBlack,
          fontSize: 16,
          height: 1.38,
        ),
        decoration: InputDecoration(
          hintText: 'Введите адрес',
          hintStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
            height: 1.38,
          ),
          prefixIcon: const Icon(
            Icons.location_on_rounded,
            color: AppColors.brandGreen,
            size: 28,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.brandGreen),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppColors.brandGreen),
          ),
        ),
      ),
    );
  }
}

class _AddressSuggestionTile extends StatelessWidget {
  const _AddressSuggestionTile({
    required this.result,
    required this.onTap,
    super.key,
  });

  final AddressSearchResult result;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasSubtitle = result.subtitle.isNotEmpty;

    return Material(
      color: AppColors.accentWhite,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: hasSubtitle ? 76 : 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFF898A8D),
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.accentBlack,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                      if (hasSubtitle) ...[
                        const SizedBox(height: 2),
                        Text(
                          result.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.accentBlack,
                            fontSize: 16,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ],
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

class _AddressEmptyState extends StatelessWidget {
  const _AddressEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      key: AddressSearchSheet.emptyStateKey,
      padding: EdgeInsets.fromLTRB(32, 32, 32, 0),
      child: Text(
        'Адреса не найдены',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 15,
          height: 1.33,
        ),
      ),
    );
  }
}
