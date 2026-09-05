import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vput/app/theme/app_colors.dart';
import 'package:vput/features/city/domain/city_option.dart';

class CitySelectionScreen extends StatefulWidget {
  const CitySelectionScreen({
    required this.cities,
    required this.onContinue,
    super.key,
  });

  static const headerKey = Key('city_selection_header');
  static const searchBarKey = Key('city_selection_search_bar');
  static const searchFieldKey = Key('city_selection_search');
  static const clearSearchKey = Key('city_selection_clear');
  static const resultsPanelKey = Key('city_selection_results');
  static const continueButtonKey = Key('city_selection_continue');

  static Key cityKey(String id) => ValueKey('city_selection_city_$id');

  final List<CityOption> cities;
  final ValueChanged<CityOption> onContinue;

  @override
  State<CitySelectionScreen> createState() => _CitySelectionScreenState();
}

class _CitySelectionScreenState extends State<CitySelectionScreen> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  CityOption? _selectedCity;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchFocusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _searchFocusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) setState(() {});
  }

  void _handleQueryChanged(String value) {
    setState(() {
      _query = value;
      _selectedCity = null;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _query = '';
      _selectedCity = null;
    });
    _searchFocusNode.requestFocus();
  }

  void _selectCity(CityOption city) {
    _searchController.text = city.name;
    _searchController.selection = TextSelection.collapsed(
      offset: city.name.length,
    );
    _searchFocusNode.unfocus();
    setState(() {
      _query = city.name;
      _selectedCity = city;
    });
  }

  List<CityOption> get _filteredCities {
    final normalizedQuery = _query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) return widget.cities;
    return widget.cities
        .where((city) => city.name.toLowerCase().contains(normalizedQuery))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    const overlayStyle = SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemStatusBarContrastEnforced: false,
      systemNavigationBarColor: AppColors.accentWhite,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: AppColors.accentWhite,
      systemNavigationBarContrastEnforced: false,
    );

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: overlayStyle,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AppColors.background,
        body: LayoutBuilder(
          builder: (context, constraints) {
            const referenceWidth = 375.0;
            final scale = (constraints.maxWidth / referenceWidth)
                .clamp(0.85, 1.15)
                .toDouble();

            return Column(
              children: [
                _CityHeader(scale: scale),
                Expanded(
                  child: _CityBody(
                    scale: scale,
                    searchController: _searchController,
                    searchFocusNode: _searchFocusNode,
                    query: _query,
                    selectedCity: _selectedCity,
                    filteredCities: _filteredCities,
                    onQueryChanged: _handleQueryChanged,
                    onSearchTap: () {
                      if (_selectedCity != null) {
                        setState(() => _selectedCity = null);
                      }
                    },
                    onClear: _clearSearch,
                    onCitySelected: _selectCity,
                    onContinue: _selectedCity == null
                        ? null
                        : () => widget.onContinue(_selectedCity!),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CityHeader extends StatelessWidget {
  const _CityHeader({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: CitySelectionScreen.headerKey,
      width: double.infinity,
      height: 124 * scale,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      padding: EdgeInsets.only(top: 54 * scale, bottom: 12 * scale),
      child: SizedBox(
        height: 48 * scale,
        child: Center(
          child: Text(
            'Выберите ваш город',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.accentBlack,
              fontSize: 20 * scale,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ),
      ),
    );
  }
}

class _CityBody extends StatelessWidget {
  const _CityBody({
    required this.scale,
    required this.searchController,
    required this.searchFocusNode,
    required this.query,
    required this.selectedCity,
    required this.filteredCities,
    required this.onQueryChanged,
    required this.onSearchTap,
    required this.onClear,
    required this.onCitySelected,
    required this.onContinue,
  });

  final double scale;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final String query;
  final CityOption? selectedCity;
  final List<CityOption> filteredCities;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onSearchTap;
  final VoidCallback onClear;
  final ValueChanged<CityOption> onCitySelected;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16 * scale),
          child: SizedBox(
            height: 40 * scale,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Поездки доступны в выбранном городе и его окрестностях',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15 * scale,
                  fontWeight: FontWeight.w400,
                  height: 1.33,
                ),
              ),
            ),
          ),
        ),
        SizedBox(height: 24 * scale),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16 * scale),
          child: _CitySearchField(
            scale: scale,
            controller: searchController,
            focusNode: searchFocusNode,
            query: query,
            selected: selectedCity != null,
            onChanged: onQueryChanged,
            onTap: onSearchTap,
            onClear: onClear,
          ),
        ),
        if (selectedCity == null) ...[
          SizedBox(height: 24 * scale),
          Expanded(
            child: _CityResultsPanel(
              scale: scale,
              cities: filteredCities,
              onCitySelected: onCitySelected,
            ),
          ),
        ] else
          Expanded(
            child: _ContinueArea(scale: scale, onContinue: onContinue!),
          ),
      ],
    );
  }
}

class _CitySearchField extends StatelessWidget {
  const _CitySearchField({
    required this.scale,
    required this.controller,
    required this.focusNode,
    required this.query,
    required this.selected,
    required this.onChanged,
    required this.onTap,
    required this.onClear,
  });

  final double scale;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String query;
  final bool selected;
  final ValueChanged<String> onChanged;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final focused = focusNode.hasFocus;
    final accentColor = focused ? AppColors.brandGreen : AppColors.divider;
    final textColor = selected || focused
        ? AppColors.accentBlack
        : AppColors.textSecondary;

