class Reservation {
  final int id;
  final int userId;
  final int parkingPlaceId;
  final String matricule;
  final String startTime;
  final String endTime;
  final String vehicleType;
  final String paymentMethod;
  final String status;
  final double amount;
  final String? qrCode;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Reservation({
    required this.id,
    required this.userId,
    required this.parkingPlaceId,
    required this.matricule,
    required this.startTime,
    required this.endTime,
    required this.vehicleType,
    required this.paymentMethod,
    required this.status,
    required this.amount,
    this.qrCode,
    required this.createdAt,
    this.updatedAt,
  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      parkingPlaceId: json['parkingPlaceId'] ?? 0,
      matricule: json['matricule'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      vehicleType: json['vehicleType'] ?? '',
      paymentMethod: json['paymentMethod'] ?? '',
      status: json['status'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      qrCode: json['qrCode'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'parkingPlaceId': parkingPlaceId,
      'matricule': matricule,
      'startTime': startTime,
      'endTime': endTime,
      'vehicleType': vehicleType,
      'paymentMethod': paymentMethod,
      'status': status,
      'amount': amount,
      'qrCode': qrCode,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  bool get isActive => status == 'ACTIVE' || status == 'CONFIRMED';
  bool get isExpired => status == 'EXPIRED' || status == 'COMPLETED';
  bool get canModify => isActive && DateTime.parse(startTime).isAfter(DateTime.now().add(Duration(hours: 1)));
}

