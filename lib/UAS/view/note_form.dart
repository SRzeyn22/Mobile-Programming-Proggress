import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../model/country.dart';
import '../model/travel_note.dart';
import '../viewmodel/country_repository.dart';
import '../viewmodel/location_service.dart';
import '../viewmodel/place_search_service.dart';
import '../viewmodel/travel_service.dart';
import '../widgets/app_colors.dart';
import '../widgets/country_flag.dart';
import '../widgets/photo_strip.dart';
import '../widgets/ui_parts.dart';
import 'country_picker.dart';
import 'place_search_page.dart';

/// Form tambah/ubah catatan. Mengembalikan [TravelNote] (id 0 untuk catatan
/// baru) lewat Navigator.pop, atau null bila dibatalkan.
///
/// Destinasi punya dua metode: Lokasi Saya (GPS + reverse geocoding) dan
/// Custom Location (pilih negara lalu cari lokasi secara manual).
class NoteFormPage extends StatefulWidget {
  final TravelNote? existing;
  const NoteFormPage({super.key, this.existing});

  @override
  State<NoteFormPage> createState() => _NoteFormPageState();
}

class _NoteFormPageState extends State<NoteFormPage> {
  static const int _maxPhotoBytes = 1500 * 1024;
  static const int _maxPhotos = 8;

  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  late final TextEditingController _titleController;
  late final TextEditingController _destinationController;
  late final TextEditingController _descriptionController;

  final LocationService _locationService = LocationService();

  // Custom Location
  String _countryCode = '';
  String _countryName = '';
  NoteLocation? _customPlace;

  // Lokasi Saya (GPS)
  LocationMethod _method = LocationMethod.custom;
  NoteLocation? _detected;
  bool _detecting = false;
  LocationException? _detectError;
  bool _detectMissing = false;

  TravelStatus _status = TravelStatus.wantToVisit;
  final List<Uint8List> _photos = [];
  bool _pickingPhoto = false;

