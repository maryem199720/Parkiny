
import 'package:flutter/material.dart';
import '../constants.dart';

class MainLayout extends StatelessWidget {
final String userName;
final bool isDarkMode;
final VoidCallback toggleDarkMode;
final int currentIndex;
final Function(int) onNavTap;
final Widget child;

const MainLayout({
super.key,
required this.userName,
required this.isDarkMode,
required this.toggleDarkMode,
required this.currentIndex,
required this.onNavTap,
required this.child,
});

@override
Widget build(BuildContext context) {
return Scaffold(
extendBody: true,
appBar: AppBar(
backgroundColor: AppColors.primaryColor,
elevation: 0,
automaticallyImplyLeading: false,
actions: [
GestureDetector(
onTap: () => onNavTap(3), // ProfilePage at index 3
child: Padding(
padding: const EdgeInsets.only(right: 16),
child: CircleAvatar(
radius: 24, // Increased size
backgroundColor: AppColors.accentLightColor,
child: Icon(
Icons.person,
color: AppColors.textColor,
size: 30, // Larger icon
),
),
),
),
],
),
body: child,
bottomNavigationBar: Container(
margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
padding: const EdgeInsets.symmetric(horizontal: 8),
height: 70,
decoration: BoxDecoration(
color: AppColors.whiteColor,
borderRadius: BorderRadius.circular(30),
boxShadow: [
BoxShadow(
color: Colors.black.withOpacity(0.2),
blurRadius: 10,
offset: const Offset(0, 4),
),
],
),
child: Row(
mainAxisAlignment: MainAxisAlignment.spaceAround,
children: [
_buildNavItem(Icons.home_outlined, 'Accueil', 0),
_buildNavItem(Icons.event_note_outlined, 'Réservation', 1),
_buildNavItem(Icons.subscriptions, 'Abonnement', 2),
_buildNavItem(Icons.notifications, 'Notification', 3),
],
),
),
);
}

Widget _buildNavItem(IconData icon, String label, int index) {
return GestureDetector(
onTap: () => onNavTap(index),
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
Icon(
icon,
size: 26,
color: currentIndex == index
? AppColors.secondaryColor
    : AppColors.subtitleColor,
),
const SizedBox(height: 4),
Text(
label,
style: TextStyle(
fontSize: 12,
color: currentIndex == index
? AppColors.secondaryColor
    : AppColors.subtitleColor,
),
),
],
),
);
}
}
