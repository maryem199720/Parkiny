import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';

class ParkingSelectionPage extends StatefulWidget {
  final String startTime;
  final String endTime;
  final String matricule;
  final int userId;

  const ParkingSelectionPage({
    super.key,
    required this.startTime,
    required this.endTime,
    required this.matricule,
    required this.userId,
  });

  @override
  State<ParkingSelectionPage> createState() => _ParkingSelectionPageState();
}

class _ParkingSelectionPageState extends State<ParkingSelectionPage> {
  String? selectedSpotId;
  List<Map<String, dynamic>> parkingSpots = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchParkingSpots();
  }

  Future<void> _fetchParkingSpots() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8082/parking/api/parking-spots/available'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer your_token_here', // Replace with actual token
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          parkingSpots = data.map((spot) => {
            'id': spot['id'].toString(),
            'status': spot['available'] ? 'available' : 'reserved',
          }).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Failed to load parking spots: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching parking spots: $e';
        isLoading = false;
      });
    }
  }

  void selectSpot(String spotId) {
    setState(() {
      selectedSpotId = spotId == selectedSpotId ? null : spotId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Parking Spot', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
        backgroundColor: AppColors.primaryColor,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryColor))
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (errorMessage != null)
              Card(
                color: AppColors.errorColor.withOpacity(0.1),
                child: ListTile(
                  leading: const Icon(Icons.error, color: AppColors.errorColor),
                  title: Text(errorMessage!, style: GoogleFonts.poppins(color: AppColors.errorColor)),
                ),
              ),
            Expanded(
              child: parkingSpots.isEmpty
                  ? const Center(child: Text('No spots available', style: TextStyle(color: AppColors.subtitleColor)))
                  : GridView.count(
                crossAxisCount: 3,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: parkingSpots.map((spot) {
                  final isSelected = selectedSpotId == spot['id'];
                  final isAvailable = spot['status'] == 'available';
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    color: isSelected
                        ? AppColors.secondaryColor.withOpacity(0.2)
                        : spot['status'] == 'reserved'
                        ? AppColors.grayColor
                        : AppColors.whiteColor,
                    child: InkWell(
                      onTap: isAvailable ? () => selectSpot(spot['id']) : null,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.local_parking,
                            color: isAvailable ? AppColors.successColor : AppColors.errorColor,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            spot['id'],
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: selectedSpotId != null
                  ? () => Navigator.pop(context, selectedSpotId)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondaryColor,
                foregroundColor: AppColors.primaryDarkColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Text('Continue', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      ),
    );
  }
}