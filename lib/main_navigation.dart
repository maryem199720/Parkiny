
import 'package:flutter/material.dart';
import 'package:smart_parking/views/home/home_page.dart';
import 'package:smart_parking/views/profile/profile_page.dart';
import 'package:smart_parking/views/reservation/reservation_page.dart';
import 'package:smart_parking/views/subscription/subscription_page.dart';
import 'package:smart_parking/views/vehicle/add_vehicle_page.dart' hide SubscriptionPage;
import 'core/layout/main_layout.dart';

class MainNavigation extends StatefulWidget {
const MainNavigation({Key? key}) : super(key: key);

@override
State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
int _selectedIndex = 0;

final List<Widget> _pages = [
HomePage(),              // Index 0: Accueil
ReservationsPage(),       // Index 1: Réservation
SubscriptionPage(),      // Index 2: Abonnement
ProfilePage(),           // Index 3: Profile
];

@override
Widget build(BuildContext context) {
return MainLayout(
userName: "User",
isDarkMode: false, // Removed dark mode
toggleDarkMode: () {}, // Removed dark mode toggle
currentIndex: _selectedIndex,
onNavTap: (index) => setState(() => _selectedIndex = index),
child: _pages[_selectedIndex],
);
}
}
