
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smart_parking/core/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class SubscriptionHistoryPage extends StatefulWidget {
const SubscriptionHistoryPage({Key? key}) : super(key: key);

@override
State<SubscriptionHistoryPage> createState() => _SubscriptionHistoryPageState();
}

class _SubscriptionHistoryPageState extends State<SubscriptionHistoryPage> {
bool isActive = false; // Default to "Expirées"
List<Map<String, dynamic>> activeSubscriptions = [];
List<Map<String, dynamic>> expiredSubscriptions = [];
bool isLoading = true;
String? errorMessage;
final FlutterSecureStorage _storage = const FlutterSecureStorage();

// Filter variables
String? selectedMonth;
String? selectedYear;
final int currentYear = DateTime.now().year;
List<int> years = [];

@override
void initState() {
super.initState();
// Initialize years list (2015 to current year + 5)
years = List.generate(currentYear + 5 - 2015 + 1, (i) => 2015 + i);
selectedYear = currentYear.toString();
_fetchSubscriptions();
}

Future<String?> _getToken() async {
try {
final token = await _storage.read(key: 'auth_token');
return token;
} catch (e) {
setState(() {
errorMessage = 'Erreur lors de la récupération du token: $e';
});
return null;
}
}

Future<int?> _getUserId() async {
try {
final userId = await _storage.read(key: 'user_id');
return userId != null ? int.parse(userId) : null;
} catch (e) {
setState(() {
errorMessage = 'Erreur lors de la récupération de l\'ID utilisateur: $e';
});
return null;
}
}

Future<void> _fetchSubscriptions() async {
setState(() {
isLoading = true;
errorMessage = null;
});

final String? token = await _getToken();
final int? userId = await _getUserId();
if (token == null || userId == null) {
setState(() {
isLoading = false;
errorMessage = 'Erreur de récupération des informations utilisateur';
});
return;
}

try {
// Build query parameters for filtering
final Map<String, dynamic> params = {'userId': userId.toString()};
if (selectedMonth != null) {
params['month'] = selectedMonth;
}
if (selectedYear != null) {
params['year'] = selectedYear;
}

final response = await http.get(
Uri.parse('http://10.0.2.2:8082/api/subscriptions/history').replace(queryParameters: params),
headers: {
'Content-Type': 'application/json',
'Authorization': 'Bearer $token',
},
).timeout(const Duration(seconds: 10), onTimeout: () {
throw Exception('Erreur de récupération des abonnements');
});

if (response.statusCode == 200) {
final data = json.decode(response.body);
final List<dynamic> subscriptions = data is List ? data : [];

final List<Map<String, dynamic>> tempActive = [];
final List<Map<String, dynamic>> tempExpired = [];
final now = DateTime.now();

for (var sub in subscriptions) {
final endDate = sub['endDate'] != null ? DateTime.parse(sub['endDate']) : now;
final subscription = {
'id': sub['id'].toString(),
'startDate': sub['startDate'] != null ? DateTime.parse(sub['startDate']) : now,
'endDate': endDate,
'status': sub['status'] ?? 'EXPIRED',
'totalCost': sub['price']?.toString() ?? '0.0',
'remainingPlaces': sub['remainingPlaces']?.toString() ?? 'N/A',
};

if (endDate.isAfter(now) && sub['status'] == 'ACTIVE') {
tempActive.add(subscription);
} else {
tempExpired.add(subscription);
}
}

setState(() {
activeSubscriptions = tempActive;
expiredSubscriptions = tempExpired;
isLoading = false;
});
} else {
setState(() {
errorMessage = 'Erreur de récupération des abonnements: ${response.body}';
isLoading = false;
});
}
} catch (e) {
setState(() {
errorMessage = 'Erreur de récupération des abonnements: $e';
isLoading = false;
});
}
}

List<Map<String, String>> getMonths() {
return [
{'name': 'Janvier', 'value': '1'},
{'name': 'Février', 'value': '2'},
{'name': 'Mars', 'value': '3'},
{'name': 'Avril', 'value': '4'},
{'name': 'Mai', 'value': '5'},
{'name': 'Juin', 'value': '6'},
{'name': 'Juillet', 'value': '7'},
{'name': 'Août', 'value': '8'},
{'name': 'Septembre', 'value': '9'},
{'name': 'Octobre', 'value': '10'},
{'name': 'Novembre', 'value': '11'},
{'name': 'Décembre', 'value': '12'},
];
}

void applyFilters() {
_fetchSubscriptions();
}

void resetFilters() {
setState(() {
selectedMonth = null;
selectedYear = currentYear.toString();
});
_fetchSubscriptions();
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: AppColors.backgroundColor,
appBar: AppBar(
backgroundColor: AppColors.primaryColor,
title: Text(
"Historique des Abonnements",
style: GoogleFonts.poppins(
color: AppColors.whiteColor,
fontSize: 20,
fontWeight: FontWeight.w600,
),
),
centerTitle: true,
leading: IconButton(
icon: const Icon(Icons.arrow_back, color: AppColors.whiteColor),
onPressed: () => Navigator.pop(context),
),
),
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
    : Padding(
padding: const EdgeInsets.all(16.0),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
if (errorMessage != null)
Container(
margin: const EdgeInsets.only(bottom: 20),
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
// Filter Container
Container(
constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 32),
padding: const EdgeInsets.all(8),
decoration: BoxDecoration(
color: AppColors.grayColor.withOpacity(0.1),
border: Border.all(color: AppColors.grayColor),
borderRadius: BorderRadius.circular(8),
),
child: Wrap(
spacing: 8,
runSpacing: 8,
children: [
Icon(Icons.filter_list, color: AppColors.primaryColor, size: 20),
DropdownButton<String>(
value: selectedMonth,
hint: Text('Tous les mois', style: GoogleFonts.poppins(fontSize: 12)),
items: getMonths().map((month) {
return DropdownMenuItem<String>(
value: month['value'] as String,
child: Text(month['name']!, style: GoogleFonts.poppins(fontSize: 12)),
);
}).toList(),
onChanged: (value) {
setState(() {
selectedMonth = value;
});
applyFilters();
},
style: GoogleFonts.poppins(
color: AppColors.textColor,
fontSize: 12,
),
underline: Container(),
dropdownColor: AppColors.whiteColor,
borderRadius: BorderRadius.circular(12),
),
DropdownButton<String>(
value: selectedYear,
items: years.map((year) {
return DropdownMenuItem<String>(
value: year.toString(),
child: Text(year.toString(), style: GoogleFonts.poppins(fontSize: 12)),
);
}).toList(),
onChanged: (value) {
setState(() {
selectedYear = value;
});
applyFilters();
},
style: GoogleFonts.poppins(
color: AppColors.textColor,
fontSize: 12,
),
underline: Container(),
dropdownColor: AppColors.whiteColor,
borderRadius: BorderRadius.circular(12),
),
ElevatedButton(
onPressed: applyFilters,
style: ElevatedButton.styleFrom(
backgroundColor: AppColors.whiteColor,
foregroundColor: AppColors.textColor,
padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
),
child: Text(
'Filtrer',
style: GoogleFonts.poppins(fontSize: 11),
),
),
],
),
),
const SizedBox(height: 20),
// Toggle Buttons
Row(
mainAxisAlignment: MainAxisAlignment.center,
children: [
ElevatedButton(
onPressed: () {
setState(() {
isActive = true;
});
},
style: ElevatedButton.styleFrom(
backgroundColor: isActive ? AppColors.primaryColor : AppColors.grayColor,
foregroundColor: isActive ? AppColors.whiteColor : AppColors.textColor,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
),
child: Text(
"Actifs",
style: GoogleFonts.poppins(
fontSize: 16,
fontWeight: FontWeight.w500,
color: isActive ? AppColors.whiteColor : AppColors.textColor,
),
),
),
const SizedBox(width: 12),
ElevatedButton(
onPressed: () {
setState(() {
isActive = false;
});
},
style: ElevatedButton.styleFrom(
backgroundColor: isActive ? AppColors.grayColor : AppColors.primaryColor,
foregroundColor: isActive ? AppColors.textColor : AppColors.whiteColor,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
),
child: Text(
"Expirés",
style: GoogleFonts.poppins(
fontSize: 16,
fontWeight: FontWeight.w500,
color: isActive ? AppColors.textColor : AppColors.whiteColor,
),
),
),
],
),
const SizedBox(height: 20),
// Subscription List
Expanded(
child: Card(
elevation: 2,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
child: isActive
? _buildSubscriptionList(activeSubscriptions)
    : _buildSubscriptionList(expiredSubscriptions),
),
),
],
),
),
);
}

