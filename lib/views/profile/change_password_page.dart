
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants.dart';


class ChangePasswordPage extends StatefulWidget {
const ChangePasswordPage({super.key});

@override
State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
final _formKey = GlobalKey<FormState>();
final _currentPasswordController = TextEditingController();
final _newPasswordController = TextEditingController();
final _verificationCodeController = TextEditingController();
bool isLoading = false;
String? errorMessage;
bool isVerificationStep = false;
bool isFormSubmitted = false;
final FlutterSecureStorage _storage = const FlutterSecureStorage();

Future<void> _requestVerificationCode() async {
if (_formKey.currentState!.validate()) {
setState(() {
isLoading = true;
errorMessage = null;
isFormSubmitted = true;
});

try {
final token = await _storage.read(key: 'auth_token');
if (token == null) {
Navigator.pushReplacementNamed(context, '/login');
return;
}

final response = await http.post(
Uri.parse('http://10.0.2.2:8082/parking/api/user/request-change-password-code'),
headers: {
'Content-Type': 'application/json',
'Authorization': 'Bearer $token',
},
body: jsonEncode({
'currentPassword': _currentPasswordController.text.trim(),
'newPassword': _newPasswordController.text.trim(),
'verificationCode': '',
}),
);

if (response.statusCode == 200) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Code de vérification envoyé par email')),
);
setState(() {
isVerificationStep = true;
});
} else {
setState(() {
errorMessage = 'Erreur lors de la demande: ${response.body}';
});
}
} catch (e) {
setState(() {
errorMessage = 'Erreur: $e';
});
} finally {
setState(() {
isLoading = false;
});
}
}
}

Future<void> _submitChangePassword() async {
if (_formKey.currentState!.validate()) {
setState(() {
isLoading = true;
errorMessage = null;
isFormSubmitted = true;
});

try {
final token = await _storage.read(key: 'auth_token');
if (token == null) {
Navigator.pushReplacementNamed(context, '/login');
return;
}

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
);

if (response.statusCode == 200) {
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Mot de passe mis à jour avec succès')),
);
_resetForm();
Navigator.pop(context); // Return to previous screen
} else {
setState(() {
errorMessage = 'Erreur lors de la mise à jour: ${response.body}';
});
}
} catch (e) {
setState(() {
errorMessage = 'Erreur: $e';
});
} finally {
setState(() {
isLoading = false;
});
}
}
}

void _goBack() {
setState(() {
isVerificationStep = false;
_verificationCodeController.clear();
errorMessage = null;
isFormSubmitted = false;
});
}

void _resetForm() {
_currentPasswordController.clear();
_newPasswordController.clear();
_verificationCodeController.clear();
setState(() {
isVerificationStep = false;
isFormSubmitted = false;
errorMessage = null;
});
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
backgroundColor: AppColors.primaryColor,
title: Text(
'Changer le Mot de Passe',
style: TextStyle(color: AppColors.whiteColor, fontFamily: 'Poppins'),
),
),
body: Padding(
padding: const EdgeInsets.all(16.0),
child: Form(
key: _formKey,
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'Changer le Mot de Passe',
style: TextStyle(
fontSize: 24,
fontWeight: FontWeight.bold,
fontFamily: 'Poppins',
),
textAlign: TextAlign.center,
),
const SizedBox(height: 8),
const Text(
'Mettez à jour votre mot de passe en toute sécurité',
style: TextStyle(
fontSize: 14,
color: Colors.grey,
fontFamily: 'Poppins',
),
textAlign: TextAlign.center,
),
const SizedBox(height: 24),
if (isLoading)
const Center(
child: Padding(
padding: EdgeInsets.only(top: 16.0),
child: CircularProgressIndicator(color: AppColors.primaryColor),
),
),
if (!isLoading)
!isVerificationStep
? Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
TextFormField(
controller: _currentPasswordController,
obscureText: true,
decoration: InputDecoration(
labelText: 'Mot de passe actuel',
border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
filled: true,
fillColor: AppColors.grayColor,
),
validator: (value) {
if (isFormSubmitted && (value == null || value.isEmpty)) {
return 'Mot de passe actuel requis';
}
return null;
},
),
const SizedBox(height: 16),
TextFormField(
controller: _newPasswordController,
obscureText: true,
decoration: InputDecoration(
labelText: 'Nouveau mot de passe',
border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
filled: true,
fillColor: AppColors.grayColor,
),
validator: (value) {
if (isFormSubmitted && (value == null || value.isEmpty)) {
return 'Nouveau mot de passe requis';
}
return null;
},
),
if (errorMessage != null)
Padding(
padding: const EdgeInsets.only(top: 8.0),
child: Text(
errorMessage!,
style: TextStyle(color: AppColors.errorColor, fontFamily: 'Poppins'),
),
),
const SizedBox(height: 24),
Row(
mainAxisAlignment: MainAxisAlignment.end,
children: [
TextButton(
onPressed: () {
Navigator.pushNamed(context, '/forgot-password');
},
child: const Text(
'Mot de passe oublié ?',
style: TextStyle(
color: AppColors.secondaryColor,
fontSize: 14,
fontFamily: 'Poppins',
),
),
),
const SizedBox(width: 16),
ElevatedButton(
onPressed: isLoading ? null : _requestVerificationCode,
style: ElevatedButton.styleFrom(
backgroundColor: AppColors.secondaryColor,
foregroundColor: AppColors.textColor,
minimumSize: const Size(120, 50),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
),
child: const Text(
'Suivant',
style: TextStyle(fontSize: 16, fontFamily: 'Poppins'),
),
),
],
),
],
)
    : Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
TextFormField(
controller: _verificationCodeController,
decoration: InputDecoration(
labelText: 'Code de vérification',
border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
filled: true,
fillColor: AppColors.grayColor,
),
validator: (value) {
if (isFormSubmitted && (value == null || value.isEmpty)) {
return 'Code de vérification requis';
}
return null;
},
),
if (errorMessage != null)
Padding(
padding: const EdgeInsets.only(top: 8.0),
child: Text(
errorMessage!,
style: TextStyle(color: AppColors.errorColor, fontFamily: 'Poppins'),
),
),
const SizedBox(height: 24),
Row(
mainAxisAlignment: MainAxisAlignment.end,
children: [
TextButton(
onPressed: _goBack,
child: const Text(
'Retour',
style: TextStyle(
color: AppColors.secondaryColor,
fontSize: 14,
fontFamily: 'Poppins',
),
),
),
const SizedBox(width: 16),
ElevatedButton(
onPressed: isLoading ? null : _submitChangePassword,
style: ElevatedButton.styleFrom(
backgroundColor: AppColors.secondaryColor,
foregroundColor: AppColors.textColor,
minimumSize: const Size(120, 50),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
),
child: const Text(
'Enregistrer',
style: TextStyle(fontSize: 16, fontFamily: 'Poppins'),
),
),
],
),
],
),
],
),
),
),
);
}
}
