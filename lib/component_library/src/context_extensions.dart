import 'package:flutter/material.dart';

extension BuildContextExtensions on BuildContext {
  void showErrorPrompt(String message) {
    showDialog(
      context: this,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
