class EmergencyContact {
  final String? id;
  final String userId;
  final String contactName;
  final String contactEmail;
  final String? contactPhone;
  final String? relationship;
  final DateTime? createdAt;

  EmergencyContact({
    this.id,
    required this.userId,
    String? contactName,
    String? name,
    this.contactEmail = '',
    String? contactPhone,
    String? phoneNumber,
    this.relationship,
    this.createdAt,
  })  : contactName = contactName ?? name ?? '',
        contactPhone = contactPhone ?? phoneNumber;

  String get name => contactName;
  String get phoneNumber => contactPhone ?? '';

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString() ?? '',
      contactName: json['contact_name'] as String? ?? '',
      contactEmail: json['contact_email'] as String? ?? '',
      contactPhone: json['contact_phone'] as String?,
      relationship: json['relationship'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'contact_name': contactName,
      'contact_email':
          contactEmail.isNotEmpty ? contactEmail : 'contact@safetour.local',
      if (contactPhone != null) 'contact_phone': contactPhone,
    };
  }
}
