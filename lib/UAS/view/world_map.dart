import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../model/travel_map_point.dart';
import '../model/travel_note.dart';
import '../viewmodel/travel_viewmodel.dart';
import '../widgets/app_colors.dart';
import '../widgets/ui_parts.dart';
import 'note_detail.dart';

Color _statusColor(TravelStatus status) =>
    status == TravelStatus.visited ? kGreen : kOcean;

IconData _statusIcon(TravelStatus status) => status == TravelStatus.visited
    ? Icons.check_circle_rounded
    : Icons.bookmark_rounded;

IconData _sourceIcon(LocationMethod method) => method == LocationMethod.detect
    ? Icons.my_location_rounded
    : Icons.search_rounded;

String _coord(double value) => value.toStringAsFixed(6);

/// Halaman World Map (flutter_map + tile OpenStreetMap).
///
/// Setiap catatan di My Travel List yang punya koordinat valid (dari GPS atau
/// Custom Location) menjadi satu titik di peta. Koordinat diambil dari
/// [NoteLocation] milik catatan, bukan dari data negara.
///
/// Warna marker = status (biru: ingin dikunjungi, hijau: sudah dikunjungi);
/// ikon kecil di kepala marker = sumber lokasi (crosshair: GPS, kaca pembesar:
/// Custom Location). Beberapa catatan di titik yang sama digabung menjadi satu
/// marker bernomor; ketuk untuk memilih catatannya.
class WorldMapPage extends StatefulWidget {
  const WorldMapPage({super.key});

  @override
  State<WorldMapPage> createState() => _WorldMapPageState();
}

class _WorldMapPageState extends State<WorldMapPage> {
  static const LatLng _worldCenter = LatLng(20, 10);
  static const double _worldZoom = 1.6;
  static const double _singleZoom = 13;
  static const double _maxZoom = 18;
  static const EdgeInsets _fitPadding = EdgeInsets.fromLTRB(56, 150, 56, 110);

  final MapController _mapController = MapController();
  final TravelViewModel _travel = TravelViewModel.instance;
  final ValueNotifier<bool> _tileError = ValueNotifier<bool>(false);

  // Opsi peta dibuat sekali (posisi awal kamera hanya berlaku saat peta
  // pertama kali tampil; perubahan data tidak menggeser kamera pengguna).
  MapOptions? _options;
  bool _mapReady = false;
  bool _refreshing = false;
  bool _legendOpen = true;
  int _tileGeneration = 0;

  @override
  void initState() {
    super.initState();
    // init() hanya berjalan sekali; pemanggilan berikutnya memakai future yang
    // sama. Perubahan data didengarkan lewat ListenableBuilder pada build().
    _travel.init();
  }

