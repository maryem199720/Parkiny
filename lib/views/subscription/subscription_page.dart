import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class SubscriptionPage extends StatefulWidget {
  final int? subscriptionId;

  const SubscriptionPage({super.key, this.subscriptionId});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  int currentStep = 1;
  String billingType = 'monthly';
  int? selectedPlan;
  List<Map<String, dynamic>> vehicles = [];
  List<Map<String, dynamic>> plans = [];
  bool isLoading = true;
  String? errorMessage;
  bool hasActiveSubscription = false;
  Map<String, dynamic>? activeSubscription;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _cardNameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _cvvController = TextEditingController();
  final _confirmationCodeController = TextEditingController();
  bool saveCard = true;
  String? sessionId;
  bool subscriptionConfirmed = false;
  String? userId;
  String? token;
  bool isDarkMode = false;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  DateTime? _lastButtonPressTime;

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchData();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _cardNameController.dispose();
    _cardNumberController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    _confirmationCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadTokenAndFetchData() async {
    setState(() => isLoading = true);
    try {
      token = await _storage.read(key: 'auth_token');
      if (token == null) {
        _showSnackBar('Veuillez vous connecter pour continuer.');
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      userId = await _storage.read(key: 'user_id');
      if (userId == null) {
        await _fetchUserProfile();
        if (userId == null) {
          throw Exception('User ID not found and could not be fetched.');
        } else {
          await _storage.write(key: 'user_id', value: userId);
        }
      }

      await Future.wait([
        _fetchPlans(),
        _fetchActiveSubscription(),
      ]);

      if (vehicles.isEmpty) {
        await _fetchUserProfile(); // Retry fetching profile if vehicles are empty
      }

      if (widget.subscriptionId != null) {
        await _fetchSubscriptionDetails(widget.subscriptionId!);
      }

      if (vehicles.isEmpty) {
        errorMessage = 'Veuillez ajouter un véhicule dans votre profil avant de continuer.';
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur lors du chargement des données : $e';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8082/parking/api/user/profile'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      print('Profile Response Status: ${response.statusCode}');
      print('Profile Response Body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          userId = data['id'].toString();
          _emailController.text = data['email'] ?? '';
          vehicles = (data['vehicles'] as List? ?? []).map((v) => {
            'id': v['id'] ?? 0,
            'name': v['matricule'] ?? 'Inconnu',
          }).toList();
        });
      } else if (response.statusCode == 401) {
        await _storage.delete(key: 'auth_token');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        throw Exception('Échec de la récupération du profil : ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur profil : $e');
    }
  }

  Future<void> _fetchPlans() async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8082/parking/api/subscription-plans'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          plans = data.map((plan) {
            final monthlyPrice = (plan['monthlyPrice'] as num?)?.toDouble() ?? 0.0;
            return {
              'id': plan['id'] ?? 0,
              'name': plan['type'] ?? 'Inconnu',
              'monthlyPrice': monthlyPrice,
              'annualPrice': monthlyPrice * 12 * 0.8,
              'features': [
                'Accès à tous les parkings',
                (plan['parkingDurationLimit'] ?? 0) > 0
                    ? '${plan['parkingDurationLimit']} heures de stationnement par jour'
                    : 'Stationnement illimité',
                'Réservation ${plan['advanceReservationDays'] ?? 0} jour${(plan['advanceReservationDays'] ?? 0) != 1 ? 's' : ''} à l\'avance',
                if (plan['hasPremiumSpots'] == true) 'Accès aux places premium',
                if (plan['hasValetService'] == true) 'Service de voiturier inclus',
              ],
              'excludedFeatures': [
                if (plan['hasPremiumSpots'] != true) 'Places premium',
                if (plan['hasValetService'] != true) 'Service de voiturier',
              ],
              'isPopular': plan['isPopular'] ?? false,
            };
          }).toList();
          selectedPlan = plans.firstWhere((p) => p['name'] == 'Premium', orElse: () => plans.first)['id'];
        });
      } else if (response.statusCode == 401) {
        await _storage.delete(key: 'auth_token');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        throw Exception('Échec plans : ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur plans : $e');
    }
  }

  Future<void> _fetchActiveSubscription() async {
    if (userId == null || userId!.isEmpty) {
      setState(() {
        errorMessage = 'User ID is invalid or not set.';
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8082/parking/api/subscriptions/active?userId=$userId'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          setState(() {
            hasActiveSubscription = (data['status'] as String?) == 'ACTIVE';
            activeSubscription = data;
          });
        } else {
          throw Exception('Invalid data format: Expected a Map, got ${data.runtimeType}');
        }
      } else if (response.statusCode == 404) {
        setState(() {
          hasActiveSubscription = false;
          activeSubscription = null;
        });
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        setState(() {
          errorMessage = 'Erreur abonnement actif : ${data['message'] ?? 'Requête invalide'}';
        });
      } else {
        throw Exception('Échec abonnement actif : ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Exception caught: $e'); // Debug log
      setState(() {
        errorMessage = 'Erreur abonnement actif : $e';
      });
    }
  }

  Future<void> _fetchSubscriptionDetails(int subscriptionId) async {
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8082/parking/api/subscriptions/$subscriptionId'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          selectedPlan = plans.firstWhere(
                (p) => p['name'] == data['subscriptionType'],
            orElse: () => plans.first,
          )['id'];
          billingType = data['billingCycle'] ?? 'monthly';
          hasActiveSubscription = data['status'] == 'ACTIVE';
          activeSubscription = data;
        });
      } else if (response.statusCode == 401) {
        await _storage.delete(key: 'auth_token');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        throw Exception('Échec récupération abonnement : ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur lors de la récupération des détails de l\'abonnement : $e';
      });
    }
  }

  Future<void> _initiateSubscription() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Veuillez remplir tous les champs obligatoires.');
      return;
    }

    setState(() => isLoading = true);
    try {
      final plan = plans.firstWhere((p) => p['id'] == selectedPlan);
      final amount = billingType == 'monthly' ? plan['monthlyPrice'] : plan['annualPrice'];

      final response = await http.post(
        Uri.parse(widget.subscriptionId != null
            ? 'http://10.0.2.2:8082/parking/api/subscriptions/renew'
            : 'http://10.0.2.2:8082/parking/api/subscribe'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'userId': userId,
          'subscriptionType': plan['name'],
          'billingCycle': billingType,
          'amount': amount,
          'paymentMethod': 'CARTE_BANCAIRE',
          'email': _emailController.text.trim(),
          'cardDetails': {
            'cardNumber': _cardNumberController.text,
            'expiryDate': _expiryDateController.text,
            'cvv': _cvvController.text,
            'cardName': _cardNameController.text,
            'saveCard': saveCard,
          },
          if (widget.subscriptionId != null) 'subscriptionId': widget.subscriptionId,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          sessionId = data['sessionId'] ?? data['session_id'];
          currentStep = 3;
        });
        _showSnackBar('Paiement initié. Vérifiez votre email pour le code de confirmation.');
      } else if (response.statusCode == 401) {
        await _storage.delete(key: 'auth_token');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        throw Exception('Échec initiation : ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur lors de l\'initiation : $e';
      });
      _showSnackBar('Erreur : $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _confirmSubscription() async {
    if (_confirmationCodeController.text.isEmpty) {
      _showSnackBar('Veuillez entrer le code de confirmation.');
      return;
    }

    setState(() => isLoading = true);
    try {
      final response = await http.post(
        Uri.parse(widget.subscriptionId != null
            ? 'http://10.0.2.2:8082/parking/api/subscriptions/confirm-renewal'
            : 'http://10.0.2.2:8082/parking/api/confirmSubscription'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'sessionId': sessionId,
          'paymentVerificationCode': _confirmationCodeController.text,
          if (widget.subscriptionId != null) 'subscriptionId': widget.subscriptionId,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        setState(() {
          subscriptionConfirmed = true;
        });
        await _fetchActiveSubscription();
        _showSnackBar('Abonnement confirmé avec succès !');
      } else if (response.statusCode == 401) {
        await _storage.delete(key: 'auth_token');
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        throw Exception('Échec confirmation : ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur lors de la confirmation : $e';
      });
      _showSnackBar('Erreur : $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.roboto(color: Colors.white),
        ),
        backgroundColor: Colors.grey[800],
        duration: const Duration(seconds: 5),
      ),
    );
  }

  bool _canPressButton() {
    final now = DateTime.now();
    if (_lastButtonPressTime == null ||
        now.difference(_lastButtonPressTime!).inMilliseconds > 2000) {
      _lastButtonPressTime = now;
      return true;
    }
    return false;
  }

  void _nextStep() {
    if (!_canPressButton()) return;

    if (currentStep == 1) {
      if (vehicles.isEmpty || selectedPlan == null) {
        _showSnackBar('Veuillez ajouter un véhicule et sélectionner un forfait.');
        if (vehicles.isEmpty) Navigator.pushNamed(context, '/profile');
        return;
      }
      if (hasActiveSubscription && widget.subscriptionId == null) {
        _showSnackBar('Vous avez un abonnement actif. Veuillez le gérer.');
        Navigator.pushNamed(context, '/app/user/subscriptions/manage');
        return;
      }
      setState(() => currentStep = 2);
    } else if (currentStep == 2) {
      _initiateSubscription();
    } else if (currentStep == 3) {
      _confirmSubscription();
    }
  }

  void _prevStep() {
    if (currentStep > 1) {
      setState(() {
        currentStep--;
        errorMessage = null;
        isLoading = false;
      });
    }
  }

  void _reset() {
    setState(() {
      currentStep = 1;
      selectedPlan = plans.firstWhere((p) => p['name'] == 'Premium', orElse: () => plans.first)['id'];
      billingType = 'monthly';
      _cardNameController.clear();
      _cardNumberController.clear();
      _expiryDateController.clear();
      _cvvController.clear();
      _confirmationCodeController.clear();
      saveCard = true;
      sessionId = null;
      errorMessage = null;
      isLoading = false;
      subscriptionConfirmed = false;
    });
  }

  void _toggleBillingType() {
    setState(() {
      billingType = billingType == 'monthly' ? 'annual' : 'monthly';
    });
  }

  void _selectPlan(int planId) {
    if (hasActiveSubscription && widget.subscriptionId == null) {
      _showSnackBar('Abonnement actif en cours.');
      return;
    }
    setState(() {
      selectedPlan = planId;
      errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFF6A1B9A);
    final secondaryColor = const Color(0xFFD4AF37);
    final darkColor = const Color(0xFF333333);
    final gold100 = const Color(0xFFF9F3D6);
    final gold200 = const Color(0xFFD4AF37);

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey[900] : const Color(0xFFF7FAFC),
      appBar: AppBar(
        backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDarkMode ? Colors.white : darkColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.subscriptionId != null ? 'Renouveler l\'abonnement' : 'Souscrivez à Parkiny',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : darkColor,
          ),
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF6A1B9A)))
            : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                widget.subscriptionId != null ? 'Renouveler votre abonnement' : 'Souscrivez à Parkiny',
                style: GoogleFonts.roboto(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: darkColor,
                ),
              ),
              Text(
                widget.subscriptionId != null
                    ? 'Renouvelez votre plan pour continuer à bénéficier des services.'
                    : 'Choisissez l\'offre qui correspond à vos besoins.',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              if (hasActiveSubscription)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified, color: Color(0xFF6A1B9A), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Abonnement Actif (ID: ${activeSubscription?['id']})',
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: darkColor,
                              ),
                            ),
                            Text(
                              'Valide jusqu\'au ${DateFormat('dd/MM/yyyy').format(DateTime.parse(activeSubscription?['endDate'] ?? DateTime.now().toString()))} | ${activeSubscription?['remainingPlaces']} places restantes',
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Pas d\'abonnement actif. ',
                        style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[600]),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => currentStep = 1),
                        child: Text(
                          'Souscrire maintenant',
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: primaryColor,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStepIndicator(1, 'Choix du forfait', currentStep >= 1),
                  Expanded(child: _buildProgressLine(currentStep >= 2)),
                  _buildStepIndicator(2, 'Informations', currentStep >= 2),
                  Expanded(child: _buildProgressLine(currentStep >= 3)),
                  _buildStepIndicator(3, 'Paiement', currentStep >= 3),
                ],
              ),
              const SizedBox(height: 24),

              if (errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFEE2E2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: GoogleFonts.roboto(
                            fontSize: 14,
                            color: const Color(0xFFEF4444),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (currentStep == 1) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Choix du forfait',
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: darkColor,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Mensuel',
                          style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[600]),
                        ),
                        Switch(
                          value: billingType == 'annual',
                          onChanged: (widget.subscriptionId != null || !hasActiveSubscription)
                              ? (v) => _toggleBillingType()
                              : null,
                          activeColor: primaryColor,
                          inactiveTrackColor: Colors.grey[300],
                        ),
                        Text(
                          'Annuel',
                          style: GoogleFonts.roboto(fontSize: 14, color: Colors.grey[600]),
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: gold100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '-20%',
                            style: GoogleFonts.roboto(
                              fontSize: 12,
                              color: secondaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (hasActiveSubscription && widget.subscriptionId == null)
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFEE2E2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning, color: Color(0xFFEF4444), size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Vous avez déjà un abonnement actif : ${activeSubscription?['subscriptionType']} (${activeSubscription?['billingCycle'] == 'monthly' ? 'Mensuel' : 'Annuel'}).',
                                style: GoogleFonts.roboto(
                                  fontSize: 14,
                                  color: const Color(0xFFB91C1C),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pushNamed(context, '/app/user/profile'),
                                child: Text(
                                  'Consultez les détails dans votre profil.',
                                  style: GoogleFonts.roboto(
                                    fontSize: 14,
                                    color: primaryColor,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                ...plans.map((plan) {
                  final isSelected = selectedPlan == plan['id'] &&
                      (widget.subscriptionId != null || !hasActiveSubscription);
                  return GestureDetector(
                    onTap: () => _selectPlan(plan['id']),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? primaryColor : Colors.grey[200]!,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      plan['name'],
                                      style: GoogleFonts.roboto(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: darkColor,
                                      ),
                                    ),
                                    if (plan['isPopular'])
                                      Transform.rotate(
                                        angle: 0.7854,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                                          color: gold200,
                                          child: Text(
                                            'Populaire',
                                            style: GoogleFonts.roboto(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: darkColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '${(billingType == 'monthly' ? plan['monthlyPrice'] : plan['annualPrice']).toStringAsFixed(0)} TND/${billingType == 'monthly' ? 'mois' : 'an'}',
                                  style: GoogleFonts.roboto(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: darkColor,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ...plan['features'].map<Widget>((feature) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 20,
                                        height: 20,
                                        decoration: BoxDecoration(
                                          color: gold100,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(Icons.check, size: 16, color: Color(0xFF6A1B9A)),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          feature,
                                          style: GoogleFonts.roboto(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                                ...plan['excludedFeatures'].map<Widget>((excluded) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.close, size: 20, color: Color(0xFFEF4444)),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          excluded,
                                          style: GoogleFonts.roboto(
                                            fontSize: 14,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: (widget.subscriptionId != null || !hasActiveSubscription)
                                      ? () => _selectPlan(plan['id'])
                                      : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isSelected ? primaryColor : Colors.white,
                                    foregroundColor: isSelected ? Colors.white : primaryColor,
                                    side: BorderSide(color: primaryColor),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                    minimumSize: const Size(double.infinity, 48),
                                  ),
                                  child: Text(
                                    isSelected ? 'Sélectionné' : 'Choisir ce forfait',
                                    style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _reset,
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFD1D5DB)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.refresh, size: 18, color: Color(0xFF374151)),
                            const SizedBox(width: 8),
                            Text(
                              'Réinitialiser',
                              style: GoogleFonts.roboto(fontSize: 14, color: const Color(0xFF374151)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (vehicles.isNotEmpty &&
                            selectedPlan != null &&
                            (widget.subscriptionId != null || !hasActiveSubscription))
                            ? _nextStep
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Suivant',
                              style: GoogleFonts.roboto(fontSize: 14, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (vehicles.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      children: [
                        Text(
                          'Veuillez ajouter un véhicule dans votre profil.',
                          style: GoogleFonts.roboto(fontSize: 14, color: const Color(0xFFEF4444)),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/profile'),
                          child: Text(
                            'Aller au profil',
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: primaryColor,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],

              if (currentStep == 2 && (widget.subscriptionId != null || !hasActiveSubscription))
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Méthode de paiement',
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: darkColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3E8FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: primaryColor),
                        ),
                        child: Column(
                          children: [
                            const Icon(Icons.credit_card, color: Color(0xFF6A1B9A), size: 24),
                            const SizedBox(height: 8),
                            Text(
                              'Carte bancaire',
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                color: darkColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputField(
                              controller: _emailController,
                              label: 'Email',
                              icon: Icons.email,
                              validator: (v) => !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(v!)
                                  ? 'Email invalide'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            _buildInputField(
                              controller: _cardNameController,
                              label: 'Nom sur la carte',
                              icon: Icons.person,
                              validator: (v) => v!.isEmpty ? 'Nom requis' : null,
                            ),
                            const SizedBox(height: 16),
                            _buildInputField(
                              controller: _cardNumberController,
                              label: 'Numéro de carte',
                              icon: Icons.credit_card,
                              validator: (v) =>
                              v!.replaceAll(' ', '').length != 16 ? '16 chiffres requis' : null,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(16),
                                _CardNumberFormatter(),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildInputField(
                                    controller: _expiryDateController,
                                    label: 'Expiration (MM/AAAA)',
                                    icon: Icons.calendar_today,
                                    validator: (v) => !RegExp(r'^(0[1-9]|1[0-2])/\d{4}$')
                                        .hasMatch(v!)
                                        ? 'Format invalide'
                                        : null,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(7),
                                      _ExpiryDateFormatter(),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildInputField(
                                    controller: _cvvController,
                                    label: 'CVV',
                                    icon: Icons.lock,
                                    validator: (v) => v!.length != 3 ? '3 chiffres requis' : null,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(3),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Checkbox(
                                  value: saveCard,
                                  onChanged: (v) => setState(() => saveCard = v!),
                                  activeColor: primaryColor,
                                ),
                                Expanded(
                                  child: Text(
                                    'Sauvegarder cette carte pour les futurs paiements',
                                    style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Récapitulatif',
                              style: GoogleFonts.roboto(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        plans.firstWhere((p) => p['id'] == selectedPlan,
                                            orElse: () => {'name': 'Forfait'})['name'],
                                        style: GoogleFonts.roboto(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                      Text(
                                        '${(billingType == 'monthly' ? plans.firstWhere((p) => p['id'] == selectedPlan)['monthlyPrice'] : plans.firstWhere((p) => p['id'] == selectedPlan)['annualPrice']).toStringAsFixed(0)} TND',
                                        style: GoogleFonts.roboto(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: darkColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    billingType == 'monthly'
                                        ? 'Facturation mensuelle'
                                        : 'Facturation annuelle',
                                    style: GoogleFonts.roboto(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Inclus :',
                                    style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: darkColor,
                                    ),
                                  ),
                                  ...plans
                                      .firstWhere((p) => p['id'] == selectedPlan)['features']
                                      .map<Widget>((feature) => Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: gold100,
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(Icons.check,
                                              size: 16, color: Color(0xFF6A1B9A)),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            feature,
                                            style: GoogleFonts.roboto(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                                  if (plans.firstWhere((p) => p['id'] == selectedPlan)['excludedFeatures'].isNotEmpty)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const SizedBox(height: 12),
                                        Text(
                                          'Non inclus :',
                                          style: GoogleFonts.roboto(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: darkColor,
                                          ),
                                        ),
                                        ...plans
                                            .firstWhere((p) => p['id'] == selectedPlan)[
                                        'excludedFeatures']
                                            .map<Widget>((excluded) => Padding(
                                          padding: const EdgeInsets.only(top: 8),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.close,
                                                  size: 20, color: Color(0xFFEF4444)),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  excluded,
                                                  style: GoogleFonts.roboto(
                                                    fontSize: 14,
                                                    color: Colors.grey[400],
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        )),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Divider(color: Color(0xFFD1D5DB)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total',
                                  style: GoogleFonts.roboto(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: darkColor,
                                  ),
                                ),
                                Text(
                                  '${(billingType == 'monthly' ? plans.firstWhere((p) => p['id'] == selectedPlan)['monthlyPrice'] : plans.firstWhere((p) => p['id'] == selectedPlan)['annualPrice']).toStringAsFixed(0)} TND',
                                  style: GoogleFonts.roboto(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'En confirmant, vous acceptez nos conditions générales et politique de confidentialité.',
                              style: GoogleFonts.roboto(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: gold100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: gold200),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.shield, color: Color(0xFFD4AF37), size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Paiement sécurisé',
                                          style: GoogleFonts.roboto(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                            color: darkColor,
                                          ),
                                        ),
                                        Text(
                                          'Vos informations sont cryptées et protégées.',
                                          style: GoogleFonts.roboto(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _prevStep,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFD1D5DB)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.arrow_back, size: 18, color: Color(0xFF374151)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Retour',
                                    style: GoogleFonts.roboto(
                                        fontSize: 14, color: const Color(0xFF374151)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _nextStep,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                                  : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    widget.subscriptionId != null ? 'Renouveler' : 'Confirmer et payer',
                                    style: GoogleFonts.roboto(fontSize: 14, color: Colors.white),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward,
                                      size: 18, color: Colors.white),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              if (currentStep == 3 && (widget.subscriptionId != null || !hasActiveSubscription))
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: subscriptionConfirmed
                      ? Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(40),
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.subscriptionId != null
                            ? 'Abonnement Renouvelé !'
                            : 'Abonnement Confirmé !',
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: darkColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.subscriptionId != null
                            ? 'Votre abonnement a été renouvelé avec succès.'
                            : 'Merci pour votre souscription. Voici les détails :',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            _buildConfirmationDetail('ID Abonnement', activeSubscription?['id'].toString() ?? ''),
                            _buildConfirmationDetail('Type', activeSubscription?['subscriptionType'] ?? ''),
                            _buildConfirmationDetail(
                                'Cycle de Facturation',
                                activeSubscription?['billingCycle'] == 'monthly'
                                    ? 'Mensuel'
                                    : 'Annuel'),
                            _buildConfirmationDetail('Date de début',
                                DateFormat('dd/MM/yyyy').format(DateTime.parse(activeSubscription?['startDate'] ?? DateTime.now().toString()))),
                            _buildConfirmationDetail('Date de fin',
                                DateFormat('dd/MM/yyyy').format(DateTime.parse(activeSubscription?['endDate'] ?? DateTime.now().toString()))),
                            _buildConfirmationDetail('Places restantes',
                                activeSubscription?['remainingPlaces'].toString() ?? ''),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: gold100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: gold200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.lightbulb, color: Color(0xFFD4AF37), size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Conseil',
                                    style: GoogleFonts.roboto(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: darkColor,
                                    ),
                                  ),
                                  Text(
                                    'Téléchargez notre application mobile pour profiter pleinement des services.',
                                    style: GoogleFonts.roboto(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _reset,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.home, size: 18, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              'Retour à l\'accueil',
                              style: GoogleFonts.roboto(fontSize: 14, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                  )
                      : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Confirmation',
                        style: GoogleFonts.roboto(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: darkColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Un code de vérification a été envoyé à ${_emailController.text}.',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildInputField(
                        controller: _confirmationCodeController,
                        label: 'Code de vérification',
                        icon: Icons.security,
                        validator: (v) => v!.isEmpty ? 'Code requis' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _prevStep,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFD1D5DB)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.arrow_back,
                                      size: 18, color: Color(0xFF374151)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Retour',
                                    style: GoogleFonts.roboto(
                                        fontSize: 14, color: const Color(0xFF374151)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _nextStep,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: isLoading
                                  ? const CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2)
                                  : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Confirmer',
                                    style: GoogleFonts.roboto(
                                        fontSize: 14, color: Colors.white),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.check,
                                      size: 18, color: Colors.white),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? const Color(0xFF6A1B9A) : const Color(0xFFD1D5DB),
              width: 2,
            ),
            color: isActive
                ? const Color(0xFF6A1B9A)
                : (currentStep > step ? Colors.green : Colors.transparent),
          ),
          child: Center(
            child: currentStep > step
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
              step.toString(),
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: isActive ? Colors.white : const Color(0xFF9CA3AF),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 12,
            color: isActive ? const Color(0xFF374151) : const Color(0xFF9CA3AF),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(bool isActive) {
    return Container(
      height: 4,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF6A1B9A) : const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: GoogleFonts.roboto(fontSize: 14, color: const Color(0xFF374151)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.roboto(fontSize: 14, color: const Color(0xFF6B7280)),
        prefixIcon: Icon(icon, color: const Color(0xFF9CA3AF)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6A1B9A), width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildConfirmationDetail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(fontSize: 14, color: const Color(0xFF6B7280)),
          ),
          Text(
            value,
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text.replaceAll(' ', '');
    String formatted = '';
    for (int i = 0; i < newText.length; i++) {
      if (i > 0 && i % 4 == 0) formatted += ' ';
      formatted += newText[i];
    }
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    String newText = newValue.text.replaceAll('/', '');
    String formatted = '';
    if (newText.length <= 2) {
      formatted = newText;
    } else {
      formatted = '${newText.substring(0, 2)}/${newText.substring(2, newText.length)}';
    }
    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}