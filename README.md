# Laporan Praktikum Mobile Programming — Country Explorer (UAS)

Repositori ini berisi kumpulan materi, latihan, tugas praktikum (Modul 1–13), proyek **UTS**, dan aplikasi **UAS Country Explorer** untuk mata kuliah **Mobile Programming** menggunakan *framework* [Flutter](https://flutter.dev/).

- `lib/main.dart` menjalankan aplikasi **UAS Country Explorer** (`lib/UAS`).
- Kode **UTS** tetap utuh di `lib/UTS` (`flutter run -t lib/UTS/main.dart`).
- Menu seluruh **Modul 1–13 & UTS** tersedia di `lib/menu_modul.dart` (`flutter run -t lib/menu_modul.dart`).

---

## Struktur Direktori

```text
Mobile-Programming-Proggress/
├── android/               # Konfigurasi proyek platform Android
├── ios/                   # Konfigurasi proyek platform iOS
├── lib/                   # Kode utama aplikasi (Dart)
│   ├── Modul-1 .. Modul-13/
│   ├── UTS/               # Aplikasi Country Explorer versi UTS
│   ├── UAS/               # Aplikasi Country Explorer versi UAS (Coastal Journey)
│   ├── main.dart          # Entry point utama (menjalankan UAS)
│   └── menu_modul.dart    # Entry point menu seluruh modul praktikum
├── assets/                # Asset gambar dan ikon
│   ├── icon/
│   └── images/
├── test/                  # Unit test dan widget test
├── env.example.json       # Template konfigurasi Unsplash Access Key
├── pubspec.yaml           # Manajer dependensi & konfigurasi paket
└── README.md              # Dokumentasi proyek
```

---

## Fitur UAS (Country Explorer — "Coastal Journey")

- **Home**: kartu editorial (foto destinasi Unsplash + bendera), pencarian negara/ibu kota, filter kawasan (Semua / Asia / Eropa / Afrika / Amerika / Oseania), serta menu Lokasi Saya, My Travel List, Favorit, dan World Map.
- **My Travel List**: CRUD catatan perjalanan (GET/POST/PUT/DELETE ke JSONPlaceholder + penyimpanan lokal `shared_preferences`), contoh awal "Holiday", Travel Statistics, galeri hingga 8 foto (galeri/kamera), pencarian destinasi, dan status Ingin/Sudah Dikunjungi.
- **Favorit**: ikon hati pada detail negara dan halaman Favorit tersimpan di perangkat.
- **World Map**: `flutter_map` + tile OpenStreetMap; penanda per catatan Travel List berkoordinat valid (GPS atau Custom Location) dengan indikator status dan sumber lokasi.
- **Lokasi Saya (Modul XII)**: `geolocator` + `geocoding` dengan penanganan null, izin, GPS, dan timeout. *(Reverse geocoding berjalan di Android/iOS, bukan di browser.)*

---

## Cara Menjalankan Proyek

### 1. Prasyarat
- [Flutter SDK](https://docs.flutter.dev/get-started/install) terinstal.
- [Git](https://git-scm.com/) terinstal.
- Editor (VS Code / Android Studio) dan emulator atau HP fisik (USB/Wireless Debugging).

### 2. Langkah-langkah
1. **Clone Repositori**
   ```bash
   git clone https://github.com/SRzeyn22/Mobile-Programming-Proggress.git
   cd Mobile-Programming-Proggress
   ```

2. **Unduh Dependensi**
   ```bash
   flutter pub get
   ```

3. **Konfigurasi Foto Unsplash (Opsional)**
   Access Key Unsplash **tidak** ditulis di source code. Tanpa Access Key, aplikasi tetap berjalan normal menggunakan bendera sebagai fallback.
   - Salin `env.example.json` menjadi `env.json` (diabaikan oleh `.gitignore`), lalu isi **Access Key** Anda:
     ```json
     {
       "UNSPLASH_ACCESS_KEY": "ACCESS_KEY_ANDA"
     }
     ```
   - Jalankan atau build dengan:
     ```bash
     flutter run --dart-define-from-file=env.json
     flutter build apk --dart-define-from-file=env.json
     ```
   - Atau langsung lewat flag:
     ```bash
     flutter run --dart-define=UNSPLASH_ACCESS_KEY=ACCESS_KEY_ANDA
     ```
   *(Catatan keamanan: gunakan hanya **Access Key**, bukan Secret Key; untuk produksi gunakan proxy backend.)*

4. **Jalankan Analisis & Pengujian**
   ```bash
   flutter analyze
   flutter test
   ```

---

- **Bahasa Pemrograman:** [Dart](https://dart.dev/)
- **Framework:** [Flutter](https://flutter.dev/)
- **GitHub:** [@SRzeyn22](https://github.com/SRzeyn22)
