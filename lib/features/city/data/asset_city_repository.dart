import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:vput/features/city/domain/city_option.dart';
import 'package:vput/features/city/domain/city_repository.dart';

class AssetCityRepository implements CityRepository {
  AssetCityRepository({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  static const assetPath = 'assets/data/russian_cities.json';

  final AssetBundle _bundle;

  @override
  Future<List<CityOption>> getCities() async {
    final source = await _bundle.loadString(assetPath);
    final json = jsonDecode(source) as List<dynamic>;

    return List.unmodifiable(
      json.map((item) => CityOption.fromJson(item as Map<String, dynamic>)),
    );
  }
}
