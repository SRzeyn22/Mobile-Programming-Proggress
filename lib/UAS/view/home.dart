import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';

import '../model/country.dart';
import '../model/country_filter.dart';
import '../viewmodel/country_repository.dart';
import '../viewmodel/unsplash_client.dart';
import '../widgets/app_colors.dart';
import '../widgets/editorial_country_card.dart';

/// Country Explorer - tema "Coastal Journey".
class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late Future<List<Country>> countryFuture;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  RegionFilter _region = RegionFilter.all;

  @override
  void initState() {
    super.initState();
    countryFuture = CountryRepository.instance.load();
    // Membaca cache foto tersimpan lebih awal agar kartu langsung bergambar.
    UnsplashClient.instance.ensureLoaded();
    _searchController.addListener(() {
      final query = _searchController.text.trim().toLowerCase();
      if (query != _query) setState(() => _query = query);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _retry() => setState(
    () => countryFuture = CountryRepository.instance.load(forceRefresh: true),
  );

  void _resetFilters() {
    _searchController.clear();
    setState(() => _region = RegionFilter.all);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kCream,
      body: SafeArea(
        child: FutureBuilder<List<Country>>(
          future: countryFuture,
          builder: (context, snapshot) {
            final all = snapshot.data ?? const <Country>[];
            final countries = filterCountries(
              all,
              query: _query,
              region: _region,
            );
            final scale = MediaQuery.textScalerOf(
              context,
            ).scale(1.0).clamp(1.0, 1.6);

            return CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: _Header()),
                const SliverToBoxAdapter(child: _FeatureMenu()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: _SearchField(controller: _searchController),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _RegionChips(
                    selected: _region,
                    onSelected: (value) => setState(() => _region = value),
                  ),
                ),
                if (snapshot.hasData)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
                      child: Text(
                        '${countries.length} negara'
                        '${_region == RegionFilter.all ? '' : ' · ${_region.label}'}',
                        style: TextStyle(
                          color: kDeepTeal.withValues(alpha: 0.65),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: kOcean),
                          SizedBox(height: 12),
                          Text(
                            'Memuat data negara...',
                            style: TextStyle(color: kDeepTeal),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (snapshot.hasError && !snapshot.hasData)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _MessageState(
                      icon: Icons.wifi_off_rounded,
                      title: 'Tidak dapat memuat data',
                      message:
                          'Periksa koneksi internet, lalu coba ambil data kembali.',
                      buttonText: 'Coba lagi',
                      onPressed: _retry,
                    ),
                  )
                else if (countries.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _MessageState(
                      icon: Icons.search_off_rounded,
                      title: 'Negara tidak ditemukan',
                      message: _region == RegionFilter.all
                          ? 'Coba kata kunci negara atau ibu kota lainnya.'
                          : 'Tidak ada hasil di kawasan ${_region.label}. '
                                'Coba kata kunci lain atau ganti kawasan.',
                      buttonText: 'Hapus pencarian & filter',
                      onPressed: _resetFilters,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                    sliver: SliverGrid(
                      // Satu kolom di ponsel, dua kolom atau lebih di layar lebar.
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 420,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        mainAxisExtent:
                            EditorialCountryCard.photoHeight +
                            EditorialCountryCard.infoHeight * scale,
                      ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final country = countries[index];
                        return EditorialCountryCard(
                          key: ValueKey(country.alpha2Code),
                          country: country,
                          onTap: () => Navigator.pushNamed(
                            context,
                            '/detail',
                            arguments: country.alpha2Code,
                          ),
                        );
                      }, childCount: countries.length),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ================================================================== HEADER
class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'COUNTRY EXPLORER',
            style: TextStyle(
              color: kOcean,
              fontSize: 11,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Jelajahi Negara',
            style: TextStyle(
              color: kDeepTeal,
              fontSize: 30,
              height: 1.1,
              letterSpacing: -0.4,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Temukan tempat baru untuk perjalananmu.',
            style: TextStyle(
              color: kDeepTeal.withValues(alpha: 0.72),
              fontSize: 14.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 10),
          const SizedBox(
            width: 64,
            height: 10,
            child: CustomPaint(painter: _WavePainter()),
          ),
        ],
      ),
    );
  }
}

/// Garis ombak kecil sebagai ciri visual header.
class _WavePainter extends CustomPainter {
  const _WavePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kSand
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(0, size.height / 2);
    const waves = 4;
    final step = size.width / waves;
    for (var i = 0; i < waves; i++) {
      final dy = i.isEven ? -4.0 : 4.0;
      path.quadraticBezierTo(
        step * i + step / 2,
        size.height / 2 + dy,
        step * (i + 1),
        size.height / 2,
      );
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================ MENU FITUR
class _FeatureMenu extends StatelessWidget {
  const _FeatureMenu();

  @override
  Widget build(BuildContext context) {
    final items = <_MenuData>[
      _MenuData(Icons.my_location_outlined, 'Lokasi Saya', '/location'),
      _MenuData(Icons.luggage_outlined, 'My Travel List', '/travel'),
      _MenuData(Icons.favorite_border_rounded, 'Favorit', '/favorites'),
      _MenuData(Icons.map_outlined, 'World Map', '/map'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: _MenuItem(
                icon: item.icon,
                label: item.label,
                onTap: () => Navigator.pushNamed(context, item.route),
              ),
            ),
        ],
      ),
    );
  }
}

class _MenuData {
  final IconData icon;
  final String label;
  final String route;
  const _MenuData(this.icon, this.label, this.route);
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: kSeafoam.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: kDeepTeal, size: 25),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: kDeepTeal,
                  fontSize: 11.5,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================================================== PENCARIAN/FILTER
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: color, width: width),
        );

    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      style: const TextStyle(color: kDeepTeal),
      cursorColor: kOcean,
      decoration: InputDecoration(
        hintText: 'Cari nama negara...',
        hintStyle: TextStyle(color: kDeepTeal.withValues(alpha: 0.45)),
        prefixIcon: const Icon(Icons.search_rounded, color: kOcean),
        suffixIcon: ListenableBuilder(
          listenable: controller,
          builder: (context, _) => controller.text.isEmpty
              ? const SizedBox.shrink()
              : IconButton(
                  tooltip: 'Hapus pencarian',
                  onPressed: controller.clear,
                  icon: const Icon(Icons.close_rounded, color: kDeepTeal),
                ),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: border(kSand.withValues(alpha: 0.7)),
        enabledBorder: border(kSand.withValues(alpha: 0.7)),
        focusedBorder: border(kDeepTeal, 1.5),
      ),
    );
  }
}

class _RegionChips extends StatelessWidget {
  final RegionFilter selected;
  final ValueChanged<RegionFilter> onSelected;

  const _RegionChips({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      // Drag mouse/trackpad diaktifkan agar daftar filter dapat digeser di web.
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: RegionFilter.values.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final filter = RegionFilter.values[index];
            final isSelected = filter == selected;
            return ChoiceChip(
              label: Text(filter.label),
              selected: isSelected,
              showCheckmark: false,
              onSelected: (_) => onSelected(filter),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : kDeepTeal,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              selectedColor: kDeepTeal,
              backgroundColor: Colors.white,
              side: BorderSide(
                color: isSelected ? kDeepTeal : kSand.withValues(alpha: 0.8),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6),
            );
          },
        ),
      ),
    );
  }
}

// ============================================================ PESAN STATUS
class _MessageState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onPressed;

  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.buttonText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: kOcean),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kDeepTeal,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: kDeepTeal.withValues(alpha: 0.7)),
            ),
            if (buttonText != null && onPressed != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onPressed,
                style: FilledButton.styleFrom(backgroundColor: kDeepTeal),
                child: Text(buttonText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
