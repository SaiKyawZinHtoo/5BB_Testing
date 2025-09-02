import 'package:flutter/material.dart';

/// Lightweight helper to show modern floating snacks across the app.
/// Use `showAppSnack(context, 'Message', type: SnackType.success, actionLabel: 'UNDO', onAction: () { ... });`

enum SnackType { success, error, info }

void showAppSnack(
  BuildContext context,
  String message, {
  SnackType type = SnackType.info,
  String? actionLabel,
  VoidCallback? onAction,
  Duration? duration,
}) {
  final color = {
    SnackType.success: Colors.green[600],
    SnackType.error: Colors.redAccent[700],
    SnackType.info: Colors.grey[850],
  }[type]!;
  final icon = {
    SnackType.success: Icons.check_circle_outline,
    SnackType.error: Icons.error_outline,
    SnackType.info: Icons.info_outline,
  }[type]!;

  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      elevation: 6,
      duration: duration ?? const Duration(seconds: 3),
      backgroundColor: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      content: Row(
        children: [
          Icon(icon, color: Colors.white70),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
      action: actionLabel != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: Colors.white,
              onPressed: onAction ?? () {},
            )
          : null,
    ),
  );
}
