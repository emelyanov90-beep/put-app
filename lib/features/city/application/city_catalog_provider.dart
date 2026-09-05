import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/features/city/data/asset_city_repository.dart';
import 'package:vput/features/city/domain/city_option.dart';
import 'package:vput/features/city/domain/city_repository.dart';

final cityRepositoryProvider = Provider<CityRepository>((ref) {
  return AssetCityRepository();
});

final cityCatalogProvider = FutureProvider<List<CityOption>>((ref) {
  return ref.watch(cityRepositoryProvider).getCities();
});
