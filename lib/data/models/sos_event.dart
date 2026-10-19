class SOSEvent {
  final String id;
  final String userId;
  final double latitude;
  final double longitude;
  final String status;
  final DateTime triggeredAt;

  const SOSEvent({
    required this.id,
    required this.userId,
    required this.latitude,
    required this.longitude,
    this.status = 'active',
    required this.triggeredAt,
  });

  factory SOSEvent.fromJson(Map<String, dynamic> json) {
    return SOSEvent(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      status: json['status'] as String? ?? 'active',
      triggeredAt: json['triggered_at'] != null
          ? DateTime.tryParse(json['triggered_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
    };
  }
}
