import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants.dart';
import '../../models/reservation.dart';

class ReservationHistoryWidget extends StatefulWidget {
  const ReservationHistoryWidget({super.key});

  @override
  State<ReservationHistoryWidget> createState() => _ReservationHistoryWidgetState();
}

class _ReservationHistoryWidgetState extends State<ReservationHistoryWidget> {
  List<Reservation> _reservations = [];
  List<Reservation> _filteredReservations = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'all'; // all, active, expired
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _fetchReservations();
  }

  Future<String?> _getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> _fetchReservations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final token = await _getToken();
    if (token == null) {
      setState(() {
        _errorMessage = 'Token non trouvé';
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8082/parking/api/reservations/my'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _reservations = data.map((json) => Reservation.fromJson(json)).toList();
          _reservations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _applyFilter();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Erreur lors du chargement des réservations: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    setState(() {
      switch (_selectedFilter) {
        case 'active':
          _filteredReservations = _reservations.where((r) => r.isActive).toList();
          break;
        case 'expired':
          _filteredReservations = _reservations.where((r) => r.isExpired).toList();
          break;
        default:
          _filteredReservations = _reservations;
      }
    });
  }

  Future<void> _modifyReservation(Reservation reservation) async {
    if (!reservation.canModify) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cette réservation ne peut plus être modifiée'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    final TimeOfDay? newStartTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.parse(reservation.startTime)),
    );

    if (newStartTime == null) return;

    final TimeOfDay? newEndTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.parse(reservation.endTime)),
    );

    if (newEndTime == null) return;

    final token = await _getToken();
    if (token == null) return;

    try {
      final response = await http.put(
        Uri.parse('http://10.0.2.2:8082/parking/api/reservations/${reservation.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'startTime': '${newStartTime.hour.toString().padLeft(2, '0')}:${newStartTime.minute.toString().padLeft(2, '0')}',
          'endTime': '${newEndTime.hour.toString().padLeft(2, '0')}:${newEndTime.minute.toString().padLeft(2, '0')}',
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Réservation modifiée avec succès'),
            backgroundColor: AppColors.primaryColor,
          ),
        );
        _fetchReservations();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la modification'),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Filter buttons
        Row(
          children: [
            Expanded(
              child: _buildFilterButton('Tous', 'all'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFilterButton('Actifs', 'active'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildFilterButton('Expirés', 'expired'),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Content
        if (_isLoading)
          const Center(child: CircularProgressIndicator())
        else if (_errorMessage != null)
          Center(
            child: Column(
              children: [
                Icon(Icons.error_outline, size: 48, color: AppColors.errorColor),
                const SizedBox(height: 8),
                Text(_errorMessage!, style: GoogleFonts.poppins(color: AppColors.errorColor)),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _fetchReservations,
                  child: Text('Réessayer'),
                ),
              ],
            ),
          )
        else if (_filteredReservations.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.history, size: 48, color: AppColors.subtitleColor),
                  const SizedBox(height: 8),
                  Text(
                    'Aucune réservation trouvée',
                    style: GoogleFonts.poppins(color: AppColors.subtitleColor),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredReservations.length,
              itemBuilder: (context, index) {
                final reservation = _filteredReservations[index];
                return _buildReservationCard(reservation);
              },
            ),
      ],
    );
  }

  Widget _buildFilterButton(String label, String value) {
    final isSelected = _selectedFilter == value;
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _selectedFilter = value;
          _applyFilter();
        });
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppColors.primaryColor : AppColors.whiteColor,
        foregroundColor: isSelected ? AppColors.whiteColor : AppColors.textColor,
        elevation: isSelected ? 2 : 0,
        side: BorderSide(
          color: isSelected ? AppColors.primaryColor : AppColors.grayColor,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildReservationCard(Reservation reservation) {
    final isActive = reservation.isActive;
    final canModify = reservation.canModify;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Réservation #${reservation.id}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    reservation.status,
                    style: GoogleFonts.poppins(
                      color: isActive ? Colors.green : Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Icon(Icons.directions_car, size: 16, color: AppColors.subtitleColor),
                const SizedBox(width: 8),
                Text(
                  reservation.matricule,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: AppColors.subtitleColor),
                const SizedBox(width: 8),
                Text(
                  '${reservation.startTime} - ${reservation.endTime}',
                  style: GoogleFonts.poppins(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Icon(Icons.payment, size: 16, color: AppColors.subtitleColor),
                const SizedBox(width: 8),
                Text(
                  '${reservation.amount.toStringAsFixed(2)} DT',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ],
            ),

            if (canModify) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _modifyReservation(reservation),
                    icon: Icon(Icons.edit, size: 16),
                    label: Text('Modifier'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

