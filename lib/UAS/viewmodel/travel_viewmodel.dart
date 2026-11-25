import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/travel_note.dart';
import 'travel_service.dart';

/// Hasil sebuah operasi, siap ditampilkan sebagai SnackBar.
class TravelResult {
  final bool ok;
  final String message;
  const TravelResult(this.ok, this.message);
}

/// Statistik perjalanan, dihitung dari data Travel List.
///
/// - [visitedCountries]: negara berbeda yang punya catatan "Sudah Dikunjungi".
/// - [wantCountries]: negara berbeda berstatus "Ingin Dikunjungi" yang belum
///   pernah ditandai dikunjungi.
class TravelStats {
  final int totalNotes;
  final int wantCountries;
  final int visitedCountries;

  const TravelStats({
    required this.totalNotes,
    required this.wantCountries,
    required this.visitedCountries,
  });

  int get totalCountries => wantCountries + visitedCountries;

  factory TravelStats.fromNotes(List<TravelNote> notes) {
    final visited = <String>{};
    final want = <String>{};
    for (final note in notes) {
      if (!note.hasCountry) continue;
      if (note.status == TravelStatus.visited) {
        visited.add(note.countryCode);
      } else {
        want.add(note.countryCode);
      }
    }
    want.removeAll(visited);
    return TravelStats(
      totalNotes: notes.length,
      wantCountries: want.length,
      visitedCountries: visited.length,
    );
  }
}

/// ViewModel My Travel List.
///
/// - Penyimpanan data: shared_preferences (di perangkat, bertahan setelah
///   aplikasi ditutup).
/// - REST (Modul XIII): setiap tambah/ubah/hapus mengirim POST/PUT/DELETE ke
///   JSONPlaceholder dan memeriksa responsnya; refresh mengirim GET.
///   JSONPlaceholder tidak menyimpan perubahan, sehingga data permanen
///   hanya ada di perangkat ini.
class TravelViewModel extends ChangeNotifier {
  TravelViewModel({TravelService? service})
      : _service = service ?? TravelService();

  static final TravelViewModel instance = TravelViewModel();

  static const String storageKey = 'travel_notes_v1';

  /// Contoh data awal agar halaman tidak kosong saat pertama dibuka.
  static TravelNote sampleHoliday() => const TravelNote(
        id: 1,
        title: 'Holiday',
        destination: 'Japan',
        countryCode: 'JP',
        description: 'Ingin mengunjungi Tokyo dan Kyoto.',
        status: TravelStatus.wantToVisit,
        userId: TravelService.demoUserId,
      );

  final TravelService _service;

  List<TravelNote> _notes = const [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _storageWarning;
  Future<void>? _initFuture;

  List<TravelNote> get notes => List<TravelNote>.unmodifiable(_notes);
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get storageWarning => _storageWarning;
  TravelStats get stats => TravelStats.fromNotes(_notes);

  // ------------------------------------------------------------- LOAD
  Future<void> init() => _initFuture ??= _init();

  Future<void> _init() async {
    try {
      final stored = await _readStore();
      if (stored == null) {
        // Pertama kali dibuka: isi contoh daftar "Holiday".
        _notes = [sampleHoliday()];
        await _writeStore();
      } else {
        _notes = stored;
      }
      _storageWarning = null;
    } catch (_) {
      _notes = [sampleHoliday()];
      _storageWarning =
          'Penyimpanan perangkat tidak dapat dibaca. Data hanya berlaku selama aplikasi terbuka.';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<List<TravelNote>?> _readStore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! List) return null;
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(TravelNote.fromJson)
        .toList();
  }

  Future<void> _writeStore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(
      storageKey,
      jsonEncode(_notes.map((note) => note.toJson()).toList()),
    );
    if (!saved) {
      throw const TravelException('Gagal menyimpan data di perangkat.');
    }
  }

