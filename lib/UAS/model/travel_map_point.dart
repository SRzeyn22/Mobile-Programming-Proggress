import 'travel_note.dart';

/// Apakah pasangan [latitude]/[longitude] layak dipakai sebagai posisi marker.
///
/// Null, NaN, tak hingga, dan nilai di luar rentang
/// (latitude -90..90, longitude -180..180) ditolak.
bool isValidMapCoordinate(double? latitude, double? longitude) {
  if (latitude == null || longitude == null) return false;
  if (!latitude.isFinite || !longitude.isFinite) return false;
  return latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;
}

/// Satu catatan perjalanan yang punya koordinat valid.
///
/// Koordinat SELALU berasal dari [NoteLocation] milik catatan itu sendiri
/// (hasil GPS atau Custom Location yang tersimpan), bukan dari data negara.
class TravelMapPoint {
  final TravelNote note;
  final NoteLocation location;
  final double latitude;
  final double longitude;

  const TravelMapPoint._({
    required this.note,
    required this.location,
    required this.latitude,
    required this.longitude,
  });

  /// Null bila catatan tidak punya lokasi atau koordinatnya tidak valid.
  static TravelMapPoint? tryFromNote(TravelNote note) {
    final location = note.location;
    if (location == null) return null;
    final lat = location.latitude;
    final lng = location.longitude;
    if (lat == null || lng == null) return null;
    if (!isValidMapCoordinate(lat, lng)) return null;
    return TravelMapPoint._(
      note: note,
      location: location,
      latitude: lat,
      longitude: lng,
    );
  }

  LocationMethod get method => location.method;
  TravelStatus get status => note.status;
}

/// Beberapa catatan yang berada di titik yang (hampir) sama.
///
/// Semua catatan tetap tersimpan di [points]; grup hanya dipakai agar marker
/// tidak saling menutupi dan pengguna tetap bisa membuka tiap catatan.
class TravelMapGroup {
  /// Presisi pengelompokan: 4 desimal ≈ 11 meter.
  static const int keyPrecision = 10000;

  final List<TravelMapPoint> points;

  const TravelMapGroup(this.points);

  bool get isCluster => points.length > 1;
  int get count => points.length;

  // Posisi grup = posisi catatan pertama (koordinat asli, bukan rata-rata).
  double get latitude => points.first.latitude;
  double get longitude => points.first.longitude;

  /// "Sudah dikunjungi" mengalahkan "ingin dikunjungi" bila status campuran.
  TravelStatus get status =>
      points.any((p) => p.status == TravelStatus.visited)
          ? TravelStatus.visited
          : TravelStatus.wantToVisit;

  /// Sumber lokasi catatan pertama (dipakai marker tunggal).
  LocationMethod get method => points.first.method;
}

/// Hasil pemetaan seluruh catatan ke marker.
class TravelMapData {
  final List<TravelMapPoint> points;
  final List<TravelMapGroup> groups;
  final int totalNotes;

  const TravelMapData({
    required this.points,
    required this.groups,
    required this.totalNotes,
  });

  static const TravelMapData empty = TravelMapData(
    points: [],
    groups: [],
    totalNotes: 0,
  );

  /// Jumlah catatan dengan koordinat valid (= jumlah lokasi perjalanan).
  int get locationCount => points.length;

  /// Jumlah catatan yang TIDAK menghasilkan marker.
  int get withoutCoordinates => totalNotes - points.length;

  bool get hasPoints => points.isNotEmpty;
  bool get hasClusters => groups.any((g) => g.isCluster);

  /// Membangun data peta dari daftar catatan. Tahan terhadap catatan lama
  /// tanpa lokasi, koordinat null, dan koordinat di luar rentang.
  factory TravelMapData.fromNotes(Iterable<TravelNote> notes) {
    final points = <TravelMapPoint>[];
    var total = 0;
    for (final note in notes) {
      total++;
      final point = TravelMapPoint.tryFromNote(note);
      if (point != null) points.add(point);
    }

    final buckets = <String, List<TravelMapPoint>>{};
    for (final point in points) {
      final latKey = (point.latitude * TravelMapGroup.keyPrecision).round();
      final lngKey = (point.longitude * TravelMapGroup.keyPrecision).round();
      buckets.putIfAbsent('$latKey:$lngKey', () => []).add(point);
    }

    return TravelMapData(
      points: List.unmodifiable(points),
      groups: List.unmodifiable([
        for (final bucket in buckets.values)
          TravelMapGroup(List.unmodifiable(bucket)),
      ]),
      totalNotes: total,
    );
  }
}
