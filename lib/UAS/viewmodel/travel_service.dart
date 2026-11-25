import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../model/travel_note.dart';

/// Exception dengan pesan yang aman ditampilkan langsung ke pengguna.
class TravelException implements Exception {
  final String message;
  const TravelException(this.message);

  @override
  String toString() => message;
}

/// Layanan REST (Modul XIII) memakai JSONPlaceholder: GET, POST, PUT, DELETE.
///
/// CATATAN: JSONPlaceholder hanyalah API demonstrasi. POST/PUT/DELETE
/// mengembalikan respons sukses tetapi TIDAK menyimpan perubahan permanen.
/// Data catatan yang sebenarnya disimpan di perangkat oleh TravelViewModel.
class TravelService {
  TravelService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl = 'https://jsonplaceholder.typicode.com';
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json; charset=UTF-8',
  };
  static const Duration _timeout = Duration(seconds: 15);

  /// User demo yang dipakai untuk pembuatan catatan.
  static const int demoUserId = 1;

  // ----------------------------------------------------------------- GET
  /// GET /posts/{id}: membaca satu resource dari server demo.
  Future<Map<String, dynamic>> fetchPost(int id) async {
    final response = await _send(
      () => _client.get(Uri.parse('$_baseUrl/posts/$id'), headers: _headers),
    );
    _ensureStatus(response, const [200], 'membaca data dari server');

    final decoded = _decode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const TravelException('Format respons server tidak sesuai.');
    }
    return decoded;
  }

  // ---------------------------------------------------------------- POST
  /// POST /posts: mengembalikan id yang diberikan server (selalu 101).
  Future<int> createNote(TravelNote note) async {
    final response = await _send(
      () => _client.post(
        Uri.parse('$_baseUrl/posts'),
        headers: _headers,
        body: jsonEncode(note.toServerJson(includeId: false)),
      ),
    );
    _ensureStatus(response, const [201], 'menambahkan catatan');

    final decoded = _decode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const TravelException('Format respons server tidak sesuai.');
    }
    final id = decoded['id'];
    return id is num ? id.toInt() : 0;
  }

  // ----------------------------------------------------------------- PUT
  /// PUT /posts/{id}. Mengembalikan false bila catatan tidak punya padanan
  /// di server demo (id > 100) sehingga tidak ada request yang dikirim.
  Future<bool> updateNote(TravelNote note) async {
    if (!note.existsOnDemoServer) return false;

    final response = await _send(
      () => _client.put(
        Uri.parse('$_baseUrl/posts/${note.id}'),
        headers: _headers,
        body: jsonEncode(note.toServerJson()),
      ),
    );
    _ensureStatus(response, const [200], 'memperbarui catatan');
    return true;
  }

  // -------------------------------------------------------------- DELETE
  /// DELETE /posts/{id}. Mengembalikan false bila tidak ada request dikirim.
  Future<bool> deleteNote(TravelNote note) async {
    if (!note.existsOnDemoServer) return false;

    final response = await _send(
      () => _client.delete(
        Uri.parse('$_baseUrl/posts/${note.id}'),
        headers: _headers,
      ),
    );
    _ensureStatus(response, const [200, 204], 'menghapus catatan');
    return true;
  }

  // ------------------------------------------------------------- HELPERS
  Future<http.Response> _send(Future<http.Response> Function() request) async {
    try {
      return await request().timeout(_timeout);
    } on TimeoutException {
      throw const TravelException(
        'Server terlalu lama merespons. Coba lagi beberapa saat.',
      );
    } on http.ClientException {
      throw const TravelException(
        'Tidak dapat terhubung ke server. Periksa koneksi internet.',
      );
    }
  }

  void _ensureStatus(http.Response response, List<int> ok, String action) {
    if (!ok.contains(response.statusCode)) {
      throw TravelException('Gagal $action (HTTP ${response.statusCode}).');
    }
  }

  dynamic _decode(String body) {
    try {
      return jsonDecode(body);
    } on FormatException {
      throw const TravelException('Respons server bukan JSON yang valid.');
    }
  }
}
