import 'package:flutter_application_1/UAS/model/travel_map_point.dart';
import 'package:flutter_application_1/UAS/model/travel_note.dart';
import 'package:flutter_test/flutter_test.dart';

TravelNote _note({
  int id = 101,
  String title = 'Catatan',
  TravelStatus status = TravelStatus.wantToVisit,
  NoteLocation? location,
}) {
  return TravelNote(
    id: id,
    title: title,
    destination: 'Indonesia',
    countryCode: 'ID',
    description: 'Deskripsi',
    status: status,
    userId: 1,
    location: location,
  );
}

NoteLocation _loc({
  LocationMethod method = LocationMethod.detect,
  double? lat,
  double? lng,
  String? placeName,
}) {
  return NoteLocation(
    method: method,
    country: 'Indonesia',
    countryCode: 'ID',
    placeName: placeName,
    latitude: lat,
    longitude: lng,
  );
}

void main() {
  group('isValidMapCoordinate', () {
    test('menolak null, NaN, tak hingga, dan di luar rentang', () {
      expect(isValidMapCoordinate(null, 10), isFalse);
      expect(isValidMapCoordinate(10, null), isFalse);
      expect(isValidMapCoordinate(double.nan, 10), isFalse);
      expect(isValidMapCoordinate(10, double.infinity), isFalse);
      expect(isValidMapCoordinate(90.0001, 10), isFalse);
      expect(isValidMapCoordinate(-90.0001, 10), isFalse);
      expect(isValidMapCoordinate(10, 180.0001), isFalse);
      expect(isValidMapCoordinate(10, -180.0001), isFalse);
    });

    test('menerima nilai valid termasuk batas rentang', () {
      expect(isValidMapCoordinate(-8.4, 112.5), isTrue);
      expect(isValidMapCoordinate(90, 180), isTrue);
      expect(isValidMapCoordinate(-90, -180), isTrue);
    });
  });

  group('TravelMapData.fromNotes', () {
    test('daftar kosong menghasilkan data kosong', () {
      final data = TravelMapData.fromNotes(const []);
      expect(data.hasPoints, isFalse);
      expect(data.locationCount, equals(0));
      expect(data.withoutCoordinates, equals(0));
      expect(data.groups, isEmpty);
    });

    test('catatan GPS dengan koordinat valid menjadi marker', () {
      final data = TravelMapData.fromNotes([
        _note(location: _loc(lat: -8.3963, lng: 112.5307)),
      ]);
      expect(data.locationCount, equals(1));
      expect(data.points.first.method, equals(LocationMethod.detect));
      expect(data.points.first.latitude, equals(-8.3963));
      expect(data.points.first.longitude, equals(112.5307));
    });

    test('catatan Custom Location dengan koordinat valid menjadi marker', () {
      final data = TravelMapData.fromNotes([
        _note(
          location: _loc(
            method: LocationMethod.custom,
            lat: -7.9797,
            lng: 112.6304,
            placeName: 'Malang',
          ),
        ),
      ]);
      expect(data.locationCount, equals(1));
      expect(data.points.first.method, equals(LocationMethod.custom));
      expect(data.points.first.location.placeName, equals('Malang'));
    });

    test('beberapa lokasi berbeda menjadi beberapa marker (GPS + Custom)', () {
      final data = TravelMapData.fromNotes([
        _note(id: 1, location: _loc(lat: -8.39, lng: 112.53)),
        _note(
          id: 2,
          location: _loc(
            method: LocationMethod.custom,
            lat: 35.68,
            lng: 139.69,
          ),
        ),
        _note(
          id: 3,
          location: _loc(
            method: LocationMethod.custom,
            lat: 48.85,
            lng: 2.35,
          ),
        ),
      ]);
      expect(data.locationCount, equals(3));
      expect(data.groups.length, equals(3));
      expect(data.hasClusters, isFalse);
      expect(data.withoutCoordinates, equals(0));
    });

    test('catatan lama tanpa NoteLocation aman dan tidak menjadi marker', () {
      final data = TravelMapData.fromNotes([_note()]);
      expect(data.locationCount, equals(0));
      expect(data.totalNotes, equals(1));
      expect(data.withoutCoordinates, equals(1));
    });

    test('koordinat null tidak menjadi marker', () {
      final data = TravelMapData.fromNotes([
        _note(id: 1, location: _loc(lat: null, lng: 112.5)),
        _note(id: 2, location: _loc(lat: -8.4, lng: null)),
        _note(id: 3, location: _loc()),
      ]);
      expect(data.locationCount, equals(0));
      expect(data.withoutCoordinates, equals(3));
    });

    test('koordinat di luar rentang atau NaN dilewati tanpa error', () {
      final data = TravelMapData.fromNotes([
        _note(id: 1, location: _loc(lat: 91, lng: 10)),
        _note(id: 2, location: _loc(lat: 10, lng: -181)),
        _note(id: 3, location: _loc(lat: double.nan, lng: 10)),
        _note(id: 4, location: _loc(lat: -8.4, lng: 112.5)),
      ]);
      expect(data.locationCount, equals(1));
      expect(data.points.first.note.id, equals(4));
      expect(data.withoutCoordinates, equals(3));
    });

    test('jumlah marker mengikuti catatan, bukan negara', () {
      // Dua catatan di negara yang sama tetapi titik berbeda = dua marker.
      final data = TravelMapData.fromNotes([
        _note(id: 1, location: _loc(lat: -8.39, lng: 112.53)),
        _note(id: 2, location: _loc(lat: -6.20, lng: 106.84)),
      ]);
      expect(data.locationCount, equals(2));
      expect(data.groups.length, equals(2));
    });

    test('status ingin/sudah dikunjungi terbawa ke marker', () {
      final data = TravelMapData.fromNotes([
        _note(
          id: 1,
          status: TravelStatus.wantToVisit,
          location: _loc(lat: -8.39, lng: 112.53),
        ),
        _note(
          id: 2,
          status: TravelStatus.visited,
          location: _loc(lat: 35.68, lng: 139.69),
        ),
      ]);
      expect(data.groups[0].status, equals(TravelStatus.wantToVisit));
      expect(data.groups[1].status, equals(TravelStatus.visited));
    });
  });

  group('Marker bertumpuk', () {
    test('catatan di titik sama digabung tanpa menghilangkan catatan', () {
      final data = TravelMapData.fromNotes([
        _note(id: 1, title: 'A', location: _loc(lat: -8.3963, lng: 112.5307)),
        _note(
          id: 2,
          title: 'B',
          location: _loc(
            method: LocationMethod.custom,
            lat: -8.3963,
            lng: 112.5307,
          ),
        ),
      ]);
      expect(data.locationCount, equals(2));
      expect(data.groups.length, equals(1));
      final group = data.groups.first;
      expect(group.isCluster, isTrue);
      expect(group.count, equals(2));
      expect(group.points.map((p) => p.note.title).toList(), equals(['A', 'B']));
    });

    test('titik berjarak ±5 meter digabung, ±1 km tidak', () {
      final data = TravelMapData.fromNotes([
        _note(id: 1, location: _loc(lat: -8.39630, lng: 112.53070)),
        _note(id: 2, location: _loc(lat: -8.39632, lng: 112.53071)),
        _note(id: 3, location: _loc(lat: -8.40630, lng: 112.53070)),
      ]);
      expect(data.groups.length, equals(2));
      expect(data.groups.first.count, equals(2));
      expect(data.groups.last.count, equals(1));
    });

    test('status grup campuran: sudah dikunjungi menang', () {
      final data = TravelMapData.fromNotes([
        _note(
          id: 1,
          status: TravelStatus.wantToVisit,
          location: _loc(lat: 1, lng: 1),
        ),
        _note(
          id: 2,
          status: TravelStatus.visited,
          location: _loc(lat: 1, lng: 1),
        ),
      ]);
      expect(data.groups.single.status, equals(TravelStatus.visited));
    });
  });

  group('Pembaruan data (edit / hapus)', () {
    test('mengedit koordinat atau status memperbarui marker', () {
      final original = _note(id: 7, location: _loc(lat: -8.39, lng: 112.53));
      final before = TravelMapData.fromNotes([original]);
      expect(before.groups.single.latitude, equals(-8.39));
      expect(before.groups.single.status, equals(TravelStatus.wantToVisit));

      final edited = original.copyWith(
        status: TravelStatus.visited,
        location: _loc(
          method: LocationMethod.custom,
          lat: 35.68,
          lng: 139.69,
        ),
      );
      final after = TravelMapData.fromNotes([edited]);
      expect(after.groups.single.latitude, equals(35.68));
      expect(after.groups.single.status, equals(TravelStatus.visited));
      expect(after.groups.single.method, equals(LocationMethod.custom));
    });

    test('menghapus catatan menghilangkan marker', () {
      final a = _note(id: 1, location: _loc(lat: -8.39, lng: 112.53));
      final b = _note(id: 2, location: _loc(lat: 35.68, lng: 139.69));
      expect(TravelMapData.fromNotes([a, b]).locationCount, equals(2));
      expect(TravelMapData.fromNotes([b]).locationCount, equals(1));
      expect(TravelMapData.fromNotes(const []).locationCount, equals(0));
    });
  });

  group('Pembacaan data tersimpan', () {
    test('JSON lama tanpa field location tetap terbaca dan aman', () {
      final note = TravelNote.fromJson({
        'id': 1,
        'title': 'Lama',
        'destination': 'Japan',
        'countryCode': 'JP',
        'description': 'x',
        'status': 'wantToVisit',
      });
      expect(note.location, isNull);
      expect(TravelMapData.fromNotes([note]).locationCount, equals(0));
    });

    test('JSON dengan koordinat bertipe string tetap menjadi marker', () {
      final note = TravelNote.fromJson({
        'id': 2,
        'title': 'Baru',
        'countryCode': 'ID',
        'location': {
          'method': 'custom',
          'country': 'Indonesia',
          'countryCode': 'ID',
          'latitude': '-8.3963',
          'longitude': 112.5307,
        },
      });
      final data = TravelMapData.fromNotes([note]);
      expect(data.locationCount, equals(1));
      expect(data.points.first.latitude, equals(-8.3963));
    });

    test('JSON dengan koordinat rusak tidak menjadi marker', () {
      final note = TravelNote.fromJson({
        'id': 3,
        'title': 'Rusak',
        'location': {
          'method': 'detect',
          'latitude': 'abc',
          'longitude': null,
        },
      });
      expect(TravelMapData.fromNotes([note]).locationCount, equals(0));
    });
  });
}
