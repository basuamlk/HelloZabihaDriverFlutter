import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized error handling utility
class ErrorHandler {
  /// Convert any exception to a user-friendly message
  static String getUserMessage(dynamic error) {
    if (error is AuthException) {
      return _getAuthErrorMessage(error);
    }

    if (error is PostgrestException) {
      return _getPostgrestErrorMessage(error);
    }

    if (error is SocketException) {
      return 'No internet connection. Please check your network.';
    }

    if (error is TimeoutException) {
      return 'Request timed out. Please try again.';
    }

    if (error is FormatException) {
      return 'Invalid data received. Please try again.';
    }

    if (error is Exception) {
      final message = error.toString();
      if (message.contains('SocketException') ||
          message.contains('Connection refused')) {
        return 'Unable to connect to server. Please check your internet.';
      }
      if (message.contains('timeout')) {
        return 'Request timed out. Please try again.';
      }
    }

    return 'Something went wrong. Please try again.';
  }

  static String _getAuthErrorMessage(AuthException error) {
    final message = error.message.toLowerCase();

    if (message.contains('invalid login credentials') ||
        message.contains('invalid email or password')) {
      return 'Invalid email or password. Please try again.';
    }

    if (message.contains('email not confirmed')) {
      return 'Please verify your email address before logging in.';
    }

    if (message.contains('user not found')) {
      return 'No account found with this email.';
    }

    if (message.contains('email already registered') ||
        message.contains('user already registered')) {
      return 'An account with this email already exists.';
    }

    if (message.contains('weak password')) {
      return 'Password is too weak. Please use a stronger password.';
    }

    if (message.contains('rate limit') || message.contains('too many requests')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }

    return error.message;
  }

  static String _getPostgrestErrorMessage(PostgrestException error) {
    final code = error.code;
    final message = error.message.toLowerCase();

    if (code == '23505' || message.contains('duplicate')) {
      return 'This record already exists.';
    }

    if (code == '23503' || message.contains('foreign key')) {
      return 'Cannot complete this action due to related data.';
    }

    if (code == '42501' || message.contains('permission denied')) {
      return 'You do not have permission to perform this action.';
    }

    if (message.contains('relation') && message.contains('does not exist')) {
      return 'Database configuration error. Please contact support.';
    }

    return 'Database error. Please try again.';
  }

  /// Show error snackbar
  static void showError(BuildContext context, dynamic error) {
    final message = getUserMessage(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Show success snackbar
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Show info snackbar
  static void showInfo(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.blue[700],
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
