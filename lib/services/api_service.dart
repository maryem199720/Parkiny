import 'dart:convert';
import 'package:http/http.dart' as http;

// API Service Classes
class ApiService {
  // Base URL as a static constant that could be configured from environment
  static const String baseUrl = "http://10.0.2.2:8082/parking";
  static const String apiPrefix = "/api";

  // Headers for API requests
  static Map<String, String> getHeaders(String token) {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Error handling helper
  static Map<String, dynamic> handleError(dynamic error) {
    return {
      'success': false,
      'message': 'Error connecting to server: $error',
    };
  }

  // Response parsing helper
  static Map<String, dynamic> parseResponse(http.Response response) {
    try {
      final data = json.decode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Request failed with status: ${response.statusCode}',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error parsing response: $e',
      };
    }
  }
}

class SubscriptionService {
  static Future<Subscription?> getActiveSubscription(int userId, String? token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}${ApiService.apiPrefix}/user/$userId/subscription'),
        headers: ApiService.getHeaders(token ?? ''),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Subscription.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error fetching subscription: $e');
      return null;
    }
  }
}

class VehicleService {
  static Future<List<Vehicle>> getUserVehicles(String? token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}${ApiService.apiPrefix}/user/profile'),
        headers: ApiService.getHeaders(token ?? ''),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final vehiclesData = data['vehicles'] as List? ?? [];
        return vehiclesData.map((v) => Vehicle.fromJson(v)).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching vehicles: $e');
      return [];
    }
  }
}

class ParkingService {
  static Future<List<ParkingSpot>> getAvailableSpots({
    required String date,
    required String startTime,
    required String endTime,
    required String token,
  }) async {
    final url = Uri.parse('${ApiService.baseUrl}${ApiService.apiPrefix}/parking-spots/available')
        .replace(queryParameters: {
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
    });

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => ParkingSpot.fromJson(json)).toList();
    } else {
      throw Exception('Failed to fetch available spots: ${response.statusCode}');
    }
  }
}
class ReservationService {
  static Future<ReservationResponse?> createReservation(
      ReservationRequest request,
      String? token,
      ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}${ApiService.apiPrefix}/reservations'),
        headers: ApiService.getHeaders(token ?? ''),
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return ReservationResponse.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error creating reservation: $e');
      return null;
    }
  }
}

class PaymentService {
  static Future<PaymentResponse?> processPayment(
      PaymentRequest request,
      String? token,
      ) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}${ApiService.apiPrefix}/payments'),
        headers: ApiService.getHeaders(token ?? ''),
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PaymentResponse.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error processing payment: $e');
      return null;
    }
  }
}

// Updated Data Models with JSON serialization
class ParkingSpot {
  final String id;
  final String type;
  final double price;
  final String status;
  final List<String> features;
  final bool available;

  ParkingSpot({
    required this.id,
    required this.type,
    required this.price,
    required this.status,
    required this.features,
    required this.available,
  });

  factory ParkingSpot.fromJson(Map<String, dynamic> json) {
    return ParkingSpot(
      id: json['id'] ?? '',
      type: json['type'] ?? 'standard',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'available',
      features: List<String>.from(json['features'] ?? []),
      available: json['available'] ?? true,
    );
  }
}

class Vehicle {
  final String id;
  final String matricule;
  final String vehicleType;
  final String name;
  final String? brand;
  final String? model;

  Vehicle({
    required this.id,
    required this.matricule,
    required this.vehicleType,
    required this.name,
    this.brand,
    this.model,
  });

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    final brand = json['brand']?.toString() ?? '';
    final model = json['model']?.toString() ?? '';
    final name = '$brand $model'.trim().isNotEmpty ? '$brand $model' : json['matricule'] ?? 'Vehicle';
    return Vehicle(
      id: json['id'].toString(),
      matricule: (json['matricule']?.toString() ?? 'UNKNOWN').toUpperCase(),
      vehicleType: (json['vehicleType']?.toString() ?? 'CAR').toUpperCase(),
      name: name,
      brand: brand.isNotEmpty ? brand : null,
      model: model.isNotEmpty ? model : null,
    );
  }
}

