import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../model/country.dart';
import '../model/unsplash_photo.dart';
import '../viewmodel/unsplash_client.dart';
import '../viewmodel/unsplash_service.dart';
import 'app_colors.dart';
import 'country_flag.dart';
import 'unsplash_attribution.dart';

/// Foto destinasi sebuah negara (Unsplash), dengan lazy loading.
///
/// * Foto baru diminta setelah widget bertahan [debounce] di layar, dan
///   permintaan dibatalkan bila widget hilang (scroll cepat tidak
///   membanjiri API).
/// * URL yang sudah pernah didapat dipakai langsung dari cache service;
///   gambarnya di-cache ke disk oleh cached_network_image.
/// * Tanpa Access Key, kuota habis, tidak ada hasil, atau gambar gagal
///   dimuat -> tampil bendera negara sebagai fallback.
class DestinationPhoto extends StatefulWidget {
  final Country country;

  /// true: resolusi besar (halaman detail). false: kartu daftar.
  final bool large;
  final bool showAttribution;
  final Duration debounce;

  /// Dipanggil (setelah frame) ketika foto tersedia.
  final ValueChanged<UnsplashPhoto>? onPhotoResolved;

  const DestinationPhoto({
    super.key,
    required this.country,
    this.large = false,
    this.showAttribution = false,
    this.debounce = const Duration(milliseconds: 350),
    this.onPhotoResolved,
  });

  @override
  State<DestinationPhoto> createState() => _DestinationPhotoState();
}

class _DestinationPhotoState extends State<DestinationPhoto> {
  final UnsplashService _service = UnsplashClient.instance;

  UnsplashPhoto? _photo;
  bool _loading = false;
  bool _imageFailed = false;
  Timer? _timer;
  UnsplashRequest? _request;
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _begin();
  }

  @override
  void didUpdateWidget(covariant DestinationPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.country.alpha2Code != widget.country.alpha2Code) {
      _cancel();
      _photo = null;
      _imageFailed = false;
      _begin();
    }
  }

  @override
  void dispose() {
    _cancel();
    super.dispose();
  }

  void _cancel() {
    _generation++;
    _timer?.cancel();
    _timer = null;
    _request?.cancel();
    _request = null;
  }

  void _notify(UnsplashPhoto photo) {
    final callback = widget.onPhotoResolved;
    if (callback == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) callback(photo);
    });
  }

  void _begin() {
    final code = widget.country.alpha2Code;
    if (code.isEmpty || !_service.isEnabled) {
      _loading = false;
      return;
    }

    if (!_service.isLoaded) {
      // Cache tersimpan belum terbaca; tunggu sebentar lalu mulai lagi.
      _loading = true;
      final gen = ++_generation;
      _service.ensureLoaded().then((_) {
        if (mounted && gen == _generation) setState(_begin);
      });
      return;
    }

    final cached = _service.cachedPhoto(code);
    if (cached != null) {
      _photo = cached;
      _loading = false;
      _notify(cached);
      return;
    }

    _loading = true;
    final gen = ++_generation;
    final query = '${widget.country.name} landscape';
    _timer = Timer(widget.debounce, () {
      final request = _service.request(code, query);
      _request = request;
      request.future.then((photo) {
        if (!mounted || gen != _generation) return;
        setState(() {
          _photo = photo;
          _loading = false;
        });
        if (photo != null) _notify(photo);
      });
    });
  }

  void _onImageError(Object _) {
    if (_imageFailed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _imageFailed = true);
    });
  }

  Widget _placeholder() => ColoredBox(
        color: kSeafoam.withValues(alpha: 0.35),
        child: Center(
          child: Icon(
            Icons.landscape_rounded,
            color: kOcean.withValues(alpha: 0.45),
            size: 34,
          ),
        ),
      );

  Widget _flagFallback(double width, double height) => Stack(
        fit: StackFit.expand,
        children: [
          CountryFlag(
            country: widget.country,
            width: width,
            height: height,
            radius: 0,
          ),
          ColoredBox(color: kDeepTeal.withValues(alpha: 0.12)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth ? constraints.maxWidth : 320.0;
        final height =
            constraints.hasBoundedHeight ? constraints.maxHeight : 180.0;
        final photo = _photo;

        final Widget image;
        if (photo != null && !_imageFailed) {
          image = CachedNetworkImage(
            imageUrl: widget.large ? photo.regularUrl : photo.smallUrl,
            width: width,
            height: height,
            fit: BoxFit.cover,
            fadeInDuration: const Duration(milliseconds: 250),
            memCacheWidth: widget.large ? 1200 : 700,
            placeholder: (_, _) => _placeholder(),
            errorWidget: (_, _, _) => _flagFallback(width, height),
            errorListener: _onImageError,
          );
        } else if (_loading && photo == null) {
          image = _placeholder();
        } else {
          image = _flagFallback(width, height);
        }

        final showCredit =
            photo != null && !_imageFailed && widget.showAttribution;

        return Stack(
          fit: StackFit.expand,
          children: [
            image,
            if (showCredit)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        kDeepTeal.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: UnsplashAttribution(photo: photo, compact: true),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
