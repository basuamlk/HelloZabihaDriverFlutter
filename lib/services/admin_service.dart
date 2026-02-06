import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'auth_service.dart';

/// Service for managing admin access to dev mode features.
/// Admin users can access developer tools even in production builds.
///
/// Configure admin emails in .env file:
/// ADMIN_EMAILS=email1@example.com,email2@example.com
class AdminService {
  static final AdminService instance = AdminService._internal();
  AdminService._internal();

  /// Get admin emails from environment variable
  List<String> get _adminEmails {
    final emails = dotenv.env['ADMIN_EMAILS'] ?? '';
    if (emails.isEmpty) return [];
    return emails.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  /// Check if the current user has admin privileges
  bool get isAdmin {
    final user = AuthService.instance.currentUser;
    if (user == null) return false;

    final email = user.email?.toLowerCase();
    if (email == null) return false;

    return _adminEmails.any((admin) => admin.toLowerCase() == email);
  }

  /// Check if a specific email has admin privileges
  bool isAdminEmail(String email) {
    return _adminEmails.any((admin) => admin.toLowerCase() == email.toLowerCase());
  }
}
