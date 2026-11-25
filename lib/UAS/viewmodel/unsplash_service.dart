import 'dart:async';
import 'dart:convert';

import '../model/unsplash_photo.dart';

/// Respons HTTP minimal agar service tidak bergantung pada package `http`.
class UnsplashHttpResponse {
  final int statusCode;
  final String body;

  /// Nilai header `X-Ratelimit-Remaining` bila ada.
  final int? rateLimitRemaining;

  const UnsplashHttpResponse({
    required this.statusCode,
    required this.body,
    this.rateLimitRemaining,
  });
}

typedef UnsplashFetcher = Future<UnsplashHttpResponse> Function(
  Uri uri,
  Map<String, String> headers,
);

/// Penyimpanan key-value (SharedPreferences pada aplikasi).
abstract class UnsplashStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

class MemoryUnsplashStore implements UnsplashStore {
  final Map<String, String> data = {};

  @override
  Future<String?> read(String key) async => data[key];

  @override
  Future<void> write(String key, String value) async => data[key] = value;
}

/// Pegangan satu permintaan foto. Panggil [cancel] saat kartu hilang dari
/// layar agar permintaan yang masih mengantre tidak dikirim.
class UnsplashRequest {
  UnsplashRequest._(this.key);

  final String key;
  final Completer<UnsplashPhoto?> _completer = Completer<UnsplashPhoto?>();
  bool _cancelled = false;
  void Function(UnsplashRequest request)? _onCancel;

  Future<UnsplashPhoto?> get future => _completer.future;
  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled || _completer.isCompleted) return;
    _cancelled = true;
    _onCancel?.call(this);
    _complete(null);
  }

  void _complete(UnsplashPhoto? photo) {
    if (!_completer.isCompleted) _completer.complete(photo);
  }
}

class _Job {
  _Job(this.key, this.query);

  final String key;
  final String query;
  final List<UnsplashRequest> requests = [];
  bool started = false;
}

/// Mengambil foto destinasi dari Unsplash secara hemat kuota.
///
/// * Hasil (URL + data fotografer) disimpan permanen -> satu negara hanya
///   memakai satu request seumur aplikasi.
/// * Permintaan yang sama digabung; maksimal [maxConcurrent] berjalan
///   bersamaan; antrean LIFO (kartu yang baru terlihat didahulukan) dan
///   dibatasi [maxQueue].
/// * Kuota dihitung per jam ([hourlyBudget], di bawah 50 milik demo) dan
///   disimpan, sehingga tidak ter-reset saat aplikasi dibuka ulang.
/// * 401 mematikan service, 403/429 memblokir 1 jam, error lain memberi jeda
///   5 menit pada negara terkait. Hasil kosong diingat 7 hari.
class UnsplashService {
  UnsplashService({
    required String accessKey,
    required this._fetcher,
    required this._store,
    DateTime Function()? clock,
    this._maxConcurrent = 2,
    this._hourlyBudget = 45,
    this._maxQueue = 40,
    Duration requestTimeout = const Duration(seconds: 15),
  })  : _accessKey = accessKey.trim(),
        _clock = clock ?? DateTime.now,
        _timeout = requestTimeout;

  static const String storeKey = 'unsplash_cache_v1';
  static const String _host = 'api.unsplash.com';
  static const Duration _window = Duration(hours: 1);
  static const Duration _missTtl = Duration(days: 7);
  static const Duration _failureCooldown = Duration(minutes: 5);

  final String _accessKey;
  final UnsplashFetcher _fetcher;
  final UnsplashStore _store;
  final DateTime Function() _clock;
  final int _maxConcurrent;
  final int _hourlyBudget;
  final int _maxQueue;
  final Duration _timeout;

  final Map<String, UnsplashPhoto> _photos = {};
  final Map<String, int> _misses = {};
  final List<int> _calls = [];
  final Set<String> _tracked = {};
  final Map<String, DateTime> _failedUntil = {};
  final Map<String, _Job> _jobs = {};
  final List<_Job> _queue = [];

