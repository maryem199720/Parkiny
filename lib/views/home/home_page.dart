import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_parking/core/layout/main_layout.dart';
import 'package:smart_parking/views/notification/notification_page.dart';
import 'package:smart_parking/views/profile/profile_page.dart';
import 'package:smart_parking/views/reservation/reservation_page.dart';
import 'package:smart_parking/views/subscription/subscription_page.dart';
import 'package:smart_parking/views/vehicle/add_vehicle_page.dart' hide SubscriptionPage;
import '../../core/constants.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  Map<String, dynamic>? userProfile;
  Map<String, dynamic>? parkingInfo;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<String?> _getToken() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('Token non trouvé');
      }
      return token;
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur lors de la récupération du token: $e';
      });
      return null;
    }
  }

  Future<void> _fetchUserData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final String? token = await _getToken();
    if (token == null) {
      setState(() {
        isLoading = false;
        errorMessage = 'Erreur de récupération du token';
      });
      return;
    }

    try {
      // Fetch user profile
      final profileResponse = await http.get(
        Uri.parse('http://10.0.2.2:8082/parking/api/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      // Fetch parking info
      final parkingResponse = await http.get(
        Uri.parse('http://10.0.2.2:8082/parking/api/parking-info'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (profileResponse.statusCode == 200) {
        userProfile = json.decode(profileResponse.body);
      }

      if (parkingResponse.statusCode == 200) {
        parkingInfo = json.decode(parkingResponse.body);
      } else {
        // Default parking info if API doesn't exist
        parkingInfo = {
          'name': 'Parkiny Smart Parking',
          'location': 'Centre-ville, Tunis',
          'totalSpots': 150,
          'availableSpots': 45,
          'features': ['Sécurisé 24h/24', 'Surveillance vidéo', 'Éclairage LED', 'Accès facile'],
        };
      }

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      currentIndex: _currentIndex,
      onTabChanged: (index) => setState(() => _currentIndex = index),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return const ReservationsPage();
      case 2:
        return const SubscriptionPage();
      case 3:
        return const NotificationPage();
      case 4:
        return const ProfilePage();
      default:
        return _buildHomeContent();
    }
  }

  Widget _buildHomeContent() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.errorColor),
            const SizedBox(height: 16),
            Text(errorMessage!, style: GoogleFonts.poppins(color: AppColors.errorColor)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchUserData,
              child: Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome Header
          _buildWelcomeHeader(),
          const SizedBox(height: 24),

          // Parking Info Card
          _buildParkingInfoCard(),
          const SizedBox(height: 24),

          // Quick Actions
          _buildQuickActions(),
          const SizedBox(height: 24),

          // Recent Activity (if any)
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    final firstName = userProfile?['firstName'] ?? 'Utilisateur';
    final currentHour = DateTime.now().hour;
    String greeting;

    if (currentHour < 12) {
      greeting = 'Bonjour';
    } else if (currentHour < 18) {
      greeting = 'Bon après-midi';
    } else {
      greeting = 'Bonsoir';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryColor, AppColors.primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, $firstName!',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.whiteColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bienvenue sur Parkiny',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: AppColors.whiteColor.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.whiteColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.local_parking,
              size: 32,
              color: AppColors.whiteColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParkingInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: AppColors.primaryColor, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        parkingInfo?['name'] ?? 'Parkiny Smart Parking',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        parkingInfo?['location'] ?? 'Centre-ville, Tunis',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppColors.subtitleColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Availability Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${parkingInfo?['availableSpots'] ?? 45}',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        Text(
                          'Places disponibles',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: AppColors.grayColor,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${parkingInfo?['totalSpots'] ?? 150}',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textColor,
                          ),
                        ),
                        Text(
                          'Places totales',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: AppColors.subtitleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Features
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: (parkingInfo?['features'] as List<dynamic>? ?? [])
                  .map<Widget>((feature) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  feature.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textColor,
                  ),
                ),
              ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Actions rapides',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Réserver',
                'Réserver une place maintenant',
                Icons.add_circle,
                AppColors.primaryColor,
                    () => setState(() => _currentIndex = 1),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                'Abonnement',
                'Gérer votre abonnement',
                Icons.subscriptions,
                Colors.orange,
                    () => setState(() => _currentIndex = 2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.whiteColor, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: AppColors.subtitleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activité récente',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Icon(
                  Icons.history,
                  size: 48,
                  color: AppColors.subtitleColor,
                ),
                const SizedBox(height: 8),
                Text(
                  'Aucune activité récente',
                  style: GoogleFonts.poppins(
                    color: AppColors.subtitleColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vos réservations et abonnements apparaîtront ici',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.subtitleColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

