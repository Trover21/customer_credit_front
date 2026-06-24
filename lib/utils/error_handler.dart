import 'dart:io';
import 'package:flutter/material.dart';

class ErrorHandler {
  static void showSnackBar(BuildContext context, dynamic error) {
    final str = error.toString();
    String message = str.replaceAll('Exception: ', '');

    if (error is SocketException ||
        str.contains('SocketException') ||
        str.contains('ClientException') ||
        str.contains('Failed host lookup') ||
        str.contains('No address associated with hostname') ||
        str.contains('Connection refused') ||
        str.contains('Connection timed out') ||
        str.contains('Network is unreachable')) {
      message = 'No internet connection or server not found. Please check your connection and try again.';
    } else if (error is FormatException ||
        str.contains('FormatException') ||
        str.contains('Unexpected character')) {
      message = 'Invalid response from server. Please verify the backend server is running and the API URL is correct.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }
}
