import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../model/unsplash_photo.dart';

/// Atribusi wajib Unsplash: "Foto: `<fotografer>` di Unsplash", keduanya berupa
/// tautan (dengan parameter UTM) ke profil fotografer dan ke Unsplash.
class UnsplashAttribution extends StatelessWidget {
  final UnsplashPhoto photo;
  final bool compact;
  final Color color;

  const UnsplashAttribution({
    super.key,
    required this.photo,
    this.compact = false,
    this.color = Colors.white,
  });

  Future<void> _open(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }
    if (opened) return;
    await Clipboard.setData(ClipboardData(text: url));
    messenger?.showSnackBar(
      const SnackBar(
        content: Text('Tautan tidak dapat dibuka dan telah disalin.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = compact ? 10.5 : 12.0;
    final base = TextStyle(color: color.withValues(alpha: 0.9), fontSize: size);
    final link = base.copyWith(
      fontWeight: FontWeight.w700,
      decoration: TextDecoration.underline,
      decorationColor: color.withValues(alpha: 0.7),
    );

    Widget tap(String text, String url) {
      final label = Text(
        text,
        style: link,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _open(context, url),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: label,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Foto: ', style: base),
        Flexible(child: tap(photo.photographerName, photo.photographerLink)),
        Text(' di ', style: base),
        tap('Unsplash', photo.unsplashLink),
      ],
    );
  }
}
