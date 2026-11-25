import 'package:flutter_application_1/UAS/model/country.dart';
import 'package:flutter_application_1/UAS/model/travel_note.dart';
import 'package:flutter_application_1/UAS/viewmodel/location_service.dart';
import 'package:flutter_application_1/UAS/viewmodel/travel_service.dart';
import 'package:flutter_application_1/UAS/viewmodel/travel_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

TravelNote _note({
  int id = 101,
  String code = 'JP',
  TravelStatus status = TravelStatus.wantToVisit,
}) {
  return TravelNote(
    id: id,
    title: 'Judul',
    destination: 'Negara',
    countryCode: code,
    description: 'Catatan',
    status: status,
    userId: 1,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocationInfo (penanganan null GPS)', () {
    test('daftar placemark kosong -> semua alamat "Tidak tersedia"', () {
      final info = LocationInfo.fromPosition(latitude: -7.25, longitude: 112.75);
      expect(info.hasAddress, isFalse);
      expect(info.street, kUnavailable);
      expect(info.city, kUnavailable);
      expect(info.fullAddress, kUnavailable);
      expect(info.countryCode, '');
    });

    test('placemark dengan semua field null tidak menyebabkan error', () {
      final info = LocationInfo.fromPosition(
        latitude: 0,
        longitude: 0,
        placemarks: [Placemark()],
      );
      expect(info.hasAddress, isFalse);
      expect(info.country, kUnavailable);
    });

    test('placemark sebagian terisi', () {
      final info = LocationInfo.fromPosition(
        latitude: -7.25,
        longitude: 112.75,
        placemarks: [
          Placemark(
            street: '  Jl. Contoh 1  ',
            subLocality: '',
            subAdministrativeArea: 'Surabaya',
            country: 'Indonesia',
            isoCountryCode: 'id',
          ),
        ],
      );
      expect(info.hasAddress, isTrue);
      expect(info.street, 'Jl. Contoh 1');
      expect(info.subLocality, kUnavailable);
      expect(info.city, 'Surabaya');
      expect(info.countryCode, 'ID');
      expect(info.fullAddress, 'Jl. Contoh 1, Surabaya, Indonesia');
    });
  });

  group('TravelNote', () {
    test('fromJson aman terhadap null dan memakai body sebagai deskripsi', () {
      final note = TravelNote.fromJson({'id': 3, 'title': null, 'body': 'Isi'});
      expect(note.id, 3);
      expect(note.title, 'Tanpa judul');
      expect(note.description, 'Isi');
      expect(note.countryCode, '');
      expect(note.status, TravelStatus.wantToVisit);
      expect(note.userId, 1);
    });

    test('toJson -> fromJson mempertahankan semua field', () {
      final original = _note(status: TravelStatus.visited).copyWith(
        photos: ['AAEC', 'AAED'],
      );
      final copy = TravelNote.fromJson(original.toJson());
      expect(copy.status, TravelStatus.visited);
      expect(copy.countryCode, 'JP');
      expect(copy.photos, ['AAEC', 'AAED']);
      expect(copy.photoBytesList.length, 2);
    });

    test('foto Base64 rusak dilewati tanpa error', () {
      final note = _note().copyWith(photos: ['###bukan-base64###', 'AAEC']);
      expect(note.photoBytesList.length, 1);
    });

    test('data lama dengan satu foto (photoBase64) tetap terbaca', () {
      final note = TravelNote.fromJson({'id': 2, 'photoBase64': 'AAEC'});
      expect(note.photos, ['AAEC']);
    });

    test('existsOnDemoServer hanya untuk id 1..100', () {
      expect(_note(id: 1).existsOnDemoServer, isTrue);
      expect(_note(id: 100).existsOnDemoServer, isTrue);
      expect(_note(id: 101).existsOnDemoServer, isFalse);
    });

    test('toServerJson tidak mengirim foto dan bisa tanpa id', () {
      final json = _note().copyWith(photos: ['AAEC']).toServerJson(
            includeId: false,
          );
      expect(json.containsKey('id'), isFalse);
      expect(json.containsKey('photos'), isFalse);
      expect(json.containsKey('photoBase64'), isFalse);
      expect(json['body'], 'Catatan');
      expect(json['countryCode'], 'JP');
    });
  });

  group('TravelStats', () {
    test('dihitung per negara dari data Travel List', () {
      final stats = TravelStats.fromNotes([
        _note(id: 1, code: 'JP'),
        _note(id: 2, code: 'JP'), // negara sama dihitung sekali
        _note(id: 3, code: 'FR', status: TravelStatus.visited),
        _note(id: 4, code: 'ID', status: TravelStatus.visited),
        _note(id: 5, code: 'ID'), // sudah dikunjungi -> tidak lagi "ingin"
      ]);
      expect(stats.totalNotes, 5);
      expect(stats.wantCountries, 1);
      expect(stats.visitedCountries, 2);
    });

    test('daftar kosong menghasilkan nol', () {
      final stats = TravelStats.fromNotes(const []);
      expect(stats.totalNotes, 0);
      expect(stats.totalCountries, 0);
    });
  });

  group('TravelViewModel (HTTP + penyimpanan lokal)', () {
    late List<String> calls;
    late TravelViewModel vm;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      calls = [];
      final client = MockClient((request) async {
        calls.add('${request.method} ${request.url.path}');
        switch (request.method) {
          case 'POST':
            return http.Response('{"id":101}', 201);
          case 'PUT':
            return http.Response('{"id":1}', 200);
          case 'DELETE':
            return http.Response('{}', 200);
          default:
            return http.Response('{"id":1,"userId":1}', 200);
        }
      });
      vm = TravelViewModel(service: TravelService(client: client));
    });

    test('pertama kali dibuka berisi contoh Holiday', () async {
      await vm.init();
      expect(vm.notes.length, 1);
      expect(vm.notes.first.title, 'Holiday');
      expect(vm.notes.first.destination, 'Japan');
      expect(vm.notes.first.countryCode, 'JP');
      expect(vm.notes.first.status, TravelStatus.wantToVisit);
      expect(vm.stats.wantCountries, 1);
    });

    test('create mengirim POST dan statistik ikut berubah', () async {
      await vm.init();
      final result = await vm.create(
        _note(id: 0, code: 'FR', status: TravelStatus.visited),
      );
      expect(result.ok, isTrue);
      expect(calls, contains('POST /posts'));
      expect(vm.notes.length, 2);
      expect(vm.notes.first.id, greaterThan(TravelNote.maxServerId));
      expect(vm.stats.visitedCountries, 1);
    });

    test('update mengirim PUT dan delete mengirim DELETE', () async {
      await vm.init();
      final holiday = vm.notes.first; // id 1 ada di server demo
      final updated = await vm.update(
        holiday.copyWith(status: TravelStatus.visited),
      );
      expect(updated.ok, isTrue);
      expect(calls, contains('PUT /posts/1'));
      expect(vm.stats.visitedCountries, 1);
      expect(vm.stats.wantCountries, 0);

      final deleted = await vm.delete(vm.notes.first);
      expect(deleted.ok, isTrue);
      expect(calls, contains('DELETE /posts/1'));
      expect(vm.notes, isEmpty);
    });

    test('refresh mengirim GET', () async {
      await vm.init();
      final result = await vm.refresh();
      expect(result.ok, isTrue);
      expect(calls, contains('GET /posts/1'));
    });

    test('data tetap ada setelah dibuka kembali (penyimpanan lokal)', () async {
      await vm.init();
      await vm.create(_note(id: 0, code: 'FR'));

      final reopened = TravelViewModel();
      await reopened.init();
      expect(reopened.notes.length, 2);
    });
  });

  group('Country', () {
    test('fromJson aman terhadap field kosong', () {
      final country = Country.fromJson({'name': 'Indonesia'});
      expect(country.name, 'Indonesia');
      expect(country.capital, 'Tidak tersedia');
      expect(country.population, 0);
      expect(country.languages, isEmpty);
      expect(country.hasCoordinates, isFalse);
    });

    test('latlng dibaca bila tersedia', () {
      final country = Country.fromJson({
        'name': 'Japan',
        'latlng': [36, 138],
      });
      expect(country.latitude, 36.0);
      expect(country.longitude, 138.0);
      expect(country.hasCoordinates, isTrue);
    });
  });
}