  // ------------------------------------------------------------- READ
  /// READ: memuat ulang dari penyimpanan perangkat dan mengirim
  /// GET /posts/{id} ke server demo.
  Future<TravelResult> refresh() async {
    try {
      final stored = await _readStore();
      if (stored != null) _notes = stored;
    } catch (_) {
      // Tetap memakai data di memori.
    }
    notifyListeners();

    final target = _notes.firstWhere(
      (note) => note.existsOnDemoServer,
      orElse: sampleHoliday,
    );
    try {
      await _service.fetchPost(target.id);
      return TravelResult(
        true,
        'Data dimuat ulang. Server demo merespons GET /posts/${target.id} dengan sukses.',
      );
    } on TravelException catch (e) {
      return TravelResult(
        false,
        '${e.message} Data tetap ditampilkan dari penyimpanan perangkat.',
      );
    } catch (_) {
      return const TravelResult(
        false,
        'Terjadi kesalahan saat membaca dari server. Data tetap ditampilkan dari perangkat.',
      );
    }
  }

  // ----------------------------------------------------------- CREATE
  Future<TravelResult> create(TravelNote draft) async {
    _setSaving(true);
    try {
      await _service.createNote(draft); // POST
      // Server demo selalu membalas id 101, jadi id lokal dibuat unik di sini.
      final note = draft.copyWith(id: _nextLocalId());
      _notes = [note, ..._notes];
      notifyListeners();
      await _writeStore();
      return const TravelResult(
        true,
        'Catatan ditambahkan. POST ke server demo berhasil (simulasi); data disimpan di perangkat ini.',
      );
    } on TravelException catch (e) {
      return TravelResult(false, e.message);
    } catch (_) {
      return const TravelResult(false, 'Terjadi kesalahan saat menambahkan catatan.');
    } finally {
      _setSaving(false);
    }
  }

  int _nextLocalId() {
    final maxId = _notes.fold<int>(0, (m, n) => n.id > m ? n.id : m);
    return maxId < TravelNote.maxServerId
        ? TravelNote.maxServerId + 1
        : maxId + 1;
  }

  // ----------------------------------------------------------- UPDATE
  Future<TravelResult> update(TravelNote note) async {
    _setSaving(true);
    try {
      final sent = await _service.updateNote(note); // PUT (bila id <= 100)
      _notes = [for (final n in _notes) n.id == note.id ? note : n];
      notifyListeners();
      await _writeStore();
      return TravelResult(
        true,
        sent
            ? 'Catatan diperbarui. PUT ke server demo berhasil (simulasi); data disimpan di perangkat ini.'
            : 'Catatan diperbarui di perangkat (catatan ini tidak ada di server demo, tanpa PUT).',
      );
    } on TravelException catch (e) {
      return TravelResult(false, e.message);
    } catch (_) {
      return const TravelResult(false, 'Terjadi kesalahan saat memperbarui catatan.');
    } finally {
      _setSaving(false);
    }
  }

  Future<TravelResult> toggleStatus(TravelNote note) {
    final next = note.status == TravelStatus.visited
        ? TravelStatus.wantToVisit
        : TravelStatus.visited;
    return update(note.copyWith(status: next));
  }

  // ----------------------------------------------------------- DELETE
  Future<TravelResult> delete(TravelNote note) async {
    _setSaving(true);
    try {
      final sent = await _service.deleteNote(note); // DELETE (bila id <= 100)
      _notes = _notes.where((n) => n.id != note.id).toList();
      notifyListeners();
      await _writeStore();
      return TravelResult(
        true,
        sent
            ? 'Catatan dihapus. DELETE ke server demo berhasil (simulasi); dihapus dari perangkat ini.'
            : 'Catatan dihapus dari perangkat.',
      );
    } on TravelException catch (e) {
      return TravelResult(false, e.message);
    } catch (_) {
      return const TravelResult(false, 'Terjadi kesalahan saat menghapus catatan.');
    } finally {
      _setSaving(false);
    }
  }

  /// Menambahkan kembali contoh "Holiday" bila sudah dihapus.
  Future<TravelResult> restoreSample() async {
    if (_notes.any((note) => note.id == sampleHoliday().id)) {
      return const TravelResult(false, 'Contoh Holiday sudah ada di daftar.');
    }
    try {
      _notes = [sampleHoliday(), ..._notes];
      notifyListeners();
      await _writeStore();
      return const TravelResult(true, 'Contoh daftar Holiday ditambahkan.');
    } catch (_) {
      return const TravelResult(false, 'Gagal menyimpan contoh Holiday.');
    }
  }

  void _setSaving(bool value) {
    _isSaving = value;
    notifyListeners();
  }
}
