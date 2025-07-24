// Environment configuration for different deployment environments
class Environment {
  static const String _environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static const String _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000',
  );

  // Current environment
  static String get environment => _environment;

  // API Configuration
  static String get apiBaseUrl => _apiBaseUrl;
  static String get pdfEndpoint => '$apiBaseUrl/api/pdfs';

  // Environment checks
  static bool get isDevelopment => _environment == 'development';
  static bool get isStaging => _environment == 'staging';
  static bool get isProduction => _environment == 'production';

  // PDF Service Configuration
  static Map<String, String> get apiHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Timeout configurations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);

  // Cache configuration
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSize = 100 * 1024 * 1024; // 100MB

  // Debug configuration
  static bool get enableLogging => isDevelopment || isStaging;
  static bool get enableCaching => true;

  // Environment-specific configurations
  static Map<String, dynamic> get config => {
    'development': {
      'apiBaseUrl': 'http://localhost:3000',
      'enableMockData': false,  // Use real API in development
      'cacheEnabled': false,
    },
    'staging': {
      'apiBaseUrl': 'https://api-staging.epaper.example.com',
      'enableMockData': false,
      'cacheEnabled': true,
    },
    'production': {
      'apiBaseUrl': 'https://api.epaper.example.com',
      'enableMockData': false,
      'cacheEnabled': true,
    },
  }[_environment] ?? {};

  // Get environment-specific value
  static T getConfigValue<T>(String key, T defaultValue) {
    return config[key] as T? ?? defaultValue;
  }
}
