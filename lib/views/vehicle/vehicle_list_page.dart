
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smart_parking/core/constants.dart';

class VehicleListPage extends StatefulWidget {
const VehicleListPage({super.key});

@override
State<VehicleListPage> createState() => _VehicleListPageState();
}

class _VehicleListPageState extends State<VehicleListPage> {
final _formKey = GlobalKey<FormState>();
final FlutterSecureStorage _storage = const FlutterSecureStorage();
final ImagePicker _picker = ImagePicker();

List<Map<String, dynamic>> vehicles = [];
Map<String, dynamic> vehicleForm = {
'matricule': '',
'brand': '',
'customBrand': '',
'model': '',
'customModel': '',
'color': '',
'customColor': '',
'matriculeImageUrl': '',
};
Map<String, dynamic>? editVehicleForm;
bool isLoading = false;
String? errorMessage;
XFile? selectedFile;

final List<String> brands = [
'Toyota', 'Honda', 'Ford', 'Volkswagen', 'BMW', 'Mercedes-Benz', 'Audi',
'Hyundai', 'Kia', 'Peugeot', 'Renault', 'Citroën', 'Tesla', 'Nissan',
'Chevrolet', 'Other'
];
final List<String> models = [
'Civic', 'Corolla', 'Focus', 'Golf', '3 Series', 'C-Class', 'A4', 'Tucson',
'Sportage', '208', 'Clio', 'C3', 'Model 3', 'Leaf', 'Camaro', 'Other'
];
final List<String> colors = [
'Rouge', 'Bleu', 'Noir', 'Blanc', 'Gris', 'Argent', 'Vert', 'Jaune',
'Orange', 'Marron', 'Beige', 'Violet', 'Or', 'Other'
];

@override
void initState() {
super.initState();
_fetchVehicles();
}

Future<void> _fetchVehicles() async {
setState(() {
isLoading = true;
errorMessage = null;
});

try {
final token = await _storage.read(key: 'auth_token');
if (token == null) {
Navigator.pushReplacementNamed(context, '/login');
return;
}

final response = await http.get(
Uri.parse('http://10.0.2.2:8082/parking/api/user/profile'),
headers: {
'Content-Type': 'application/json',
'Authorization': 'Bearer $token',
},
);

if (response.statusCode == 200) {
final data = json.decode(response.body);
setState(() {
vehicles = List<Map<String, dynamic>>.from(data['vehicles'] ?? []);
isLoading = false;
});
} else {
setState(() {
errorMessage = 'Erreur lors de la récupération des véhicules: ${response.body}';
isLoading = false;
});
}
} catch (e) {
setState(() {
errorMessage = 'Erreur: $e';
isLoading = false;
});
}
}

Future<void> _pickImage() async {
final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
if (image != null) {
setState(() {
selectedFile = image;
vehicleForm['matriculeImageUrl'] = image.path; // Local path for preview
});
}
}

Future<void> _sendPlateImage() async {
  if (selectedFile == null) {
    setState(() {
      errorMessage = 'Veuillez sélectionner une image de plaque';
    });
    return;
  }

  setState(() {
    isLoading = true;
    errorMessage = null;
  });

  try {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://10.0.2.2:5000/api/process-plate'),
    );
    request.files.add(await http.MultipartFile.fromPath(
      'file', // Ensure this matches the FastAPI parameter name
      selectedFile!.path,
      filename: selectedFile!.name, // Use the original filename for better tracking
    ));
    final token = await _storage.read(key: 'auth_token');
    if (token != null) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    final response = await request.send();
    final responseBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = json.decode(responseBody);
      setState(() {
        vehicleForm['matricule'] = data['matricule'] ?? '';
        errorMessage = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Matricule détecté avec succès')),
      );
    } else {
      setState(() {
        errorMessage = 'Erreur lors de la détection: $responseBody';
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

Future<void> _submitVehicle() async {
if (_formKey.currentState!.validate()) {
setState(() {
isLoading = true;
errorMessage = null;
});

try {
final token = await _storage.read(key: 'auth_token');
if (token == null) {
Navigator.pushReplacementNamed(context, '/login');
return;
}

final brand = vehicleForm['brand'] == 'Other' ? vehicleForm['customBrand'] : vehicleForm['brand'];
final model = vehicleForm['model'] == 'Other' ? vehicleForm['customModel'] : vehicleForm['model'];
final color = vehicleForm['color'] == 'Other' ? vehicleForm['customColor'] : vehicleForm['color'];

if ((vehicleForm['brand'] == 'Other' && vehicleForm['customBrand'].isEmpty) ||
(vehicleForm['model'] == 'Other' && vehicleForm['customModel'].isEmpty) ||
(vehicleForm['color'] == 'Other' && vehicleForm['customColor'].isEmpty)) {
setState(() {
errorMessage = 'Veuillez spécifier les champs personnalisés si "Other" est sélectionné';
});
return;
}

final response = await http.post(
Uri.parse('http://10.0.2.2:8082/parking/api/vehicle'),
headers: {
'Content-Type': 'application/json',
'Authorization': 'Bearer $token',
},
body: jsonEncode({
'userId': 'current_user_id', // Replace with actual user ID from auth
'matricule': vehicleForm['matricule'],
'vehicleType': 'car',
'brand': brand,
'model': model,
'color': color,
}),
);

if (response.statusCode == 200) {
_resetForm();
_fetchVehicles();
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Véhicule ajouté avec succès')),
);
} else {
setState(() {
errorMessage = 'Erreur: ${response.body}';
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

void _startEditVehicle(Map<String, dynamic> vehicle) {
setState(() {
editVehicleForm = {
...vehicle,
'originalMatricule': vehicle['matricule'],
};
});
}

Future<void> _updateVehicle() async {
if (editVehicleForm == null || _formKey.currentState!.validate()) {
setState(() {
isLoading = true;
errorMessage = null;
});

try {
final token = await _storage.read(key: 'auth_token');
if (token == null) {
Navigator.pushReplacementNamed(context, '/login');
return;
}

final color = editVehicleForm!['color'] == 'Other' ? editVehicleForm!['customColor'] : editVehicleForm!['color'];

final response = await http.put(
Uri.parse('http://10.0.2.2:8082/parking/api/user/update-vehicle/${editVehicleForm!['id']}'),
headers: {
'Content-Type': 'application/json',
'Authorization': 'Bearer $token',
},
body: jsonEncode({
'matricule': editVehicleForm!['matricule'],
'vehicleType': editVehicleForm!['vehicleType'],
'brand': editVehicleForm!['brand'],
'model': editVehicleForm!['model'],
'color': color,
}),
);

if (response.statusCode == 200) {
setState(() {
editVehicleForm = null;
});
_fetchVehicles();
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Véhicule mis à jour avec succès')),
);
} else {
setState(() {
errorMessage = 'Erreur: ${response.body}';
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

void _cancelEdit() {
setState(() {
editVehicleForm = null;
});
}

Future<void> _deleteVehicle(Map<String, dynamic> vehicle) async {
if (await showDialog(
context: context,
builder: (context) => AlertDialog(
title: const Text('Confirmer la suppression'),
content: Text('Êtes-vous sûr de vouloir supprimer le véhicule avec la matricule ${vehicle['matricule']} ?'),
actions: [
TextButton(
onPressed: () => Navigator.pop(context, false),
child: const Text('Annuler'),
),
TextButton(
onPressed: () => Navigator.pop(context, true),
child: const Text('Supprimer'),
),
],
),
) ?? false) {
setState(() {
isLoading = true;
errorMessage = null;
});

try {
final token = await _storage.read(key: 'auth_token');
if (token == null) {
Navigator.pushReplacementNamed(context, '/login');
return;
}

final response = await http.delete(
Uri.parse('http://10.0.2.2:8082/parking/api/user/vehicle/${vehicle['id']}'),
headers: {
'Content-Type': 'application/json',
'Authorization': 'Bearer $token',
},
);

if (response.statusCode == 200) {
_fetchVehicles();
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(content: Text('Véhicule supprimé avec succès')),
);
} else {
setState(() {
errorMessage = 'Erreur: ${response.body}';
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

void _resetForm() {
setState(() {
vehicleForm = {
'matricule': '',
'brand': '',
'customBrand': '',
'model': '',
'customModel': '',
'color': '',
'customColor': '',
'matriculeImageUrl': '',
};
selectedFile = null;
editVehicleForm = null;
errorMessage = null;
});
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(
backgroundColor: AppColors.primaryColor,
title: Text(
'Mes Véhicules',
style: GoogleFonts.poppins(
color: AppColors.whiteColor,
fontSize: 20,
fontWeight: FontWeight.w600,
),
),
centerTitle: true,
),
body: Padding(
padding: const EdgeInsets.all(16.0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const Text(
'Mes Véhicules',
style: TextStyle(
fontSize: 24,
fontWeight: FontWeight.bold,
fontFamily: 'Poppins',
),
textAlign: TextAlign.center,
),
const SizedBox(height: 8),
const Text(
'Gérez vos véhicules enregistrés',
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
Expanded(
child: SingleChildScrollView(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
if (vehicles.isEmpty)
Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
const Icon(Icons.directions_car, size: 48, color: Colors.grey),
const SizedBox(height: 8),
const Text(
'Aucun véhicule',
style: TextStyle(
fontSize: 16,
color: Colors.grey,
fontFamily: 'Poppins',
),
),
],
),
),
if (vehicles.isNotEmpty)
...vehicles.map((vehicle) => Container(
margin: const EdgeInsets.only(bottom: 12),
  decoration: BoxDecoration(
    border: Border(
      left: const BorderSide(color: AppColors.primaryColor, width: 4),
    ),
    borderRadius: const BorderRadius.only(
      topRight: Radius.circular(8),
      bottomRight: Radius.circular(8),
    ),
    color: Colors.grey[50],
  ),
child: ListTile(
contentPadding: const EdgeInsets.all(16),
leading: const Icon(Icons.directions_car, color: AppColors.primaryColor),
title: Text(
'${vehicle['brand'] ?? 'N/A'} ${vehicle['model'] ?? 'N/A'}',
style: GoogleFonts.poppins(
fontWeight: FontWeight.w500,
color: AppColors.textColor,
),
),
subtitle: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text(
'Matricule: ${vehicle['matricule'] ?? 'N/A'}',
style: GoogleFonts.poppins(
fontSize: 14,
color: AppColors.subtitleColor,
),
),
Text(
'Couleur: ${vehicle['color'] ?? 'N/A'}',
style: GoogleFonts.poppins(
fontSize: 14,
color: AppColors.subtitleColor,
),
),
],
),
trailing: Row(
mainAxisSize: MainAxisSize.min,
children: [
IconButton(
icon: const Icon(Icons.edit, color: Colors.blue),
onPressed: () => _startEditVehicle(vehicle),
),
IconButton(
icon: const Icon(Icons.delete, color: Colors.red),
onPressed: () => _deleteVehicle(vehicle),
),
],
),
),
)).toList(),
if (editVehicleForm != null)
Form(
key: _formKey,
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const SizedBox(height: 24),
const Text(
'Modifier le Véhicule',
style: TextStyle(
fontSize: 20,
fontWeight: FontWeight.bold,
fontFamily: 'Poppins',
),
textAlign: TextAlign.center,
),
const SizedBox(height: 16),
TextFormField(
initialValue: editVehicleForm!['matricule'],
decoration: InputDecoration(
labelText: 'Matricule',
border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
filled: true,
fillColor: AppColors.grayColor,
),
validator: (value) =>
value!.isEmpty ? 'Matricule requis' : null,
onChanged: (value) => editVehicleForm!['matricule'] = value,
),
const SizedBox(height: 16),
TextFormField(
initialValue: editVehicleForm!['brand'],
decoration: InputDecoration(
labelText: 'Marque',
border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
filled: true,
fillColor: AppColors.grayColor,
),
enabled: false,
),
const SizedBox(height: 16),
TextFormField(
initialValue: editVehicleForm!['model'],
decoration: InputDecoration(
labelText: 'Modèle',
border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
filled: true,
fillColor: AppColors.grayColor,
),
enabled: false,
),
const SizedBox(height: 16),
DropdownButtonFormField<String>(
value: editVehicleForm!['color'],
decoration: InputDecoration(
labelText: 'Couleur',
border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
filled: true,
fillColor: AppColors.grayColor,
),
items: colors.map((color) {
return DropdownMenuItem(
value: color,
child: Text(color),
);
}).toList(),
onChanged: (value) {
setState(() {
editVehicleForm!['color'] = value!;
editVehicleForm!.remove('customColor');
});
},
validator: (value) =>
value == null || value.isEmpty ? 'Couleur requise' : null,
),
if (editVehicleForm!['color'] == 'Other')
TextFormField(
decoration: InputDecoration(
labelText: 'Spécifier la couleur',
border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
filled: true,
fillColor: AppColors.grayColor,
),
onChanged: (value) => editVehicleForm!['customColor'] = value,
),
const SizedBox(height: 24),
Row(
mainAxisAlignment: MainAxisAlignment.end,
children: [
TextButton(
onPressed: _cancelEdit,
child: const Text('Annuler'),
),
const SizedBox(width: 16),
ElevatedButton(
onPressed: _updateVehicle,
style: ElevatedButton.styleFrom(
backgroundColor: AppColors.secondaryColor,
foregroundColor: AppColors.textColor,
minimumSize: const Size(120, 50),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
),
child: const Text('Mettre à jour'),
),
],
),
],
),
),
if (editVehicleForm == null)
Form(
key: _formKey,
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const SizedBox(height: 24),
const Text(
'Ajouter un Véhicule',
style: TextStyle(
fontSize: 20,
fontWeight: FontWeight.bold,
fontFamily: 'Poppins',
),
textAlign: TextAlign.center,
),
const SizedBox(height: 16),
GestureDetector(
onTap: _pickImage,
child: AbsorbPointer(
child: TextFormField(
decoration: InputDecoration(
labelText: 'Image de la Plaque',
border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
filled: true,
fillColor: AppColors.grayColor,
),
enabled: false,
),
),
),
if (vehicleForm['matriculeImageUrl'] != null && vehicleForm['matriculeImageUrl'].isNotEmpty)
Padding(
padding: const EdgeInsets.only(top: 8.0),
child: Image.file(
File(vehicleForm['matriculeImageUrl']),
width: 128,
height: 96,
fit: BoxFit.cover,
),
),
ElevatedButton(
onPressed: _sendPlateImage,
style: ElevatedButton.styleFrom(
backgroundColor: AppColors.secondaryColor,
foregroundColor: AppColors.textColor,
minimumSize: const Size(double.infinity, 50),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
),
child: const Text('Envoyer l\'Image'),
),
TextFormField(
initialValue: vehicleForm['matricule'],
decoration: InputDecoration(
labelText: 'Matricule (sera rempli par l\'IA)',
border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
filled: true,
fillColor: AppColors.grayColor,
),
enabled: false,
),
const SizedBox(height: 16),
DropdownButtonFormField<String>(
value: vehicleForm['brand'].isNotEmpty ? vehicleForm['brand'] : null,
decoration: InputDecoration(
labelText: 'Marque',
border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
filled: true,
fillColor: AppColors.grayColor,
),
items: brands.map((brand) {
return DropdownMenuItem(
value: brand,
child: Text(brand),
);
}).toList(),
onChanged: (value) {
setState(() {
vehicleForm['brand'] = value!;
vehicleForm['customBrand'] = '';
});
},
validator: (value) =>
value == null || value.isEmpty ? 'Marque requise' : null,
),
if (vehicleForm['brand'] == 'Other')
TextFormField(
decoration: InputDecoration(
labelText: 'Spécifier la marque',
border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
filled: true,
fillColor: AppColors.grayColor,
),
onChanged: (value) => vehicleForm['customBrand'] = value,
),
const SizedBox(height: 16),
DropdownButtonFormField<String>(
value: vehicleForm['model'].isNotEmpty ? vehicleForm['model'] : null,
decoration: InputDecoration(
labelText: 'Modèle',
border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
filled: true,
fillColor: AppColors.grayColor,
),
items: models.map((model) {
return DropdownMenuItem(
value: model,
child: Text(model),
);
}).toList(),
onChanged: (value) {
setState(() {
vehicleForm['model'] = value!;
vehicleForm['customModel'] = '';
});
},
validator: (value) =>
value == null || value.isEmpty ? 'Modèle requis' : null,
),
if (vehicleForm['model'] == 'Other')
TextFormField(
decoration: InputDecoration(
labelText: 'Spécifier le modèle',
border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
filled: true,
fillColor: AppColors.grayColor,
),
onChanged: (value) => vehicleForm['customModel'] = value,
),
const SizedBox(height: 16),
DropdownButtonFormField<String>(
value: vehicleForm['color'].isNotEmpty ? vehicleForm['color'] : null,
decoration: InputDecoration(
labelText: 'Couleur',
border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
filled: true,
fillColor: AppColors.grayColor,
),
items: colors.map((color) {
return DropdownMenuItem(
value: color,
child: Text(color),
);
}).toList(),
onChanged: (value) {
setState(() {
vehicleForm['color'] = value!;
vehicleForm['customColor'] = '';
});
},
validator: (value) =>
value == null || value.isEmpty ? 'Couleur requise' : null,
),
if (vehicleForm['color'] == 'Other')
TextFormField(
decoration: InputDecoration(
labelText: 'Spécifier la couleur',
border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
filled: true,
fillColor: AppColors.grayColor,
),
onChanged: (value) => vehicleForm['customColor'] = value,
),
if (errorMessage != null)
Padding(
padding: const EdgeInsets.only(top: 8.0),
child: Text(
errorMessage!,
style: TextStyle(color: AppColors.errorColor, fontFamily: 'Poppins'),
),
),
const SizedBox(height: 16),
ElevatedButton(
onPressed: _submitVehicle,
style: ElevatedButton.styleFrom(
backgroundColor: AppColors.secondaryColor,
foregroundColor: AppColors.textColor,
minimumSize: const Size(double.infinity, 50),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
),
child: const Text('Ajouter un Véhicule'),
),
],
),
),
],
),
),
),
],
),
),
);
}
}
