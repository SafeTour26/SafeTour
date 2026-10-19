class SafetyZone {
  final String id;
  final String areaName;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final double dayScore;
  final double nightScore;
  final double overallScore;
  final int crowdRating;
  final int lightingRating;
  final String safetyTips;
  final DateTime? updatedAt;

  const SafetyZone({
    required this.id,
    required this.areaName,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 1000,
    required this.dayScore,
    required this.nightScore,
    required this.overallScore,
    required this.crowdRating,
    required this.lightingRating,
    required this.safetyTips,
    this.updatedAt,
  });

  factory SafetyZone.fromJson(Map<String, dynamic> json) {
    return SafetyZone(
      id: json['id']?.toString() ?? json['area_name']?.toString() ?? '',
      areaName: json['area_name'] as String? ?? 'Unknown Area',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusMeters: json['radius_meters'] != null
          ? (json['radius_meters'] as num).toInt()
          : 1000,
      dayScore: (json['day_score'] as num).toDouble(),
      nightScore: (json['night_score'] as num).toDouble(),
      overallScore: (json['overall_score'] as num).toDouble(),
      crowdRating: json['crowd_rating'] != null
          ? (json['crowd_rating'] as num).toInt()
          : 5,
      lightingRating: json['lighting_rating'] != null
          ? (json['lighting_rating'] as num).toInt()
          : 7,
      safetyTips: json['safety_tips'] as String? ?? '',
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'area_name': areaName,
      'latitude': latitude,
      'longitude': longitude,
      'radius_meters': radiusMeters,
      'day_score': dayScore,
      'night_score': nightScore,
      'overall_score': overallScore,
      'crowd_rating': crowdRating,
      'lighting_rating': lightingRating,
      'safety_tips': safetyTips,
    };
  }
}
