import 'dart:async';

import 'package:flutter/material.dart';
import 'package:utility_app/routing/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 2), () {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Smart Utility Monitor',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.orange,
              ),
            ),
            SizedBox(height: 40),

            Icon(Icons.account_balance, size: 100, color: Colors.blueAccent),

            SizedBox(height: 24),

            CircularProgressIndicator(color: Colors.green),
          ],
        ),
      ),
    );
  }
}
