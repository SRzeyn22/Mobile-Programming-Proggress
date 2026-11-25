import 'package:flutter/material.dart';

import '../model/country.dart';
import '../model/unsplash_photo.dart';
import '../viewmodel/favorite_service.dart';
import '../viewmodel/fetchcountry.dart';
import '../viewmodel/unsplash_client.dart';
import '../widgets/app_colors.dart';
import '../widgets/country_flag.dart';
import '../widgets/destination_photo.dart';
import '../widgets/unsplash_attribution.dart';

class Detail extends StatefulWidget {
  final String countryCode;

  const Detail({super.key, required this.countryCode});

  @override
  State<Detail> createState() => _DetailState();
}

class _DetailState extends State<Detail> {
  late Future<Country> countryFuture;
  UnsplashPhoto? _photo;

  @override
  void initState() {
    super.initState();
    countryFuture = fetchCountryByCode(widget.countryCode);
  }

  void _retry() {
    setState(() => countryFuture = fetchCountryByCode(widget.countryCode));
  }

  /// Foto tampil di halaman detail: simpan untuk atribusi dan laporkan
  /// penggunaannya ke Unsplash (sekali per foto, ketentuan API).
  void _onPhoto(UnsplashPhoto photo) {
    if (_photo?.id == photo.id) return;
    setState(() => _photo = photo);
    UnsplashClient.instance.trackDownload(photo);
  }

  Future<void> _toggleFavorite(Country country) async {
    final messenger = ScaffoldMessenger.of(context);
    final added = await FavoriteService.instance.toggle(country.alpha2Code);
    if (!mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            added
                ? '${country.name} ditambahkan ke favorit.'
                : '${country.name} dihapus dari favorit.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      body: FutureBuilder<Country>(
        future: countryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: kOcean),
            );
          }
          if (snapshot.hasError) {
            return _ErrorView(onRetry: _retry);
          }
          final country = snapshot.data;
          if (country == null) {
            return const Center(child: Text('Data negara tidak tersedia.'));
          }

          final photo = _photo;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 290,
                pinned: true,
                backgroundColor: kDeepTeal,
                foregroundColor: Colors.white,
                actions: [
                  if (country.alpha2Code.isNotEmpty)
                    ListenableBuilder(
                      listenable: FavoriteService.instance,
                      builder: (context, _) {
                        final isFavorite = FavoriteService.instance
                            .isFavorite(country.alpha2Code);
                        return IconButton(
                          tooltip: isFavorite
                              ? 'Hapus dari favorit'
                              : 'Tambahkan ke favorit',
                          onPressed: () => _toggleFavorite(country),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black38,
                          ),
                          icon: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFavorite ? kCoral : Colors.white,
                          ),
                        );
                      },
                    ),
                  const SizedBox(width: 8),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    country.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      shadows: [Shadow(blurRadius: 6, color: Colors.black45)],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      DestinationPhoto(
                        key: ValueKey('detail-${country.alpha2Code}'),
                        country: country,
                        large: true,
                        debounce: Duration.zero,
                        onPhotoResolved: _onPhoto,
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              kDeepTeal.withValues(alpha: 0.4),
                              Colors.transparent,
                              kDeepTeal.withValues(alpha: 0.9),
                            ],
                            stops: const [0, 0.35, 1],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Row(
                      children: [
                        CountryFlag(
                          country: country,
                          width: 54,
                          height: 38,
                          radius: 7,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                country.capital,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: kDeepTeal,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                [country.region, country.subregion]
                                    .where((e) => e != 'Tidak tersedia')
                                    .join(' · '),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: kOcean,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (photo != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: UnsplashAttribution(
                          photo: photo,
                          color: kDeepTeal,
                        ),
                      ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.people_alt_outlined,
                            label: 'Populasi',
                            value: _formatNumber(country.population),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.landscape_outlined,
                            label: 'Luas wilayah',
                            value: country.area > 0
                                ? '${_formatNumber(country.area.round())} km²'
                                : 'Tidak tersedia',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const _SectionTitle('Informasi negara'),
                    const SizedBox(height: 10),
                    _InfoCard(
                      children: [
                        _InfoRow(
                          label: 'Ibu kota',
                          value: country.capital,
                          icon: Icons.location_city_rounded,
                        ),
                        _InfoRow(
                          label: 'Kawasan',
                          value: country.region,
                          icon: Icons.public_rounded,
                        ),
                        _InfoRow(
                          label: 'Subkawasan',
                          value: country.subregion,
                          icon: Icons.explore_outlined,
                        ),
                        _InfoRow(
                          label: 'Nama lokal',
                          value: country.nativeName,
                          icon: Icons.translate_rounded,
                        ),
                        _InfoRow(
                          label: 'Kode negara',
                          value: country.alpha2Code,
                          icon: Icons.tag_rounded,
                        ),
                        _InfoRow(
                          label: 'Kode ISO-3',
                          value: country.alpha3Code,
                          icon: Icons.qr_code_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const _SectionTitle('Fakta lainnya'),
                    const SizedBox(height: 10),
                    _InfoCard(
                      children: [
                        _InfoRow(
                          label: 'Mata uang',
                          value: _joinOrFallback(country.currencies),
                          icon: Icons.payments_outlined,
                        ),
                        _InfoRow(
                          label: 'Bahasa',
                          value: _joinOrFallback(country.languages),
                          icon: Icons.language_rounded,
                        ),
                        _InfoRow(
                          label: 'Zona waktu',
                          value: _joinOrFallback(country.timezones),
                          icon: Icons.schedule_rounded,
                        ),
                        _InfoRow(
                          label: 'Kode telepon',
                          value: _joinOrFallback(country.callingCodes, '+'),
                          icon: Icons.phone_outlined,
                        ),
                        _InfoRow(
                          label: 'Negara berbatasan',
                          value: _joinOrFallback(country.borders),
                          icon: Icons.map_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Data ditampilkan dari API countries.dev.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: kDeepTeal.withValues(alpha: 0.5),
                        fontSize: 12,
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: kDeepTeal,
        fontSize: 19,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

BoxDecoration _cardDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(17),
  border: Border.all(color: kSand.withValues(alpha: 0.55)),
);

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: kOcean, size: 23),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: kDeepTeal.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: kDeepTeal,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: _cardDecoration(),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: kOcean, size: 20),
          const SizedBox(width: 11),
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: TextStyle(
                color: kDeepTeal.withValues(alpha: 0.6),
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: kDeepTeal,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, color: kOcean, size: 52),
            const SizedBox(height: 14),
            const Text(
              'Detail negara gagal dimuat',
              style: TextStyle(
                color: kDeepTeal,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Pastikan perangkat terhubung ke internet, lalu coba lagi.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kDeepTeal.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(backgroundColor: kDeepTeal),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      ),
    );
  }
}

String _joinOrFallback(List<String> values, [String prefix = '']) {
  if (values.isEmpty) return 'Tidak tersedia';
  return values.map((value) => '$prefix$value').join(', ');
}

String _formatNumber(num value) {
  final source = value.round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < source.length; i++) {
    buffer.write(source[i]);
    final remaining = source.length - i - 1;
    if (remaining > 0 && remaining % 3 == 0) buffer.write('.');
  }
  return buffer.toString();
}
