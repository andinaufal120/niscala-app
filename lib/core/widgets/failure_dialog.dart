import 'package:flutter/material.dart';

/// Shows why an action failed. The dialog stays until the user closes it.
Future<void> showFailureDialog(
  BuildContext context, {
  required String title,
  required String message,
}) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: Text(title),
    content: Text(message),
    actions: [
      FilledButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Mengerti'),
      ),
    ],
  ),
);
