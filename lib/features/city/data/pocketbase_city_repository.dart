import 'package:pocketbase/pocketbase.dart';
import 'package:vput/features/city/domain/city_option.dart';
import 'package:vput/features/city/domain/city_repository.dart';

class PocketBaseCityRepository implements CityRepository {
  const PocketBaseCityRepository(this._client);

  final PocketBase _client;

  @override
  Future<List<CityOption>> getCities() async {
    final result = await _client.collection('cities').getFullList(sort: 'name');
    return result
        .map(
          (record) => CityOption(
            id: record.id,
            name: record.get<String>('name'),
            region: '',
            countryCode: record.get<String>('country_code'),
            latitude: record.get<double>('latitude'),
            longitude: record.get<double>('longitude'),
          ),
        )
        .toList(growable: false);
  }
}
