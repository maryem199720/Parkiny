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
import '../subscription/subscription_page.dart' as subscription;
import '../vehicle/add_vehicle_page.dart';
import '../vehicle/vehicle_details_page.dart';
import '../vehicle/vehicle_list_page.dart';

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

  // State for collapsible sections
  bool _isReservationsExpanded = false;
  bool _isVehiclesExpanded = false;
  bool _isSubscriptionExpanded = false;

  // Controllers for profile editing
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  // Controllers for password changing
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  bool _isVerificationCodeSent = false;

  // Controllers for vehicle addition
  final _matriculeController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _colorController = TextEditingController();
  File? _matriculeImage;

  // State variable to track matricule processing
  bool _isMatriculeProcessed = false;

  // Gold color for icons (equivalent to text-gold-500)
  final Color _goldColor = const Color(0xFFD4AF37);

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
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _verificationCodeController.dispose();
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

  Future<void> _requestPasswordReset() async {
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
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8082/parking/api/user/request-password-reset'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'method': 'email',
          'email': userProfile?['email'] ?? '',
          'phone': userProfile?['phone'] ?? '',
        }),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _isVerificationCodeSent = true;
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Code de vérification envoyé par email')),
        );
      } else {
        setState(() {
          errorMessage = 'Erreur lors de la demande: ${response.body}';
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

  Future<void> _changePassword() async {
    if (_verificationCodeController.text.isEmpty) {
      if (mounted) {
        setState(() {
          errorMessage = 'Veuillez entrer le code de vérification';
        });
      }
      return;
    }

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
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8082/parking/api/user/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'currentPassword': _currentPasswordController.text.trim(),
          'newPassword': _newPasswordController.text.trim(),
          'verificationCode': _verificationCodeController.text.trim(),
        }),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.pop(context);
        setState(() {
          _isVerificationCodeSent = false;
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _verificationCodeController.clear();
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mot de passe mis à jour avec succès')),
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

  Future<String> _processMatriculeImage(File image) async {
    final String? token = await _getToken();
    if (token == null) throw Exception('Token non trouvé');

    if (!await image.exists()) {
      throw Exception('Image non trouvée');
    }
    final imageSize = await image.length();
    if (imageSize == 0) {
      throw Exception('Fichier image vide');
    }

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://10.0.2.2:5000/api/process-plate'),
    );
    request.headers['Authorization'] = 'Bearer $token';
    final multipartFile = await http.MultipartFile.fromPath('image', image.path, filename: 'car.jpg');
    request.files.add(multipartFile);

    try {
      final response = await request.send().timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final data = json.decode(responseBody);
        return data['matricule'] as String;
      } else {
        final errorBody = await response.stream.bytesToString();
        throw Exception('Erreur serveur: $errorBody (Statut: ${response.statusCode})');
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Erreur de connexion au serveur: $e';
      });
      rethrow;
    }
  }

  Future<void> _pickMatriculeImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      setState(() {
        _matriculeImage = File(pickedFile.path);
        _isMatriculeProcessed = false;
      });
    }
  }

  Future<void> _submitVehicle() async {
    if (_matriculeController.text.isEmpty ||
        _brandController.text.isEmpty ||
        _modelController.text.isEmpty ||
        _colorController.text.isEmpty) {
      if (mounted) {
        setState(() {
          errorMessage = 'Veuillez remplir tous les champs';
        });
      }
      return;
    }

    if (!mounted) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final vehicleData = {
      'matricule': _matriculeController.text.trim(),
      'vehicleType': 'car',
      'brand': _brandController.text.trim(),
      'model': _modelController.text.trim(),
      'color': _colorController.text.trim(),
    };

    try {
      final token = await _getToken();
      if (token == null) throw Exception('Token non trouvé');

      final response = await http.post(
        Uri.parse('http://10.0.2.2:8082/parking/api/vehicle'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(vehicleData),
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 201) {
        Navigator.pop(context);
        setState(() {
          _matriculeController.clear();
          _brandController.clear();
          _modelController.clear();
          _colorController.clear();
          _matriculeImage = null;
          _isMatriculeProcessed = false;
          isLoading = false;
        });
        await _fetchUserProfile();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Véhicule ajouté avec succès')),
        );
      } else {
        setState(() {
          errorMessage = 'Erreur: ${response.body}';
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

  void _showProfileEditDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier les Informations Personnelles', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _firstNameController,
                decoration: InputDecoration(labelText: 'Prénom', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _lastNameController,
                decoration: InputDecoration(labelText: 'Nom', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(labelText: 'Téléphone', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(errorMessage!, style: TextStyle(color: AppColors.errorColor)),
              ],
              const SizedBox(height: 20),
              isLoading
                  ? const CircularProgressIndicator()
                  : PrimaryButton(label: 'Enregistrer', onPressed: _updateProfile, isFullWidth: true),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: GoogleFonts.poppins(color: AppColors.primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showPasswordChangeDialog() {
    if (userProfile == null) {
      if (mounted) {
        setState(() {
          errorMessage = 'Veuillez attendre le chargement du profil';
        });
      }
      return;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setDialogState) => AlertDialog(
          title: Text(
            'Changer le mot de passe',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Étape 1 : Demander un code de vérification',
                  style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                Text(
                  'Un code sera envoyé à votre email: ${userProfile?['email'] ?? 'Non défini'}',
                  style: GoogleFonts.poppins(fontSize: 14, color: AppColors.subtitleColor),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Demander le code',
                  onPressed: () async {
                    await _requestPasswordReset();
                    setDialogState(() {});
                  },
                  isFullWidth: true,
                ),
                if (_isVerificationCodeSent) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Étape 2 : Entrer les détails du mot de passe',
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _verificationCodeController,
                    decoration: InputDecoration(
                      labelText: 'Code de vérification (6 chiffres)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _currentPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe actuel',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Nouveau mot de passe',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Confirmer le changement',
                    onPressed: () {
                      if (_verificationCodeController.text.trim().length != 6 ||
                          !RegExp(r'^\d{6}$').hasMatch(_verificationCodeController.text.trim())) {
                        setDialogState(() {
                          errorMessage = 'Le code de vérification doit être un nombre de 6 chiffres';
                        });
                        return;
                      }
                      if (_currentPasswordController.text.trim().isEmpty) {
                        setDialogState(() {
                          errorMessage = 'Le mot de passe actuel est requis';
                        });
                        return;
                      }
                      if (_newPasswordController.text.trim().length < 8) {
                        setDialogState(() {
                          errorMessage = 'Le nouveau mot de passe doit contenir au moins 8 caractères';
                        });
                        return;
                      }
                      _changePassword();
                    },
                    isFullWidth: true,
                  ),
                ],
                if (errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(errorMessage!, style: TextStyle(color: AppColors.errorColor)),
                ],
                const SizedBox(height: 20),
                if (isLoading) const CircularProgressIndicator(),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler', style: GoogleFonts.poppins(color: AppColors.primaryColor)),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddVehicleDialog() {
    bool isProcessingImage = false;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajouter un Véhicule', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!_isMatriculeProcessed) ...[
                    GestureDetector(
                      onTap: () async {
                        await _pickMatriculeImage();
                        setDialogState(() {});
                      },
                      child: Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: AppColors.grayColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.subtitleColor),
                        ),
                        child: _matriculeImage == null
                            ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.camera_alt, color: AppColors.subtitleColor),
                              Text('Uploader l\'image de la matricule', style: GoogleFonts.poppins(color: AppColors.subtitleColor)),
                            ],
                          ),
                        )
                            : Stack(
                          alignment: Alignment.center,
                          children: [
                            Image.file(_matriculeImage!, fit: BoxFit.cover),
                            Positioned(
                              bottom: 8,
                              child: isProcessingImage
                                  ? const CircularProgressIndicator()
                                  : PrimaryButton(
                                label: 'Envoyer',
                                onPressed: () async {
                                  if (_matriculeImage == null) return;

                                  setDialogState(() {
                                    isProcessingImage = true;
                                  });

                                  try {
                                    final matricule = await _processMatriculeImage(_matriculeImage!);
                                    if (mounted) {
                                      setState(() {
                                        _matriculeController.text = matricule;
                                        _isMatriculeProcessed = true;
                                      });
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      setState(() {
                                        errorMessage = 'Erreur lors du traitement de l\'image: $e';
                                      });
                                    }
                                  } finally {
                                    setDialogState(() {
                                      isProcessingImage = false;
                                    });
                                  }

                                  setDialogState(() {});
                                },
                                isFullWidth: false,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _matriculeController,
                      decoration: InputDecoration(
                        labelText: 'Matricule (sera rempli après envoi)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: AppColors.grayColor,
                        enabled: false,
                      ),
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Passer à l\'étape suivante',
                      onPressed: () {
                        if (_isMatriculeProcessed) {
                          setDialogState(() {});
                        }
                      },
                      isFullWidth: true,
                    ),
                  ] else ...[
                    TextField(
                      controller: _matriculeController,
                      decoration: InputDecoration(
                        labelText: 'Matricule',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: AppColors.grayColor,
                        enabled: false,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Marque',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      value: _brandController.text.isNotEmpty ? _brandController.text : null,
                      items: [
                        'Toyota',
                        'Honda',
                        'Ford',
                        'Volkswagen',
                        'Other',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: GoogleFonts.poppins()),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue == 'Other') {
                          setDialogState(() {
                            _brandController.text = '';
                          });
                          _showManualInputDialog('Marque', _brandController);
                        } else {
                          setDialogState(() {
                            _brandController.text = newValue ?? '';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Modèle',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      value: _modelController.text.isNotEmpty ? _modelController.text : null,
                      items: [
                        'Civic',
                        'Corolla',
                        'Focus',
                        'Golf',
                        'Other',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: GoogleFonts.poppins()),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue == 'Other') {
                          setDialogState(() {
                            _modelController.text = '';
                          });
                          _showManualInputDialog('Modèle', _modelController);
                        } else {
                          setDialogState(() {
                            _modelController.text = newValue ?? '';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Couleur',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      value: _colorController.text.isNotEmpty ? _colorController.text : null,
                      items: [
                        'Rouge',
                        'Bleu',
                        'Noir',
                        'Blanc',
                        'Other',
                      ].map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value, style: GoogleFonts.poppins()),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue == 'Other') {
                          setDialogState(() {
                            _colorController.text = '';
                          });
                          _showManualInputDialog('Couleur', _colorController);
                        } else {
                          setDialogState(() {
                            _colorController.text = newValue ?? '';
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Ajouter',
                      onPressed: () {
                        if (_brandController.text.isEmpty ||
                            _modelController.text.isEmpty ||
                            _colorController.text.isEmpty) {
                          setState(() {
                            errorMessage = 'Veuillez remplir tous les champs';
                          });
                          return;
                        }
                        _submitVehicle();
                      },
                      isFullWidth: true,
                    ),
                  ],
                  if (errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(errorMessage!, style: TextStyle(color: AppColors.errorColor)),
                  ],
                  const SizedBox(height: 20),
                  if (isLoading && !isProcessingImage) const CircularProgressIndicator(),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (mounted) {
                setState(() {
                  _isMatriculeProcessed = false;
                  _matriculeImage = null;
                  _matriculeController.clear();
                  _brandController.clear();
                  _modelController.clear();
                  _colorController.clear();
                  errorMessage = null;
                });
              }
            },
            child: Text('Annuler', style: GoogleFonts.poppins(color: AppColors.primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showManualInputDialog(String label, TextEditingController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Entrer $label manuellement', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: GoogleFonts.poppins(color: AppColors.primaryColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: GoogleFonts.poppins(color: AppColors.primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showReservationDetailsOverlay(Map<String, dynamic> reservation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ReservationDetailsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primaryColor),
            const SizedBox(height: 10),
            Text(
              'Chargement',
              style: GoogleFonts.poppins(color: AppColors.textColor),
            ),
          ],
        ),
      )
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.errorColor.withOpacity(0.1),
                    border: Border(
                      left: BorderSide(color: AppColors.errorColor, width: 4),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: AppColors.errorColor),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: GoogleFonts.poppins(color: AppColors.errorColor),
                        ),
                      ),
                    ],
                  ),
                ),
              // Profile Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.primaryLightColor,
                      foregroundColor: _goldColor,
                      radius: 30,
                      child: Text(
                        '${userProfile?['firstName']?.substring(0, 1).toUpperCase() ?? ''}${userProfile?['lastName']?.substring(0, 1).toUpperCase() ?? ''}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        '${userProfile?['firstName'] ?? ''} ${userProfile?['lastName'] ?? ''}',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 22,
                          color: AppColors.textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Modifier le profil Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLightColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.edit, color: _goldColor),
                  ),
                  title: Text(
                    'Modifier le profil',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textColor,
                    ),
                  ),
                  subtitle: Text(
                    'Mettre à jour les informations personnelles',
                    style: GoogleFonts.poppins(
                      color: AppColors.subtitleColor,
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.subtitleColor),
                  onTap: _showProfileEditDialog,
                ),
              ),
              const SizedBox(height: 16),
              // Change Password
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLightColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.lock, color: _goldColor),
                  ),
                  title: Text(
                    'Changer le mot de passe',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textColor,
                    ),
                  ),
                  subtitle: Text(
                    'Mettre à jour la sécurité du compte',
                    style: GoogleFonts.poppins(
                      color: AppColors.subtitleColor,
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.subtitleColor),
                  onTap: _showPasswordChangeDialog,
                ),
              ),
              const SizedBox(height: 16),
              // Reservations Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        onTap: () {
                          setState(() {
                            _isReservationsExpanded = !_isReservationsExpanded;
                          });
                        },
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.successColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.event, color: _goldColor),
                        ),
                        title: Text(
                          'Mes réservations',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textColor,
                          ),
                        ),
                        trailing: Icon(
                          _isReservationsExpanded ? Icons.expand_less : Icons.expand_more,
                          color: AppColors.subtitleColor,
                        ),
                      ),
                      if (_isReservationsExpanded) ...[
                        const Divider(),
                        if (userProfile?['reservations'] != null && (userProfile?['reservations'] as List).isNotEmpty)
                          ...List.generate(
                            (userProfile?['reservations'] as List).length,
                                (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: ListTile(
                                title: Text(
                                  'Réservation à ${userProfile?['reservations'][index]['parkingName'] ?? 'N/A'}',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textColor,
                                  ),
                                ),
                                subtitle: Text(
                                  'Du ${userProfile?['reservations'][index]['startDate'] ?? 'N/A'} au ${userProfile?['reservations'][index]['endDate'] ?? 'N/A'}',
                                  style: GoogleFonts.poppins(
                                    color: AppColors.subtitleColor,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: const Icon(Icons.chevron_right, color: AppColors.subtitleColor),
                                onTap: () {
                                  _showReservationDetailsOverlay(userProfile?['reservations'][index]);
                                },
                              ),
                            ),
                          )
                        else
                          Column(
                            children: [
                              const Icon(Icons.event, size: 48, color: AppColors.subtitleColor),
                              const SizedBox(height: 8),
                              Text(
                                'Aucune réservation',
                                style: GoogleFonts.poppins(
                                  color: AppColors.subtitleColor,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Vehicles Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        onTap: () {
                          setState(() {
                            _isVehiclesExpanded = !_isVehiclesExpanded;
                          });
                        },
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLightColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.directions_car, color: _goldColor),
                        ),
                        title: Text(
                          'Mes véhicules',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textColor,
                          ),
                        ),
                        trailing: Icon(
                          _isVehiclesExpanded ? Icons.expand_less : Icons.expand_more,
                          color: AppColors.subtitleColor,
                        ),
                      ),
                      if (_isVehiclesExpanded) ...[
                        const Divider(),
                        if (userProfile?['vehicles'] != null && (userProfile?['vehicles'] as List).isNotEmpty)
                          ...List.generate(
                            (userProfile?['vehicles'] as List).length,
                                (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryLightColor,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.directions_car, color: _goldColor),
                                ),
                                title: Text(
                                  '${userProfile?['vehicles'][index]['brand'] ?? 'N/A'} ${userProfile?['vehicles'][index]['model'] ?? 'N/A'}',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textColor,
                                  ),
                                ),
                                subtitle: Text(
                                  'Matricule: ${userProfile?['vehicles'][index]['matricule'] ?? 'N/A'} • Couleur: ${userProfile?['vehicles'][index]['color'] ?? 'N/A'}',
                                  style: GoogleFonts.poppins(
                                    color: AppColors.subtitleColor,
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: const Icon(Icons.chevron_right, color: AppColors.subtitleColor),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => VehicleDetailsPage(
                                        vehicle: userProfile?['vehicles'][index],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          )
                        else
                          Column(
                            children: [
                              const Icon(Icons.directions_car, size: 48, color: AppColors.subtitleColor),
                              const SizedBox(height: 12),
                              Text(
                                'Aucun véhicule',
                                style: GoogleFonts.poppins(
                                  color: AppColors.subtitleColor,
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: _showAddVehicleDialog,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add, size: 16, color: AppColors.primaryColor),
                                const SizedBox(width: 4),
                                Text(
                                  'Ajouter un véhicule',
                                  style: GoogleFonts.poppins(
                                    color: AppColors.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Subscription Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        onTap: () {
                          setState(() {
                            _isSubscriptionExpanded = !_isSubscriptionExpanded;
                          });
                        },
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.accentLightColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.subscriptions, color: _goldColor),
                        ),
                        title: Text(
                          'Mon abonnement',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textColor,
                          ),
                        ),
                        trailing: Icon(
                          _isSubscriptionExpanded ? Icons.expand_less : Icons.expand_more,
                          color: AppColors.subtitleColor,
                        ),
                      ),
                      if (_isSubscriptionExpanded) ...[
                        const Divider(),
                        if (userProfile?['subscription'] != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: ListTile(
                              title: Text(
                                'Plan Premium',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textColor,
                                ),
                              ),
                              subtitle: Text(
                                'Valide jusqu\'au ${userProfile?['subscription']['subscriptionEndDate'] ?? 'N/A'}',
                                style: GoogleFonts.poppins(
                                  color: AppColors.subtitleColor,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          )
                        else
                          Column(
                            children: [
                              const Icon(Icons.account_balance_wallet, size: 48, color: AppColors.subtitleColor),
                              const SizedBox(height: 8),
                              Text(
                                'Aucun abonnement actif',
                                style: GoogleFonts.poppins(
                                  color: AppColors.subtitleColor,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Logout Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.errorColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.logout, color: _goldColor),
                  ),
                  title: Text(
                    'Déconnexion',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      color: AppColors.textColor,
                    ),
                  ),
                  subtitle: Text(
                    'Quitter la session',
                    style: GoogleFonts.poppins(
                      color: AppColors.subtitleColor,
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.subtitleColor),
                  onTap: _logout,
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}