import '../api/buyer_api.dart';

/// One entry from the PSGC address API: a province, city/municipality or
/// barangay. Same shape the rider app uses.
class PhPlace {
  const PhPlace({required this.code, required this.name, this.type});

  final String code;
  final String name;
  final String? type;

  /// The proxy tags cities "City" and municipalities "Mun".
  bool get isCity => (type ?? '').toLowerCase() == 'city';

  static PhPlace? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final code = raw['code']?.toString().trim() ?? '';
    final name = raw['name']?.toString().trim() ?? '';
    if (code.isEmpty || name.isEmpty) return null;
    return PhPlace(code: code, name: name, type: raw['type']?.toString());
  }
}

/// Reads the `/api/address/*` PSGC proxy — the same endpoints the rider and
/// seller registration forms use — so the buyer gets every province, city and
/// barangay instead of a typed-in guess.
///
/// Results are cached for the life of the app; the proxy itself caches for a
/// day, so a province list is fetched once.
class PhAddressApi {
  PhAddressApi._();

  static final PhAddressApi instance = PhAddressApi._();

  final Map<String, List<PhPlace>> _cache = {};

  Future<List<PhPlace>> provinces() => _places('address/provinces');

  Future<List<PhPlace>> cities(String provinceCode) =>
      _places('address/provinces/$provinceCode/cities-municipalities');

  Future<List<PhPlace>> barangays(PhPlace city) => _places(
    'address/${city.isCity ? 'cities' : 'municipalities'}/${city.code}/barangays',
  );

  Future<List<PhPlace>> _places(String path) async {
    final cached = _cache[path];
    if (cached != null) return cached;

    final raw = await BuyerApi.instance.getList(path);
    final places = <PhPlace>[];
    for (final item in raw) {
      final place = PhPlace.fromJson(item);
      if (place != null) places.add(place);
    }
    if (places.isEmpty) {
      throw const BuyerApiException(
        'The address service returned no options. Please try again.',
      );
    }

    places.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return _cache[path] = places;
  }
}
