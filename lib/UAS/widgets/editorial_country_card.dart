import 'package:flutter/material.dart';

import '../model/country.dart';
import '../model/country_format.dart';
import '../viewmodel/favorite_service.dart';
import 'app_colors.dart';
import 'country_flag.dart';
import 'destination_photo.dart';

/// Kartu negara bergaya editorial (Coastal Journey): foto destinasi besar,
/// bendera sebagai identitas, lalu nama, ibu kota, dan satu baris info.
class EditorialCountryCard extends StatelessWidget {
  final Country country;
  final VoidCallback onTap;

  const EditorialCountryCard({
    super.key,
    required this.country,
    required this.onTap,
  });

  static const double photoHeight = 180;

  /// Tinggi area teks pada skala teks 1.0 (dikali skala teks pengguna).
  static const double infoHeight = 100;

  static bool _has(String value) =>
      value.trim().isNotEmpty && value != 'Tidak tersedia';

  @override
  Widget build(BuildContext context) {
    final population = compactPopulation(country.population);
    final meta = [
      if (_has(country.region)) country.region,
      if (population != null) '$population penduduk',
    ].join(' · ');

    const radius = BorderRadius.all(Radius.circular(22));

    return Semantics(
      button: true,
      label: 'Buka detail ${country.name}',
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: radius,
          border: Border.all(color: kSand.withValues(alpha: 0.55)),
          boxShadow: [
            BoxShadow(
              color: kDeepTeal.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: photoHeight,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        DestinationPhoto(
                          key: ValueKey('photo-${country.alpha2Code}'),
                          country: country,
                          showAttribution: true,
                        ),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(7),
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x33000000),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: CountryFlag(
                              country: country,
                              width: 36,
                              height: 26,
                              radius: 5,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: ListenableBuilder(
                            listenable: FavoriteService.instance,
                            builder: (context, _) {
                              if (!FavoriteService.instance.isFavorite(
                                country.alpha2Code,
                              )) {
                                return const SizedBox.shrink();
                              }
                              return Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.92),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.favorite_rounded,
                                  color: kCoral,
                                  size: 18,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          country.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: kDeepTeal,
                            fontSize: 18,
                            height: 1.25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.place_outlined,
                              size: 15,
                              color: kOcean,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                country.capital,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: kDeepTeal.withValues(alpha: 0.8),
                                  fontSize: 13.5,
                                  height: 1.3,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (meta.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: kOcean,
                              fontSize: 12,
                              height: 1.3,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