  // Tab aktif: 0 = Detail Perjalanan, 1 = Album Foto. Semua state form berada
  // di State ini (bukan di tab), sehingga berpindah tab tidak menghapus data.
  int _tab = 0;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final note = widget.existing;
    _titleController = TextEditingController(text: note?.title ?? '');
    _descriptionController = TextEditingController(
      text: note?.description ?? '',
    );
    final saved = note?.location;
    if (saved != null && saved.method == LocationMethod.detect) {
      _method = LocationMethod.detect;
      _detected = saved;
    }
    _countryCode = note?.countryCode ?? '';
    _countryName = note?.destination ?? '';
    if (saved != null &&
        saved.method == LocationMethod.custom &&
        saved.placeName != null) {
      _customPlace = saved;
    }
    _destinationController = TextEditingController(text: _countryName);
    _status = note?.status ?? TravelStatus.wantToVisit;
    _photos.addAll(note?.photoBytesList ?? const <Uint8List>[]);
    _warmUpCountries();
  }

  /// Memuat data negara agar bendera pada kolom destinasi bisa tampil.
  Future<void> _warmUpCountries() async {
    try {
      await CountryRepository.instance.load();
    } catch (_) {
      // Bendera hanya hiasan; kegagalan ditangani saat memilih negara.
    }
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    _destinationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------- FOTO
  void _snack(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  /// Menambah foto dari galeri (boleh banyak sekaligus) atau kamera.
  Future<void> _addPhotos(ImageSource source) async {
    if (_pickingPhoto) return;
    final remaining = _maxPhotos - _photos.length;
    if (remaining <= 0) {
      _snack('Maksimal $_maxPhotos foto per catatan.');
      return;
    }

    setState(() => _pickingPhoto = true);
    try {
      final List<XFile> files;
      if (source == ImageSource.gallery) {
        files = await _picker.pickMultiImage(
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 70,
        );
      } else {
        final single = await _picker.pickImage(
          source: source,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 70,
        );
        files = single == null ? const <XFile>[] : [single];
      }
      if (files.isEmpty) return; // pengguna membatalkan

      final added = <Uint8List>[];
      var tooLarge = 0;
      for (final file in files.take(remaining)) {
        final bytes = await file.readAsBytes();
        if (bytes.length > _maxPhotoBytes) {
          tooLarge++;
        } else {
          added.add(bytes);
        }
      }
      if (!mounted) return;
      setState(() => _photos.addAll(added));

      if (files.length > remaining) {
        _snack('Hanya $remaining foto yang ditambahkan (maksimal $_maxPhotos).');
      } else if (tooLarge > 0) {
        _snack('$tooLarge foto dilewati karena lebih dari 1,5 MB.');
      }
    } catch (_) {
      if (!mounted) return;
      _snack('Foto tidak dapat dipilih. Periksa izin kamera/galeri.');
    } finally {
      if (mounted) setState(() => _pickingPhoto = false);
    }
  }

  // --------------------------------------------------------- DESTINASI
  Future<void> _pickCountry() async {
    final picked = await Navigator.push<Country>(
      context,
      MaterialPageRoute(
        builder: (_) => CountryPickerPage(selectedCode: _countryCode),
      ),
    );
    if (!mounted || picked == null) return;
    setState(() {
      if (picked.alpha2Code != _countryCode) _customPlace = null;
      _countryCode = picked.alpha2Code;
      _countryName = picked.name;
      _destinationController.text = picked.name;
    });
    _formKey.currentState?.validate();
  }

  Future<void> _pickPlace() async {
    if (_countryCode.isEmpty) {
      _snack('Pilih negara terlebih dahulu.');
      return;
    }
    final picked = await Navigator.push<PlaceResult>(
      context,
      MaterialPageRoute(
        builder: (_) => PlaceSearchPage(
          countryCode: _countryCode,
          countryName: _countryName,
        ),
      ),
    );
    if (!mounted || picked == null) return;
    setState(() => _customPlace = picked.toNoteLocation());
  }

  /// Mendeteksi posisi lewat GPS, lalu reverse geocoding. Hasil ditampilkan
  /// dulu kepada pengguna; baru tersimpan saat tombol Simpan ditekan.
  Future<void> _detectLocation() async {
    if (_detecting) return;
    setState(() {
      _detecting = true;
      _detectError = null;
      _detectMissing = false;
    });
    try {
      final info = await _locationService.getCurrentLocation();
      try {
        await CountryRepository.instance.load();
      } catch (_) {
        // Nama negara memakai hasil geocoding bila daftar negara gagal dimuat.
      }
      if (!mounted) return;

      if (info.countryCode.isEmpty) {
        setState(() {
          _detected = null;
          _detectError = LocationException(
            LocationFailure.unknown,
            info.addressNote ??
                'Posisi berhasil didapat, tetapi negara tidak dapat '
                    'diidentifikasi (alamat tidak tersedia). Coba lagi, atau '
                    'gunakan Custom Location.',
          );
        });
        return;
      }

      final country = CountryRepository.instance.byCode(info.countryCode);
      String? value(String text) => text == kUnavailable ? null : text;
      setState(() {
        _detected = NoteLocation(
          method: LocationMethod.detect,
          country: country?.name ?? value(info.country) ?? info.countryCode,
          countryCode: info.countryCode,
          province: value(info.province),
          city: value(info.city),
          address: info.hasAddress ? value(info.fullAddress) : null,
          latitude: info.latitude,
          longitude: info.longitude,
        );
      });
    } on LocationException catch (e) {
      if (!mounted) return;
      setState(() {
        _detected = null;
        _detectError = e;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _detected = null;
        _detectError = const LocationException(
          LocationFailure.unknown,
          'Lokasi gagal dideteksi. Coba lagi atau gunakan Custom Location.',
        );
      });
    } finally {
      if (mounted) setState(() => _detecting = false);
    }
  }

  // ------------------------------------------------------------ SIMPAN
  String? _required(String? value, String label, int minLength) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$label wajib diisi';
    if (text.length < minLength) return '$label minimal $minLength karakter';
    return null;
  }

  void _submit() {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      if (_tab != 0) setState(() => _tab = 0);
      return;
    }

    final NoteLocation location;
    if (_method == LocationMethod.detect) {
      final detected = _detected;
      if (detected == null) {
        setState(() {
          _detectMissing = true;
          _tab = 0;
        });
        _snack('Deteksi lokasi Anda terlebih dahulu.');
        return;
      }
      location = detected;
    } else {
      final place = _customPlace;
      location = NoteLocation(
        method: LocationMethod.custom,
        country: _countryName,
        countryCode: _countryCode,
        placeName: place?.placeName,
        city: place?.city,
        province: place?.province,
        address: place?.address,
        latitude: place?.latitude,
        longitude: place?.longitude,
      );
    }

    final existing = widget.existing;
    Navigator.pop(
      context,
      TravelNote(
        id: existing?.id ?? 0,
        title: _titleController.text.trim(),
        destination: location.country,
        countryCode: location.countryCode,
        description: _descriptionController.text.trim(),
        status: _status,
        photos: _photos.map(base64Encode).toList(),
        userId: existing?.userId ?? TravelService.demoUserId,
        location: location,
      ),
    );
  }

  // ---------------------------------------------------------------- UI
  InputDecoration _decoration(
    String label,
    IconData? icon, {
    String? hint,
    bool alignTop = false,
    Widget? prefix,
    Widget? suffix,
    bool inlineLabel = false,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      // inlineLabel: tanpa label mengambang; judul section sudah menjelaskan
      // kolom, dan teks contoh (hint) langsung terlihat tanpa harus diketuk.
      labelText: inlineLabel ? null : label,
      hintText: hint,
      hintStyle: const TextStyle(
        color: kTextMuted,
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
      ),
      alignLabelWithHint: alignTop,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      prefixIcon: prefix ??
          (alignTop || icon == null
              ? null
              : Icon(icon, color: kTextSecondary, size: 22)),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: border(kBorder),
      enabledBorder: border(kBorder),
      focusedBorder: border(kOcean, 1.5),
      errorBorder: border(kRed),
      focusedErrorBorder: border(kRed, 1.5),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Column(
              children: [
                _buildHeader(),
                _buildTabBar(),
                Expanded(
                  child: Form(
                    key: _formKey,
                    // IndexedStack menjaga kedua tab tetap hidup sehingga
                    // isian dan validasi tidak hilang saat berpindah tab.
                    child: IndexedStack(
                      index: _tab,
                      children: [_buildDetailTab(), _buildAlbumTab()],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Row(
        children: [
          Material(
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: kBorder),
            ),
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(14),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.arrow_back_rounded, color: kDeepTeal),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEdit ? 'Ubah Catatan' : 'Tambah Catatan',
                  style: const TextStyle(
                    color: kDeepTeal,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Lengkapi informasi perjalananmu.',
                  style: TextStyle(color: kTextSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    Widget tab(int index, IconData icon, String label) {
      final active = _tab == index;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            FocusScope.of(context).unfocus();
            setState(() => _tab = index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 11),
            decoration: BoxDecoration(
              color: active ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(13),
              boxShadow: active
                  ? const [
                      BoxShadow(
                        color: kShadow,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 19,
                  color: active ? kOcean : kTextSecondary,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: active ? kDeepTeal : kTextSecondary,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                if (index == 1 && _photos.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: kSoftSeafoam,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_photos.length}',
                      style: const TextStyle(
                        color: kDeepTeal,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: kSoftSand,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          tab(0, Icons.place_outlined, 'Detail Perjalanan'),
          tab(1, Icons.photo_library_outlined, 'Album Foto'),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: kBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Center(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: kDeepTeal,
                        minimumSize: const Size.fromHeight(50),
                        side: const BorderSide(color: kBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: kDeepTeal,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _isEdit ? 'Perbarui' : 'Simpan',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
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

  // --------------------------------------------------------- TAB 1: DETAIL
  Widget _section(String title, Widget child, {String? hint}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: cardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: kOcean,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 3),
            Text(
              hint,
              style: const TextStyle(color: kTextSecondary, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailTab() {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
      children: [
        _section(
          'JUDUL PERJALANAN',
          TextFormField(
            controller: _titleController,
            textInputAction: TextInputAction.next,
            style: const TextStyle(color: kDeepTeal, fontSize: 14.5),
            decoration: _decoration(
              'Judul',
              null,
              hint: 'Contoh: Liburan ke Jepang',
              inlineLabel: true,
            ),
            validator: (v) => _required(v, 'Judul', 3),
          ),
        ),
        _section(
          'LOKASI',
          _buildDestinationSection(),
          hint: 'Pilih cara menentukan lokasi perjalanan.',
        ),
        _section('STATUS PERJALANAN', _buildStatusSelector()),
        _section(
          'CATATAN (OPSIONAL)',
          TextFormField(
            controller: _descriptionController,
            minLines: 3,
            maxLines: 5,
            style: const TextStyle(color: kDeepTeal, fontSize: 14.5),
            decoration: _decoration(
              'Catatan',
              null,
              hint: 'Mis. Ingin mengunjungi Tokyo dan Kyoto.',
              alignTop: true,
              inlineLabel: true,
            ),
          ),
        ),
      ],
    );
  }

  Widget _choiceCard({
    required IconData icon,
    required String label,
    required bool selected,
    required Color color,
    required Color soft,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: selected ? soft : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected ? color : kBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
            child: Column(
              children: [
                IconTile(
                  icon: icon,
                  size: 40,
                  radius: 13,
                  background: selected ? Colors.white : kBackground,
                  color: selected ? color : kTextSecondary,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    color: selected ? color : kDeepTeal,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDestinationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _choiceCard(
              icon: Icons.my_location_rounded,
              label: 'Lokasi Saya',
              selected: _method == LocationMethod.detect,
              color: kDeepTeal,
              soft: kSoftSeafoam,
              onTap: () => setState(() => _method = LocationMethod.detect),
            ),
            const SizedBox(width: 10),
            _choiceCard(
              icon: Icons.edit_location_alt_outlined,
              label: 'Custom',
              selected: _method == LocationMethod.custom,
              color: kDeepTeal,
              soft: kSoftSeafoam,
              onTap: () => setState(() => _method = LocationMethod.custom),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (_method == LocationMethod.detect)
          _buildDetectPanel()
        else
          _buildCustomPanel(),
      ],
    );
  }

  Widget _buildCustomPanel() {
    final hasCountry = _countryCode.isNotEmpty;
    final place = _customPlace;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _destinationController,
          readOnly: true,
          onTap: _pickCountry,
          decoration: _decoration(
            'Negara',
            Icons.public_rounded,
            hint: 'Ketuk untuk mencari negara',
            prefix: hasCountry
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: CountryFlag(
                      country: CountryRepository.instance.byCode(_countryCode),
                      width: 30,
                      height: 22,
                      radius: 4,
                    ),
                  )
                : null,
            suffix: const Icon(Icons.search_rounded, color: kTextSecondary),
          ),
          validator: (_) =>
              _countryCode.isEmpty ? 'Pilih negara dari hasil pencarian' : null,
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _pickPlace,
          borderRadius: BorderRadius.circular(14),
          child: InputDecorator(
            decoration: _decoration(
              'Lokasi Tambahan (opsional)',
              Icons.place_outlined,
              suffix: place == null
                  ? const Icon(Icons.search_rounded, color: kTextSecondary)
                  : IconButton(
                      tooltip: 'Hapus lokasi',
                      onPressed: () => setState(() => _customPlace = null),
                      icon: const Icon(Icons.close_rounded),
                    ),
            ),
            child: Text(
              place?.placeName ?? 'Ketuk untuk mencari kota atau tempat',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: place == null ? kTextMuted : kDeepTeal),
            ),
          ),
        ),
        if (place != null &&
            (place.city != null || place.province != null)) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              [place.city, place.province].whereType<String>().join(', '),
              style: const TextStyle(color: kTextSecondary, fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDetectPanel() {
    final detected = _detected;
    final error = _detectError;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: kBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (detected != null) ...[
            Row(
              children: [
                CountryFlag(
                  country: CountryRepository.instance.byCode(
                    detected.countryCode,
                  ),
                  width: 30,
                  height: 22,
                  radius: 4,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    detected.country,
                    style: const TextStyle(
                      color: kDeepTeal,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _InfoLine('Provinsi / wilayah', detected.province),
            _InfoLine('Kota / kabupaten', detected.city),
            _InfoLine('Alamat', detected.address),
            _InfoLine(
              'Koordinat',
              detected.hasCoordinates
                  ? '${detected.latitude?.toStringAsFixed(6)}, '
                      '${detected.longitude?.toStringAsFixed(6)}'
                  : null,
            ),
          ] else if (error != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: kErrorText,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    error.message,
                    style: const TextStyle(
                      color: kErrorTextDark,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            Text(
              'Gunakan GPS untuk mengisi negara, wilayah, alamat, dan '
              'koordinat secara otomatis.',
              style: TextStyle(
                color: _detectMissing ? kErrorText : Colors.black54,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _detecting ? null : _detectLocation,
                icon: _detecting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_rounded, size: 18),
                label: Text(
                  _detecting
                      ? 'Mendeteksi...'
                      : (detected != null || error != null)
                          ? 'Deteksi ulang'
                          : 'Deteksi lokasi saya',
                ),
              ),
              if (error?.failure == LocationFailure.serviceDisabled)
                OutlinedButton(
                  onPressed: _locationService.openLocationSettings,
                  child: const Text('Buka pengaturan lokasi'),
                ),
              if (error?.failure == LocationFailure.permissionDeniedForever)
                OutlinedButton(
                  onPressed: _locationService.openAppSettings,
                  child: const Text('Buka pengaturan aplikasi'),
                ),
              if (error != null)
                OutlinedButton(
                  onPressed: () =>
                      setState(() => _method = LocationMethod.custom),
                  child: const Text('Pakai Custom Location'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSelector() {
    return Row(
      children: [
        _choiceCard(
          icon: Icons.bookmark_rounded,
          label: 'Ingin Dikunjungi',
          selected: _status == TravelStatus.wantToVisit,
          color: kDeepTeal,
          soft: kSoftSeafoam,
          onTap: () => setState(() => _status = TravelStatus.wantToVisit),
        ),
        const SizedBox(width: 10),
        _choiceCard(
          icon: Icons.check_circle_rounded,
          label: 'Sudah Dikunjungi',
          selected: _status == TravelStatus.visited,
          color: kGreen,
          soft: kSoftGreen,
          onTap: () => setState(() => _status = TravelStatus.visited),
        ),
      ],
    );
  }

  // ---------------------------------------------------------- TAB 2: ALBUM
  Widget _buildAlbumTab() {
    final full = _photos.length >= _maxPhotos;
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: cardDecoration(radius: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'ALBUM FOTO',
                      style: TextStyle(
                        color: kOcean,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: kSoftSeafoam,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${_photos.length}/$_maxPhotos',
                      style: const TextStyle(
                        color: kDeepTeal,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Opsional. Maksimal $_maxPhotos foto per catatan.',
                style: TextStyle(color: kTextSecondary, fontSize: 12),
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: (_pickingPhoto || full)
                    ? null
                    : () => _addPhotos(ImageSource.gallery),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 26),
                  decoration: BoxDecoration(
                    color: kBackground,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: kBorder),
                  ),
                  child: Column(
                    children: [
                      const IconTile(
                        icon: Icons.add_photo_alternate_outlined,
                        size: 56,
                        radius: 18,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        full ? 'Album penuh' : 'Tambahkan foto perjalanan',
                        style: const TextStyle(
                          color: kDeepTeal,
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Pilih dari galeri perangkatmu',
                        style: TextStyle(color: kTextSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: (_pickingPhoto || full)
                          ? null
                          : () => _addPhotos(ImageSource.gallery),
                      style: FilledButton.styleFrom(
                        backgroundColor: kDeepTeal,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      icon: _pickingPhoto
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.photo_library_outlined, size: 18),
                      label: const Text('Pilih dari Galeri'),
                    ),
                  ),
                  if (!kIsWeb) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 46,
                      child: OutlinedButton.icon(
                        onPressed: (_pickingPhoto || full)
                            ? null
                            : () => _addPhotos(ImageSource.camera),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kDeepTeal,
                          side: const BorderSide(color: kBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                        icon: const Icon(Icons.photo_camera_outlined, size: 18),
                        label: const Text('Kamera'),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        if (_photos.isNotEmpty) ...[
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: cardDecoration(radius: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'PRATINJAU',
                  style: TextStyle(
                    color: kOcean,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _photos.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 140,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemBuilder: (context, index) => _photoTile(index),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _photoTile(int index) {
    return GestureDetector(
      onTap: () => showPhotoViewer(context, _photos, index),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.memory(_photos[index], fit: BoxFit.cover),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Material(
              color: kScrim,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => setState(() => _photos.removeAt(index)),
                child: const Padding(
                  padding: EdgeInsets.all(5),
                  child: Icon(Icons.close_rounded, color: Colors.white, size: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String? value;
  const _InfoLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: kTextSecondary, fontSize: 12.5),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Tidak tersedia',
              style: TextStyle(
                color: value == null ? kTextMuted : kDeepTeal,
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
