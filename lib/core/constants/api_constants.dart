class ApiConstants {
  static const String baseUrl =
      'https://35916813-9406-48c9-9f9a-7b8d7186c2f5-00-2el52dy6a2wi8.picard.replit.dev';

  static const String apiPath = '/api';
  static String get apiBase => '$baseUrl$apiPath';
  static String get socketUrl => baseUrl;

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
