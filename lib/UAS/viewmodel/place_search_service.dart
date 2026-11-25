import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;

import '../model/travel_note.dart';

/// Hasil pencarian lokasi untuk Custom Location.
class PlaceResult {
  final String name;
  final String? city;
  final String? province;
  final String? address;
  final String countryCode;
  final String country;
  final double? latitude;
  final double? longitude;

  const PlaceResult({
    required this.name,
    required this.countryCode,
    required this.country,
    this.city,
    this.province,
    this.address,
    this.latitude,
    this.longitude,
  });

  /// Ringkasan satu baris untuk daftar hasil.
  String get summary {
    final parts = <String>[
      ?city,
      ?province,
      if (country.isNotEmpty) country,
    ];
    return parts.join(', ');
  }

  NoteLocation toNoteLocation() => NoteLocation(
        method: LocationMethod.custom,
        country: country,
        countryCode: countryCode,
        placeName: name,
        city: city,
        province: province,
        address: address,
        latitude: latitude,
        longitude: longitude,
      );
}

class PlaceSearchException implements Exception {
  final String message;
  const PlaceSearchException(this.message);

  @override
  String toString() => message;
}

/// Pencarian lokasi manual (tanpa GPS). Sumber utama: OpenStreetMap Nominatim
/// lewat paket `http` yang sudah ada. Bila gagal di Android/iOS, dicoba
/// geocoding perangkat (`geocoding`).
class PlaceSearchService {
  PlaceSearchService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 10);

  /// Mencari [query]. Bila [countryCode] diisi, hasil dibatasi pada negara itu.
  Future<List<PlaceResult>> search(
    String query, {
    String countryCode = '',
    String countryName = '',
  }) async {
    final text = query.trim();
    if (text.length < 2) return const [];

    try {
      return await _searchNominatim(text, countryCode);
    } catch (_) {
      if (kIsWeb) {
        throw const PlaceSearchException(
          'Pencarian lokasi gagal. Periksa koneksi internet lalu coba lagi.',
        );
      }
    }

    // Cadangan: geocoding perangkat.
    try {
      final fallbackQuery =
          countryName.isEmpty ? text : '$text, $countryName';
      final locations =
          await locationFromAddress(fallbackQuery).timeout(_timeout);
      final results = <PlaceResult>[];
      for (final loc in locations.take(5)) {
        final marks = await placemarkFromCoordinates(
          loc.latitude,
          loc.longitude,
        ).timeout(_timeout);
        final place = marks.isEmpty ? null : marks.first;
        final code = (place?.isoCountryCode ?? '').toUpperCase();
        if (countryCode.isNotEmpty && code.isNotEmpty && code != countryCode) {
          continue;
        }
        results.add(
          PlaceResult(
            name: text,
            countryCode: code,
            country: _clean(place?.country) ?? countryName,
            city: _clean(place?.subAdministrativeArea) ??
                _clean(place?.locality),
            province: _clean(place?.administrativeArea),
            address: _joinAddress([
              place?.street,
              place?.subLocality,
              place?.locality,
              place?.administrativeArea,
              place?.country,
            ]),
            latitude: loc.latitude,
            longitude: loc.longitude,
          ),
        );
      }
      return results;
    } catch (_) {
      throw const PlaceSearchException(
        'Pencarian lokasi gagal. Periksa koneksi internet lalu coba lagi.',
      );
    }
  }

  Future<List<PlaceResult>> _searchNominatim(
    String query,
    String countryCode,
  ) async {
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': query,
      'format': 'jsonv2',
      'addressdetails': '1',
      'limit': '8',
      'accept-language': 'id',
      if (countryCode.isNotEmpty) 'countrycodes': countryCode.toLowerCase(),
    });
    final response = await _client.get(
      uri,
      headers: const {'Accept': 'application/json'},
    ).timeout(_timeout);
    if (response.statusCode != 200) {
      throw PlaceSearchException('HTTP ${response.statusCode}');
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! List) return const [];

    final results = <PlaceResult>[];
    for (final item in decoded) {
      if (item is! Map) continue;
      final address = item['address'];
      final addr = address is Map ? address : const {};
      String? pick(List<String> keys) {
        for (final key in keys) {
          final value = _clean(addr[key]?.toString());
          if (value != null) return value;
        }
        return null;
      }

      final displayName = _clean(item['display_name']?.toString());
      final name = _clean(item['name']?.toString()) ??
          displayName?.split(',').first.trim() ??
          '';
      if (name.isEmpty) continue;

      results.add(
        PlaceResult(
          name: name,
          countryCode: (addr['country_code']?.toString() ?? '').toUpperCase(),
          country: pick(['country']) ?? '',
          city: pick([
            'city',
            'town',
            'municipality',
            'county',
            'regency',
            'village',
          ]),
          province: pick(['state', 'province', 'region', 'state_district']),
          address: displayName,
          latitude: double.tryParse('${item['lat']}'),
          longitude: double.tryParse('${item['lon']}'),
        ),
      );
    }
    return results;
  }

  static String? _clean(String? value) {
    final trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  static String? _joinAddress(List<String?> parts) {
    final cleaned = <String>{
      for (final part in parts)
        if (_clean(part) != null) _clean(part)!,
    };
    return cleaned.isEmpty ? null : cleaned.join(', ');
  }
}
