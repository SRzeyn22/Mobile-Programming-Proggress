import 'package:flutter/material.dart';

import '../viewmodel/location_service.dart';
import '../widgets/app_colors.dart';

enum _Status { loading, success, error }

/// Halaman Lokasi Saya (Modul XII): GPS + reverse geocoding.
class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  final LocationService _service = LocationService();

  _Status _status = _Status.loading; // langsung loading saat halaman dibuka
  LocationInfo? _info;
  LocationException? _error;
  bool _busy = false; // mencegah proses ganda saat tombol ditekan berulang

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    if (_busy) return;
    _busy = true;

    // Pada panggilan pertama status sudah loading, jadi tidak perlu setState.
    if (_status != _Status.loading) {
      setState(() {
        _status = _Status.loading;
        _error = null;
      });
    }

    try {
      final info = await _service.getCurrentLocation();
      if (!mounted) return; // pengguna sudah meninggalkan halaman
      setState(() {
        _info = info;
        _error = null;
        _status = _Status.success;
      });
    } on LocationException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _status = _Status.error;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = const LocationException(
          LocationFailure.unknown,
          'Terjadi kesalahan saat mengambil lokasi. Silakan coba lagi.',
        );
        _status = _Status.error;
      });
    } finally {
      _busy = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lokasi Saya',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                const _Header(),
                const SizedBox(height: 18),
                _buildContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_status) {
      case _Status.loading:
        return const _Panel(
          child: Column(
            children: [
              SizedBox(height: 12),
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Sedang mengambil lokasi...'),
              SizedBox(height: 12),
            ],
          ),
        );
      case _Status.error:
        return _buildError();
      case _Status.success:
        final info = _info;
        if (info == null) {
          // Seharusnya tidak terjadi, tetapi ditangani tanpa operator "!".
          return _buildError(
            const LocationException(
              LocationFailure.unknown,
              'Data lokasi tidak tersedia. Silakan coba lagi.',
            ),
          );
        }
        return _buildSuccess(info);
    }
  }

  Widget _buildError([LocationException? override]) {
    final error = override ??
        _error ??
        const LocationException(
          LocationFailure.unknown,
          'Terjadi kesalahan saat mengambil lokasi.',
        );

    final (IconData icon, String title) = switch (error.failure) {
      LocationFailure.serviceDisabled => (
        Icons.location_disabled_rounded,
        'GPS tidak aktif',
      ),
      LocationFailure.permissionDenied => (
        Icons.lock_outline_rounded,
        'Izin lokasi ditolak',
      ),
      LocationFailure.permissionDeniedForever => (
        Icons.block_rounded,
        'Izin lokasi diblokir',
      ),
      LocationFailure.timeout => (Icons.timer_off_outlined, 'Lokasi belum didapat'),
      LocationFailure.unknown => (Icons.error_outline_rounded, 'Gagal mengambil lokasi'),
    };

    return _Panel(
      child: Column(
        children: [
          Icon(icon, size: 48, color: kRed),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kDeepTeal,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: kTextSecondary, height: 1.4),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: _loadLocation,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Coba lagi'),
          ),
          if (error.failure == LocationFailure.serviceDisabled) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _service.openLocationSettings,
              icon: const Icon(Icons.settings_rounded),
              label: const Text('Buka pengaturan lokasi'),
            ),
          ],
          if (error.failure == LocationFailure.permissionDeniedForever) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _service.openAppSettings,
              icon: const Icon(Icons.settings_rounded),
              label: const Text('Buka pengaturan aplikasi'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuccess(LocationInfo info) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionTitle('Alamat'),
              if (!info.hasAddress)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    info.addressNote ??
                        'Data alamat untuk lokasi ini tidak ditemukan.',
                    style: const TextStyle(
                      color: kTextSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ),
              _InfoRow(
                icon: Icons.signpost_outlined,
                label: 'Jalan',
                value: info.street,
              ),
              _InfoRow(
                icon: Icons.holiday_village_outlined,
                label: 'Kelurahan/Kec.',
                value: info.subLocality,
              ),
              _InfoRow(
                icon: Icons.location_city_rounded,
                label: 'Kota/Kab.',
                value: info.city,
              ),
              _InfoRow(
                icon: Icons.map_outlined,
                label: 'Provinsi',
                value: info.province,
              ),
              _InfoRow(
                icon: Icons.public_rounded,
                label: 'Negara',
                value: info.country,
              ),
              _InfoRow(
                icon: Icons.markunread_mailbox_outlined,
                label: 'Kode pos',
                value: info.postalCode,
              ),
              _InfoRow(
                icon: Icons.home_work_outlined,
                label: 'Alamat lengkap',
                value: info.fullAddress,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (info.countryCode.isNotEmpty) ...[
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(
              context,
              '/detail',
              arguments: info.countryCode,
            ),
            icon: const Icon(Icons.flag_outlined),
            label: Text('Lihat detail ${info.country}'),
          ),
          const SizedBox(height: 8),
        ],
        FilledButton.icon(
          onPressed: _loadLocation,
          icon: const Icon(Icons.my_location_rounded),
          label: const Text('Perbarui lokasi'),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: kOcean.withValues(alpha: 0.11),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(Icons.my_location_rounded, color: kOcean, size: 26),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Lokasi perangkat Anda',
            style: TextStyle(
              color: kDeepTeal,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: kBorder),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: kDeepTeal,
          fontSize: 16,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: kOcean, size: 20),
          const SizedBox(width: 11),
          SizedBox(
            width: 104,
            child: Text(
              label,
              style: const TextStyle(color: kTextSecondary, fontSize: 13),
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
