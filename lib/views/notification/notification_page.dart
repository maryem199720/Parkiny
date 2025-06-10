import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:smart_parking/models/notification.dart';
import 'package:smart_parking/views/subscription/subscription_page.dart';
import '../../core/constants.dart';
import 'notification_provider.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

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
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          if (provider.notifications.isEmpty) {
            return Center(
              child: Text(
                'Aucune notification disponible',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: isDarkMode ? AppColors.accentLightColor : AppColors.subtitleColor,
                ),
              ),
            );
          }
          return ListView.builder(
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
                  title: Text(
                    notification.message,
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                      color: isDarkMode ? AppColors.whiteColor : AppColors.textColor,
                    ),
                  ),
                  subtitle: Text(
                    notification.createdAt.toString(),
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
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}