import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants.dart';

class MainLayout extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabChanged;
  final Widget body;

  const MainLayout({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: body,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.whiteColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: onTabChanged,
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.whiteColor,
            selectedItemColor: AppColors.primaryColor,
            unselectedItemColor: AppColors.subtitleColor,
            elevation: 0,
            selectedLabelStyle: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.normal,
            ),
            items: [
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.home_outlined, 0),
                activeIcon: _buildNavIcon(Icons.home, 0),
                label: 'Accueil',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.local_parking_outlined, 1),
                activeIcon: _buildNavIcon(Icons.local_parking, 1),
                label: 'Réserver',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.subscriptions_outlined, 2),
                activeIcon: _buildNavIcon(Icons.subscriptions, 2),
                label: 'Abonnement',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.notifications_outlined, 3),
                activeIcon: _buildNavIcon(Icons.notifications, 3),
                label: 'Notifications',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.person_outline, 4),
                activeIcon: _buildNavIcon(Icons.person, 4),
                label: 'Profil',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index) {
    final isSelected = currentIndex == index;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryColor.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 24,
        color: isSelected ? AppColors.primaryColor : AppColors.subtitleColor,
      ),
    );
  }
}

