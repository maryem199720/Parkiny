import 'package:flutter/material.dart';
import 'package:smart_parking/views/auth/login_page.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/parkiny.jpeg',
              height: 150,
            ),
            const SizedBox(height: 20),
            const Text(
              "Parkiny",
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 50),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text(
                "Get Started",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }
}