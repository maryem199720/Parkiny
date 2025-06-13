import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants.dart';
import '../../models/subscription.dart';

class SubscriptionHistoryWidget extends StatefulWidget {
  const SubscriptionHistoryWidget({super.key});

  @override
  State<SubscriptionHistoryWidget> createState() => _SubscriptionHistoryWidgetState();
}

class _SubscriptionHistoryWidgetState extends State<SubscriptionHistoryWidget> {
  List<SubscriptionHistory> _subscriptions = [];
  List<SubscriptionHistory> _filteredSubscriptions = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedFilter = 'all'; // all, active, expired
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _fetchSubscriptions();
  }

  Future<String?> _getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  Future<void> _fetchSubscriptions() async {
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
        Uri.parse('http://10.0.2.2:8082/parking/api/subscriptions/history'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _subscriptions = data.map((json) => SubscriptionHistory.fromJson(json)).toList();
          _subscriptions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _applyFilter();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Erreur lors du chargement des abonnements: ${response.statusCode}';
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
          _filteredSubscriptions = _subscriptions.where((s) => s.isActive).toList();
          break;
        case 'expired':
          _filteredSubscriptions = _subscriptions.where((s) => s.isExpired).toList();
          break;
        default:
          _filteredSubscriptions = _subscriptions;
      }
    });
  }

  Future<void> _deleteSubscription(SubscriptionHistory subscription) async {
    if (!subscription.canDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Les abonnements actifs ne peuvent pas être supprimés'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la suppression', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text('Êtes-vous sûr de vouloir supprimer cet abonnement ?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: GoogleFonts.poppins(color: AppColors.subtitleColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Supprimer', style: GoogleFonts.poppins(color: AppColors.errorColor)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final token = await _getToken();
    if (token == null) return;

    try {
      final response = await http.delete(
        Uri.parse('http://10.0.2.2:8082/parking/api/subscriptions/${subscription.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Abonnement supprimé avec succès'),
            backgroundColor: AppColors.primaryColor,
          ),
        );
        _fetchSubscriptions();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la suppression'),
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

  Future<void> _modifySubscription(SubscriptionHistory subscription) async {
    if (!subscription.isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seuls les abonnements actifs peuvent être modifiés'),
          backgroundColor: AppColors.errorColor,
        ),
      );
      return;
    }

    final List<String> billingOptions = ['MONTHLY', 'QUARTERLY', 'YEARLY'];
    String? selectedBilling = subscription.billingCycle;

    final String? newBilling = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier l\'abonnement', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Choisir un nouveau cycle de facturation:', style: GoogleFonts.poppins()),
            const SizedBox(height: 16),
            ...billingOptions.map((option) => RadioListTile<String>(
              title: Text(_getBillingDisplayName(option), style: GoogleFonts.poppins()),
              value: option,
              groupValue: selectedBilling,
              onChanged: (value) {
                selectedBilling = value;
                Navigator.pop(context, value);
              },
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: GoogleFonts.poppins(color: AppColors.subtitleColor)),
          ),
        ],
      ),
    );

    if (newBilling == null || newBilling == subscription.billingCycle) return;

    final token = await _getToken();
    if (token == null) return;

    try {
      final response = await http.put(
        Uri.parse('http://10.0.2.2:8082/parking/api/subscriptions/${subscription.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'billingCycle': newBilling,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Abonnement modifié avec succès'),
            backgroundColor: AppColors.primaryColor,
          ),
        );
        _fetchSubscriptions();
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

  String _getBillingDisplayName(String billing) {
    switch (billing) {
      case 'MONTHLY':
        return 'Mensuel';
      case 'QUARTERLY':
        return 'Trimestriel';
      case 'YEARLY':
        return 'Annuel';
      default:
        return billing;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
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
                  onPressed: _fetchSubscriptions,
                  child: Text('Réessayer'),
                ),
              ],
            ),
          )
        else if (_filteredSubscriptions.isEmpty)
            Center(
              child: Column(
                children: [
                  Icon(Icons.subscriptions, size: 48, color: AppColors.subtitleColor),
                  const SizedBox(height: 8),
                  Text(
                    'Aucun abonnement trouvé',
                    style: GoogleFonts.poppins(color: AppColors.subtitleColor),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _filteredSubscriptions.length,
              itemBuilder: (context, index) {
                final subscription = _filteredSubscriptions[index];
                return _buildSubscriptionCard(subscription);
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

  Widget _buildSubscriptionCard(SubscriptionHistory subscription) {
    final isActive = subscription.isActive;

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
                  'Abonnement #${subscription.id}',
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
                    subscription.status,
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
                Icon(Icons.category, size: 16, color: AppColors.subtitleColor),
                const SizedBox(width: 8),
                Text(
                  subscription.subscriptionType,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Icon(Icons.schedule, size: 16, color: AppColors.subtitleColor),
                const SizedBox(width: 8),
                Text(
                  _getBillingDisplayName(subscription.billingCycle),
                  style: GoogleFonts.poppins(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Icon(Icons.date_range, size: 16, color: AppColors.subtitleColor),
                const SizedBox(width: 8),
                Text(
                  '${_formatDate(subscription.startDate)} - ${_formatDate(subscription.endDate)}',
                  style: GoogleFonts.poppins(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Icon(Icons.local_parking, size: 16, color: AppColors.subtitleColor),
                const SizedBox(width: 8),
                Text(
                  '${subscription.remainingPlaces} places restantes',
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
                  '${subscription.amount.toStringAsFixed(2)} DT',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ],
            ),

            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isActive) ...[
                  TextButton.icon(
                    onPressed: () => _modifySubscription(subscription),
                    icon: Icon(Icons.edit, size: 16),
                    label: Text('Modifier'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (subscription.canDelete)
                  TextButton.icon(
                    onPressed: () => _deleteSubscription(subscription),
                    icon: Icon(Icons.delete, size: 16),
                    label: Text('Supprimer'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.errorColor,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

