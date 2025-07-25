import 'package:flutter/material.dart';

Future<bool?> showConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  IconData icon = Icons.help_outline,
  String confirmText = 'Yes',
  String cancelText = 'No',
  Color? confirmColor,
}) {
  final theme = Theme.of(context);
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(icon, color: confirmColor ?? theme.colorScheme.primary, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      content: Text(message, style: theme.textTheme.bodyLarge),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(cancelText, style: theme.textTheme.labelLarge),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor ?? theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmText, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimary)),
        ),
      ],
    ),
  );
} 