Widget _buildSubscriptionList(List<Map<String, dynamic>> subscriptions) {
if (subscriptions.isEmpty) {
return Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
const Icon(Icons.subscriptions, size: 48, color: AppColors.subtitleColor),
const SizedBox(height: 12),
Text(
isActive ? 'Aucun abonnement actif' : 'Aucun abonnement expiré',
style: GoogleFonts.poppins(
color: AppColors.subtitleColor,
fontSize: 16,
),
),
],
),
);
}

return ListView.builder(
padding: const EdgeInsets.all(16.0),
itemCount: subscriptions.length,
itemBuilder: (context, index) {
final subscription = subscriptions[index];
return Card(
elevation: 1,
margin: const EdgeInsets.only(bottom: 12),
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
child: ListTile(
contentPadding: const EdgeInsets.all(12),
leading: Container(
padding: const EdgeInsets.all(8),
decoration: BoxDecoration(
color: AppColors.primaryLightColor,
borderRadius: BorderRadius.circular(8),
),
child: const Icon(Icons.subscriptions, color: AppColors.primaryColor),
),
title: Text(
'Abonnement #${subscription['id']}',
style: GoogleFonts.poppins(
fontSize: 16,
fontWeight: FontWeight.w600,
color: AppColors.textColor,
),
),
subtitle: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
const SizedBox(height: 4),
Text(
'Début: ${DateFormat('dd/MM/yyyy').format(subscription['startDate'])}',
style: GoogleFonts.poppins(
fontSize: 14,
color: AppColors.subtitleColor,
),
),
Text(
'Fin: ${DateFormat('dd/MM/yyyy').format(subscription['endDate'])}',
style: GoogleFonts.poppins(
fontSize: 14,
color: AppColors.subtitleColor,
),
),
Text(
'Coût: ${subscription['totalCost']} DT',
style: GoogleFonts.poppins(
fontSize: 14,
color: AppColors.subtitleColor,
),
),
Text(
'Places restantes: ${subscription['remainingPlaces']}',
style: GoogleFonts.poppins(
fontSize: 14,
color: AppColors.subtitleColor,
),
),
],
),
trailing: Icon(
subscription['status'] == 'ACTIVE' ? Icons.access_time : Icons.check_circle,
color: subscription['status'] == 'ACTIVE' ? AppColors.secondaryColor : AppColors.successColor,
),
),
);
},
);
}
}
