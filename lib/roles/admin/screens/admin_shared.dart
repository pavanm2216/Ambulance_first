import 'package:flutter/material.dart';
import '../theme/admin_theme.dart';

String money(dynamic value) {
  final n = value is num ? value.toDouble() : double.tryParse('$value') ?? 0.0;
  return '₹${n.toStringAsFixed(2)}';
}

String titleCase(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .map((e) => e.isEmpty ? e : '${e[0].toUpperCase()}${e.substring(1).toLowerCase()}')
      .join(' ');
}

void showStitchToast(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      backgroundColor: isError ? StitchTheme.error : StitchTheme.inverseSurface,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(StitchTheme.radiusSm)),
      margin: const EdgeInsets.only(bottom: 80, left: 24, right: 24),
      duration: const Duration(seconds: 3),
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            size: 18,
            color: isError ? Colors.white : StitchTheme.tertiaryFixed,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: StitchTheme.labelMd(color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );
}
