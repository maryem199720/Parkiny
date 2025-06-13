import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:smart_parking/models/notification.dart';
import 'package:smart_parking/views/subscription/subscription_page.dart';
import '../../core/constants.dart';
import 'notification_provider.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  @override
  void initState() {
    super.initState();
    // Initialize notifications when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<NotificationProviderImproved>(context, listen: false);
      provider.init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: GoogleFonts.roboto(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? AppColors.whiteColor : AppColors.textColor,
          ),
        ),
        backgroundColor: isDarkMode ? AppColors.darkBackgroundColor : AppColors.whiteColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Consumer<NotificationProviderImproved>(
            builder: (context, provider, child) {
              return IconButton(
                icon: Icon(
                  provider.isConnected ? Icons.wifi : Icons.wifi_off,
                  color: provider.isConnected ? Colors.green : Colors.red,
                ),
                onPressed: () {
                  if (!provider.isConnected) {
                    provider.connectWebSocket();
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<NotificationProviderImproved>(
        builder: (context, provider, child) {
          if (provider.notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 64,
                    color: isDarkMode ? AppColors.accentLightColor : AppColors.subtitleColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune notification disponible',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      color: isDarkMode ? AppColors.accentLightColor : AppColors.subtitleColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    provider.isConnected ? 'Connecté au serveur' : 'Connexion en cours...',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: provider.isConnected ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: provider.fetchNotifications,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.notifications.length,
              itemBuilder: (context, index) {
                final notification = provider.notifications[index];
                return Card(
                  color: isDarkMode ? AppColors.primaryDarkColor : AppColors.whiteColor,
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: notification.isRead
                          ? (isDarkMode ? AppColors.accentLightColor : AppColors.subtitleColor)
                          : AppColors.primaryColor,
                      child: Icon(
                        _getNotificationIcon(notification.type),
                        color: AppColors.whiteColor,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      notification.message,
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                        color: isDarkMode ? AppColors.whiteColor : AppColors.textColor,
                      ),
                    ),
                    subtitle: Text(
                      _formatDateTime(notification.createdAt),
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: isDarkMode ? AppColors.accentLightColor : AppColors.subtitleColor,
                      ),
                    ),
                    trailing: notification.isRead
                        ? null
                        : const Icon(
                      Icons.circle,
                      color: AppColors.errorColor,
                      size: 10,
                    ),
                    onTap: () {
                      if (!notification.isRead) {
                        provider.markAsRead(notification.id);
                      }
                      _handleNotificationTap(context, notification);
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'SUBSCRIPTION_RENEWAL':
        return Icons.autorenew;
      case 'RESERVATION_REMINDER':
        return Icons.schedule;
      case 'PAYMENT_SUCCESS':
        return Icons.payment;
      case 'PAYMENT_FAILED':
        return Icons.payment_outlined;
      default:
        return Icons.notifications;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return 'Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}';
    } else {
      return 'À l\'instant';
    }
  }

  void _handleNotificationTap(BuildContext context, ParkingNotification notification) {
    if (notification.type == 'SUBSCRIPTION_RENEWAL' &&
        notification.action != null &&
        notification.action!['action'] == 'RENEW') {
      final subscriptionId = notification.action!['subscriptionId'] as int?;
      if (subscriptionId != null) {
        print('Navigating to SubscriptionPage with subscriptionId: $subscriptionId');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SubscriptionPage(subscriptionId: subscriptionId),
          ),
        );
      } else {
        print('Error: subscriptionId is null in action: ${notification.action}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Erreur : ID d\'abonnement manquant.',
              style: GoogleFonts.roboto(color: AppColors.whiteColor),
            ),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
    }
  }
}

