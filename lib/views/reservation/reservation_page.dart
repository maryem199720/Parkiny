import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:smart_parking/core/constants.dart';
import 'package:path_provider/path_provider.dart';
import '../../services/api_service.dart';


class ReservationsPage extends StatefulWidget {
  const ReservationsPage({Key? key}) : super(key: key);

  @override
  State<ReservationsPage> createState() => _ReservationsPageState();
}

class _ReservationsPageState extends State<ReservationsPage> {
  final _storage = const FlutterSecureStorage();
  // Form controllers
  final _dateController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _emailController = TextEditingController();
  final _cardNameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();
  final _verificationCodeController = TextEditingController();

  // Form keys
  final _reservationFormKey = GlobalKey<FormState>();
  final _paymentFormKey = GlobalKey<FormState>();

  // State variables
  int currentStep = 1;
  bool isLoading = false;
  bool hasActiveSubscription = false;
  String? subscriptionId;
  String? subscriptionEndDate;
  int remainingPlaces = 0;
  String errorMessage = '';
  bool isReservationConfirmed = false;
  String? reservationId;
  String? qrCodeString;
  ParkingSpot? selectedSpot;
  int? selectedVehicleIndex;
  List<Vehicle> userVehicles = [];
  List<ParkingSpot> availableSpots = [];
  double totalAmount = 0.0;
  bool emailConfirmation = true;
  bool saveCard = false;
  Subscription? subscription;

  @override
  void initState() {
    super.initState();
    _initializeDefaultValues();
    _loadTokenAndFetchData();
  }

  Future<void> _loadTokenAndFetchData() async {
    setState(() => isLoading = true);
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Token non trouvé');
      }
      final userId = await _storage.read(key: 'user_id');
      if (userId == null) {
        await _fetchUserProfile(token);
        if (StorageService.getUserId() == null) throw Exception('User ID not found');
      } else {
        StorageService.setUserId(int.parse(userId));
      }
      StorageService.setToken(token);

      await _fetchUserVehicles(token); // Ensure this completes first
      await _checkSubscriptionStatus(token); // Then this
      await _checkSpotAvailability(); // Then this

