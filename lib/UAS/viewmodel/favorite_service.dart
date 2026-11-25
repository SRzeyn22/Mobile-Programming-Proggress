import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Negara favorit. Disimpan di penyimpanan lokal (shared_preferences)
/// sehingga tetap ada setelah aplikasi ditutup.
class FavoriteService extends ChangeNotifier {
  FavoriteService._();

  static final FavoriteService instance = FavoriteService._();

  static const String _storageKey = 'favorite_country_codes';

  final Set<String> _codes = <String>{};
  Future<void>? _loading;

  Set<String> get codes => Set<String>.unmodifiable(_codes);
  int get count => _codes.length;

  bool isFavorite(String code) => _codes.contains(code.toUpperCase());

  Future<void> load() => _loading ??= _read();

  Future<void> _read() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_storageKey) ?? const <String>[];
      _codes
        ..clear()
        ..addAll(stored.where((code) => code.isNotEmpty));
    } catch (_) {
      // Penyimpanan tidak terbaca: mulai dari daftar kosong.
    }
    notifyListeners();
  }

  /// Menambah/menghapus favorit. Mengembalikan true bila kini menjadi favorit.
  Future<bool> toggle(String code) async {
    final upper = code.toUpperCase();
    if (upper.isEmpty) return false;
    await load();

    final added = _codes.add(upper);
    if (!added) _codes.remove(upper);
    notifyListeners();
    await _save();
    return added;
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_storageKey, _codes.toList()..sort());
    } catch (_) {
      // Gagal menyimpan: perubahan tetap berlaku selama aplikasi terbuka.
    }
  }
}
