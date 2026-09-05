import 'package:vput/features/city/domain/city_option.dart';

abstract interface class CityRepository {
  Future<List<CityOption>> getCities();
}
