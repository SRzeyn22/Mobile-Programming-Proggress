import 'package:flutter/material.dart';

import '../model/travel_note.dart';
import '../viewmodel/country_repository.dart';
import '../viewmodel/travel_viewmodel.dart';
import '../widgets/app_colors.dart';
import '../widgets/country_flag.dart';
import '../widgets/photo_strip.dart';
import '../widgets/state_message.dart';
import '../widgets/ui_parts.dart';

/// Halaman detail (hanya baca) satu catatan perjalanan.
///
/// Catatan dicari berdasarkan [noteId] langsung dari [TravelViewModel],
/// sehingga selalu menampilkan data terbaru dan aman bila catatan sudah
/// dihapus. Dibuka dari World Map lewat tombol "Lihat Detail Catatan".
class NoteDetailPage extends StatelessWidget {
  final int noteId;
  const NoteDetailPage({super.key, required this.noteId});

  static TravelNote? _find(List<TravelNote> notes, int id) {
    for (final note in notes) {
      if (note.id == id) return note;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final vm = TravelViewModel.instance;
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        final note = _find(vm.notes, noteId);
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Detail Catatan',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          body: note == null
              ? const StateMessage(
                  icon: Icons.search_off_rounded,
                  title: 'Catatan tidak ditemukan',
                  message: 'Catatan ini mungkin sudah dihapus dari My Travel List.',
                )
              : _NoteDetailBody(note: note),
        );
      },
    );
  }
}

class _NoteDetailBody extends StatelessWidget {
  final TravelNote note;
  const _NoteDetailBody({required this.note});

  @override
  Widget build(BuildContext context) {
    final photos = note.photoBytesList;
    final visited = note.status == TravelStatus.visited;
    final location = note.location;
    final country = CountryRepository.instance.byCode(note.countryCode);

    final place = location?.placeName;
    final city = location?.city;
    final province = location?.province;
    final address = location?.address;
    final hasCoordinates = location?.hasCoordinates ?? false;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        children: [
          if (photos.isNotEmpty) ...[
            PhotoStrip(photos: photos, height: 180),
            const SizedBox(height: 14),
          ],
          Text(
            note.title,
            style: const TextStyle(
              color: kDeepTeal,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              CountryFlag(country: country, width: 28, height: 20, radius: 4),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  note.destination.isEmpty
                      ? 'Destinasi belum dipilih'
                      : note.destination,
                  style: const TextStyle(
                    color: kTextSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              SoftChip(
                icon: visited
                    ? Icons.check_circle_rounded
                    : Icons.bookmark_rounded,
                label: note.status.label,
                background: visited ? kSoftGreen : kSoftSeafoam,
                foreground: visited ? kGreen : kDeepTeal,
              ),
              if (location != null)
                SoftChip(
                  icon: location.method == LocationMethod.detect
                      ? Icons.my_location_rounded
                      : Icons.search_rounded,
                  label: location.method.label,
                  background: kSoftSand,
                  foreground: kDeepTeal,
                ),
            ],
          ),
          const SizedBox(height: 16),
          _Section(
            title: 'Catatan',
            child: Text(
              note.description.isEmpty
                  ? 'Tidak ada deskripsi.'
                  : note.description,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: note.description.isEmpty
                    ? kTextMuted
                    : kTextBody,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Lokasi',
            child: location == null
                ? const Text(
                    'Catatan ini dibuat sebelum detail lokasi tersedia. '
                    'Ubah catatan di My Travel List untuk menambahkan lokasi.',
                    style: TextStyle(
                      color: kTextSecondary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  )
                : Column(
                    children: [
                      if (place != null) _Row('Nama tempat', place),
                      if (city != null) _Row('Kota', city),
                      if (province != null) _Row('Provinsi', province),
                      if (address != null) _Row('Alamat', address),
                      if (place == null &&
                          city == null &&
                          province == null &&
                          address == null)
                        const _Row('Alamat', null),
                      _Row(
                        'Latitude',
                        hasCoordinates
                            ? location.latitude?.toStringAsFixed(6)
                            : null,
                      ),
                      _Row(
                        'Longitude',
                        hasCoordinates
                            ? location.longitude?.toStringAsFixed(6)
                            : null,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: kDeepTeal,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String? value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
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
