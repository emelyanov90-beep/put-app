import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vput/core/api/pocketbase_provider.dart';
import 'package:vput/core/config/app_config.dart';
import 'package:vput/features/city/data/asset_city_repository.dart';
import 'package:vput/features/city/data/pocketbase_city_repository.dart';
import 'package:vput/features/city/domain/city_option.dart';
import 'package:vput/features/city/domain/city_repository.dart';

final cityRepositoryProvider = Provider<CityRepository>((ref) {
  if (AppConfig.hasPocketBaseUrl) {
    return PocketBaseCityRepository(ref.watch(pocketBaseProvider));
  }
  return AssetCityRepository();
});

final cityCatalogProvider = FutureProvider<List<CityOption>>((ref) {
  return ref.watch(cityRepositoryProvider).getCities();
});
