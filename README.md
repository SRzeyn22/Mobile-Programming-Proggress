# Country Explorer (UAS)

Aplikasi Flutter Country Explorer. `lib/main.dart` menjalankan versi **UAS**
(`lib/UAS`). Kode UTS ada di `lib/UTS` dan **tidak diubah**.

## Cara menjalankan
```
flutter pub get
flutter analyze
flutter test
flutter run            # pilih perangkat Android
```
UTS: `flutter run -t lib/UTS/main.dart` · Menu modul: `flutter run -t lib/menu_modul.dart`

## Fitur UAS
- **Home**: daftar & pencarian negara (API countries.dev), menu Lokasi Saya, My Travel List, Favorit, World Map.
- **My Travel List**: CRUD catatan (GET/POST/PUT/DELETE ke JSONPlaceholder), contoh awal "Holiday", Travel Statistics, banyak foto (maks. 8, galeri/kamera, digeser ke samping), destinasi lewat pencarian negara, status Ingin/Sudah Dikunjungi.
- **Favorit**: ikon hati di detail negara, halaman Favorit, tersimpan di perangkat.
- **World Map**: flutter_map + tile OpenStreetMap; satu penanda per catatan Travel List yang punya koordinat valid (GPS atau Custom Location). Warna = status (biru: ingin, hijau: sudah dikunjungi), ikon kecil = sumber lokasi (crosshair: GPS, kaca pembesar: Custom). Ketuk penanda untuk info catatan; tombol "Lihat Detail Catatan" membuka halaman detail.
- **Lokasi Saya (Modul XII)**: geolocator + geocoding dengan penanganan null/izin/GPS/timeout.

## Dependensi & kebutuhan
- Internet: API negara, JSONPlaceholder, dan tile peta OpenStreetMap.
- Paket baru: `shared_preferences`, `image_picker`, `flutter_map`, `latlong2`.
- Reverse geocoding (alamat) hanya berjalan di Android/iOS, bukan di browser.

## Catatan data
JSONPlaceholder adalah API demonstrasi: POST/PUT/DELETE tidak tersimpan permanen
di server. Data catatan, foto, dan favorit disimpan **di perangkat** (shared_preferences).

## Country Explorer "Coastal Journey" dan foto Unsplash

- Home memakai kartu editorial (foto destinasi + bendera), pencarian, dan filter kawasan (Semua/Asia/Eropa/Afrika/Amerika/Oseania) berdasarkan field `region` dari API.
- Foto destinasi diambil dari Unsplash secara lazy dan di-cache (URL di SharedPreferences, gambar di disk lewat `cached_network_image`). Tanpa Access Key, kartu memakai bendera.
- Access Key TIDAK ditulis di source. Berikan saat menjalankan/membangun aplikasi:

      flutter run --dart-define=UNSPLASH_ACCESS_KEY=ACCESS_KEY_ANDA
      flutter build apk --dart-define=UNSPLASH_ACCESS_KEY=ACCESS_KEY_ANDA

- Catatan keamanan: Access Key pada aplikasi client-side dapat diekstrak dari APK. Gunakan hanya Access Key (bukan Secret Key); untuk produksi gunakan proxy backend.
