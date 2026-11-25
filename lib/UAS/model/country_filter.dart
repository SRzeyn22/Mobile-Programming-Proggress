import 'country.dart';

/// Filter kawasan Country Explorer. Dicocokkan ke nilai `region` yang
/// dikirim API (countries.dev), bukan klasifikasi buatan sendiri.
enum RegionFilter {
  all('Semua'),
  asia('Asia'),
  europe('Eropa'),
  africa('Afrika'),
  americas('Amerika'),
  oceania('Oseania');

  final String label;
  const RegionFilter(this.label);

  bool matches(Country country) {
    final region = country.region.trim().toLowerCase();
    switch (this) {
      case RegionFilter.all:
        return true;
      case RegionFilter.asia:
        return region == 'asia';
      case RegionFilter.europe:
        return region == 'europe';
      case RegionFilter.africa:
        return region == 'africa';
      case RegionFilter.americas:
        // API memakai "Americas"; varian "America" dan "North/South America"
        // ikut diterima agar tidak ada negara Amerika yang terlewat.
        return region == 'americas' ||
            region == 'america' ||
            region.endsWith(' america');
      case RegionFilter.oceania:
        return region == 'oceania';
    }
  }
}

/// Menggabungkan pencarian teks dan filter kawasan (keduanya harus cocok).
///
/// Teks pencarian dicocokkan ke nama, ibu kota, dan kawasan seperti
/// implementasi Home sebelumnya, sehingga pencarian ibu kota tetap berfungsi.
List<Country> filterCountries(
  List<Country> countries, {
  String query = '',
  RegionFilter region = RegionFilter.all,
}) {
  final q = query.trim().toLowerCase();
  return countries.where((country) {
    if (!region.matches(country)) return false;
    if (q.isEmpty) return true;
    final text = '${country.name} ${country.capital} ${country.region}'
        .toLowerCase();
    return text.contains(q);
  }).toList();
}
