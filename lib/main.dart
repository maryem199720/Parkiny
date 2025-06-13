import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_parking/views/notification/notification_provider.dart';
import 'package:smart_parking/views/splash/splash_screen.dart';
import 'package:smart_parking/views/auth/login_page.dart';
import 'package:smart_parking/views/home/home_page.dart';
import 'package:smart_parking/views/auth/signup_page.dart';
import 'core/theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => NotificationProviderImproved(),
        ),
      ],
      child: MaterialApp(
        title: 'Parkiny',
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: lightTheme,
        themeMode: ThemeMode.system,
        initialRoute: '/splash',
        routes: {
          '/splash': (context) => const SplashScreen(),
          '/login': (context) => const LoginPage(),
          '/home': (context) => const HomePage(),
          '/signup': (context) => const SignupPage(),
        },
      ),
    );
  }
}