import 'package:flutter/material.dart';

/// Sistem warna global aplikasi UAS: identitas visual "Coastal Journey".
///
/// Seluruh halaman dan widget UAS mengambil warna dari file ini (dan dari
/// `ThemeData` di `main.dart` yang dibangun dari konstanta yang sama), sehingga
/// komponen baru otomatis mengikuti Coastal Journey.

// ---------------------------------------------------------------------------
// 1. Palet inti Coastal Journey
// ---------------------------------------------------------------------------

/// Tombol utama, judul, navigasi, elemen penting.
const Color kDeepTeal = Color(0xFF264653);

/// Ikon aktif, elemen sekunder, indikator interaksi (focus border, progress).
const Color kOcean = Color(0xFF457B78);

/// Latar badge dan elemen pendukung.
const Color kSeafoam = Color(0xFFA8C5B5);

/// Highlight dan informasi tertentu.
const Color kSand = Color(0xFFE9CFA8);

/// Latar belakang halaman.
const Color kCream = Color(0xFFF6F3EA);

/// Aksen khusus, dipakai secukupnya.
const Color kCoral = Color(0xFFD98964);

// ---------------------------------------------------------------------------
// 2. Turunan netral & permukaan (semua bernuansa hangat/teal, bukan biru)
// ---------------------------------------------------------------------------

/// Latar halaman (alias semantik untuk [kCream]).
const Color kBackground = kCream;

/// Permukaan kartu, input, dan bottom sheet.
const Color kSurface = Colors.white;

/// Border netral hangat untuk kartu, input, dan pemisah.
const Color kBorder = Color(0xFFEBDDC3);

/// Teks sekunder (kontras 4.7:1 di atas Cream).
const Color kTextSecondary = Color(0xFF5F6F6D);

/// Teks isi paragraf.
const Color kTextBody = Color(0xFF3F5558);

/// Warna ikon/teks pada elemen yang nonaktif atau placeholder.
const Color kTextMuted = Color(0xFF7D8B89);

/// Latar lembut berbasis Seafoam untuk badge/ikon (teks Deep Teal di atasnya
/// berkontras 8:1).
const Color kSoftSeafoam = Color(0xFFDCE9E1);

/// Latar lembut berbasis Sand untuk highlight/informasi netral.
const Color kSoftSand = Color(0xFFF2E4C9);

/// Bayangan lembut bernuansa Deep Teal.
const Color kShadow = Color(0x14264653);

/// Scrim gelap bernuansa Deep Teal (di atas foto).
const Color kScrim = Color(0xAA264653);

// ---------------------------------------------------------------------------
// 3. Warna semantik status (sengaja tetap berbeda dari palet utama)
// ---------------------------------------------------------------------------

/// Sudah Dikunjungi: hijau yang mudah dikenali (5.3:1 di atas putih).
const Color kGreen = Color(0xFF1E7A45);
const Color kSoftGreen = Color(0xFFDDF4E5);

/// Bahaya / gagal / hapus.
const Color kRed = Color(0xFFD13438);
const Color kSoftRed = Color(0xFFFDECEC);
const Color kErrorText = Color(0xFFB42318);
const Color kErrorTextDark = Color(0xFF7A1B14);
const Color kErrorBackground = Color(0xFFFDE8E8);

/// Peringatan (amber) dengan kontras teks memadai (5:1).
const Color kWarningBackground = Color(0xFFFFF4D6);
const Color kWarningText = Color(0xFF8A6100);
const Color kWarningTextDark = Color(0xFF5C4300);

/// Warna status "Ingin Dikunjungi": Deep Teal/Ocean di atas Seafoam.
const Color kWantForeground = kDeepTeal;
const Color kWantBackground = kSoftSeafoam;

/// Dekorasi kartu putih standar dengan border hangat.
BoxDecoration cardDecoration({double radius = 17}) => BoxDecoration(
      color: kSurface,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: kBorder),
    );
