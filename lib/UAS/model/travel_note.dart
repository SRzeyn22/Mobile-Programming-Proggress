import 'dart:convert';
import 'dart:typed_data';

/// Status sebuah catatan perjalanan.
enum TravelStatus {
  wantToVisit,
  visited;

  String get label => switch (this) {
        TravelStatus.wantToVisit => 'Ingin Dikunjungi',
        TravelStatus.visited => 'Sudah Dikunjungi',
      };

  static TravelStatus fromStorage(dynamic value) =>
      value == TravelStatus.visited.name
          ? TravelStatus.visited
          : TravelStatus.wantToVisit;
}

/// Cara lokasi catatan ditentukan.
enum LocationMethod {
  /// Dari GPS perangkat + reverse geocoding.
  detect,

  /// Dipilih manual oleh pengguna (pencarian lokasi).
  custom;

  String get label => switch (this) {
        LocationMethod.detect => 'Lokasi Saya (GPS)',
        LocationMethod.custom => 'Custom Location',
      };

  static LocationMethod fromStorage(dynamic value) =>
      value == LocationMethod.detect.name
          ? LocationMethod.detect
          : LocationMethod.custom;
}

/// Detail lokasi sebuah catatan. Semua field selain [method], [country] dan
/// [countryCode] boleh null; null berarti datanya memang tidak tersedia.
class NoteLocation {
  final LocationMethod method;
  final String country;
  final String countryCode;

  /// Nama lokasi yang dipilih (khusus Custom Location).
  final String? placeName;
  final String? province;
  final String? city;
  final String? address;
  final double? latitude;
  final double? longitude;

  const NoteLocation({
    required this.method,
    required this.country,
    required this.countryCode,
    this.placeName,
    this.province,
    this.city,
    this.address,
    this.latitude,
    this.longitude,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  factory NoteLocation.fromJson(Map<String, dynamic> json) {
    String? text(dynamic value) {
      final result = value?.toString().trim() ?? '';
      return result.isEmpty ? null : result;
    }

    double? number(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse('$value');
    }

    return NoteLocation(
      method: LocationMethod.fromStorage(json['method']),
      country: text(json['country']) ?? '',
      countryCode: (text(json['countryCode']) ?? '').toUpperCase(),
      placeName: text(json['placeName']),
      province: text(json['province']),
      city: text(json['city']),
      address: text(json['address']),
      latitude: number(json['latitude']),
      longitude: number(json['longitude']),
    );
  }

  Map<String, dynamic> toJson() => {
        'method': method.name,
        'country': country,
        'countryCode': countryCode,
        'placeName': placeName,
        'province': province,
        'city': city,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
      };
}

/// Model catatan perjalanan untuk fitur My Travel List (Modul XIII).
///
/// Field `title`, `description` (dikirim sebagai `body`) dan `userId`
/// sesuai resource /posts JSONPlaceholder. Field `destination`,
/// `countryCode`, `status` dikirim sebagai field tambahan (JSONPlaceholder
/// membalasnya tetapi tidak menyimpannya). Foto TIDAK dikirim ke server;
/// foto hanya disimpan di perangkat.
class TravelNote {
  final int id;
  final String title;

  /// Nama negara (dari data API Country Explorer).
  final String destination;

  /// Kode negara ISO alpha-2 (mis. "JP").
  final String countryCode;
  final String description;
  final TravelStatus status;

  /// Foto-foto perjalanan dalam Base64 (disimpan di perangkat, tidak dikirim
  /// ke server). Kosong bila belum ada foto.
  final List<String> photos;
  final int userId;

  /// Detail lokasi (Lokasi Saya / Custom Location). Null pada catatan lama
  /// yang dibuat sebelum fitur ini ada.
  final NoteLocation? location;

  const TravelNote({
    required this.id,
    required this.title,
    required this.destination,
    required this.countryCode,
    required this.description,
    required this.status,
    required this.userId,
    this.photos = const [],
    this.location,
  });

  /// JSONPlaceholder hanya memiliki resource /posts/1 sampai /posts/100.
  static const int maxServerId = 100;

  /// True jika catatan ini punya padanan resource di server demo.
  /// Catatan yang dibuat lewat POST mendapat id palsu (101) sehingga
  /// PUT/DELETE ke id tersebut tidak valid di server demo.
  bool get existsOnDemoServer => id >= 1 && id <= maxServerId;

  bool get hasCountry => countryCode.isNotEmpty;

  /// Byte semua foto; foto dengan Base64 rusak dilewati.
  List<Uint8List> get photoBytesList {
    final result = <Uint8List>[];
    for (final data in photos) {
      if (data.isEmpty) continue;
      try {
        result.add(base64Decode(data));
      } catch (_) {
        // Lewati foto rusak.
      }
    }
    return result;
  }

  /// Membaca dari penyimpanan lokal / respons server. Tahan terhadap null.
  factory TravelNote.fromJson(Map<String, dynamic> json) {
    String text(dynamic value, String fallback) {
      final result = value?.toString().trim() ?? '';
      return result.isEmpty ? fallback : result;
    }

    int number(dynamic value, int fallback) {
      if (value is num) return value.toInt();
      return int.tryParse('$value') ?? fallback;
    }

    // Mendukung data lama yang hanya punya satu foto ("photoBase64").
    final photos = <String>[];
    final rawPhotos = json['photos'];
    if (rawPhotos is List) {
      for (final item in rawPhotos) {
        if (item is String && item.isNotEmpty) photos.add(item);
      }
    }
    final legacy = json['photoBase64'];
    if (photos.isEmpty && legacy is String && legacy.isNotEmpty) {
      photos.add(legacy);
    }

    final rawLocation = json['location'];

    return TravelNote(
      id: number(json['id'], 0),
      title: text(json['title'], 'Tanpa judul'),
      destination: text(json['destination'], ''),
      countryCode: text(json['countryCode'], '').toUpperCase(),
      description: text(json['description'] ?? json['body'], ''),
      status: TravelStatus.fromStorage(json['status']),
      photos: photos,
      userId: number(json['userId'], 1),
      location: rawLocation is Map<String, dynamic>
          ? NoteLocation.fromJson(rawLocation)
          : null,
    );
  }

  /// Format penyimpanan lokal (lengkap, termasuk foto).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'destination': destination,
      'countryCode': countryCode,
      'description': description,
      'status': status.name,
      'photos': photos,
      'userId': userId,
      if (location != null) 'location': location?.toJson(),
    };
  }

  /// Format body request ke JSONPlaceholder (tanpa foto).
  Map<String, dynamic> toServerJson({bool includeId = true}) {
    return {
      if (includeId) 'id': id,
      'title': title,
      'body': description,
      'userId': userId,
      'destination': destination,
      'countryCode': countryCode,
      'status': status.name,
    };
  }

  TravelNote copyWith({
    int? id,
    String? title,
    String? destination,
    String? countryCode,
    String? description,
    TravelStatus? status,
    List<String>? photos,
    int? userId,
    NoteLocation? location,
  }) {
    return TravelNote(
      id: id ?? this.id,
      title: title ?? this.title,
      destination: destination ?? this.destination,
      countryCode: countryCode ?? this.countryCode,
      description: description ?? this.description,
      status: status ?? this.status,
      photos: photos ?? this.photos,
      userId: userId ?? this.userId,
      location: location ?? this.location,
    );
  }
}
