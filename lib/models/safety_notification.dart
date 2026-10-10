class SafetyNotification {
  final String id;
  final DateTime timestamp;
  final String title;
  final String message;
  final String type;
  final bool isRead;

  SafetyNotification({
    required this.id,
    required this.timestamp,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
  });

  SafetyNotification copyWith({
    bool? isRead,
  }) {
    return SafetyNotification(
      id: id,
      timestamp: timestamp,
      title: title,
      message: message,
      type: type,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'title': title,
      'message': message,
      'type': type,
      'isRead': isRead,
    };
  }

  factory SafetyNotification.fromJson(
    Map<String, dynamic> json,
  ) {
    return SafetyNotification(
      id: json['id'] ?? '',
      timestamp: DateTime.tryParse(
            json['timestamp'] ?? '',
          ) ??
          DateTime.now(),
      title: json['title'] ?? 'Safety Alert',
      message: json['message'] ?? '',
      type: json['type'] ?? 'info',
      isRead: json['isRead'] ?? false,
    );
  }
}