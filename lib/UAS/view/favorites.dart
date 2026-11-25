import 'package:flutter/material.dart';

import '../model/country.dart';
import '../viewmodel/country_repository.dart';
import '../viewmodel/favorite_service.dart';
import '../widgets/app_colors.dart';
import '../widgets/country_card.dart';
import '../widgets/state_message.dart';

/// Halaman Negara Favorit: daftar negara yang ditandai dengan ikon hati.
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late Future<List<Country>> _future;

  @override
  void initState() {
    super.initState();
    FavoriteService.instance.load();
    _future = CountryRepository.instance.load();
  }

  void _retry() {
    setState(() {
      _future = CountryRepository.instance.load(forceRefresh: true);
    });
  }

  Future<void> _remove(Country country) async {
    final messenger = ScaffoldMessenger.of(context);
    await FavoriteService.instance.toggle(country.alpha2Code);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${country.name} dihapus dari favorit.'),
          action: SnackBarAction(
            label: 'Urungkan',
            onPressed: () => FavoriteService.instance.toggle(country.alpha2Code),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Negara Favorit',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: FutureBuilder<List<Country>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final all = snapshot.data;
            if (snapshot.hasError || all == null) {
              return StateMessage(
                icon: Icons.wifi_off_rounded,
                title: 'Data negara gagal dimuat',
                message: 'Periksa koneksi internet, lalu coba lagi.',
                buttonText: 'Coba lagi',
                onPressed: _retry,
              );
            }

            return ListenableBuilder(
              listenable: FavoriteService.instance,
              builder: (context, _) {
                final codes = FavoriteService.instance.codes;
                final favorites =
                    all.where((c) => codes.contains(c.alpha2Code)).toList();

                if (favorites.isEmpty) {
                  return const StateMessage(
                    icon: Icons.favorite_border_rounded,
                    illustration: _EmptyFavoritesIllustration(),
                    title: 'Belum ada negara favorit',
                    message:
                        'Buka detail sebuah negara lalu ketuk ikon hati untuk '
                        'menandainya sebagai favorit.',
                  );
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 10),
                      child: Text(
                        '${favorites.length} negara favorit',
                        style: const TextStyle(
                          color: kDeepTeal,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    for (final country in favorites)
                      CountryCard(
                        key: ValueKey(country.alpha2Code),
                        country: country,
                        showFavoriteBadge: false,
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/detail',
                          arguments: country.alpha2Code,
                        ),
                        trailing: IconButton(
                          tooltip: 'Hapus dari favorit',
                          onPressed: () => _remove(country),
                          iconSize: 32,
                          icon: const Icon(
                            Icons.favorite_rounded,
                            color: kCoral,
                          ),
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Ilustrasi peta lipat + pin lokasi (aset PNG transparan, sumber: SVG).
/// Lebar proporsional terhadap layar, dibatasi 160-190 px agar tidak overflow.
class _EmptyFavoritesIllustration extends StatelessWidget {
  const _EmptyFavoritesIllustration();

  @override
  Widget build(BuildContext context) {
    final width = (MediaQuery.sizeOf(context).width * 0.5).clamp(160.0, 190.0);
    return Image.asset(
      'assets/images/empty_favorites.png',
      width: width,
      fit: BoxFit.contain,
      semanticLabel: 'Ilustrasi peta lipat dengan pin lokasi',
      errorBuilder: (_, _, _) =>
          const Icon(Icons.map_outlined, size: 64, color: kOcean),
    );
  }
}