  Future<void>? _loading;
  bool _loaded = false;
  int _active = 0;
  DateTime? _blockedUntil;
  bool _disabled = false;

  /// Access Key terisi (dari --dart-define=UNSPLASH_ACCESS_KEY).
  bool get hasAccessKey => _accessKey.isNotEmpty;

  /// Aktif bila key ada dan belum ditolak server (401).
  bool get isEnabled => hasAccessKey && !_disabled;

  bool get isLoaded => _loaded;

  /// Jumlah permintaan yang menunggu/berjalan (untuk pengujian).
  int get pendingCount => _queue.length + _active;

  Map<String, String> get _headers => {
        'Authorization': 'Client-ID $_accessKey',
        'Accept-Version': 'v1',
      };

  static String _norm(String key) => key.trim().toUpperCase();

  // ---------------------------------------------------------- PENYIMPANAN
  Future<void> ensureLoaded() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final raw = await _store.read(storeKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          final photos = decoded['photos'];
          if (photos is Map) {
            photos.forEach((key, value) {
              if (key is String && value is Map) {
                final photo = UnsplashPhoto.fromStored(value);
                if (photo.isUsable) _photos[_norm(key)] = photo;
              }
            });
          }
          final misses = decoded['misses'];
          if (misses is Map) {
            misses.forEach((key, value) {
              if (key is String && value is int) _misses[_norm(key)] = value;
            });
          }
          final calls = decoded['calls'];
          if (calls is List) _calls.addAll(calls.whereType<int>());
          final tracked = decoded['tracked'];
          if (tracked is List) _tracked.addAll(tracked.whereType<String>());
        }
      }
    } catch (_) {
      // Data tersimpan rusak: mulai dari kosong, aplikasi tetap jalan.
    } finally {
      _loaded = true;
    }
  }

  Future<void> _persist() async {
    try {
      await _store.write(
        storeKey,
        jsonEncode({
          'photos': {for (final e in _photos.entries) e.key: e.value.toJson()},
          'misses': _misses,
          'calls': _calls,
          'tracked': _tracked.toList(),
        }),
      );
    } catch (_) {
      // Gagal menyimpan tidak boleh mengganggu tampilan.
    }
  }

  // --------------------------------------------------------------- KUOTA
  DateTime _now() => _clock();

  int get _budgetLeft {
    final cutoff = _now().subtract(_window).millisecondsSinceEpoch;
    _calls.removeWhere((ms) => ms < cutoff);
    return _hourlyBudget - _calls.length;
  }

  bool get _isBlocked {
    final until = _blockedUntil;
    return until != null && _now().isBefore(until);
  }

  void _recordCall() => _calls.add(_now().millisecondsSinceEpoch);

  void _applyStatus(int status) {
    if (status == 401) {
      _disabled = true;
    } else if (status == 403 || status == 429) {
      _blockedUntil = _now().add(_window);
    }
  }

  bool _isMissFresh(String key) {
    final at = _misses[key];
    if (at == null) return false;
    final age = _now().millisecondsSinceEpoch - at;
    return age < _missTtl.inMilliseconds;
  }

  bool _isCoolingDown(String key) {
    final until = _failedUntil[key];
    return until != null && _now().isBefore(until);
  }

  // ------------------------------------------------------------- PERMINTAAN
  /// Foto yang sudah tersimpan (null bila belum ada / belum dimuat).
  UnsplashPhoto? cachedPhoto(String key) => _photos[_norm(key)];

  /// Meminta foto untuk [key] (kode negara) dengan kata kunci [query].
  /// Cache, hasil kosong, jeda gagal, dan kuota dicek sebelum ada request.
  UnsplashRequest request(String key, String query) {
    final k = _norm(key);
    final req = UnsplashRequest._(k);
    _start(req, k, query);
    return req;
  }

  Future<void> _start(UnsplashRequest req, String key, String query) async {
    await ensureLoaded();
    if (req.isCancelled) return;

    final hit = _photos[key];
    if (hit != null) {
      req._complete(hit);
      return;
    }
    if (!isEnabled ||
        key.isEmpty ||
        query.trim().isEmpty ||
        _isMissFresh(key) ||
        _isCoolingDown(key) ||
        _isBlocked ||
        _budgetLeft <= 0) {
      req._complete(null);
      return;
    }

    final job = _jobs[key] ?? _createJob(key, query);
    job.requests.add(req);
    req._onCancel = (r) => _onCancel(job, r);
    _pump();
  }

  _Job _createJob(String key, String query) {
    final job = _Job(key, query);
    _jobs[key] = job;
    _queue.insert(0, job); // LIFO: yang terbaru terlihat didahulukan.
    while (_queue.length > _maxQueue) {
      _dropJob(_queue.removeLast());
    }
    return job;
  }

  void _dropJob(_Job job) {
    _jobs.remove(job.key);
    for (final r in List<UnsplashRequest>.of(job.requests)) {
      r._complete(null);
    }
  }

  void _onCancel(_Job job, UnsplashRequest request) {
    job.requests.remove(request);
    if (job.requests.isEmpty && !job.started) {
      _queue.remove(job);
      _jobs.remove(job.key);
    }
  }

  void _pump() {
    while (_active < _maxConcurrent && _queue.isNotEmpty) {
      if (!isEnabled || _isBlocked || _budgetLeft <= 0) {
        for (final job in List<_Job>.of(_queue)) {
          _dropJob(job);
        }
        _queue.clear();
        return;
      }
      final job = _queue.removeAt(0);
      job.started = true;
      _active++;
      _recordCall(); // dihitung sebelum fetch agar kuota tidak terlampaui
      _run(job).whenComplete(() {
        _active--;
        _pump();
      });
    }
  }

  Future<void> _run(_Job job) async {
    UnsplashPhoto? result;
    try {
      final uri = Uri.https(_host, '/search/photos', {
        'query': job.query,
        'per_page': '5',
        'orientation': 'landscape',
        'content_filter': 'high',
      });
      final response = await _fetcher(uri, _headers).timeout(_timeout);
      final remaining = response.rateLimitRemaining;
      if (remaining != null && remaining <= 0) {
        _blockedUntil = _now().add(_window);
      }

      if (response.statusCode == 200) {
        result = _firstPhoto(response.body);
        if (result != null) {
          _photos[job.key] = result;
          _misses.remove(job.key);
        } else {
          _misses[job.key] = _now().millisecondsSinceEpoch;
        }
        await _persist();
      } else if (response.statusCode == 401 ||
          response.statusCode == 403 ||
          response.statusCode == 429) {
        _applyStatus(response.statusCode);
      } else {
        _failedUntil[job.key] = _now().add(_failureCooldown);
      }
    } catch (_) {
      _failedUntil[job.key] = _now().add(_failureCooldown);
    }

    _jobs.remove(job.key);
    for (final r in List<UnsplashRequest>.of(job.requests)) {
      r._complete(result);
    }
  }

  UnsplashPhoto? _firstPhoto(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map) return null;
    final results = decoded['results'];
    if (results is! List) return null;
    for (final item in results) {
      final photo = UnsplashPhoto.fromApi(item);
      if (photo != null) return photo;
    }
    return null;
  }

  // ------------------------------------------------------ PELACAKAN UNDUHAN
  /// Memberi tahu Unsplash bahwa [photo] dipakai (ketentuan API). Hanya ke
  /// host api.unsplash.com, maksimal sekali per foto, dan ikut hitungan kuota.
  Future<void> trackDownload(UnsplashPhoto photo) async {
    await ensureLoaded();
    final target = photo.downloadLocation;
    if (target == null || !isEnabled || _tracked.contains(photo.id)) return;
    final uri = Uri.tryParse(target);
    if (uri == null || uri.scheme != 'https' || uri.host != _host) return;
    if (_isBlocked || _budgetLeft <= 0) return;

    _tracked.add(photo.id);
    _recordCall();
    try {
      final response = await _fetcher(uri, _headers).timeout(_timeout);
      _applyStatus(response.statusCode);
    } catch (_) {
      // Pelacakan bersifat best-effort.
    }
    await _persist();
  }
}
