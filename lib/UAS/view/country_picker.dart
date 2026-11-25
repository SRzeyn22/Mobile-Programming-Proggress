import 'package:flutter/material.dart';

import '../model/country.dart';
import '../viewmodel/country_repository.dart';
import '../widgets/app_colors.dart';
import '../widgets/country_flag.dart';
import '../widgets/state_message.dart';

/// Halaman pencarian & pemilihan negara untuk destinasi catatan.
/// Memakai sumber data yang sama dengan Home (CountryRepository / API).
/// Mengembalikan [Country] yang dipilih lewat Navigator.pop.
class CountryPickerPage extends StatefulWidget {
  final String selectedCode;
  const CountryPickerPage({super.key, this.selectedCode = ''});

  @override
  State<CountryPickerPage> createState() => _CountryPickerPageState();
}

class _CountryPickerPageState extends State<CountryPickerPage> {
  late Future<List<Country>> _future;
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = CountryRepository.instance.load();
    _controller.addListener(() {
      final next = _controller.text.trim().toLowerCase();
      if (next != _query) setState(() => _query = next);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _future = CountryRepository.instance.load(forceRefresh: true);
    });
  }

  /// Pencarian berdasarkan nama negara; nama yang diawali kata kunci
  /// ditampilkan lebih dulu.
  List<Country> _filter(List<Country> all) {
    final valid = all.where((c) => c.alpha2Code.isNotEmpty);
    if (_query.isEmpty) return valid.toList();
    final starts = <Country>[];
    final contains = <Country>[];
    for (final country in valid) {
      final name = country.name.toLowerCase();
      if (name.startsWith(_query)) {
        starts.add(country);
      } else if (name.contains(_query)) {
        contains.add(country);
      }
    }
    return [...starts, ...contains];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Pilih Destinasi',
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
                decoration: InputDecoration(
                  hintText: 'Cari nama negara, mis. Japan',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          tooltip: 'Hapus kata kunci',
                          onPressed: _controller.clear,
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
            Expanded(
              child: FutureBuilder<List<Country>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 12),
                          Text('Memuat daftar negara...'),
                        ],
                      ),
                    );
                  }
                  final data = snapshot.data;
                  if (snapshot.hasError || data == null) {
                    return StateMessage(
                      icon: Icons.wifi_off_rounded,
                      title: 'Daftar negara gagal dimuat',
                      message:
                          'Periksa koneksi internet, lalu coba ambil data kembali.',
                      buttonText: 'Coba lagi',
                      onPressed: _retry,
                    );
                  }

                  final results = _filter(data);
                  if (results.isEmpty) {
                    return const StateMessage(
                      icon: Icons.search_off_rounded,
                      title: 'Negara tidak ditemukan',
                      message: 'Coba kata kunci nama negara yang lain.',
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: results.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final country = results[index];
                      final selected = country.alpha2Code == widget.selectedCode;
                      return Container(
                        decoration: cardDecoration(radius: 14).copyWith(
                          border: Border.all(
                            color: selected ? kOcean : kBorder,
                            width: selected ? 1.5 : 1,
                          ),
                        ),
                        child: ListTile(
                          onTap: () => Navigator.pop(context, country),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          leading: CountryFlag(
                            country: country,
                            width: 46,
                            height: 32,
                            radius: 6,
                          ),
                          title: Text(
                            country.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: kDeepTeal,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            '${country.alpha2Code} · ${country.region}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: selected
                              ? const Icon(Icons.check_circle_rounded, color: kOcean)
                              : null,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
