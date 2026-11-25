import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Deretan foto yang bisa digeser ke samping. Ketuk foto untuk melihat ukuran
/// penuh. Bila [onRemove] diisi, setiap foto punya tombol hapus (mode form).
class PhotoStrip extends StatelessWidget {
  final List<Uint8List> photos;
  final double height;
  final void Function(int index)? onRemove;

  const PhotoStrip({
    super.key,
    required this.photos,
    this.height = 120,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final remove = onRemove;
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: photos.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => showPhotoViewer(context, photos, index),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    photos[index],
                    width: height * 1.3,
                    height: height,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    errorBuilder: (_, _, _) => Container(
                      width: height * 1.3,
                      height: height,
                      color: kSoftSeafoam,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined, color: kOcean),
                    ),
                  ),
                ),
                if (remove != null)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: InkWell(
                      onTap: () => remove(index),
                      customBorder: const CircleBorder(),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Melihat foto ukuran penuh (geser untuk foto lain, cubit untuk zoom).
void showPhotoViewer(BuildContext context, List<Uint8List> photos, int initial) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      final controller = PageController(initialPage: initial);
      return Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            PageView.builder(
              controller: controller,
              itemCount: photos.length,
              itemBuilder: (context, index) => InteractiveViewer(
                child: Center(
                  child: Image.memory(photos[index], fit: BoxFit.contain),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  tooltip: 'Tutup',
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
