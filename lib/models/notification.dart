class ParkingNotification {
  final int id;
  final String type;
  final String message;
  final DateTime createdAt;
  bool isRead;
  final Map<String, dynamic>? action;

  ParkingNotification({
    required this.id,
    required this.type,
    required this.message,
    required this.createdAt,
    required this.isRead,
    this.action,
  });

  factory ParkingNotification.fromJson(Map<String, dynamic> json) {
    return ParkingNotification(
      id: json['id'] as int,
      type: json['type'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isRead: json['isRead'] as bool,
      action: json['action'] != null ? Map<String, dynamic>.from(json['action'] as Map) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'action': action,
    };
  }
}