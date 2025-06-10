import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smart_parking/views/home/home_page.dart';
import 'package:smart_parking/views/auth/signup_page.dart';
import 'package:smart_parking/core/constants.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final savedEmail = await _storage.read(key: 'remembered_email');
      final savedPassword = await _storage.read(key: 'remembered_password');
      if (savedEmail != null && savedPassword != null) {
        setState(() {
          _emailController.text = savedEmail;
          _passwordController.text = savedPassword;
          _rememberMe = true;
        });
      }
    } catch (e) {
      print('Error loading credentials: $e');
    }
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      const String baseUrl = 'http://10.0.2.2:8082/parking';
      final url = Uri.parse('$baseUrl/api/auth/signin');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final token = responseData['token'];
        final userName = responseData['userName'];

        // Save credentials if "Remember Me" is checked
        if (_rememberMe) {
          await _storage.write(key: 'remembered_email', value: email);
          await _storage.write(key: 'remembered_password', value: password);
        } else {
          await _storage.delete(key: 'remembered_email');
          await _storage.delete(key: 'remembered_password');
        }

        // Store the token
        await _storage.write(key: 'auth_token', value: token);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomePage(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Échec de la connexion: ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Connexion",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryColor,
                    fontFamily: 'Poppins',
                  ),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: "Email",
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.grayColor,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Mot de passe",
                    prefixIcon: Icon(Icons.lock_outline, color: AppColors.primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.grayColor,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                      activeColor: AppColors.secondaryColor,
                    ),
                    const Text(
                      "Se souvenir de moi",
                      style: TextStyle(fontFamily: 'Poppins'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryColor,
                    foregroundColor: AppColors.textColor,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Connexion",
                    style: TextStyle(fontSize: 18, fontFamily: 'Poppins'),
                  ),
                ),
                const SizedBox(height: 15),
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const SignupPage()),
                    );
                  },
                  child: Text(
                    "Pas de compte ? S'inscrire",
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}