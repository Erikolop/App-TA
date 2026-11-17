class Config {
  Config._();

  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://ta-iot.vercel.app/api',
  );
}