    return Container(
      key: CitySelectionScreen.searchBarKey,
      height: 36 * scale,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: accentColor)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 8 * scale),
      child: Row(
        children: [
          Icon(
            Icons.search_rounded,
            size: 20 * scale,
            color: focused ? AppColors.brandGreen : AppColors.textSecondary,
          ),
          SizedBox(width: 8 * scale),
          Expanded(
            child: TextField(
              key: CitySelectionScreen.searchFieldKey,
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              onTap: onTap,
              onSubmitted: (_) => focusNode.unfocus(),
              textInputAction: TextInputAction.search,
              cursorColor: AppColors.brandGreen,
              style: TextStyle(
                color: textColor,
                fontSize: 15 * scale,
                fontWeight: FontWeight.w400,
                height: 1.33,
              ),
              decoration: InputDecoration.collapsed(
                hintText: 'Поиск города...',
                hintStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15 * scale,
                  fontWeight: FontWeight.w400,
                  height: 1.33,
                ),
              ),
            ),
          ),
          if (focused && query.isNotEmpty)
            IconButton(
              key: CitySelectionScreen.clearSearchKey,
              onPressed: onClear,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints.tight(Size.square(18 * scale)),
              icon: Icon(
                Icons.cancel,
                size: 18 * scale,
                color: AppColors.accentBlack,
              ),
            ),
        ],
      ),
    );
  }
}

class _CityResultsPanel extends StatelessWidget {
  const _CityResultsPanel({
    required this.scale,
    required this.cities,
    required this.onCitySelected,
  });

  final double scale;
  final List<CityOption> cities;
  final ValueChanged<CityOption> onCitySelected;

  @override
  Widget build(BuildContext context) {
    final groups = <String, List<CityOption>>{};
    final nameCounts = <String, int>{};
    for (final city in cities) {
      final letter = city.name.substring(0, 1).toUpperCase();
      groups.putIfAbsent(letter, () => []).add(city);
      nameCounts.update(city.name, (count) => count + 1, ifAbsent: () => 1);
    }

    return Container(
      key: CitySelectionScreen.resultsPanelKey,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.accentWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16 * scale),
      clipBehavior: Clip.antiAlias,
      child: groups.isEmpty
          ? _EmptyCities(scale: scale)
          : ListView.builder(
              padding: EdgeInsets.zero,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final entry = groups.entries.elementAt(index);
                return _CityGroup(
                  scale: scale,
                  letter: entry.key,
                  cities: entry.value,
                  nameCounts: nameCounts,
                  onCitySelected: onCitySelected,
                );
              },
            ),
    );
  }
}

class _CityGroup extends StatelessWidget {
  const _CityGroup({
    required this.scale,
    required this.letter,
    required this.cities,
    required this.nameCounts,
    required this.onCitySelected,
  });

  final double scale;
  final String letter;
  final List<CityOption> cities;
  final Map<String, int> nameCounts;
  final ValueChanged<CityOption> onCitySelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      padding: EdgeInsets.symmetric(vertical: 16 * scale),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(minWidth: 32 * scale),
            padding: EdgeInsets.symmetric(
              horizontal: 12 * scale,
              vertical: 4 * scale,
            ),
            decoration: BoxDecoration(
              color: AppColors.accentSurface,
              borderRadius: BorderRadius.circular(12 * scale),
            ),
            child: Text(
              letter,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.accentBlack,
                fontSize: 13 * scale,
                fontWeight: FontWeight.w600,
                height: 1.38,
              ),
            ),
          ),
          SizedBox(height: 16 * scale),
          for (var index = 0; index < cities.length; index++)
            _CityRow(
              scale: scale,
              city: cities[index],
              showRegion: (nameCounts[cities[index].name] ?? 0) > 1,
              includeBottomSpacing: index != cities.length - 1,
              onTap: () => onCitySelected(cities[index]),
            ),
        ],
      ),
    );
  }
}

class _CityRow extends StatelessWidget {
  const _CityRow({
    required this.scale,
    required this.city,
    required this.showRegion,
    required this.includeBottomSpacing,
    required this.onTap,
  });

  final double scale;
  final CityOption city;
  final bool showRegion;
  final bool includeBottomSpacing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: showRegion ? '${city.name}, ${city.region}' : city.name,
      child: InkWell(
        key: CitySelectionScreen.cityKey(city.id),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: includeBottomSpacing ? 16 * scale : 0,
          ),
          child: SizedBox(
            width: double.infinity,
            height: 22 * scale,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text.rich(
                  TextSpan(
                    style: TextStyle(
                      color: AppColors.accentBlack,
                      fontSize: 17 * scale,
                      fontWeight: FontWeight.w400,
                      height: 1.29,
                    ),
                    children: [
                      TextSpan(text: city.name),
                      if (showRegion)
                        TextSpan(
                          text: ' · ${city.region}',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13 * scale,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyCities extends StatelessWidget {
  const _EmptyCities({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24 * scale),
        child: Text(
          'Моего города нет в списке',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15 * scale,
            fontWeight: FontWeight.w600,
            height: 1.33,
          ),
        ),
      ),
    );
  }
}

class _ContinueArea extends StatelessWidget {
  const _ContinueArea({required this.scale, required this.onContinue});

  final double scale;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Stack(
      children: [
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00FFFFFF), AppColors.accentWhite],
                stops: [0.55, 1],
              ),
            ),
          ),
        ),
        Positioned(
          left: 16 * scale,
          right: 16 * scale,
          bottom: bottomInset + 8 * scale,
          height: 48 * scale,
          child: FilledButton(
            key: CitySelectionScreen.continueButtonKey,
            onPressed: onContinue,
            style: FilledButton.styleFrom(
              foregroundColor: AppColors.accentWhite,
              backgroundColor: AppColors.brandGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12 * scale),
              ),
              textStyle: TextStyle(
                fontSize: 15 * scale,
                fontWeight: FontWeight.w600,
                height: 1.33,
              ),
            ),
            child: const Text('Далее'),
          ),
        ),
      ],
    );
  }
}