      if (userVehicles.isEmpty) {
        setState(() => errorMessage = 'Veuillez ajouter un véhicule dans votre profil.');
      }
    } catch (e) {
      if (mounted) {
        setState(() => errorMessage = 'Erreur lors du chargement des données : $e');
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _initializeDefaultValues() {
    final now = DateTime.now();
    final startTime = now.add(const Duration(minutes: 10));
    final endTime = startTime.add(const Duration(hours: 1));

    _dateController.text = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
    _startTimeController.text = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    _endTimeController.text = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    _emailController.text = 'user@example.com'; // This should come from user profile
  }

  @override
  void dispose() {
    _dateController.dispose();
    _startTimeController.dispose();
    _endTimeController.dispose();
    _emailController.dispose();
    _cardNameController.dispose();
    _cardNumberController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Réservations',
          style: TextStyle(
            color: AppColors.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.whiteColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textColor),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildSubscriptionBanner(),
              const SizedBox(height: 24),
              _buildProgressBar(),
              const SizedBox(height: 24),
              if (errorMessage.isNotEmpty) _buildErrorMessage(errorMessage),
              _buildCurrentStep(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'Réservez avec Parkiny',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textColor,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Réservez votre place de parking en quelques étapes simples.',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.subtitleColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSubscriptionBanner() {
    if (hasActiveSubscription) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryColor.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.verified,
              color: AppColors.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Abonnement Premium (ID: $subscriptionId)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppColors.textColor,
                    ),
                  ),
                  Text(
                    'Valide jusqu\'au $subscriptionEndDate | $remainingPlaces/10 places restantes',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primaryColor.withOpacity(0.2),
          ),
        ),
        child: Center(
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: AppColors.subtitleColor),
              children: [
                const TextSpan(text: 'Vous n\'avez pas d\'abonnement actif. '),
                TextSpan(
                  text: 'Souscrire maintenant',
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        Row(
          children: [
            _buildStepIndicator(1, 'Choix de la place'),
            _buildProgressLine(currentStep >= 2),
            _buildStepIndicator(2, 'Détails'),
            _buildProgressLine(currentStep >= 3),
            _buildStepIndicator(3, hasActiveSubscription ? 'Vérification' : 'Paiement'),
            _buildProgressLine(currentStep >= 4),
            _buildStepIndicator(4, 'Confirmation'),
          ],
        ),
      ],
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = currentStep >= step;
    final isCompleted = currentStep > step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppColors.primaryColor : AppColors.whiteColor,
              border: Border.all(
                color: isActive ? AppColors.primaryColor : AppColors.grayColor,
                width: 2,
              ),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(
                Icons.check,
                color: AppColors.whiteColor,
                size: 16,
              )
                  : Text(
                step.toString(),
                style: TextStyle(
                  color: isActive ? AppColors.whiteColor : AppColors.subtitleColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: AppColors.subtitleColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressLine(bool isCompleted) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isCompleted ? AppColors.primaryColor : AppColors.grayColor,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.errorColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: AppColors.errorColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppColors.errorColor,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (currentStep) {
      case 1:
        return _buildSpotSelectionStep();
      case 2:
        return _buildReservationDetailsStep();
      case 3:
        return _buildPaymentVerificationStep();
      case 4:
        return _buildConfirmationStep();
      default:
        return _buildSpotSelectionStep();
    }
  }

  Future<void> _fetchUserProfile(String token) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}${ApiService.apiPrefix}/user/profile'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        StorageService.setUserId(data['id']);
        userVehicles = (data['vehicles'] as List? ?? []).map((v) => Vehicle.fromJson(v)).toList();
      });
    } else if (response.statusCode == 401) {
      await _storage.delete(key: 'auth_token');
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      throw Exception('Échec de la récupération du profil : ${response.statusCode}');
    }
  }

  Future<void> _fetchUserVehicles(String token) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}${ApiService.apiPrefix}/user/profile'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 10));

    print('Vehicles Response Status: ${response.statusCode}');
    print('Vehicles Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        userVehicles = (data['vehicles'] as List? ?? []).map((v) => Vehicle.fromJson(v)).toList();
      });
    } else if (response.statusCode == 401) {
      await _storage.delete(key: 'auth_token');
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      throw Exception('Échec de la récupération des véhicules : ${response.statusCode}');
    }
  }

  Future<void> _checkSubscriptionStatus(String token) async {
    final userId = StorageService.getUserId();
    if (userId == null) throw Exception('User ID not found');

    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}${ApiService.apiPrefix}/subscriptions/active?userId=$userId'),
      headers: {'Authorization': 'Bearer $token'},
    ).timeout(const Duration(seconds: 10));

    print('Subscription Response Status: ${response.statusCode}');
    print('Subscription Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        hasActiveSubscription = (data['status'] as String?)?.toUpperCase() == 'ACTIVE';
        subscription = hasActiveSubscription ? Subscription.fromJson(data) : null;
        if (subscription != null) {
          subscriptionId = subscription!.id.toString();
          subscriptionEndDate = subscription!.endDate;
          remainingPlaces = subscription!.remainingPlaces;
        } else {
          subscriptionId = null;
          subscriptionEndDate = null;
          remainingPlaces = 0;
        }
      });
    } else if (response.statusCode == 404) {
      setState(() {
        hasActiveSubscription = false;
        subscription = null;
        subscriptionId = null;
        subscriptionEndDate = null;
        remainingPlaces = 0;
      });
    } else {
      throw Exception('Échec de la vérification de l\'abonnement : ${response.statusCode}');
    }
  }
  Future<String?> _getToken() async {
    return await _storage.read(key: 'auth_token');
  }
  Future<void> _checkSpotAvailability() async {
    final startTime = _startTimeController.text;
    final endTime = _endTimeController.text;
    final dateText = _dateController.text;

    if (startTime.isEmpty || endTime.isEmpty || dateText.isEmpty) {
      if (mounted) {
        setState(() => availableSpots = []);
      }
      return;
    }

    if (mounted) {
      setState(() => isLoading = true);
    }

    try {
      final token = await _getToken();
      if (token == null) {
        throw Exception('No authentication token available. Please log in.');
      }

      final dateParts = dateText.split('/');
      if (dateParts.length != 3) throw Exception('Invalid date format');
      final formattedDate = '${dateParts[2]}-${dateParts[1]}-${dateParts[0]}';

      final formattedStartTime = startTime.padLeft(5, '0');
      final formattedEndTime = endTime.padLeft(5, '0');

      final uri = Uri.parse('${ApiService.baseUrl}${ApiService.apiPrefix}/parking-spots/available')
          .replace(queryParameters: {
        'date': formattedDate,
        'startTime': formattedStartTime,
        'endTime': formattedEndTime,
        if (hasActiveSubscription) 'subscriptionId': subscriptionId,
      });

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('Délai de connexion dépassé. Veuillez réessayer.');
      });

      if (response.statusCode == 200) {
        final List<dynamic> spots = json.decode(response.body);
        if (spots.isEmpty) {
          if (mounted) {
            setState(() {
              availableSpots = [];
              isLoading = false;
            });
          }
          return;
        }

        if (mounted) {
          setState(() {
            availableSpots = spots.map((spot) {
              if (spot['id'] == null || spot['available'] == null) {
                throw Exception('Données de place de parking incomplètes: $spot');
              }
              final spotId = spot['id'].toString();
              final isSubscriptionSpot = hasActiveSubscription && spotId.startsWith('S');
              return ParkingSpot(
                id: spotId,
                type: spot['type'] ?? 'standard',
                price: isSubscriptionSpot ? 0.0 : (spot['price'] as num?)?.toDouble() ?? 0.0,
                status: spot['available'] == true ? 'available' : 'reserved',
                features: List<String>.from(spot['features'] ?? []),
                available: spot['available'] ?? true,
              );
            }).toList();
            isLoading = false;
          });
        }
      } else {
        throw Exception('Erreur API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          availableSpots = [];
          errorMessage = 'Erreur: $e. Veuillez vérifier votre connexion ou réessayer plus tard.';
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e. Réessayez.'),
            backgroundColor: AppColors.errorColor,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _formatDateForBackend(String dateText) {
    final parts = dateText.split('/');
    if (parts.length == 3) {
      return dateText; // Return as "dd/MM/yyyy" without reformatting
    }
    return dateText;
  }

  Future<void> _submitReservation() async {
    if (!_reservationFormKey.currentState!.validate() || selectedSpot == null || selectedVehicleIndex == null) {
      setState(() {
        errorMessage = 'Veuillez compléter tous les champs requis.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final userId = StorageService.getUserId();
      final token = StorageService.getToken();

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final dateValue = _dateController.text;
      final startTime = _startTimeController.text;
      final endTime = _endTimeController.text;
      final vehicleMatricule = userVehicles[selectedVehicleIndex!].matricule;
      final email = _emailController.text;

      final parkingPlaceId = int.parse(selectedSpot!.id);
      final formattedDate = _formatDateForBackend(dateValue);

      final startTimeParts = startTime.split(':');
      final endTimeParts = endTime.split(':');
      if (startTimeParts.length == 2 && endTimeParts.length == 2) {
        final formattedStartTime = '${startTimeParts[0].padLeft(2, '0')}:${startTimeParts[1].padLeft(2, '0')}';
        final formattedEndTime = '${endTimeParts[0].padLeft(2, '0')}:${endTimeParts[1].padLeft(2, '0')}';

        final startDateTime = DateTime.parse('2025-${formattedDate.split('/')[1]}-${formattedDate.split('/')[0]}T$formattedStartTime:00');
        final endDateTime = DateTime.parse('2025-${formattedDate.split('/')[1]}-${formattedDate.split('/')[0]}T$formattedEndTime:00');

        // Format without milliseconds and timezone
        final formattedStartTimeString = startDateTime.toIso8601String().split('.')[0]; // e.g., "2025-06-12T11:28:00"
        final formattedEndTimeString = endDateTime.toIso8601String().split('.')[0];     // e.g., "2025-06-12T12:28:00"

        final request = ReservationRequest(
          userId: userId,
          parkingPlaceId: parkingPlaceId,
          matricule: vehicleMatricule,
          startTime: formattedStartTimeString,
          endTime: formattedEndTimeString,
          vehicleType: userVehicles[selectedVehicleIndex!].vehicleType,
          paymentMethod: hasActiveSubscription && totalAmount == 0 ? 'SUBSCRIPTION' : 'CARTE_BANCAIRE',
          email: email,
          subscriptionId: hasActiveSubscription ? int.tryParse(subscriptionId ?? '') : null,
          specialRequest: '',
        );

        // Debug: Log the request details
        final requestJson = json.encode(request.toJson());
        print('Request URL: ${ApiService.baseUrl}${ApiService.apiPrefix}/createReservation');
        print('Request Body: $requestJson');

        final httpResponse = await ReservationService.createReservation(request, token);

        // Debug: Log the raw response
        print('Response Status: ${httpResponse.statusCode}');
        print('Response Body: ${httpResponse.body}');

        if (httpResponse.statusCode == 200 || httpResponse.statusCode == 201) {
          final response = ReservationResponse.fromJson(json.decode(httpResponse.body));
          if (response.reservationId.isNotEmpty) {
            setState(() {
              reservationId = response.reservationId.replaceAll('RES-', '');
              emailConfirmation = true;

              if (response.reservationConfirmationCode != null) {
                _verificationCodeController.text = response.reservationConfirmationCode!;
              }

              currentStep = 3;
              isLoading = false;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(hasActiveSubscription
                    ? 'Réservation créée. Vérifiez votre email pour le code de confirmation.'
                    : 'Réservation créée. Veuillez procéder au paiement.'),
                backgroundColor: AppColors.successColor,
              ),
            );
          } else {
            throw Exception('Aucune ID de réservation retournée dans la réponse: ${response.toString()}');
          }
        } else {
          throw Exception('Échec de la requête: Statut ${httpResponse.statusCode}, Body: ${httpResponse.body}');
        }
      } else {
        throw Exception('Format d\'heure invalide.');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Erreur lors de la réservation: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la réservation: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );

      // Debug: Log the full exception
      print('Exception: $e');
    }
  }

  Future<void> _submitPayment() async {
    if (hasActiveSubscription && totalAmount == 0) {
      setState(() {
        currentStep = 4;
        qrCodeString = 'RES-${reservationId ?? '123456'}';
      });
      return;
    }

    if (!_paymentFormKey.currentState!.validate() || reservationId == null) {
      setState(() {
        errorMessage = 'Veuillez compléter les informations de paiement.';
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final token = StorageService.getToken();

      final request = PaymentRequest(
        reservationId: int.parse(reservationId!),
        amount: totalAmount,
        paymentMethod: 'CARTE_BANCAIRE',
        paymentReference: _cardNumberController.text.replaceAll(' ', '').substring(12),
        cardDetails: {
          'cardName': _cardNameController.text,
          'cardNumber': _cardNumberController.text.replaceAll(' ', ''),
          'cardExpiry': _cardExpiryController.text,
          'cardCvv': _cardCvvController.text,
        },
      );

      final response = await PaymentService.processPayment(request, token);

      if (response != null && response.success) {
        setState(() {
          currentStep = 4;
          qrCodeString = 'RES-$reservationId';
          isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paiement effectué avec succès!'),
            backgroundColor: AppColors.successColor,
          ),
        );
      } else {
        throw Exception(response?.message ?? 'Échec du paiement');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Erreur lors du paiement: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du paiement'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  void _calculateTotalAmount() {
    if (selectedSpot == null || _startTimeController.text.isEmpty || _endTimeController.text.isEmpty) {
      setState(() {
        totalAmount = 0.0;
      });
      return;
    }

    final startParts = _startTimeController.text.split(':');
    final endParts = _endTimeController.text.split(':');

    if (startParts.length != 2 || endParts.length != 2) return;

    final startHours = int.tryParse(startParts[0]) ?? 0;
    final startMinutes = int.tryParse(startParts[1]) ?? 0;
    final endHours = int.tryParse(endParts[0]) ?? 0;
    final endMinutes = int.tryParse(endParts[1]) ?? 0;

    final durationHours = (endHours + endMinutes / 60) - (startHours + startMinutes / 60);
    final basePrice = selectedSpot!.price;
    double cost = durationHours * basePrice;

    if (hasActiveSubscription && remainingPlaces > 0) {
      cost = 0;
    } else if (durationHours > 5) {
      cost *= 0.9; // 10% discount for long reservations
    }

    setState(() {
      totalAmount = cost > 0 ? double.parse(cost.toStringAsFixed(2)) : 0.0;
    });
  }

  void _selectSpot(ParkingSpot spot) {
    if (spot.status == 'available') {
      setState(() {
        selectedSpot = spot;
      });
      _calculateTotalAmount();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cette place est déjà réservée.'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  void _selectVehicle(int index) {
    setState(() {
      selectedVehicleIndex = index;
    });
  }

  void _nextStep() {
    if (currentStep == 2) {
      _submitReservation();
    } else if (currentStep == 3) {
      if (hasActiveSubscription) {
        if (_verificationCodeController.text.isNotEmpty) {
          setState(() {
            currentStep = 4;
            qrCodeString = 'RES-${reservationId ?? '123456'}';
          });
        }
      } else {
        _submitPayment();
      }
    } else if (currentStep < 4) {
      setState(() {
        currentStep++;
        errorMessage = '';
      });
    }
  }

  void _prevStep() {
    if (currentStep > 1) {
      setState(() {
        currentStep--;
        errorMessage = '';
      });
    }
  }

  void _reset() {
    setState(() {
      currentStep = 1;
      selectedSpot = null;
      selectedVehicleIndex = null;
      errorMessage = '';
      totalAmount = 0.0;
      userVehicles.clear();
      availableSpots.clear();
      hasActiveSubscription = false;
      subscriptionId = null;
      subscriptionEndDate = null;
      remainingPlaces = 0;
      subscription = null;
    });
    _initializeDefaultValues();
    _loadTokenAndFetchData();
  }

  Widget _buildSpotSelectionStep() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Choix de la place',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 20),
          _buildSpotTypeLegend(),
          const SizedBox(height: 20),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
              ),
            )
          else if (availableSpots.isEmpty)
            _buildNoSpotsAvailable()
          else
            _buildParkingMap(),
          const SizedBox(height: 20),
          if (selectedSpot != null) _buildSelectedPlaceDetails(),
          const SizedBox(height: 20),
          _buildStepNavigationButtons(
            onReset: _reset,
            onNext: selectedSpot != null ? _nextStep : null,
            showBack: false,
          ),
          const SizedBox(height: 16),
          _buildSpotLegend(),
        ],
      ),
    );
  }

  Widget _buildSpotTypeLegend() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildLegendItem(AppColors.whiteColor, 'Standard (5 TND/h)'),
          const SizedBox(width: 12),
          _buildLegendItem(AppColors.deepPurple, 'Premium (8 TND/h)'),
          const SizedBox(width: 12),
          _buildLegendItem(AppColors.grayColor, 'Réservé'),
          const SizedBox(width: 12),
          _buildLegendItem(AppColors.pastelPurple, 'Incluse dans abonnement'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(
              color: AppColors.secondaryColor,
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.subtitleColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildParkingMap() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: availableSpots.length,
      itemBuilder: (context, index) {
        final spot = availableSpots[index];
        return _buildParkingSpot(spot);
      },
    );
  }

  Widget _buildParkingSpot(ParkingSpot spot) {
    final isSelected = selectedSpot?.id == spot.id;
    final isAvailable = spot.status == 'available';
    final isPremium = spot.type == 'premium';
    final isIncluded = hasActiveSubscription && spot.id.startsWith('S');

    Color backgroundColor;
    if (isSelected) {
      backgroundColor = AppColors.primaryColor.withOpacity(0.1);
    } else if (!isAvailable) {
      backgroundColor = AppColors.grayColor;
    } else if (isIncluded) {
      backgroundColor = AppColors.pastelPurple;
    } else if (isPremium) {
      backgroundColor = AppColors.deepPurple;
    } else {
      backgroundColor = AppColors.whiteColor;
    }

    return GestureDetector(
      onTap: isAvailable ? () => _selectSpot(spot) : null,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : AppColors.secondaryColor,
            width: isSelected ? 3 : 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AppIcons.vehicle,
              color: isAvailable ? AppColors.textColor : AppColors.subtitleColor,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              spot.id,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isAvailable ? AppColors.textColor : AppColors.subtitleColor,
              ),
            ),
            Text(
              _getSpotStatusText(spot),
              style: TextStyle(
                fontSize: 10,
                color: isAvailable ? AppColors.textColor : AppColors.subtitleColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getSpotStatusText(ParkingSpot spot) {
    if (spot.status == 'reserved') return 'Réservé';
    if (hasActiveSubscription && spot.id.startsWith('S')) return 'Incluse';
    return '${spot.price.toStringAsFixed(0)} TND/h';
  }

  Widget _buildNoSpotsAvailable() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.sentiment_dissatisfied,
            color: AppColors.subtitleColor,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune place disponible.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.subtitleColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedPlaceDetails() {
    if (selectedSpot == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Détails de la place',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.location_on, 'Place', selectedSpot!.id),
          _buildDetailRow(AppIcons.vehicle, 'Type', selectedSpot!.type),
          _buildDetailRow(
            Icons.monetization_on,
            'Tarif',
            hasActiveSubscription && selectedSpot!.id.startsWith('S')
                ? 'Incluse'
                : '${selectedSpot!.price.toStringAsFixed(0)} TND/h',
          ),
          _buildDetailRow(Icons.star, 'Avantages', selectedSpot!.features.join(', ')),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primaryColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textColor,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpotLegend() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _buildSmallLegendItem(AppColors.primaryColor.withOpacity(0.1), 'Sélectionné'),
        _buildSmallLegendItem(AppColors.whiteColor, 'Disponible (${_getAvailableSpotCount()})'),
        _buildSmallLegendItem(AppColors.grayColor, 'Réservé'),
        _buildSmallLegendItem(AppColors.deepPurple, 'Premium'),
        _buildSmallLegendItem(AppColors.pastelPurple, 'Incluse'),
      ],
    );
  }

  Widget _buildSmallLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(
              color: AppColors.secondaryColor,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.subtitleColor,
          ),
        ),
      ],
    );
  }

  int _getAvailableSpotCount() {
    return availableSpots.where((spot) => spot.status == 'available').length;
  }

  Widget _buildReservationDetailsStep() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Form(
        key: _reservationFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Détails de la réservation',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.textColor,
              ),
            ),
            const SizedBox(height: 20),
            _buildDateTimeFields(),
            const SizedBox(height: 20),
            _buildEmailField(),
            const SizedBox(height: 20),
            _buildVehicleSelection(),
            const SizedBox(height: 20),
            _buildStepNavigationButtons(
              onBack: _prevStep,
              onNext: _isReservationFormValid() ? _nextStep : null,
              showBack: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeFields() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInputField(
                controller: _dateController,
                label: 'Date de réservation',
                icon: Icons.calendar_today,
                hintText: 'jj/MM/aaaa',
                validator: _validateDate,
                onTap: () => _selectDate(context),
                readOnly: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildInputField(
                controller: _startTimeController,
                label: 'Heure de début',
                icon: Icons.access_time,
                hintText: 'HH:mm',
                validator: _validateStartTime,
                onTap: () => _selectTime(context, _startTimeController),
                readOnly: true,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildInputField(
                controller: _endTimeController,
                label: 'Heure de fin',
                icon: Icons.access_time,
                hintText: 'HH:mm',
                validator: _validateEndTime,
                onTap: () => _selectTime(context, _endTimeController),
                readOnly: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return _buildInputField(
      controller: _emailController,
      label: 'Email',
      icon: Icons.email,
      hintText: 'votre@email.com',
      validator: _validateEmail,
      keyboardType: TextInputType.emailAddress,
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hintText,
    String? Function(String?)? validator,
    VoidCallback? onTap,
    bool readOnly = false,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          onTap: onTap,
          readOnly: readOnly,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: Icon(icon, color: AppColors.primaryColor),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.grayColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.secondaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.errorColor),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: (value) {
            _calculateTotalAmount();
          },
        ),
      ],
    );
  }

  Widget _buildVehicleSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sélectionnez votre véhicule',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textColor,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.grayColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: userVehicles.isEmpty
              ? _buildNoVehiclesMessage()
              : Column(
            children: userVehicles.asMap().entries.map((entry) {
              final index = entry.key;
              final vehicle = entry.value;
              return _buildVehicleItem(vehicle, index);
            }).toList(),
          ),
        ),
      ],
    );
  }
  Widget _buildQRCodeSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grayColor),
      ),
      child: Column(
        children: [
          const Text(
            'Code QR de réservation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.grayColor),
            ),
            child: Center(
              child: reservationId != null
                  ? QrImageView(
                data: 'RES-$reservationId',
                version: QrVersions.auto,
                size: 180.0,
              )
                  : const Text(
                'Génération du QR en cours...',
                style: TextStyle(color: AppColors.subtitleColor),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Présentez ce code QR à l\'entrée du parking',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.subtitleColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _downloadQRCode() async {
    if (reservationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune réservation pour télécharger le QR code.'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    if (await Permission.storage.request().isGranted) {
      try {
        final directory = await getApplicationDocumentsDirectory(); // Use getApplicationDocumentsDirectory
        if (directory == null) {
          throw Exception('Impossible de trouver le répertoire de stockage.');
        }

        final filePath = '${directory.path}/reservation_qr_${reservationId}.png';
        final qrImage = await QrPainter(
          data: 'RES-$reservationId',
          version: QrVersions.auto,
          gapless: false,
        ).toImage(200);
        final byteData = await qrImage.toByteData(format: ImageByteFormat.png);
        if (byteData == null) {
          throw Exception('Échec de la génération de l\'image QR.');
        }

        final file = File(filePath);
        await file.writeAsBytes(byteData.buffer.asUint8List());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR Code téléchargé avec succès à $filePath'),
            backgroundColor: AppColors.successColor,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du téléchargement: $e'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permission de stockage refusée.'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  Widget _buildConfirmationStep() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.successColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              color: AppColors.successColor,
              size: 64,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Réservation confirmée !',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Votre place de parking a été réservée avec succès.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.subtitleColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _buildQRCodeSection(),
          const SizedBox(height: 32),
          _buildConfirmationDetails(),
          const SizedBox(height: 32),
          _buildConfirmationActions(),
        ],
      ),
    );
  }
  Widget _buildVehicleItem(Vehicle vehicle, int index) {
    final isSelected = selectedVehicleIndex == index;
    final isLast = index == userVehicles.length - 1;

    return GestureDetector(
      onTap: () => _selectVehicle(index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor.withOpacity(0.1) : AppColors.whiteColor,
          border: isLast ? null : const Border(
            bottom: BorderSide(color: AppColors.grayColor),
          ),
          borderRadius: isLast
              ? const BorderRadius.only(
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(8),
          )
              : index == 0
              ? const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              AppIcons.vehicle,
              color: AppColors.primaryColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textColor,
                    ),
                  ),
                  Text(
                    vehicle.matricule,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.subtitleColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primaryColor,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoVehiclesMessage() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            AppIcons.vehicle,
            color: AppColors.subtitleColor,
            size: 32,
          ),
          const SizedBox(height: 8),
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: AppColors.subtitleColor,
              ),
              children: [
                const TextSpan(text: 'Aucun véhicule. '),
                TextSpan(
                  text: 'Ajoutez un véhicule',
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    decoration: TextDecoration.underline,
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentVerificationStep() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          hasActiveSubscription ? _buildVerificationForm() : _buildPaymentForm(),
          if (!hasActiveSubscription) ...[
            const SizedBox(height: 24),
            _buildSummarySection(),
          ],
        ],
      ),
    );
  }

  Widget _buildVerificationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vérification de la réservation',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppColors.textColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Un code de vérification a été envoyé à ${_emailController.text}.',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.subtitleColor,
          ),
        ),
        const SizedBox(height: 20),
        _buildInputField(
          controller: _verificationCodeController,
          label: 'Code de Vérification',
          icon: Icons.security,
          hintText: 'Entrez le code',
          validator: _validateVerificationCode,
        ),
        if (!emailConfirmation) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: AppColors.errorColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Échec de l\'envoi de l\'email',
                    style: TextStyle(
                      color: AppColors.errorColor,
                      fontSize: 14,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _resendConfirmation,
                  child: const Text(
                    'Renvoyer',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        _buildStepNavigationButtons(
          onBack: _prevStep,
          onNext: _verificationCodeController.text.isNotEmpty ? _nextStep : null,
          showBack: true,
          nextLabel: 'Vérifier',
          nextIcon: Icons.check,
        ),
      ],
    );
  }

  Widget _buildPaymentForm() {
    return Form(
      key: _paymentFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Paiement',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 20),
          _buildInputField(
            controller: _cardNameController,
            label: 'Nom sur la carte',
            icon: Icons.person,
            hintText: 'Ex: Jean Dupont',
            validator: _validateCardName,
          ),
          const SizedBox(height: 16),
          _buildCardNumberField(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInputField(
                  controller: _cardExpiryController,
                  label: 'Date d\'expiration',
                  icon: Icons.calendar_today,
                  hintText: 'MM/AAAA',
                  validator: _validateCardExpiry,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildInputField(
                  controller: _cardCvvController,
                  label: 'CVV',
                  icon: Icons.help_outline,
                  hintText: '123',
                  validator: _validateCardCvv,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: saveCard,
                onChanged: (value) {
                  setState(() {
                    saveCard = value ?? false;
                  });
                },
                activeColor: AppColors.primaryColor,
              ),
              Expanded(
                child: Text(
                  'Sauvegarder cette carte pour mes prochains paiements',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.subtitleColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStepNavigationButtons(
            onBack: _prevStep,
            onNext: _isPaymentFormValid() ? _nextStep : null,
            showBack: true,
            nextLabel: 'Payer',
            nextIcon: Icons.payment,
          ),
        ],
      ),
    );
  }

  Widget _buildCardNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Numéro de carte',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _cardNumberController,
          validator: _validateCardNumber,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(16),
            _CardNumberInputFormatter(),
          ],
          decoration: InputDecoration(
            hintText: 'XXXX XXXX XXXX XXXX',
            prefixIcon: const Icon(Icons.credit_card, color: AppColors.primaryColor),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.credit_card, color: Colors.blue[600], size: 20),
                const SizedBox(width: 4),
                Icon(Icons.credit_card, color: Colors.orange[600], size: 20),
                const SizedBox(width: 8),
              ],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.grayColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.secondaryColor, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.errorColor),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildSummarySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.whiteColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grayColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Récapitulatif',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Réservation',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textColor,
                      ),
                    ),
                    Text(
                      '${totalAmount.toStringAsFixed(2)} TND',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Détails :',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                if (selectedSpot != null) ...[
                  _buildSummaryDetailRow(Icons.location_on, 'Place', selectedSpot!.id),
                  _buildSummaryDetailRow(AppIcons.vehicle, 'Type', selectedSpot!.type),
                  _buildSummaryDetailRow(Icons.access_time, 'Durée', _getDurationText()),
                  _buildSummaryDetailRow(Icons.calendar_today, 'Date', _dateController.text),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primaryColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.subtitleColor,
            ),
          ),
        ],
      ),
    );
  }

  String _getDurationText() {
    if (_startTimeController.text.isEmpty || _endTimeController.text.isEmpty) {
      return 'N/A';
    }

    final startParts = _startTimeController.text.split(':');
    final endParts = _endTimeController.text.split(':');

    if (startParts.length != 2 || endParts.length != 2) return 'N/A';

    final startHours = int.tryParse(startParts[0]) ?? 0;
    final startMinutes = int.tryParse(startParts[1]) ?? 0;
    final endHours = int.tryParse(endParts[0]) ?? 0;
    final endMinutes = int.tryParse(endParts[1]) ?? 0;

    final durationHours = (endHours + endMinutes / 60) - (startHours + startMinutes / 60);

    if (durationHours >= 1) {
      return '${durationHours.toStringAsFixed(1)}h';
    } else {
      return '${(durationHours * 60).toStringAsFixed(0)}min';
    }
  }



  Widget _buildConfirmationDetails() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Détails de la réservation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildConfirmationDetailRow(
            Icons.confirmation_number,
            'ID de réservation',
            reservationId ?? 'RES-123456',
          ),
          _buildConfirmationDetailRow(
            Icons.location_on,
            'Place de parking',
            selectedSpot?.id ?? 'N/A',
          ),
          _buildConfirmationDetailRow(
            Icons.calendar_today,
            'Date',
            _dateController.text,
          ),
          _buildConfirmationDetailRow(
            Icons.access_time,
            'Heure',
            '${_startTimeController.text} - ${_endTimeController.text}',
          ),
          _buildConfirmationDetailRow(
            AppIcons.vehicle,
            'Véhicule',
            selectedVehicleIndex != null
                ? '${userVehicles[selectedVehicleIndex!].name} (${userVehicles[selectedVehicleIndex!].matricule})'
                : 'N/A',
          ),
          _buildConfirmationDetailRow(
            Icons.email,
            'Email de confirmation',
            _emailController.text,
          ),
          if (!hasActiveSubscription)
            _buildConfirmationDetailRow(
              Icons.payment,
              'Montant payé',
              '${totalAmount.toStringAsFixed(2)} TND',
            ),
        ],
      ),
    );
  }

  Widget _buildConfirmationDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.subtitleColor,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _downloadQRCode,
            icon: const Icon(Icons.download),
            label: const Text('Télécharger le QR Code'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: AppColors.whiteColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _shareReservation,
            icon: const Icon(Icons.share),
            label: const Text('Partager'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primaryColor,
              side: const BorderSide(color: AppColors.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: _newReservation,
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle réservation'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.secondaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepNavigationButtons({
    VoidCallback? onBack,
    VoidCallback? onNext,
    VoidCallback? onReset,
    bool showBack = true,
    String? nextLabel,
    IconData? nextIcon,
  }) {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.grayColor),
        ),
      ),
      child: Row(
        children: [
          if (onReset != null) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onReset,
                icon: const Icon(Icons.refresh),
                label: const Text('Réinitialiser'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondaryColor,
                  side: const BorderSide(color: AppColors.secondaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          if (showBack && onBack != null) ...[
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.secondaryColor,
                  side: const BorderSide(color: AppColors.secondaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onNext,
              icon: Icon(nextIcon ?? Icons.arrow_forward),
              label: Text(nextLabel ?? 'Suivant'),
              style: ElevatedButton.styleFrom(
                backgroundColor: onNext != null ? AppColors.primaryColor : AppColors.grayColor,
                foregroundColor: AppColors.whiteColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

extension ReservationsPageValidation on _ReservationsPageState {
  String? _validateDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date requise';
    }

    final parts = value.split('/');
    if (parts.length != 3) {
      return 'Format: jj/MM/aaaa';
    }

    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);

    if (day == null || month == null || year == null) {
      return 'Date invalide';
    }

    final date = DateTime(year, month, day);
    final today = DateTime.now();

    if (date.isBefore(DateTime(today.year, today.month, today.day))) {
      return 'Date doit être aujourd\'hui ou après';
    }

    return null;
  }

  String? _validateStartTime(String? value) {
    if (value == null || value.isEmpty) {
      return 'Heure requise';
    }

    final parts = value.split(':');
    if (parts.length != 2) {
      return 'Format invalide';
    }

    final hours = int.tryParse(parts[0]);
    final minutes = int.tryParse(parts[1]);

    if (hours == null || minutes == null || hours < 0 || hours > 23 || minutes < 0 || minutes > 59) {
      return 'Heure invalide';
    }

    final dateText = _dateController.text;
    if (dateText.isNotEmpty) {
      final dateParts = dateText.split('/');
      if (dateParts.length == 3) {
        final day = int.tryParse(dateParts[0]);
        final month = int.tryParse(dateParts[1]);
        final year = int.tryParse(dateParts[2]);

        if (day != null && month != null && year != null) {
          final selectedDate = DateTime(year, month, day);
          final today = DateTime.now();

          if (selectedDate.year == today.year &&
              selectedDate.month == today.month &&
              selectedDate.day == today.day) {
            final selectedTime = DateTime(year, month, day, hours, minutes);
            final oneHourFromNow = DateTime.now().add(const Duration(hours: 1));

            if (selectedTime.isBefore(oneHourFromNow)) {
              return 'Heure doit être dans 1h minimum';
            }
          }
        }
      }
    }

    return null;
  }

  String? _validateEndTime(String? value) {
    if (value == null || value.isEmpty) {
      return 'Heure requise';
    }

    final parts = value.split(':');
    if (parts.length != 2) {
      return 'Format invalide';
    }

    final hours = int.tryParse(parts[0]);
    final minutes = int.tryParse(parts[1]);

    if (hours == null || minutes == null || hours < 0 || hours > 23 || minutes < 0 || minutes > 59) {
      return 'Heure invalide';
    }

    final startTimeText = _startTimeController.text;
    if (startTimeText.isNotEmpty) {
      final startParts = startTimeText.split(':');
      if (startParts.length == 2) {
        final startHours = int.tryParse(startParts[0]);
        final startMinutes = int.tryParse(startParts[1]);

        if (startHours != null && startMinutes != null) {
          final startTotalMinutes = startHours * 60 + startMinutes;
          final endTotalMinutes = hours * 60 + minutes;

          if (endTotalMinutes <= startTotalMinutes) {
            return 'Doit être après le début';
          }
        }
      }
    }

    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email requis';
    }

    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email invalide';
    }

    return null;
  }

  String? _validateCardName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Nom requis';
    }
    return null;
  }

  String? _validateCardNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Numéro requis';
    }

    final cleanValue = value.replaceAll(' ', '');
    if (cleanValue.length != 16) {
      return 'Doit être 16 chiffres';
    }

    return null;
  }

  String? _validateCardExpiry(String? value) {
    if (value == null || value.isEmpty) {
      return 'Date requise';
    }

    final parts = value.split('/');
    if (parts.length != 2) {
      return 'Format invalide, ex: 07/2029';
    }

    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);

    if (month == null || year == null || month < 1 || month > 12) {
      return 'Format invalide, ex: 07/2029';
    }

    final currentDate = DateTime.now();
    final expiryDate = DateTime(year, month);

    if (expiryDate.isBefore(DateTime(currentDate.year, currentDate.month))) {
      return 'Carte expirée';
    }

    return null;
  }

  String? _validateCardCvv(String? value) {
    if (value == null || value.isEmpty) {
      return 'CVV requis';
    }

    if (value.length != 3) {
      return 'Doit être 3 chiffres';
    }

    return null;
  }

  String? _validateVerificationCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'Code requis';
    }
    return null;
  }

  bool _isReservationFormValid() {
    return _reservationFormKey.currentState?.validate() ?? false && selectedVehicleIndex != null;
  }

  bool _isPaymentFormValid() {
    return _paymentFormKey.currentState?.validate() ?? false;
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: AppColors.whiteColor,
              surface: AppColors.whiteColor,
              onSurface: AppColors.textColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
      _checkSpotAvailability();
      _calculateTotalAmount();
    }
  }

  Future<void> _selectTime(BuildContext context, TextEditingController controller) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryColor,
              onPrimary: AppColors.whiteColor,
              surface: AppColors.whiteColor,
              onSurface: AppColors.textColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        controller.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
      _checkSpotAvailability();
      _calculateTotalAmount();
    }
  }


  void _shareReservation() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Partage de la réservation...'),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }

  void _newReservation() {
    _reset();
  }

  void _resendConfirmation() {
    setState(() {
      emailConfirmation = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Code de vérification renvoyé'),
        backgroundColor: AppColors.successColor,
      ),
    );
  }
}