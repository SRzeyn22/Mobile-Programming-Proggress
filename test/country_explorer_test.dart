import 'dart:convert';

import 'package:flutter_application_1/UAS/model/country.dart';
import 'package:flutter_application_1/UAS/model/country_filter.dart';
import 'package:flutter_application_1/UAS/model/country_format.dart';
import 'package:flutter_application_1/UAS/model/unsplash_photo.dart';
import 'package:flutter_application_1/UAS/viewmodel/unsplash_service.dart';
import 'package:flutter_test/flutter_test.dart';

Country _country(
  String name,
  String code,
  String region, {
  String capital = 'Ibu Kota',
  int population = 1000,
}) {
  return Country(
    name: name,
    alpha2Code: code,
    alpha3Code: code,
    flagEmoji: '',
    flagImage: '',
    capital: capital,
    region: region,
    subregion: 'Tidak tersedia',
    population: population,
    area: 0,
    nativeName: name,
    languages: const [],
    currencies: const [],
    timezones: const [],
    borders: const [],
    callingCodes: const [],
  );
}

Map<String, dynamic> _apiPhoto(String id, {String user = 'Jane Doe'}) => {
      'id': id,
      'urls': {
        'small': 'https://images.unsplash.com/$id?w=400&ixid=abc',
        'regular': 'https://images.unsplash.com/$id?w=1080&ixid=abc',
      },
      'user': {
        'name': user,
        'links': {'html': 'https://unsplash.com/@jane'},
      },
      'links': {
        'html': 'https://unsplash.com/photos/$id',
        'download_location': 'https://api.unsplash.com/photos/$id/download',
      },
    };

UnsplashHttpResponse _ok(List<Map<String, dynamic>> results,
        {int? remaining}) =>
    UnsplashHttpResponse(
      statusCode: 200,
      body: jsonEncode({'results': results}),
      rateLimitRemaining: remaining,
    );

class _Fake {
  final List<Uri> calls = [];
  final List<Map<String, String>> headers = [];
  int inFlight = 0;
  int maxInFlight = 0;
  Duration delay = const Duration(milliseconds: 15);
  UnsplashHttpResponse Function(Uri uri)? responder;

  Future<UnsplashHttpResponse> fetch(Uri uri, Map<String, String> h) async {
    calls.add(uri);
    headers.add(h);
    inFlight++;
    if (inFlight > maxInFlight) maxInFlight = inFlight;
    await Future<void>.delayed(delay);
    inFlight--;
    final custom = responder;
    if (custom != null) return custom(uri);
    final q = uri.queryParameters['query'] ?? 'x';
    return _ok([_apiPhoto('photo-${q.hashCode}')]);
  }
}

UnsplashService _service(
  _Fake fake, {
  UnsplashStore? store,
  String key = 'KEY',
  int budget = 45,
  int maxQueue = 40,
  DateTime Function()? clock,
}) {
  return UnsplashService(
    accessKey: key,
    fetcher: fake.fetch,
    store: store ?? MemoryUnsplashStore(),
    hourlyBudget: budget,
    maxQueue: maxQueue,
    clock: clock,
  );
}

