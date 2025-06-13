class SubscriptionHistory {
  final int id;
  final int userId;
  final String subscriptionType;
  final String billingCycle;
  final String status;
  final int remainingPlaces;
  final double amount;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SubscriptionHistory({
    required this.id,
    required this.userId,
    required this.subscriptionType,
    required this.billingCycle,
    required this.status,
    required this.remainingPlaces,
    required this.amount,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    this.updatedAt,
  });

  factory SubscriptionHistory.fromJson(Map<String, dynamic> json) {
    return SubscriptionHistory(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      subscriptionType: json['subscriptionType'] ?? '',
      billingCycle: json['billingCycle'] ?? '',
      status: json['status'] ?? '',
      remainingPlaces: json['remainingPlaces'] ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      startDate: DateTime.parse(json['startDate'] ?? DateTime.now().toIso8601String()),
      endDate: DateTime.parse(json['endDate'] ?? DateTime.now().toIso8601String()),
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'subscriptionType': subscriptionType,
      'billingCycle': billingCycle,
      'status': status,
      'remainingPlaces': remainingPlaces,
      'amount': amount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  bool get isActive => status == 'ACTIVE';
  bool get isExpired => status == 'EXPIRED' || status == 'CANCELLED';
  bool get canDelete => !isActive;
}

