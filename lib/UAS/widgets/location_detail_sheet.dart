import 'package:flutter/material.dart';

import '../model/country.dart';
import '../model/travel_note.dart';
import 'app_colors.dart';
import 'country_flag.dart';

/// Menampilkan detail lokasi sebuah catatan. Isinya hanya data yang benar-benar
/// tersimpan; field yang kosong ditampilkan sebagai "Tidak tersedia".
Future<void> showLocationDetail(
  BuildContext context, {
  required TravelNote note,
  required Country? country,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (_) => _LocationDetailSheet(note: note, country: country),
  );
}

class _LocationDetailSheet extends StatelessWidget {
  final TravelNote note;
  final Country? country;
  const _LocationDetailSheet({required this.note, required this.country});

  @override
  Widget build(BuildContext context) {
    final location = note.location;
    final method = location?.method;
    final isDetect = method == LocationMethod.detect;
    final countryName = (location?.country.isNotEmpty ?? false)
        ? location?.country
        : (note.destination.isEmpty ? null : note.destination);

    final rows = <(String, String?)>[
      ('Negara', countryName),
      if (isDetect) ...[
        ('Provinsi / wilayah', location?.province),
        ('Kota / kabupaten', location?.city),
        ('Alamat', location?.address),
        ('Latitude', location?.latitude?.toStringAsFixed(6)),
        ('Longitude', location?.longitude?.toStringAsFixed(6)),
      ] else ...[
        ('Nama lokasi', location?.placeName),
        ('Kota / wilayah', _cityRegion(location)),
        ('Alamat / informasi', location?.address),
        if (location?.hasCoordinates ?? false) ...[
          ('Latitude', location?.latitude?.toStringAsFixed(6)),
          ('Longitude', location?.longitude?.toStringAsFixed(6)),
        ],
      ],
    ];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Detail Lokasi',
              style: TextStyle(
                color: kDeepTeal,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              note.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: kTextSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                CountryFlag(country: country, width: 34, height: 24, radius: 4),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    method == null
                        ? 'Metode lokasi: belum tercatat'
                        : 'Metode: ${method.label}',
                    style: const TextStyle(color: kOcean, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: kBorder),
            for (final row in rows) _DetailRow(row.$1, row.$2),
            if (location == null) ...[
              const SizedBox(height: 8),
              const Text(
                'Catatan ini dibuat sebelum detail lokasi tersedia. '
                'Ubah catatan untuk menambahkan lokasi.',
                style: TextStyle(color: kTextSecondary, fontSize: 12, height: 1.4),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String? _cityRegion(NoteLocation? location) {
    final parts = <String>[
      ?location?.city,
      ?location?.province,
    ];
    return parts.isEmpty ? null : parts.join(', ');
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String? value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: kTextSecondary, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Tidak tersedia',
              style: TextStyle(
                color: value == null ? kTextMuted : kDeepTeal,
                fontSize: 14,
                height: 1.35,
                fontWeight: value == null ? FontWeight.w400 : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
