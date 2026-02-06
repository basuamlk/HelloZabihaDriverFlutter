import 'auth_service.dart';

/// Service for managing admin access to dev mode features.
/// Admin users can access developer tools even in production builds.
class AdminService {
  static final AdminService instance = AdminService._internal();
  AdminService._internal();

  /// List of email addresses with admin access.
  /// Add your email here to enable dev mode features.
  static const List<String> _adminEmails = [
    // Add admin emails here (case-insensitive)
    'basu@example.com', // Replace with your actual email
  ];

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
