import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

void main() {
  runApp(const MyApp());
}

// ==========================================
// WIDGET UTAMA APLIKASI
// ==========================================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lokasi Saya',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      ),
      home: const LocationScreen(),
    );
  }
}

// ==========================================
// HALAMAN LOKASI
// ==========================================

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  // Variabel untuk menyimpan informasi lokasi
  String? _kecamatan;
  String? _kota;

  // Variabel untuk mengatur loading dan error
  bool _isLoading = false;
  String? _errorMessage;

  // ==========================================
  // FUNGSI MENGAMBIL LOKASI GPS
  // ==========================================

  Future<void> _getLocation() async {
    // 1. Mengatur status loading
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _kecamatan = null;
      _kota = null;
    });

    try {
      // 2. Memeriksa apakah GPS aktif
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception('Layanan lokasi tidak aktif. Mohon aktifkan GPS.');
      }

      // 3. Memeriksa izin lokasi
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          throw Exception('Izin lokasi ditolak oleh pengguna.');
        }
      }

      // Memeriksa izin yang ditolak secara permanen
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Izin lokasi ditolak permanen. Silakan ubah izin melalui pengaturan aplikasi.',
        );
      }

      // 4. Mengambil posisi perangkat
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      // 5. Melakukan reverse geocoding
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      // 6. Mengambil informasi alamat
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        if (!mounted) return;

        setState(() {
          _kecamatan = place.subLocality;
          _kota = place.subAdministrativeArea;
        });
      } else {
        throw Exception('Tidak dapat menemukan informasi alamat.');
      }
    } catch (e) {
      // 7. Menangani kesalahan
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      // 8. Menghentikan loading
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ==========================================
  // TAMPILAN APLIKASI
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // APP BAR
      appBar: AppBar(
        title: const Text(
          'Lokasi Saya',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF1A237E),
        centerTitle: true,
      ),

      // BODY
      body: Padding(
        padding: const EdgeInsets.all(16.0),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [
            // ICON LOKASI
            const Icon(Icons.location_on, size: 85, color: Color(0xFF1A237E)),

            const SizedBox(height: 20),

            const Text(
              'Lokasi Perangkat Anda',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 25),

            // CARD INFORMASI LOKASI
            Card(
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),

              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 32.0,
                  horizontal: 16.0,
                ),

                child: _isLoading
                    // KONDISI LOADING
                    ? const Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 15),
                            Text('Sedang mengambil lokasi...'),
                          ],
                        ),
                      )
                    // KONDISI ERROR
                    : (_errorMessage != null)
                    ? Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontSize: 14),
                      )
                    // KONDISI AWAL
                    : (_kecamatan == null && _kota == null)
                    ? const Text(
                        'Tekan tombol untuk menampilkan lokasi.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15),
                      )
                    // KONDISI LOKASI BERHASIL
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          const Text(
                            'Lokasi Berhasil Ditemukan!',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            'Kelurahan/Kecamatan:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),

                          Text(
                            _kecamatan?.isNotEmpty == true
                                ? _kecamatan!
                                : 'Tidak tersedia',
                            style: const TextStyle(fontSize: 16),
                          ),

                          const SizedBox(height: 15),

                          const Text(
                            'Kota:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),

                          Text(
                            _kota?.isNotEmpty == true
                                ? _kota!
                                : 'Tidak tersedia',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 35),

            // TOMBOL TAMPILKAN LOKASI
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _getLocation,

              icon: const Icon(Icons.my_location, color: Colors.white),

              label: const Text(
                'TAMPILKAN LOKASI SAAT INI',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),

              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A237E),
                padding: const EdgeInsets.symmetric(vertical: 17.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                elevation: 5.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
