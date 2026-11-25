import 'dart:async';

import 'package:flutter/material.dart';

import '../viewmodel/place_search_service.dart';
import '../widgets/app_colors.dart';
import '../widgets/state_message.dart';

/// Pencarian lokasi untuk Custom Location. Hasil dibatasi pada negara yang
/// sudah dipilih. Mengembalikan [PlaceResult] lewat Navigator.pop.
class PlaceSearchPage extends StatefulWidget {
  final String countryCode;
  final String countryName;
  const PlaceSearchPage({
    super.key,
    required this.countryCode,
    required this.countryName,
  });

  @override
  State<PlaceSearchPage> createState() => _PlaceSearchPageState();
}

class _PlaceSearchPageState extends State<PlaceSearchPage> {
  final PlaceSearchService _service = PlaceSearchService();
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  List<PlaceResult> _results = const [];
  bool _loading = false;
  String? _error;
  String _lastQuery = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String _) {
    _debounce?.cancel();
    setState(() {});
    _debounce = Timer(const Duration(milliseconds: 700), _search);
  }

  Future<void> _search() async {
    _debounce?.cancel();
    final query = _controller.text.trim();
    if (query.length < 2) {
      setState(() {
        _results = const [];
        _error = null;
        _lastQuery = '';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await _service.search(
        query,
        countryCode: widget.countryCode,
        countryName: widget.countryName,
      );
      if (!mounted || _controller.text.trim() != query) return;
      setState(() {
        _results = results;
        _lastQuery = query;
        _loading = false;
      });
    } on PlaceSearchException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Pencarian lokasi gagal. Coba lagi.';
        _loading = false;
      });
    }
  }

  /// Memakai teks yang diketik apa adanya (mis. saat offline). Hanya nama
  /// lokasi dan negara yang tersimpan; data lain ditandai tidak tersedia.
  void _useTypedName() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;
    Navigator.pop(
      context,
      PlaceResult(
        name: name,
        countryCode: widget.countryCode,
        country: widget.countryName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final typed = _controller.text.trim();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cari Lokasi',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _controller,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: _onChanged,
                onSubmitted: (_) => _search(),
                decoration: InputDecoration(
                  hintText: 'Cari kota, tempat, atau alamat di '
                      '${widget.countryName}',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: typed.isNotEmpty
                      ? IconButton(
                          tooltip: 'Hapus kata kunci',
                          onPressed: () {
                            _controller.clear();
                            _onChanged('');
                          },
                          icon: const Icon(Icons.close_rounded),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            Expanded(child: _buildBody(typed)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(String typed) {
    if (_error != null) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          StateMessage(
            icon: Icons.wifi_off_rounded,
            title: 'Pencarian gagal',
            message: _error ?? '',
            buttonText: 'Coba lagi',
            onPressed: _search,
          ),
          if (typed.length >= 2) _typedTile(typed),
        ],
      );
    }
    if (typed.length < 2) {
      return const StateMessage(
        icon: Icons.travel_explore_rounded,
        title: 'Cari lokasi tujuan',
        message: 'Ketik minimal 2 huruf, mis. nama kota atau tempat wisata.',
      );
    }
    if (!_loading && _lastQuery == typed && _results.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const StateMessage(
            icon: Icons.search_off_rounded,
            title: 'Lokasi tidak ditemukan',
            message: 'Coba kata kunci lain, atau gunakan teks yang Anda ketik.',
          ),
          _typedTile(typed),
        ],
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        for (final place in _results)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: cardDecoration(radius: 14),
            child: ListTile(
              onTap: () => Navigator.pop(context, place),
              leading: const Icon(Icons.place_outlined, color: kOcean),
              title: Text(
                place.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: kDeepTeal,
                  fontWeight: FontWeight.w700,
                ),
              ),
              subtitle: Text(
                place.summary.isEmpty ? 'Detail tidak tersedia' : place.summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        if (_results.isNotEmpty) _typedTile(typed),
      ],
    );
  }

  Widget _typedTile(String typed) {
    return ListTile(
      onTap: _useTypedName,
      leading: const Icon(Icons.edit_location_alt_outlined, color: kOcean),
      title: Text('Gunakan "$typed"'),
      subtitle: const Text('Simpan nama ini tanpa data hasil pencarian'),
    );
  }
}
