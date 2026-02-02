import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = 'https://xdatjvzwjevqqugynkyf.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InhkYXRqdnp3amV2cXF1Z3lua3lmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY2Nzg0NTEsImV4cCI6MjA4MjI1NDQ1MX0.RKGGAqHjxzJR3T2TPldomGJGBdhbAB9DEBJT9WlPIPg';

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }
}
