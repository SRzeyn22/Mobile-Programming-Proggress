import 'package:flutter/material.dart';

import '../model/country.dart';
import 'app_colors.dart';

/// Bendera negara dengan fallback (emoji / ikon) bila gambar gagal dimuat.
class CountryFlag extends StatelessWidget {
  final Country? country;
  final double width;
  final double height;
  final double radius;

  const CountryFlag({
    super.key,
    required this.country,
    this.width = 40,
    this.height = 28,
    this.radius = 6,
  });

  @override
  Widget build(BuildContext context) {
    final data = country;
    final url = data?.flagImage ?? '';
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        width: width,
        height: height,
        child: url.isNotEmpty
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallback(data),
              )
            : _fallback(data),
      ),
    );
  }

  Widget _fallback(Country? data) {
    final emoji = data?.flagEmoji ?? '';
    return Container(
      color: kSoftSeafoam,
      alignment: Alignment.center,
      child: emoji.isNotEmpty
          ? Text(emoji, style: TextStyle(fontSize: height * 0.6))
          : Icon(Icons.public_rounded, size: height * 0.6, color: kOcean),
    );
  }
}
