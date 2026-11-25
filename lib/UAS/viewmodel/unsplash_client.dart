import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'unsplash_service.dart';

/// Access Key Unsplash, diberikan saat build/run, TIDAK ditulis di source:
///
///   flutter run --dart-define=UNSPLASH_ACCESS_KEY=xxxxxxxx
///   flutter build apk --dart-define=UNSPLASH_ACCESS_KEY=xxxxxxxx
///
/// Tanpa key, aplikasi tetap berjalan: kartu memakai bendera sebagai gambar.
const String kUnsplashAccessKey = String.fromEnvironment(
  'UNSPLASH_ACCESS_KEY',
);

class SharedPrefsUnsplashStore implements UnsplashStore {
  @override
  Future<String?> read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  @override
  Future<void> write(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }
}

Future<UnsplashHttpResponse> _httpFetch(
  Uri uri,
  Map<String, String> headers,
) async {
  final response = await http.get(uri, headers: headers);
  return UnsplashHttpResponse(
    statusCode: response.statusCode,
    body: utf8.decode(response.bodyBytes, allowMalformed: true),
    rateLimitRemaining: int.tryParse(
      response.headers['x-ratelimit-remaining'] ?? '',
    ),
  );
}

/// Satu instance service untuk seluruh aplikasi (cache & antrean dibagi).
class UnsplashClient {
  UnsplashClient._();

  static final UnsplashService instance = UnsplashService(
    accessKey: kUnsplashAccessKey,
    fetcher: _httpFetch,
    store: SharedPrefsUnsplashStore(),
  );
}
