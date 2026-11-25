import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

const String kUnavailable = 'Tidak tersedia';

/// Jenis kegagalan pengambilan lokasi (dipakai UI untuk memilih pesan/tombol).
enum LocationFailure {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unknown,
}

class LocationException implements Exception {
  final LocationFailure failure;
  final String message;
  const LocationException(this.failure, this.message);

  @override
  String toString() => message;
}

String? _clean(String? value) {
  final trimmed = value?.trim();
  return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
}

String? _firstNonEmpty(Iterable<String?> values) {
  for (final value in values) {
    final cleaned = _clean(value);
    if (cleaned != null) return cleaned;
  }
  return null;
}

/// Hasil lokasi. Semua field teks dijamin tidak null (diganti "Tidak tersedia"
/// jika data alamat kosong), sehingga UI tidak perlu operator `!`.
class LocationInfo {
  final double latitude;
  final double longitude;
  final String street;
  final String subLocality;
  final String city;
  final String province;
  final String country;
  final String countryCode;
  final String postalCode;
  final String fullAddress;

  /// False bila reverse geocoding tidak menghasilkan data alamat sama sekali.
  final bool hasAddress;

  /// Penjelasan bila alamat tidak dapat diambil (mis. dijalankan di browser).
  final String? addressNote;

  const LocationInfo({
    required this.latitude,
    required this.longitude,
    required this.street,
    required this.subLocality,
    required this.city,
    required this.province,
    required this.country,
    required this.countryCode,
    required this.postalCode,
    required this.fullAddress,
    required this.hasAddress,
    this.addressNote,
  });

  /// Membangun [LocationInfo] dari koordinat dan hasil geocoding.
  /// Aman terhadap daftar kosong dan field null pada Placemark.
  factory LocationInfo.fromPosition({
    required double latitude,
    required double longitude,
    List<Placemark> placemarks = const [],
    String? addressNote,
  }) {
    final Placemark? place = placemarks.isEmpty ? null : placemarks.first;

    final thoroughfare = _firstNonEmpty([
      [place?.thoroughfare, place?.subThoroughfare]
          .map(_clean)
          .whereType<String>()
          .join(' '),
    ]);

    final street = _firstNonEmpty([place?.street, thoroughfare, place?.name]);
    final subLocality = _firstNonEmpty([place?.subLocality, place?.locality]);
    final city = _firstNonEmpty([place?.subAdministrativeArea, place?.locality]);
    final province = _clean(place?.administrativeArea);
    final country = _clean(place?.country);
    final postalCode = _clean(place?.postalCode);

    final parts = <String>{
      ...[street, subLocality, city, province, postalCode, country]
          .whereType<String>(),
    };

    return LocationInfo(
      latitude: latitude,
      longitude: longitude,
      street: street ?? kUnavailable,
      subLocality: subLocality ?? kUnavailable,
      city: city ?? kUnavailable,
      province: province ?? kUnavailable,
      country: country ?? kUnavailable,
      countryCode: _clean(place?.isoCountryCode)?.toUpperCase() ?? '',
      postalCode: postalCode ?? kUnavailable,
      fullAddress: parts.isEmpty ? kUnavailable : parts.join(', '),
      hasAddress: parts.isNotEmpty,
      addressNote: addressNote,
    );
  }
}

/// Layanan GPS (Modul XII): cek layanan -> cek/minta izin -> ambil posisi ->
/// reverse geocoding.
class LocationService {
  static const Duration _gpsTimeout = Duration(seconds: 20);
  static const Duration _geocodeTimeout = Duration(seconds: 10);

  Future<LocationInfo> getCurrentLocation() async {
    // 1. Layanan lokasi perangkat aktif?
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException(
        LocationFailure.serviceDisabled,
        'Layanan lokasi (GPS) perangkat tidak aktif. Aktifkan GPS lalu coba lagi.',
      );
    }

    // 2. Izin lokasi
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
        LocationFailure.permissionDeniedForever,
        'Izin lokasi ditolak permanen. Aktifkan izin lokasi untuk aplikasi ini melalui pengaturan perangkat.',
      );
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      throw const LocationException(
        LocationFailure.permissionDenied,
        'Izin lokasi ditolak. Izinkan akses lokasi agar posisi Anda dapat ditampilkan.',
      );
    }

    // 3. Koordinat
    final Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: _gpsTimeout,
        ),
      );
    } on TimeoutException {
      throw const LocationException(
        LocationFailure.timeout,
        'Pengambilan lokasi terlalu lama. Pastikan sinyal GPS baik (coba di tempat terbuka) lalu coba lagi.',
      );
    } on LocationServiceDisabledException {
      throw const LocationException(
        LocationFailure.serviceDisabled,
        'Layanan lokasi (GPS) perangkat tidak aktif. Aktifkan GPS lalu coba lagi.',
      );
    } on PermissionDeniedException {
      throw const LocationException(
        LocationFailure.permissionDenied,
        'Izin lokasi ditolak. Izinkan akses lokasi agar posisi Anda dapat ditampilkan.',
      );
    }

    // 4. Reverse geocoding. Kegagalan di tahap ini TIDAK menggagalkan seluruh
    //    proses: koordinat tetap ditampilkan dengan alamat "Tidak tersedia".
    //    Plugin geocoding tidak mendukung browser (web), jadi langkah ini
    //    dilewati dan pengguna diberi penjelasan.
    List<Placemark> placemarks = const [];
    String? addressNote;
    if (kIsWeb) {
      addressNote =
          'Reverse geocoding tidak didukung di browser. Jalankan aplikasi di '
          'perangkat Android untuk melihat alamat.';
    } else {
      try {
        placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        ).timeout(_geocodeTimeout);
      } catch (_) {
        placemarks = const [];
      }
    }

    return LocationInfo.fromPosition(
      latitude: position.latitude,
      longitude: position.longitude,
      placemarks: placemarks,
      addressNote: addressNote,
    );
  }

  Future<bool> openLocationSettings() async {
    try {
      return await Geolocator.openLocationSettings();
    } catch (_) {
      return false;
    }
  }

  Future<bool> openAppSettings() async {
    try {
      return await Geolocator.openAppSettings();
    } catch (_) {
      return false;
    }
  }
}
