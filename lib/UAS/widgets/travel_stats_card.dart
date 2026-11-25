import 'package:flutter/material.dart';

import '../viewmodel/travel_viewmodel.dart';
import 'app_colors.dart';

/// Ringkasan Travel Statistics. Angka dihitung dari data Travel List sehingga
/// otomatis berubah saat catatan ditambah, diedit, atau dihapus.
class TravelStatsCard extends StatelessWidget {
  final TravelStats stats;
  const TravelStatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final total = stats.totalCountries;
    final progress = total == 0 ? 0.0 : stats.visitedCountries / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Travel Statistics',
            style: TextStyle(
              color: kDeepTeal,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              children: [
                _Stat(value: stats.wantCountries, label: 'Ingin Dikunjungi'),
                const VerticalDivider(width: 1, color: kBorder),
                _Stat(value: stats.visitedCountries, label: 'Sudah Dikunjungi'),
                const VerticalDivider(width: 1, color: kBorder),
                _Stat(value: stats.totalNotes, label: 'Total Catatan'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: kBorder,
              valueColor: const AlwaysStoppedAnimation<Color>(kOcean),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            total == 0
                ? 'Belum ada negara di Travel List.'
                : '${stats.visitedCountries} dari $total negara sudah dikunjungi',
            style: const TextStyle(color: kTextSecondary, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final int value;
  final String label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: const TextStyle(
              color: kDeepTeal,
              fontSize: 22,
              height: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: kTextSecondary, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}
