class AppConstants {
  static const String appName = 'SafeTour';
  static const String appTagline = 'Bengaluru Personal Safety Radar';

  // Bengaluru Map defaults (Central coordinates)
  static const double defaultLatitude = 12.9716;
  static const double defaultLongitude = 77.5946;
  static const double defaultZoom = 13.0;

  // Tile Provider - OpenStreetMap with Dark Filter (100% free, zero watermark, zero API key)
  static const String mapTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String mapTileFallbackUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const List<String> mapSubdomains = ['a', 'b', 'c'];

  // Bengaluru Emergency Helplines
  static const String policeEmergency = '112';
  static const String womenHelpline = '1091';
  static const String policeControlRoom = '100';
  static const String cyberCrimeHelpline = '1930';
  static const String ambulanceEmergency = '108';
  static const String trafficHelpline = '1095';
}
