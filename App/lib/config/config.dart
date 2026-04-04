/// Application Configuration
class AppConfig {
  /// Toggle for Mock Data Mode.
  /// When true: Connects to realistic mock services.
  /// When false: Connects to the real Firebase & FastAPI backend.
  static const bool useMockData = false;

  /// The base URL of the backend API (used when useMockData == false)
  static const String apiBaseUrl = 'http://localhost:8000';

  // Useful constants for simulated delays in mock services.
  static const Duration mockNetworkDelay = Duration(milliseconds: 1500);
}
