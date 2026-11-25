import 'package:flutter/material.dart';

import '../model/country.dart';
import '../model/travel_note.dart';
import 'app_colors.dart';
import 'country_flag.dart';
import 'location_detail_sheet.dart';
import 'photo_strip.dart';
import 'ui_parts.dart';

/// Kartu satu catatan perjalanan: foto, judul, bendera + negara + Detail,
/// status, catatan, serta tombol ubah, hapus, dan ganti status.
class TravelCard extends StatelessWidget {
  final TravelNote note;
  final Country? country;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleStatus;
  final bool enabled;

  const TravelCard({
    super.key,
    required this.note,
    required this.country,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final photos = note.photoBytesList;
    final visited = note.status == TravelStatus.visited;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
        boxShadow: const [
          BoxShadow(
            color: kShadow,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (photos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: PhotoStrip(photos: photos, height: 140),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    note.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kDeepTeal,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                      height: 1.25,
                    ),
                  ),
                ),
                _ActionIcon(
                  tooltip: 'Ubah',
                  icon: Icons.edit_outlined,
                  color: kDeepTeal,
                  background: kSoftSeafoam,
                  onPressed: enabled ? onEdit : null,
                ),
                const SizedBox(width: 6),
                _ActionIcon(
                  tooltip: 'Hapus',
                  icon: Icons.delete_outline_rounded,
                  color: kRed,
                  background: kSoftRed,
                  onPressed: enabled ? onDelete : null,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(
              children: [
                CountryFlag(country: country, width: 24, height: 17, radius: 3),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    note.destination.isEmpty
                        ? 'Destinasi belum dipilih'
                        : note.destination,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: kTextSecondary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Wrap(
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
                if (note.hasCountry)
                  SoftChip(
                    icon: Icons.place_rounded,
                    label: 'Detail',
                    background: kSoftSand,
                    foreground: kDeepTeal,
                    onTap: () => showLocationDetail(
                      context,
                      note: note,
                      country: country,
                    ),
                  ),
              ],
            ),
          ),
          if (note.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                note.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: kTextBody,
                ),
              ),
            ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: kBorder),
          InkWell(
            onTap: enabled ? onToggleStatus : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    visited
                        ? Icons.undo_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 18,
                    color: enabled ? kOcean : kTextSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    visited
                        ? 'Tandai ingin dikunjungi'
                        : 'Tandai sudah dikunjungi',
                    style: TextStyle(
                      color: enabled ? kOcean : kTextSecondary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback? onPressed;

  const _ActionIcon({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.background,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: onPressed == null ? kBackground : background,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(11),
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(
              icon,
              size: 19,
              color: onPressed == null ? kTextSecondary : color,
            ),
          ),
        ),
      ),
    );
  }
}
