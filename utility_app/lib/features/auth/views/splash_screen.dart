import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:utility_app/features/admin/views/admin_dashboard.dart';
import 'package:utility_app/features/auth/views/login_screen.dart';
import 'package:utility_app/features/citizen/views/citizen_home_dashboard.dart';
import 'package:utility_app/features/authority/views/authority_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 2));

    final user = FirebaseAuth.instance.currentUser;

    if (user != null && mounted) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final role = (doc.data()?['role']?.toString().toLowerCase()) ?? 'citizen';

          if (role == 'authority') {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const AuthorityDashboard()));
            return;
          } else if (role == 'admin') {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const AdminDashboard()));
            return;
          } else {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const CitizenHomeDashboard()));
            return;
          }
        }
      } catch (e) {
        print("Auth check failed: $e");
      }
    }

    if (mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
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
