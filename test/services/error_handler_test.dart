import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hello_zabiha_driver/utils/error_handler.dart';

void main() {
  group('ErrorHandler', () {
    group('getUserMessage', () {
      test('returns friendly message for SocketException', () {
        final error = const SocketException('Connection refused');
        expect(
          ErrorHandler.getUserMessage(error),
          'No internet connection. Please check your network.',
        );
      });

      test('returns friendly message for TimeoutException', () {
        final error = TimeoutException('Request timed out');
        expect(
          ErrorHandler.getUserMessage(error),
          'Request timed out. Please try again.',
        );
      });

      test('returns friendly message for FormatException', () {
        const error = FormatException('Invalid JSON');
        expect(
          ErrorHandler.getUserMessage(error),
          'Invalid data received. Please try again.',
        );
      });

      test('returns generic message for unknown exceptions', () {
        final error = Exception('Unknown error');
        expect(
          ErrorHandler.getUserMessage(error),
          'Something went wrong. Please try again.',
        );
      });

      test('returns friendly message for connection refused', () {
        final error = Exception('SocketException: Connection refused');
        expect(
          ErrorHandler.getUserMessage(error),
          'Unable to connect to server. Please check your internet.',
        );
      });

      test('returns friendly message for timeout in message', () {
        final error = Exception('Request timeout occurred');
        expect(
          ErrorHandler.getUserMessage(error),
          'Request timed out. Please try again.',
        );
      });
    });

    group('Auth errors', () {
      test('handles invalid credentials', () {
        final error = AuthException('Invalid login credentials');
        expect(
          ErrorHandler.getUserMessage(error),
          'Invalid email or password. Please try again.',
        );
      });

      test('handles email not confirmed', () {
        final error = AuthException('Email not confirmed');
        expect(
          ErrorHandler.getUserMessage(error),
          'Please verify your email address before logging in.',
        );
      });

      test('handles rate limiting', () {
        final error = AuthException('Too many requests');
        expect(
          ErrorHandler.getUserMessage(error),
          'Too many attempts. Please wait a moment and try again.',
        );
      });
    });
  });
}
