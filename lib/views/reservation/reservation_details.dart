
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:smart_parking/core/constants.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class ReservationDetailsPage extends StatefulWidget {
const ReservationDetailsPage({Key? key}) : super(key: key);

@override
State<ReservationDetailsPage> createState() => _ReservationDetailsPageState();
}

class _ReservationDetailsPageState extends State<ReservationDetailsPage> {
bool isActive = false; // Default to "Expirées"
List<Map<String, dynamic>> activeReservations = [];
List<Map<String, dynamic>> expiredReservations = [];
bool isLoading = true;
String? errorMessage;
final FlutterSecureStorage _storage = const FlutterSecureStorage();

// Filter variables
String filterType = 'month'; // Default filter type: month, week, or year
String? selectedMonth;
String? selectedYear;
DateTime? selectedWeekStartDate;
DateTime? selectedWeekEndDate;
final int currentYear = DateTime.now().year;
List<int> years = [];

@override
void initState() {
super.initState();
// Initialize years list (2015 to current year + 5)
years = List.generate(currentYear + 5 - 2015 + 1, (i) => 2015 + i);
selectedYear = currentYear.toString();
_fetchReservations();
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
final userId = await _storage.read(key: 'user_id'); // Assuming user_id is stored
return userId != null ? int.parse(userId) : null;
} catch (e) {
setState(() {
errorMessage = 'Erreur lors de la récupération de l\'ID utilisateur: $e';
});
return null;
}
}

Future<void> _fetchReservations() async {
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
if (filterType == 'month' && selectedMonth != null) {
params['month'] = selectedMonth;
}
if (selectedYear != null) {
params['year'] = selectedYear;
}
if (filterType == 'week' && selectedWeekStartDate != null && selectedWeekEndDate != null) {
params['startDate'] = DateFormat('yyyy-MM-dd').format(selectedWeekStartDate!);
params['endDate'] = DateFormat('yyyy-MM-dd').format(selectedWeekEndDate!);
}

final response = await http.get(
Uri.parse('http://10.0.2.2:8082/parking/api/reservations/filter').replace(queryParameters: params),
headers: {
'Content-Type': 'application/json',
'Authorization': 'Bearer $token',
},
).timeout(const Duration(seconds: 10), onTimeout: () {
throw Exception('Erreur de récupération des réservations');
});

if (response.statusCode == 200) {
final data = json.decode(response.body);
final List<dynamic> reservations = data['reservations'] ?? [];

final List<Map<String, dynamic>> tempActive = [];
final List<Map<String, dynamic>> tempExpired = [];
final now = DateTime.now();

for (var res in reservations) {
final endTime = DateTime.parse(res['endTime']);
final reservation = {
'id': res['id'].toString(),
'parkingSpotId': res['parkingPlaceId'].toString(),
'startTime': DateTime.parse(res['startTime']),
'endTime': endTime,
'status': res['status'],
'totalCost': res['totalAmount']?.toString() ?? '0.0',
};

if (endTime.isAfter(now) && res['status'] == 'ACTIVE') {
tempActive.add(reservation);
} else {
tempExpired.add(reservation);
}
}

setState(() {
activeReservations = tempActive;
expiredReservations = tempExpired;
isLoading = false;
});
} else {
setState(() {
errorMessage = 'Erreur de récupération des réservations: ${response.body}';
isLoading = false;
});
}
} catch (e) {
setState(() {
errorMessage = 'Erreur de récupération des réservations: $e';
isLoading = false;
});
}
}

Future<void> _deleteReservation(String reservationId) async {
final String? token = await _getToken();
if (token == null) {
setState(() {
errorMessage = 'Erreur de récupération du token';
});
return;
}

try {
final response = await http.delete(
Uri.parse('http://10.0.2.2:8082/parking/api/reservations/$reservationId'),
headers: {
'Content-Type': 'application/json',
'Authorization': 'Bearer $token',
},
).timeout(const Duration(seconds: 10), onTimeout: () {
throw Exception('Erreur de suppression de la réservation');
});

if (response.statusCode == 200) {
setState(() {
expiredReservations = expiredReservations.where((res) => res['id'] != reservationId).toList();
});
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('Réservation supprimée avec succès'),
backgroundColor: AppColors.successColor,
duration: Duration(seconds: 3),
),
);
} else {
setState(() {
errorMessage = 'Erreur de suppression: ${response.body}';
});
}
} catch (e) {
setState(() {
errorMessage = 'Erreur de suppression: $e';
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
if (filterType == 'week' && (selectedWeekStartDate == null || selectedWeekEndDate == null)) {
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('Veuillez sélectionner les dates de début et de fin.'),
backgroundColor: AppColors.errorColor,
duration: Duration(seconds: 3),
),
);
return;
}
_fetchReservations();
}

