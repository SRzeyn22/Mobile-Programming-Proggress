import 'package:flutter/material.dart';

import '../model/travel_note.dart';
import '../viewmodel/country_repository.dart';
import '../viewmodel/favorite_service.dart';
import '../viewmodel/travel_viewmodel.dart';
import '../widgets/app_colors.dart';
import '../widgets/state_message.dart';
import '../widgets/travel_card.dart';
import '../widgets/travel_stats_card.dart';
import 'note_form.dart';

/// Halaman My Travel List: CRUD catatan perjalanan (Modul XIII) + statistik.
class TravelList extends StatefulWidget {
  const TravelList({super.key});

  @override
  State<TravelList> createState() => _TravelListState();
}

class _TravelListState extends State<TravelList> {
  final TravelViewModel _vm = TravelViewModel.instance;

  @override
  void initState() {
    super.initState();
    _vm.init();
    FavoriteService.instance.load();
    _warmUpCountries();
  }

  /// Data negara dipakai untuk menampilkan bendera pada kartu.
  Future<void> _warmUpCountries() async {
    try {
      await CountryRepository.instance.load();
    } catch (_) {
      // Tanpa data negara, kartu memakai ikon pengganti bendera.
    }
    if (!mounted) return;
    setState(() {});
  }

  void _showResult(TravelResult result) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor:
              result.ok ? kGreen : kRed,
        ),
      );
  }

  Future<void> _openForm({TravelNote? existing}) async {
    final draft = await Navigator.push<TravelNote>(
      context,
      MaterialPageRoute(builder: (_) => NoteFormPage(existing: existing)),
    );
    if (draft == null || !mounted) return;
    final result = existing == null
        ? await _vm.create(draft)
        : await _vm.update(draft);
    _showResult(result);
  }

  Future<void> _confirmDelete(TravelNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus catatan?'),
        content: Text('Catatan "${note.title}" akan dihapus dari daftar.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kRed),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    _showResult(await _vm.delete(note));
  }

  Future<void> _refresh() async {
    _showResult(await _vm.refresh());
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final busy = _vm.isLoading || _vm.isSaving;
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'My Travel List',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: [
              IconButton(
                tooltip: 'Peta dunia',
                onPressed: () => Navigator.pushNamed(context, '/map'),
                icon: const Icon(Icons.map_outlined),
              ),
              IconButton(
                tooltip: 'Muat ulang (GET)',
                onPressed: busy ? null : _refresh,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: busy ? null : () => _openForm(),
            backgroundColor: kDeepTeal,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Tambah'),
          ),
          body: SafeArea(
            child: Column(
              children: [
                if (_vm.isSaving) const LinearProgressIndicator(minHeight: 3),
                Expanded(child: _buildBody()),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    if (_vm.isLoading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Memuat catatan perjalanan...'),
          ],
        ),
      );
    }

    final notes = _vm.notes;
    final warning = _vm.storageWarning;

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
        children: [
          TravelStatsCard(stats: _vm.stats),
          const SizedBox(height: 12),
          if (warning != null) _InfoBanner(text: warning, isWarning: true),
          const SizedBox(height: 6),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Daftar perjalanan',
                  style: TextStyle(
                    color: kDeepTeal,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${notes.length} catatan',
                style: const TextStyle(color: kTextSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (notes.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: StateMessage(
                icon: Icons.luggage_outlined,
                title: 'Belum ada catatan',
                message:
                    'Ketuk tombol Tambah untuk membuat catatan perjalanan, atau '
                    'tampilkan kembali contoh daftar Holiday.',
                buttonText: 'Tampilkan contoh Holiday',
                onPressed: () async => _showResult(await _vm.restoreSample()),
              ),
            )
          else
            for (final note in notes)
              TravelCard(
                key: ValueKey(note.id),
                note: note,
                country: CountryRepository.instance.byCode(note.countryCode),
                enabled: !_vm.isSaving,
                onEdit: () => _openForm(existing: note),
                onDelete: () => _confirmDelete(note),
                onToggleStatus: () async =>
                    _showResult(await _vm.toggleStatus(note)),
              ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String text;
  final bool isWarning;
  const _InfoBanner({required this.text, this.isWarning = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWarning ? kErrorBackground : kWarningBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isWarning ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
            size: 20,
            color: isWarning ? kErrorText : kWarningText,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: isWarning ? kErrorTextDark : kWarningTextDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
