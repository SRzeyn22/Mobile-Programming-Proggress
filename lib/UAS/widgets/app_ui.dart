import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Ikon di tengah kotak rounded dengan latar lembut (gaya menu layanan).
class IconBox extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;
  final double radius;
  final Color background;
  final Color color;

  const IconBox(
    this.icon, {
    super.key,
    this.size = 44,
    this.iconSize = 24,
    this.radius = 14,
    this.background = kSoftSeafoam,
    this.color = kOcean,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}

/// Badge/chip kecil berwarna. Bila [onTap] diisi, chip bisa diketuk.
class PillChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;

  const PillChip({
    super.key,
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 15, color: foreground),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