class Subscription {
  final int id;
  final int userId;
  final String subscriptionType;
  final String billingCycle;
  final String status;
  final int remainingPlaces;
  final String? endDate;

  Subscription({
    required this.id,
    required this.userId,
    required this.subscriptionType,
    required this.billingCycle,
    required this.status,
    required this.remainingPlaces,
    this.endDate,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      subscriptionType: json['subscriptionType'] ?? '',
      billingCycle: json['billingCycle'] ?? '',
      status: json['status'] ?? '',
      remainingPlaces: json['remainingPlaces'] ?? 0,
      endDate: json['endDate']?.toString(),
    );
  }
}

class ReservationRequest {
  final int userId;
  final int parkingPlaceId;
  final String matricule;
  final String startTime;
  final String endTime;
  final String vehicleType;
  final String paymentMethod;
  final String email;
  final int? subscriptionId;
  final String? specialRequest;

  ReservationRequest({
    required this.userId,
    required this.parkingPlaceId,
    required this.matricule,
    required this.startTime,
    required this.endTime,
    required this.vehicleType,
    required this.paymentMethod,
    required this.email,
    this.subscriptionId,
    this.specialRequest,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'parkingPlaceId': parkingPlaceId,
      'matricule': matricule,
      'startTime': startTime,
      'endTime': endTime,
      'vehicleType': vehicleType,
      'paymentMethod': paymentMethod,
      'email': email,
      if (subscriptionId != null) 'subscriptionId': subscriptionId,
      if (specialRequest != null) 'specialRequest': specialRequest,
    };
  }
}

class ReservationResponse {
  final String reservationId;
  final String? paymentVerificationCode;
  final String? reservationConfirmationCode;
  final String? message;

  ReservationResponse({
    required this.reservationId,
    this.paymentVerificationCode,
    this.reservationConfirmationCode,
    this.message,
  });

  factory ReservationResponse.fromJson(Map<String, dynamic> json) {
    return ReservationResponse(
      reservationId: json['reservationId']?.toString() ?? '',
      paymentVerificationCode: json['paymentVerificationCode']?.toString(),
      reservationConfirmationCode: json['reservationConfirmationCode']?.toString(),
      message: json['message']?.toString(),
    );
  }
}

class PaymentRequest {
  final int reservationId;
  final double amount;
  final String paymentMethod;
  final String paymentReference;
  final Map<String, String> cardDetails;

  PaymentRequest({
    required this.reservationId,
    required this.amount,
    required this.paymentMethod,
    required this.paymentReference,
    required this.cardDetails,
  });

  Map<String, dynamic> toJson() {
    return {
      'reservationId': reservationId,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'paymentReference': paymentReference,
      'cardDetails': cardDetails,
    };
  }
}

class PaymentResponse {
  final bool success;
  final String? transactionId;
  final String? message;

  PaymentResponse({
    required this.success,
    this.transactionId,
    this.message,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      success: json['success'] ?? false,
      transactionId: json['transactionId']?.toString(),
      message: json['message']?.toString(),
    );
  }
}

// Storage Service for token management
class StorageService {
  static String? _token;
  static int? _userId;
  static Map<String, dynamic>? _user;

  static String? getToken() => _token;
  static int? getUserId() => _userId;
  static Map<String, dynamic>? getUser() => _user;

  static void setToken(String token) => _token = token;
  static void setUserId(int userId) => _userId = userId;
  static void setUser(Map<String, dynamic> user) => _user = user;

  static bool isLoggedIn() => _token != null && _userId != null;

  static void logout() {
    _token = null;
    _userId = null;
    _user = null;
  }
}



extension StringExtension on String {
  String padStart(int length, String pad) {
    if (this.length >= length) {
      return this;
    }
    return pad * (length - this.length) + this;
  }
}