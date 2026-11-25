import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

import '../model/country.dart';
import 'fetchcountry.dart';

/// Sumber data negara bersama (Home, pencarian destinasi, Favorit, World Map).
/// Data diambil dari API yang sama (countries.dev) dan di-cache di memori
/// sehingga tidak diunduh berulang.
class CountryRepository {
  CountryRepository._();

  static final CountryRepository instance = CountryRepository._();

  List<Country>? _cache;
  Future<List<Country>>? _inflight;
  final Map<String, LatLng?> _geocodedPoints = {};

  /// Daftar negara dari cache (null bila belum pernah dimuat).
  List<Country>? get cached => _cache;

  Future<List<Country>> load({bool forceRefresh = false}) {
    if (!forceRefresh) {
      final cache = _cache;
      if (cache != null) return Future.value(cache);
      final running = _inflight;
      if (running != null) return running;
    }

    final future = fetchCountries().then((list) {
      _cache = list;
      return list;
    }).whenComplete(() {
      _inflight = null;
    });
    _inflight = future;
    return future;
  }

  /// Mencari negara berdasarkan kode alpha-2 di cache.
  Country? byCode(String code) {
    final list = _cache;
    if (list == null || code.isEmpty) return null;
    final upper = code.toUpperCase();
    for (final country in list) {
      if (country.alpha2Code == upper) return country;
    }
    return null;
  }

  /// Koordinat negara: dari `latlng` API; bila tidak ada, dicoba lewat
  /// geocoding perangkat (hanya Android/iOS). Null bila tidak ditemukan.
  Future<LatLng?> coordinatesOf(Country country) async {
    final lat = country.latitude;
    final lng = country.longitude;
    if (lat != null && lng != null) return LatLng(lat, lng);

    if (kIsWeb) return null; // plugin geocoding tidak mendukung web
    final key = country.alpha2Code;
    if (_geocodedPoints.containsKey(key)) return _geocodedPoints[key];

    LatLng? point;
    try {
      final results = await locationFromAddress(country.name)
          .timeout(const Duration(seconds: 8));
      if (results.isNotEmpty) {
        point = LatLng(results.first.latitude, results.first.longitude);
      }
    } catch (_) {
      point = null;
    }
    _geocodedPoints[key] = point;
    return point;
  }
}
