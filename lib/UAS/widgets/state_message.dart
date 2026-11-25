import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tampilan untuk kondisi kosong / error / informasi pada sebuah halaman.
class StateMessage extends StatelessWidget {
  final IconData icon;

  /// Ilustrasi opsional; bila diisi, menggantikan [icon] di bagian atas.
  final Widget? illustration;
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onPressed;

  const StateMessage({
    super.key,
    required this.icon,
    this.illustration,
    required this.title,
    required this.message,
    this.buttonText,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final label = buttonText;
    final action = onPressed;
    final content = Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          illustration ?? Icon(icon, size: 48, color: kOcean),
          SizedBox(height: illustration == null ? 12 : 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kDeepTeal,
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: kTextSecondary, height: 1.4),
          ),
          if (label != null && action != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: action, child: Text(label)),
          ],
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // Di dalam ListView (tinggi tak terbatas) cukup dipusatkan; pada tinggi
        // terbatas konten dipusatkan dan dapat digulir agar tidak overflow
        // (mis. layar pendek / mode landscape).
        if (!constraints.hasBoundedHeight) return Center(child: content);
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: content),
          ),
        );
      },
    );
  }
}
