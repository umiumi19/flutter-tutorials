class AppConfig {
  static const env = String.fromEnvironment('ENV', defaultValue: 'local');
  static const apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://localhost:8080',
  );
}
