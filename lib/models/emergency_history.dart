class EmergencyHistory {
  final String id;
  final DateTime timestamp;
  final int sentCount;
  final int failedCount;
  final int totalContacts;
  final bool locationAvailable;
  final double? latitude;
  final double? longitude;
  final String status;
  final String? errorMessage;

  EmergencyHistory({
    required this.id,
    required this.timestamp,
    required this.sentCount,
    required this.failedCount,
    required this.totalContacts,
    required this.locationAvailable,
    this.latitude,
    this.longitude,
    required this.status,
    this.errorMessage,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'sentCount': sentCount,
      'failedCount': failedCount,
      'totalContacts': totalContacts,
      'locationAvailable': locationAvailable,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'errorMessage': errorMessage,
    };
  }

  factory EmergencyHistory.fromJson(
    Map<String, dynamic> json,
  ) {
    return EmergencyHistory(
      id: json['id'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      sentCount: json['sentCount'] ?? 0,
      failedCount: json['failedCount'] ?? 0,
      totalContacts: json['totalContacts'] ?? 0,
      locationAvailable:
          json['locationAvailable'] ?? false,
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      status: json['status'] ?? 'FAILED',
      errorMessage: json['errorMessage'],
    );
  }
}