  @override
  void dispose() {
    _tileError.dispose();
    _mapController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------ KAMERA
  List<LatLng> _pointsOf(TravelMapData data) => [
        for (final g in data.groups) LatLng(g.latitude, g.longitude),
      ];

  MapOptions _buildOptions(TravelMapData data) {
    final points = _pointsOf(data);
    return MapOptions(
      initialCenter: points.length == 1 ? points.first : _worldCenter,
      initialZoom: points.length == 1 ? _singleZoom : _worldZoom,
      initialCameraFit: points.length > 1
          ? CameraFit.coordinates(
              coordinates: points,
              padding: _fitPadding,
              maxZoom: 15,
            )
          : null,
      minZoom: 1,
      maxZoom: _maxZoom,
      onMapReady: () => _mapReady = true,
      interactionOptions: const InteractionOptions(
        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
      ),
    );
  }

  void _fitAll(TravelMapData data) {
    final points = _pointsOf(data);
    if (points.isEmpty) {
      _snack('Belum ada lokasi perjalanan untuk ditampilkan.');
      return;
    }
    if (!_mapReady) return;
    if (points.length == 1) {
      _mapController.move(points.first, _singleZoom);
      return;
    }
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: _fitPadding,
        maxZoom: 15,
      ),
    );
  }

  // ----------------------------------------------------------- MUAT ULANG
  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    TravelResult? result;
    try {
      // Membaca ulang catatan dari ViewModel (tanpa data/koordinat negara).
      result = await _travel.refresh();
    } catch (_) {
      result = null;
    }
    if (!mounted) return;
    final count = TravelMapData.fromNotes(_travel.notes).locationCount;
    setState(() {
      _refreshing = false;
      _tileGeneration++; // memuat ulang tile bila sebelumnya gagal
    });
    _tileError.value = false;
    _snack(
      (result?.ok ?? false)
          ? 'Peta diperbarui · $count lokasi perjalanan.'
          : 'Peta diperbarui dari data di perangkat · $count lokasi perjalanan.',
    );
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _onTileError() {
    if (_tileError.value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _tileError.value = true;
    });
  }

  // -------------------------------------------------------- INTERAKSI MARKER
  void _openGroup(TravelMapGroup group) {
    if (group.isCluster) {
      _showGroupSheet(group);
    } else {
      _showNoteSheet(group.points.first);
    }
  }

  void _showGroupSheet(TravelMapGroup group) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => _GroupSheet(
        group: group,
        onSelect: (point) {
          Navigator.pop(sheetContext);
          if (mounted) _showNoteSheet(point);
        },
      ),
    );
  }

  void _showNoteSheet(TravelMapPoint point) {
    final navigator = Navigator.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) => _NoteSheet(
        point: point,
        onOpenDetail: () {
          Navigator.pop(sheetContext);
          // ID dibawa dari catatan yang diketuk; halaman detail mencari
          // catatan yang sama di TravelViewModel.
          navigator.push(
            MaterialPageRoute<void>(
              builder: (_) => NoteDetailPage(noteId: point.note.id),
            ),
          );
        },
      ),
    );
  }

  // ----------------------------------------------------------------- BUILD
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _travel,
      builder: (context, _) {
        final loading = _travel.isLoading;
        final data = loading
            ? TravelMapData.empty
            : TravelMapData.fromNotes(_travel.notes);

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'World Map',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: [
              IconButton(
                tooltip: 'Muat ulang',
                onPressed: (loading || _refreshing) ? null : _refresh,
                icon: _refreshing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      )
                    : const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          floatingActionButton: loading
              ? null
              : FloatingActionButton.small(
                  // heroTag null: halaman My Travel List juga memakai FAB.
                  heroTag: null,
                  tooltip: 'Tampilkan semua lokasi',
                  backgroundColor: Colors.white,
                  foregroundColor: kDeepTeal,
                  onPressed: () => _fitAll(data),
                  child: const Icon(Icons.zoom_out_map_rounded),
                ),
          body: loading
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Menyiapkan peta...'),
                    ],
                  ),
                )
              : _buildMap(data),
        );
      },
    );
  }

  Widget _buildMap(TravelMapData data) {
    final options = _options ??= _buildOptions(data);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: options,
          children: [
            TileLayer(
              key: ValueKey(_tileGeneration),
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.flutter_application_1',
              errorTileCallback: (tile, error, stackTrace) => _onTileError(),
            ),
            MarkerLayer(
              markers: [
                for (final group in data.groups)
                  Marker(
                    point: LatLng(group.latitude, group.longitude),
                    width: 52,
                    height: 52,
                    // Ujung pin tepat di koordinat.
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _openGroup(group),
                      child: _Pin(group: group),
                    ),
                  ),
              ],
            ),
            const RichAttributionWidget(
              alignment: AttributionAlignment.bottomLeft,
              attributions: [
                TextSourceAttribution('© OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
        Positioned(
          top: 10,
          left: 10,
          right: 10,
          child: Align(
            alignment: Alignment.topLeft,
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: _InfoPanel(
                locationCount: data.locationCount,
                withoutCoordinates: data.withoutCoordinates,
                hasClusters: data.hasClusters,
                open: _legendOpen,
                onToggle: () => setState(() => _legendOpen = !_legendOpen),
              ),
            ),
          ),
        ),
        if (data.totalNotes == 0)
          const Positioned(
            left: 16,
            right: 16,
            bottom: 90,
            child: _EmptyCard(
              title: 'Belum ada lokasi perjalanan.',
              message:
                  'Tambahkan catatan perjalanan melalui My Travel List untuk '
                  'melihat lokasinya di World Map.',
            ),
          )
        else if (!data.hasPoints)
          const Positioned(
            left: 16,
            right: 16,
            bottom: 90,
            child: _EmptyCard(
              title: 'Belum ada koordinat lokasi.',
              message:
                  'Catatan Anda belum memiliki koordinat. Pilih Lokasi Saya '
                  '(GPS) atau Custom Location saat menambah atau mengubah '
                  'catatan.',
            ),
          ),
        Positioned(
          left: 12,
          right: 72,
          bottom: 40,
          child: ValueListenableBuilder<bool>(
            valueListenable: _tileError,
            builder: (context, failed, _) =>
                failed ? const _TileErrorBanner() : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

// =============================================================== MARKER
class _Pin extends StatelessWidget {
  final TravelMapGroup group;
  const _Pin({required this.group});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(group.status);
    final badge = group.isCluster
        ? Text(
            group.count > 99 ? '99+' : '${group.count}',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          )
        : Icon(_sourceIcon(group.method), size: 12, color: color);

    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        Icon(
          Icons.location_on_rounded,
          color: color,
          size: 46,
          shadows: const [Shadow(blurRadius: 6, color: Colors.black38)],
        ),
        Positioned(
          top: 8,
          child: Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: badge,
          ),
        ),
      ],
    );
  }
}

// ============================================================ LEGENDA
class _InfoPanel extends StatelessWidget {
  final int locationCount;
  final int withoutCoordinates;
  final bool hasClusters;
  final bool open;
  final VoidCallback onToggle;

  const _InfoPanel({
    required this.locationCount,
    required this.withoutCoordinates,
    required this.hasClusters,
    required this.open,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
              child: Row(
                children: [
                  const Icon(Icons.pin_drop_rounded, color: kOcean, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Total Lokasi Perjalanan: $locationCount',
                      style: const TextStyle(
                        color: kDeepTeal,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(
                    open
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: kTextSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (withoutCoordinates > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: Text(
                '$withoutCoordinates catatan belum memiliki koordinat lokasi.',
                style: const TextStyle(
                  color: kWarningText,
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
            ),
          if (open) ...[
            const Divider(height: 1, color: kBorder),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _LegendTitle('Status'),
                  const Wrap(
                    spacing: 14,
                    runSpacing: 4,
                    children: [
                      _LegendItem(
                        leading: Icon(
                          Icons.location_on_rounded,
                          color: kOcean,
                          size: 18,
                        ),
                        label: 'Ingin Dikunjungi',
                      ),
                      _LegendItem(
                        leading: Icon(
                          Icons.location_on_rounded,
                          color: kGreen,
                          size: 18,
                        ),
                        label: 'Sudah Dikunjungi',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const _LegendTitle('Sumber lokasi'),
                  Wrap(
                    spacing: 14,
                    runSpacing: 4,
                    children: [
                      _LegendItem(
                        leading: _sourceDot(Icons.my_location_rounded),
                        label: 'GPS = Lokasi Saya',
                      ),
                      _LegendItem(
                        leading: _sourceDot(Icons.search_rounded),
                        label: 'Custom = pilihan manual',
                      ),
                    ],
                  ),
                  if (hasClusters) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Angka pada marker = beberapa catatan di titik yang sama.',
                      style: TextStyle(color: kTextSecondary, fontSize: 11.5),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _sourceDot(IconData icon) => Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: kDeepTeal.withValues(alpha: 0.4)),
        ),
        child: Icon(icon, size: 11, color: kDeepTeal),
      );
}

class _LegendTitle extends StatelessWidget {
  final String text;
  const _LegendTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Text(
        text,
        style: const TextStyle(
          color: kTextSecondary,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Widget leading;
  final String label;
  const _LegendItem({required this.leading, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        leading,
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 12, color: kDeepTeal)),
      ],
    );
  }
}

// =========================================================== PESAN / INFO
class _EmptyCard extends StatelessWidget {
  final String title;
  final String message;
  const _EmptyCard({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: const [
          BoxShadow(
            color: kShadow,
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconTile(icon: Icons.pin_drop_outlined, size: 44, radius: 13),
          const SizedBox(width: 12),
          Expanded(
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
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: kTextSecondary,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TileErrorBanner extends StatelessWidget {
  const _TileErrorBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: kWarningBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.wifi_off_rounded, color: kWarningText, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Gambar peta tidak dapat dimuat. Periksa koneksi internet. '
              'Catatan dan koordinat Anda tetap aman.',
              style: TextStyle(
                fontSize: 12,
                color: kWarningTextDark,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================ BOTTOM SHEET
class _NoteSheet extends StatelessWidget {
  final TravelMapPoint point;
  final VoidCallback onOpenDetail;
  const _NoteSheet({required this.point, required this.onOpenDetail});

  static String? _text(String? value) {
    final result = value?.trim() ?? '';
    return result.isEmpty ? null : result;
  }

  @override
  Widget build(BuildContext context) {
    final note = point.note;
    final location = point.location;
    final status = point.status;
    final color = _statusColor(status);

    final country = _text(location.country) ?? _text(note.destination);
    final place = _text(location.placeName);
    final city = _text(location.city);
    final province = _text(location.province);
    final address = _text(location.address);
    final noAddressInfo =
        place == null && city == null && province == null && address == null;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              note.title,
              style: const TextStyle(
                color: kDeepTeal,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SoftChip(
                  icon: _statusIcon(status),
                  label: status.label,
                  background: color.withValues(alpha: 0.12),
                  foreground: color,
                ),
                SoftChip(
                  icon: _sourceIcon(point.method),
                  label: point.method.label,
                  background: kSoftSand,
                  foreground: kDeepTeal,
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(height: 1, color: kBorder),
            if (country != null) _InfoRow('Negara', country),
            if (place != null) _InfoRow('Nama tempat', place),
            if (city != null) _InfoRow('Kota', city),
            if (province != null) _InfoRow('Provinsi', province),
            if (address != null) _InfoRow('Alamat', address),
            if (noAddressInfo) const _InfoRow('Alamat', null),
            _InfoRow('Latitude', _coord(point.latitude)),
            _InfoRow('Longitude', _coord(point.longitude)),
            _InfoRow('Sumber lokasi', point.method.label),
            _InfoRow('Status', status.label),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onOpenDetail,
                icon: const Icon(Icons.article_outlined),
                label: const Text('Lihat Detail Catatan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupSheet extends StatelessWidget {
  final TravelMapGroup group;
  final ValueChanged<TravelMapPoint> onSelect;
  const _GroupSheet({required this.group, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.55;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${group.count} catatan di lokasi ini',
              style: const TextStyle(
                color: kDeepTeal,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '${_coord(group.latitude)}, ${_coord(group.longitude)}',
              style: const TextStyle(color: kTextSecondary, fontSize: 12.5),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: group.points.length,
                separatorBuilder: (_, _) =>
                    const Divider(height: 1, color: kBorder),
                itemBuilder: (context, index) {
                  final point = group.points[index];
                  final color = _statusColor(point.status);
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    onTap: () => onSelect(point),
                    leading: Icon(
                      Icons.location_on_rounded,
                      color: color,
                      size: 30,
                    ),
                    title: Text(
                      point.note.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: kDeepTeal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      '${point.status.label} · ${point.method.label}',
                      style: const TextStyle(fontSize: 12.5),
                    ),
                    trailing: Icon(
                      _sourceIcon(point.method),
                      size: 18,
                      color: kTextSecondary,
                    ),
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
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
