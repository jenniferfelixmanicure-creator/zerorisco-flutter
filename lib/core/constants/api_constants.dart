class ApiConstants {
  static const String supabaseUrl =
      'https://ttwbuvnbyxqifztofunx.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
      '.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR0d2J1dm5ieXhxaWZ6dG9mdW54'
      'Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA1MTU3OTMsImV4cCI6MjA5NjA5'
      'MTc5M30.91eH-1zVq1RWSsRaAD_t8tZ1ltC815Ni1Re0nZA6iIw';

  static const String baseUrl = 'https://saquadrive.onrender.com';
  static const String apiPath = '/api';
  static String get apiBase => '$baseUrl$apiPath';
  static String get socketUrl => baseUrl;

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
