import 'package:flutter/material.dart';

import '../model/country.dart';
import '../viewmodel/favorite_service.dart';
import 'app_colors.dart';
import 'country_flag.dart';

class CountryCard extends StatelessWidget {
  final Country country;
  final VoidCallback onTap;

  /// Widget di ujung kanan kartu (default: panah). Dipakai halaman Favorit
  /// untuk tombol hapus.
  final Widget? trailing;

  /// Tampilkan hati kecil di samping nama bila negara favorit.
  final bool showFavoriteBadge;

  const CountryCard({
    super.key,
    required this.country,
    required this.onTap,
    this.trailing,
    this.showFavoriteBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 11),
      color: Colors.white,
      elevation: 0,
      shadowColor: kShadow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: kBorder),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CountryFlag(country: country, width: 88, height: 66, radius: 11),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            country.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: kDeepTeal,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        // Indikator visual: hati merah bila negara favorit.
                        if (showFavoriteBadge)
                          ListenableBuilder(
                          listenable: FavoriteService.instance,
                          builder: (context, _) {
                            if (!FavoriteService.instance
                                .isFavorite(country.alpha2Code)) {
                              return const SizedBox.shrink();
                            }
                            return const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Icon(
                                Icons.favorite_rounded,
                                color: kCoral,
                                size: 17,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: kOcean,
                          size: 15,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            country.capital,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: kTextSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: kSoftSeafoam,
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        country.region,
                        style: const TextStyle(
                          color: kOcean,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  const Icon(Icons.chevron_right_rounded, color: kTextMuted),
            ],
          ),
        ),
      ),
    );
  }
}