void main() {
  final countries = [
    _country('Japan', 'JP', 'Asia', capital: 'Tokyo'),
    _country('Indonesia', 'ID', 'Asia', capital: 'Jakarta'),
    _country('France', 'FR', 'Europe', capital: 'Paris'),
    _country('Egypt', 'EG', 'Africa', capital: 'Cairo'),
    _country('Brazil', 'BR', 'Americas', capital: 'Brasilia'),
    _country('Canada', 'CA', 'Americas', capital: 'Ottawa'),
    _country('Fiji', 'FJ', 'Oceania', capital: 'Suva'),
    _country('Antarctica', 'AQ', 'Polar', capital: 'Tidak tersedia'),
  ];

  group('Filter kawasan + pencarian', () {
    test('Semua menampilkan seluruh negara', () {
      expect(filterCountries(countries).length, equals(8));
    });

    test('tiap filter hanya memuat negara dengan region yang sesuai', () {
      List<String> names(RegionFilter f) =>
          filterCountries(countries, region: f).map((c) => c.name).toList();
      expect(names(RegionFilter.asia), equals(['Japan', 'Indonesia']));
      expect(names(RegionFilter.europe), equals(['France']));
      expect(names(RegionFilter.africa), equals(['Egypt']));
      expect(names(RegionFilter.americas), equals(['Brazil', 'Canada']));
      expect(names(RegionFilter.oceania), equals(['Fiji']));
    });

    test('region di luar enam pilihan (Polar) hanya muncul di Semua', () {
      for (final f in RegionFilter.values) {
        final has = filterCountries(countries, region: f)
            .any((c) => c.name == 'Antarctica');
        expect(has, equals(f == RegionFilter.all));
      }
    });

    test('varian penulisan Amerika tetap cocok', () {
      expect(
        RegionFilter.americas.matches(_country('A', 'AA', 'North America')),
        isTrue,
      );
      expect(
        RegionFilter.americas.matches(_country('B', 'BB', 'South America')),
        isTrue,
      );
      expect(RegionFilter.americas.matches(_country('C', 'CC', 'Asia')),
          isFalse);
    });

    test('pencarian nama dan filter berjalan bersamaan', () {
      final both = filterCountries(
        countries,
        query: 'an',
        region: RegionFilter.asia,
      );
      expect(both.map((c) => c.name).toList(), equals(['Japan']));
      // "an" juga cocok dengan Canada, tetapi tersaring oleh kawasan.
      final americas = filterCountries(
        countries,
        query: 'an',
        region: RegionFilter.americas,
      );
      expect(americas.map((c) => c.name).toList(), equals(['Canada']));
    });

    test('pencarian ibu kota tetap berfungsi dan tidak peka huruf besar', () {
      final result = filterCountries(countries, query: '  PARIS ');
      expect(result.map((c) => c.name).toList(), equals(['France']));
    });

    test('kombinasi tanpa hasil mengembalikan daftar kosong', () {
      expect(
        filterCountries(countries, query: 'japan', region: RegionFilter.europe),
        isEmpty,
      );
    });
  });

  group('compactPopulation', () {
    test('format ringkas', () {
      expect(compactPopulation(0), isNull);
      expect(compactPopulation(-5), isNull);
      expect(compactPopulation(950), equals('950'));
      expect(compactPopulation(12500), equals('12,5 rb'));
      expect(compactPopulation(125700000), equals('125,7 jt'));
      expect(compactPopulation(2000000), equals('2 jt'));
      expect(compactPopulation(1400000000), equals('1,4 miliar'));
    });
  });

  group('UnsplashPhoto', () {
    test('membaca item API lengkap dengan atribusi', () {
      final photo = UnsplashPhoto.fromApi(_apiPhoto('abc'))!;
      expect(photo.id, equals('abc'));
      expect(photo.photographerName, equals('Jane Doe'));
      expect(
        photo.smallUrl,
        equals('https://images.unsplash.com/abc?w=400&ixid=abc'),
      );
      expect(
        photo.photographerLink,
        equals('https://unsplash.com/@jane?${UnsplashPhoto.utm}'),
      );
      expect(photo.unsplashLink.contains('utm_source='), isTrue);
    });

    test('menolak data tidak lengkap atau URL non-https', () {
      expect(UnsplashPhoto.fromApi(null), isNull);
      expect(UnsplashPhoto.fromApi({'id': 'x'}), isNull);
      final insecure = _apiPhoto('y');
      (insecure['urls'] as Map)['small'] = 'http://images.unsplash.com/y';
      expect(UnsplashPhoto.fromApi(insecure), isNull);
    });

    test('toJson/fromStored saling konsisten', () {
      final photo = UnsplashPhoto.fromApi(_apiPhoto('z'))!;
      final back = UnsplashPhoto.fromStored(photo.toJson());
      expect(back.id, equals('z'));
      expect(back.regularUrl, equals(photo.regularUrl));
      expect(back.downloadLocation, equals(photo.downloadLocation));
      expect(back.isUsable, isTrue);
    });
  });

  group('UnsplashService', () {
    test('tanpa Access Key tidak pernah mengirim request', () async {
      final fake = _Fake();
      final service = _service(fake, key: '');
      expect(service.isEnabled, isFalse);
      final photo = await service.request('JP', 'Japan landscape').future;
      expect(photo, isNull);
      expect(fake.calls.length, equals(0));
    });

    test('request memakai endpoint, query, dan header yang benar', () async {
      final fake = _Fake();
      final service = _service(fake);
      final photo = await service.request('jp', 'Japan landscape').future;
      expect(photo, isNotNull);
      expect(fake.calls.length, equals(1));
      final uri = fake.calls.single;
      expect(uri.host, equals('api.unsplash.com'));
      expect(uri.path, equals('/search/photos'));
      expect(uri.queryParameters['query'], equals('Japan landscape'));
      expect(uri.queryParameters['per_page'], equals('5'));
      expect(fake.headers.single['Authorization'], equals('Client-ID KEY'));
    });

    test('foto yang sudah ada di cache tidak memicu request lagi', () async {
      final fake = _Fake();
      final service = _service(fake);
      await service.request('JP', 'Japan landscape').future;
      await service.request('JP', 'Japan landscape').future;
      await service.request('jp', 'Japan landscape').future;
      expect(fake.calls.length, equals(1));
      expect(service.cachedPhoto('JP'), isNotNull);
    });

    test('cache bertahan setelah aplikasi dibuka ulang (store sama)', () async {
      final store = MemoryUnsplashStore();
      final fake1 = _Fake();
      await _service(fake1, store: store)
          .request('JP', 'Japan landscape')
          .future;
      expect(fake1.calls.length, equals(1));

      final fake2 = _Fake();
      final reopened = _service(fake2, store: store);
      final photo = await reopened.request('JP', 'Japan landscape').future;
      expect(photo, isNotNull);
      expect(fake2.calls.length, equals(0));
    });

    test('permintaan serentak untuk negara yang sama digabung', () async {
      final fake = _Fake();
      final service = _service(fake);
      final a = service.request('ID', 'Indonesia landscape');
      final b = service.request('ID', 'Indonesia landscape');
      final results = await Future.wait([a.future, b.future]);
      expect(results[0], isNotNull);
      expect(results[1], isNotNull);
      expect(fake.calls.length, equals(1));
    });

    test('maksimal 2 request berjalan bersamaan saat scroll cepat', () async {
      final fake = _Fake();
      final service = _service(fake);
      final requests = [
        for (var i = 0; i < 10; i++)
          service.request('C$i', 'Country $i landscape'),
      ];
      await Future.wait(requests.map((r) => r.future));
      expect(fake.calls.length, equals(10));
      expect(fake.maxInFlight <= 2, isTrue);
    });

    test('permintaan yang dibatalkan sebelum berjalan tidak dikirim', () async {
      final fake = _Fake();
      final service = _service(fake);
      final requests = [
        for (var i = 0; i < 8; i++) service.request('K$i', 'K$i landscape'),
      ];
      // Simulasi scroll cepat: kartu 0..5 sudah hilang sebelum giliran.
      await Future<void>.delayed(const Duration(milliseconds: 1));
      for (var i = 0; i < 6; i++) {
        requests[i].cancel();
      }
      await Future.wait(requests.map((r) => r.future));
      final sent = fake.calls.map((u) => u.queryParameters['query']).toList();
      // Hanya yang sempat berjalan (maks 2 awal) + 2 terakhir yang masih aktif.
      expect(fake.calls.length <= 4, isTrue);
      expect(sent.contains('K7 landscape'), isTrue);
      expect(sent.contains('K6 landscape'), isTrue);
    });

    test('antrean dibatasi maxQueue', () async {
      final fake = _Fake();
      final service = _service(fake, maxQueue: 3);
      final requests = [
        for (var i = 0; i < 12; i++) service.request('Q$i', 'Q$i landscape'),
      ];
      await Future.wait(requests.map((r) => r.future));
      expect(fake.calls.length < 12, isTrue);
    });

    test('kuota per jam dihormati dan tidak mengirim melebihi batas', () async {
      final fake = _Fake();
      var now = DateTime(2026, 11, 22, 10);
      final service = _service(fake, budget: 3, clock: () => now);
      for (var i = 0; i < 6; i++) {
        await service.request('B$i', 'B$i landscape').future;
      }
      expect(fake.calls.length, equals(3));

      // Satu jam kemudian kuota pulih.
      now = now.add(const Duration(hours: 1, minutes: 1));
      await service.request('B9', 'B9 landscape').future;
      expect(fake.calls.length, equals(4));
    });

    test('kuota tersimpan: aplikasi dibuka ulang tidak mereset hitungan',
        () async {
      final store = MemoryUnsplashStore();
      final now = DateTime(2026, 11, 22, 10);
      final fake1 = _Fake();
      final s1 = _service(fake1, store: store, budget: 2, clock: () => now);
      await s1.request('A1', 'A1 landscape').future;
      await s1.request('A2', 'A2 landscape').future;

      final fake2 = _Fake();
      final s2 = _service(fake2, store: store, budget: 2, clock: () => now);
      final photo = await s2.request('A3', 'A3 landscape').future;
      expect(photo, isNull);
      expect(fake2.calls.length, equals(0));
    });

    test('hasil kosong diingat dan tidak diminta ulang', () async {
      final fake = _Fake()..responder = (_) => _ok([]);
      final service = _service(fake);
      expect(await service.request('XX', 'Nowhere landscape').future, isNull);
      expect(await service.request('XX', 'Nowhere landscape').future, isNull);
      expect(fake.calls.length, equals(1));
    });

    test('error server memberi jeda, tidak langsung mengulang', () async {
      final fake = _Fake()
        ..responder = (_) =>
            const UnsplashHttpResponse(statusCode: 500, body: 'oops');
      final service = _service(fake);
      expect(await service.request('JP', 'Japan landscape').future, isNull);
      expect(await service.request('JP', 'Japan landscape').future, isNull);
      expect(fake.calls.length, equals(1));
      expect(service.cachedPhoto('JP'), isNull);
    });

    test('respons rusak (bukan JSON) tidak menyebabkan crash', () async {
      final fake = _Fake()
        ..responder = (_) =>
            const UnsplashHttpResponse(statusCode: 200, body: '<html>');
      final service = _service(fake);
      expect(await service.request('JP', 'Japan landscape').future, isNull);
    });

    test('401 mematikan service; request berikutnya tidak dikirim', () async {
      final fake = _Fake()
        ..responder = (_) =>
            const UnsplashHttpResponse(statusCode: 401, body: '{}');
      final service = _service(fake);
      await service.request('JP', 'Japan landscape').future;
      expect(service.isEnabled, isFalse);
      await service.request('ID', 'Indonesia landscape').future;
      expect(fake.calls.length, equals(1));
    });

    test('403 (rate limit) memblokir request selama satu jam', () async {
      final fake = _Fake()
        ..responder = (_) =>
            const UnsplashHttpResponse(statusCode: 403, body: 'Rate Limit');
      var now = DateTime(2026, 11, 22, 10);
      final service = _service(fake, clock: () => now);
      await service.request('JP', 'Japan landscape').future;
      await service.request('ID', 'Indonesia landscape').future;
      expect(fake.calls.length, equals(1));

      fake.responder = null;
      now = now.add(const Duration(hours: 1, minutes: 1));
      final photo = await service.request('ID', 'Indonesia landscape').future;
      expect(photo, isNotNull);
    });

    test('header sisa kuota 0 menghentikan request berikutnya', () async {
      final fake = _Fake()..responder = (_) => _ok([_apiPhoto('p')], remaining: 0);
      final service = _service(fake);
      await service.request('JP', 'Japan landscape').future;
      await service.request('ID', 'Indonesia landscape').future;
      expect(fake.calls.length, equals(1));
    });

    test('trackDownload: sekali per foto dan hanya ke api.unsplash.com',
        () async {
      final fake = _Fake();
      final service = _service(fake);
      final photo = UnsplashPhoto.fromApi(_apiPhoto('t1'))!;
      await service.trackDownload(photo);
      await service.trackDownload(photo);
      expect(fake.calls.length, equals(1));
      expect(fake.calls.single.path, equals('/photos/t1/download'));

      final evil = UnsplashPhoto(
        id: 'evil',
        smallUrl: 'https://x/y',
        regularUrl: 'https://x/y',
        photographerName: 'x',
        photographerUrl: 'https://unsplash.com/',
        photoPageUrl: 'https://unsplash.com/',
        downloadLocation: 'https://evil.example.com/steal',
      );
      await service.trackDownload(evil);
      expect(fake.calls.length, equals(1));
    });
  });
}
