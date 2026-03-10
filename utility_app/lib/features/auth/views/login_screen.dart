import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:utility_app/features/admin/views/admin_dashboard.dart';
import 'package:utility_app/features/auth/views/signup_screen.dart';
import 'package:utility_app/features/authority/views/authority_dashboard.dart';
import 'package:utility_app/features/citizen/views/citizen_home_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String email = '';
  String password = '';
  bool isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => isLoading = true);

    try {
      // 🔐 Firebase Auth login
      UserCredential userCred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCred.user!.uid;

      // 👥 Fetch role from Firestore
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        throw Exception('User record not found in Firestore.');
      }

      // Safely fetch role and normalize to lowercase
      String role =
          (userDoc.data() as Map<String, dynamic>)['role']
              ?.toString()
              .toLowerCase() ??
          'citizen';

      print('Logged in user role: $role'); // 🔹 For debugging

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login successful!')));

      // 🚀 Navigate based on role
      switch (role) {
        case 'citizen':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const CitizenHomeDashboard(),
            ),
          );
          break;
        case 'authority':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>  AuthorityDashboard(),
            ),
          );
          break;
        case 'admin':
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminDashboard()),
          );
          break;
        default:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid role assigned.')),
          );
      }
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Login failed';
      if (e.code == 'user-not-found') {
        errorMsg = 'No user found for this email.';
      } else if (e.code == 'wrong-password') {
        errorMsg = 'Incorrect password.';
      } else if (e.code == 'invalid-email') {
        errorMsg = 'Invalid email format.';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMsg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF057060), Color(0xFF00BFA5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const Icon(
                    Icons.account_balance,
                    size: 90,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Smart Utility Monitor',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your city, your voice, your change',
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  const SizedBox(height: 35),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const Text(
                            "Welcome Back 👋",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF057060),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: const Icon(
                                Icons.email,
                                color: Color(0xFF057060),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Email is required';
                              }
                              if (!val.contains('@')) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                            onSaved: (val) => email = val!.trim(),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(
                                Icons.lock,
                                color: Color(0xFF057060),
                              ),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return 'Password is required';
                              }
                              return null;
                            },
                            onSaved: (val) => password = val!.trim(),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF057060),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child:
                                isLoading
                                    ? const CircularProgressIndicator(
                                      color: Colors.white,
                                    )
                                    : const Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Don't have an account?",
                                style: TextStyle(color: Colors.black87),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => const SignupScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Sign Up",
                                  style: TextStyle(
                                    color: Color(0xFF057060),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '© 2025 Smart Utility Team',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
