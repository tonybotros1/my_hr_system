class AppConfig {
  AppConfig._();

  /// Override at build/run time with:
  /// `--dart-define=BACKEND_URL=https://your-api.example.com`
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'http://192.168.1.10:8000',
  );

  static const Duration requestTimeout = Duration(seconds: 20);

  static Uri endpoint(String path) {
    final base = backendBaseUrl.endsWith('/')
        ? backendBaseUrl.substring(0, backendBaseUrl.length - 1)
        : backendBaseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$base$normalizedPath');
  }
}
