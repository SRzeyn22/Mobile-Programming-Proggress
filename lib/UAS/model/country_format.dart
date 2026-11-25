/// Format populasi ringkas untuk kartu ("125,7 jt", "1,4 miliar").
/// Mengembalikan null bila populasi tidak tersedia (<= 0).
String? compactPopulation(int population) {
  if (population <= 0) return null;
  String decimal(double value) {
    var text = value.toStringAsFixed(1);
    if (text.endsWith('.0')) text = text.substring(0, text.length - 2);
    return text.replaceAll('.', ',');
  }

  if (population >= 1000000000) return '${decimal(population / 1e9)} miliar';
  if (population >= 1000000) return '${decimal(population / 1e6)} jt';
  if (population >= 1000) return '${decimal(population / 1e3)} rb';
  return '$population';
}
