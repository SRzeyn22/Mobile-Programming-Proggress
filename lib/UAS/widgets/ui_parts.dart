import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Ikon di dalam kotak rounded dengan latar Seafoam lembut (gaya menu layanan).
class IconTile extends StatelessWidget {
  final IconData icon;
  final double size;
  final double radius;
  final Color background;
  final Color color;

  const IconTile({
    super.key,
    required this.icon,
    this.size = 52,
    this.radius = 16,
    this.background = kWantBackground,
    this.color = kWantForeground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

/// Chip kecil berlatar lembut (status, tombol Detail, dsb).
class SoftChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;

  const SoftChip({
    super.key,
    required this.icon,
    required this.label,
    this.background = kWantBackground,
    this.foreground = kWantForeground,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: foreground),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return chip;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: chip,
      ),
    );
  }
}