void resetFilters() {
setState(() {
filterType = 'month';
selectedMonth = null;
selectedYear = currentYear.toString();
selectedWeekStartDate = null;
selectedWeekEndDate = null;
});
_fetchReservations();
}

@override
Widget build(BuildContext context) {
return Scaffold(
backgroundColor: AppColors.backgroundColor,
appBar: AppBar(
backgroundColor: AppColors.primaryColor,
title: Text(
"Détails de la Réservation",
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
Wrap(
spacing: 8,
runSpacing: 8,
children: [
// Filter Container
  Container(
    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 32), // Account for padding
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
        // Filter Type Dropdown
        DropdownButton<String>(
          value: filterType,
          items: [
            DropdownMenuItem(value: 'month', child: Text('Mois')),
            DropdownMenuItem(value: 'week', child: Text('Semaine')),
            DropdownMenuItem(value: 'year', child: Text('Année')),
          ],
          onChanged: (value) {
            setState(() {
              filterType = value!;
              selectedMonth = null;
              selectedWeekStartDate = null;
              selectedWeekEndDate = null;
              selectedYear = currentYear.toString();
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
        // Month Dropdown
        if (filterType == 'month')
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
        // Week Date Pickers
        if (filterType == 'week') ...[
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedWeekStartDate ?? DateTime.now(),
                firstDate: DateTime(2015),
                lastDate: DateTime(currentYear + 5),
              );
              if (picked != null) {
                setState(() {
                  selectedWeekStartDate = picked;
                });
                applyFilters();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.grayColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                selectedWeekStartDate != null
                    ? DateFormat('dd/MM/yy').format(selectedWeekStartDate!)
                    : 'Début',
                style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textColor),
              ),
            ),
          ),
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: selectedWeekEndDate ?? DateTime.now(),
                firstDate: DateTime(2015),
                lastDate: DateTime(currentYear + 5),
              );
              if (picked != null) {
                setState(() {
                  selectedWeekEndDate = picked;
                });
                applyFilters();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.grayColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                selectedWeekEndDate != null
                    ? DateFormat('dd/MM/yy').format(selectedWeekEndDate!)
                    : 'Fin',
                style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textColor),
              ),
            ),
          ),
        ],
        // Year Dropdown
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
        // Filter Button
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
],
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
"Actives",
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
"Expirées",
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
// Reservation List
Expanded(
child: Card(
elevation: 2,
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
child: isActive
? _buildReservationList(activeReservations)
    : _buildReservationList(expiredReservations, isExpired: true),
),
),
],
),
),
);
}

Widget _buildReservationList(List<Map<String, dynamic>> reservations, {bool isExpired = false}) {
if (reservations.isEmpty) {
return Center(
child: Column(
mainAxisAlignment: MainAxisAlignment.center,
children: [
const Icon(Icons.event_busy, size: 48, color: AppColors.subtitleColor),
const SizedBox(height: 12),
Text(
isActive ? 'Aucune réservation active' : 'Aucune réservation expirée',
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
itemCount: reservations.length,
itemBuilder: (context, index) {
final reservation = reservations[index];
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
child: const Icon(Icons.local_parking, color: AppColors.primaryColor),
),
title: Text(
'Place ${reservation['parkingSpotId']}',
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
'Début: ${DateFormat('dd/MM/yyyy HH:mm').format(reservation['startTime'])}',
style: GoogleFonts.poppins(
fontSize: 14,
color: AppColors.subtitleColor,
),
),
Text(
'Fin: ${DateFormat('dd/MM/yyyy HH:mm').format(reservation['endTime'])}',
style: GoogleFonts.poppins(
fontSize: 14,
color: AppColors.subtitleColor,
),
),
Text(
'Coût: ${reservation['totalCost']} DT',
style: GoogleFonts.poppins(
fontSize: 14,
color: AppColors.subtitleColor,
),
),
],
),
trailing: isExpired
? IconButton(
icon: Icon(Icons.delete, color: AppColors.errorColor),
onPressed: () {
showDialog(
context: context,
builder: (context) => AlertDialog(
title: Text('Supprimer la réservation', style: GoogleFonts.poppins()),
content: Text(
'Êtes-vous sûr de vouloir supprimer cette réservation de l\'historique ?',
style: GoogleFonts.poppins(),
),
actions: [
TextButton(
onPressed: () => Navigator.pop(context),
child: Text('Annuler', style: GoogleFonts.poppins()),
),
TextButton(
onPressed: () {
_deleteReservation(reservation['id']);
Navigator.pop(context);
},
child: Text('Confirmer', style: GoogleFonts.poppins(color: AppColors.errorColor)),
),
],
),
);
},
)
    : Icon(
reservation['status'] == 'ACTIVE' ? Icons.access_time : Icons.check_circle,
color: reservation['status'] == 'ACTIVE' ? AppColors.secondaryColor : AppColors.successColor,
),
),
);
},
);
}
}
