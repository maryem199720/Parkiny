import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smart_parking/core/constants.dart';
import 'package:smart_parking/views/auth/login_page.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../widgets/primary_button.dart';
import '../reservation/reservation_details.dart';
import '../subscription/subscription_history_page.dart';
import '../subscription/subscription_page.dart' as subscription;
import '../vehicle/add_vehicle_page.dart';
import '../vehicle/vehicle_details_page.dart';
import '../vehicle/vehicle_list_page.dart';
import 'change_password_page.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userProfile;
  bool isLoading = true;
  String? errorMessage;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // State for in-page views
  String _currentView = 'profile'; // profile, reservations, subscriptions

  // Controllers for profile editing
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // Controllers for vehicle addition
  final _matriculeController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _colorController = TextEditingController();
  File? _matriculeImage;

  // State variable to track matricule processing
  bool _isMatriculeProcessed = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _matriculeController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      }
      return token;
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Erreur lors de la récupération du token: $e';
        });
      }
      return null;
    }
  }

  Future<void> _fetchUserProfile() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final String? token = await _getToken();
    if (token == null) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = 'Erreur de récupération du profil';
        });
      }
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8082/parking/api/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('Erreur de récupération du profil');
      });

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userProfile = data;
          _firstNameController.text = data['firstName'] ?? '';
          _lastNameController.text = data['lastName'] ?? '';
          _emailController.text = data['email'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        await _storage.delete(key: 'auth_token');
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
          );
        }
      } else {
        setState(() {
          errorMessage = 'Erreur de récupération du profil: ${response.body}';
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Erreur de récupération du profil: $e';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _updateProfile() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final token = await _getToken();
    if (token == null) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
      return;
    }

    try {
      final response = await http.put(
        Uri.parse('http://10.0.2.2:8082/parking/api/user/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'firstName': _firstNameController.text.trim(),
          'lastName': _lastNameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
        }),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.pop(context);
        setState(() {
          userProfile = json.decode(response.body);
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour avec succès')),
        );
      } else {
        setState(() {
          errorMessage = 'Erreur lors de la mise à jour: ${response.body}';
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Erreur: $e';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la déconnexion', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Êtes-vous sûr de vouloir vous déconnecter ?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: GoogleFonts.poppins(color: AppColors.primaryColor)),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _storage.delete(key: 'auth_token');
                await _storage.delete(key: 'remembered_email');
                await _storage.delete(key: 'remembered_password');
              } catch (e) {
                if (mounted) {
                  setState(() {
                    errorMessage = 'Erreur lors de la déconnexion: $e';
                  });
                }
              }
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                );
              }
            },
            child: Text('Déconnexion', style: GoogleFonts.poppins(color: AppColors.errorColor)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    if (userProfile == null) return;

    showDialog(
      context: context,
      builder: (context) => ChangePasswordWidget(
        userEmail: userProfile!['email'] ?? '',
      ),
    );
  }

  void _showProfileEditDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier le Profil', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: 'Prénom',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: 'Nom',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Téléphone',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: GoogleFonts.poppins(color: AppColors.subtitleColor)),
          ),
          ElevatedButton(
            onPressed: _updateProfile,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: AppColors.whiteColor,
            ),
            child: Text('Sauvegarder', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.whiteColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primaryColor,
                    child: Text(
                      userProfile != null
                          ? '${userProfile!['firstName']?[0] ?? ''}${userProfile!['lastName']?[0] ?? ''}'
                          : 'U',
                      style: GoogleFonts.poppins(
                        color: AppColors.whiteColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userProfile != null
                              ? '${userProfile!['firstName'] ?? ''} ${userProfile!['lastName'] ?? ''}'
                              : 'Profil',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textColor,
                          ),
                        ),
                        if (userProfile != null)
                          Text(
                            userProfile!['email'] ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.subtitleColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _logout,
                    icon: Icon(Icons.logout, color: AppColors.errorColor),
                  ),
                ],
              ),
            ),

            // Navigation Tabs
            Container(
              margin: const EdgeInsets.all(16),
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
              child: Row(
                children: [
                  Expanded(child: _buildTabButton('Profil', 'profile', Icons.person)),
                  Expanded(child: _buildTabButton('Réservations', 'reservations', Icons.history)),
                  Expanded(child: _buildTabButton('Abonnements', 'subscriptions', Icons.subscriptions)),
                ],
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildCurrentView(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, String value, IconData icon) {
    final isSelected = _currentView == value;
    return GestureDetector(
      onTap: () => setState(() => _currentView = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.whiteColor : AppColors.subtitleColor,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.whiteColor : AppColors.subtitleColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentView() {
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
              onPressed: _fetchUserProfile,
              child: Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    switch (_currentView) {
      case 'reservations':
        return const ReservationHistoryWidget();
      case 'subscriptions':
        return const SubscriptionHistoryWidget();
      default:
        return _buildProfileView();
    }
  }

  Widget _buildProfileView() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Profile Info Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Informations personnelles',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: _showProfileEditDialog,
                        icon: Icon(Icons.edit, color: AppColors.primaryColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(Icons.person, 'Nom complet',
                      '${userProfile?['firstName'] ?? ''} ${userProfile?['lastName'] ?? ''}'),
                  _buildInfoRow(Icons.email, 'Email', userProfile?['email'] ?? ''),
                  _buildInfoRow(Icons.phone, 'Téléphone', userProfile?['phone'] ?? ''),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Actions Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Actions',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildActionButton(
                    Icons.lock,
                    'Changer le mot de passe',
                    'Modifier votre mot de passe avec vérification par email',
                    _showChangePasswordDialog,
                  ),
                  const SizedBox(height: 12),
                  _buildActionButton(
                    Icons.directions_car,
                    'Gérer les véhicules',
                    'Ajouter ou modifier vos véhicules',
                        () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const VehicleListPage()),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.subtitleColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.subtitleColor,
                  ),
                ),
                Text(
                  value.isNotEmpty ? value : 'Non renseigné',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: value.isNotEmpty ? AppColors.textColor : AppColors.subtitleColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.grayColor.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
            Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.subtitleColor),
          ],
        ),
      ),
    );
  }
}

