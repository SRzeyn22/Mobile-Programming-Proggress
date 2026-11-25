/// Foto destinasi dari Unsplash beserta data atribusi fotografer.
///
/// Hanya URL `https` yang diterima. URL gambar disimpan apa adanya (termasuk
/// parameter `ixid`) karena ketentuan Unsplash mewajibkan hotlink ke CDN.
class UnsplashPhoto {
  /// Parameter UTM untuk tautan atribusi (ketentuan Unsplash).
  static const String utm = 'utm_source=country_explorer&utm_medium=referral';

  final String id;
  final String smallUrl;
  final String regularUrl;
  final String photographerName;
  final String photographerUrl;
  final String photoPageUrl;

  /// Endpoint pelacakan unduhan (`links.download_location`).
  final String? downloadLocation;

  const UnsplashPhoto({
    required this.id,
    required this.smallUrl,
    required this.regularUrl,
    required this.photographerName,
    required this.photographerUrl,
    required this.photoPageUrl,
    this.downloadLocation,
  });

  String get photographerLink => withUtm(photographerUrl);
  String get unsplashLink => withUtm('https://unsplash.com/');

  static String withUtm(String url) =>
      url.contains('?') ? '$url&$utm' : '$url?$utm';

  static String? _httpsUrl(dynamic value) {
    if (value is! String) return null;
    final text = value.trim();
    final uri = Uri.tryParse(text);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return null;
    return text;
  }

  static Map<dynamic, dynamic>? _map(dynamic value) =>
      value is Map ? value : null;

  /// Membaca satu item hasil `/search/photos`. Null bila data penting hilang.
  static UnsplashPhoto? fromApi(dynamic json) {
    final root = _map(json);
    if (root == null) return null;
    final id = root['id'];
    final urls = _map(root['urls']);
    if (id is! String || id.isEmpty || urls == null) return null;

    final small = _httpsUrl(urls['small']);
    final regular = _httpsUrl(urls['regular']) ?? small;
    if (small == null || regular == null) return null;

    final user = _map(root['user']);
    final userLinks = _map(user?['links']);
    final links = _map(root['links']);
    final rawName = user?['name'];
    final name = rawName is String && rawName.trim().isNotEmpty
        ? rawName.trim()
        : 'Fotografer Unsplash';

    return UnsplashPhoto(
      id: id,
      smallUrl: small,
      regularUrl: regular,
      photographerName: name,
      photographerUrl:
          _httpsUrl(userLinks?['html']) ?? 'https://unsplash.com/',
      photoPageUrl: _httpsUrl(links?['html']) ?? 'https://unsplash.com/',
      downloadLocation: _httpsUrl(links?['download_location']),
    );
  }

  factory UnsplashPhoto.fromStored(Map<dynamic, dynamic> json) {
    String text(String key) => json[key] is String ? json[key] as String : '';
    final download = text('downloadLocation');
    return UnsplashPhoto(
      id: text('id'),
      smallUrl: text('smallUrl'),
      regularUrl: text('regularUrl'),
      photographerName: text('photographerName'),
      photographerUrl: text('photographerUrl'),
      photoPageUrl: text('photoPageUrl'),
      downloadLocation: download.isEmpty ? null : download,
    );
  }

  /// Data tersimpan dianggap rusak bila URL gambar/ID kosong.
  bool get isUsable => id.isNotEmpty && smallUrl.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'smallUrl': smallUrl,
        'regularUrl': regularUrl,
        'photographerName': photographerName,
        'photographerUrl': photographerUrl,
        'photoPageUrl': photoPageUrl,
        'downloadLocation': downloadLocation,
      };
}
