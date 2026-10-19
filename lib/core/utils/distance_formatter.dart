import 'dart:math';

class DistanceFormatter {
  /// Calculates distance in meters between two lat/lng points using Haversine formula
  static double calculateDistanceMeters(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const p = 0.017453292519943295; // Math.PI / 180
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000; // 2 * R; R = 6371 km
  }

  static String formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m away';
    } else {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)} km away';
    }
  }
}
