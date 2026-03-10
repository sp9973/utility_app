import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:utility_app/features/auth/views/login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String email = '';
  String password = '';
  String selectedRole = 'citizen'; // Default role
  bool isLoading = false;
  bool _obscurePassword = true;

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => isLoading = true);

    try {
      // ✅ Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ✅ Save user info with role in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'role': selectedRole,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account created successfully as $selectedRole!'),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String errorMsg = 'Signup failed';
      if (e.code == 'email-already-in-use') {
        errorMsg = 'This email is already registered.';
      } else if (e.code == 'weak-password') {
        errorMsg = 'Password is too weak.';
      } else if (e.code == 'invalid-email') {
        errorMsg = 'Invalid email format.';
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(errorMsg)));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // 🌈 Gradient background
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF00BFA5), Color(0xFF057060)],
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
                    Icons.account_circle,
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
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Join the movement for a smarter city',
                    style: TextStyle(color: Colors.white70, fontSize: 15),
                  ),
                  const SizedBox(height: 35),

                  // 📦 Signup Form Container
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
                            "Create Your Account 👋",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF057060),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Email
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

                          // Password
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
                              if (val.length < 6) return 'Minimum 6 characters';
                              return null;
                            },
                            onSaved: (val) => password = val!.trim(),
                          ),
                          const SizedBox(height: 16),

                          // 🧠 Role Dropdown
                          DropdownButtonFormField<String>(
                            initialValue: selectedRole,
                            decoration: InputDecoration(
                              labelText: 'Select Role',
                              prefixIcon: const Icon(
                                Icons.person,
                                color: Color(0xFF057060),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade100,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'citizen',
                                child: Text('Citizen'),
                              ),
                              DropdownMenuItem(
                                value: 'authority',
                                child: Text('Authority'),
                              ),
                              DropdownMenuItem(
                                value: 'admin',
                                child: Text('Admin'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedRole = value!;
                              });
                            },
                          ),
                          const SizedBox(height: 24),

                          // Signup Button
                          ElevatedButton(
                            onPressed: isLoading ? null : _signup,
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
                                      'Create Account',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                          ),
                          const SizedBox(height: 16),

                          // Go to Login
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Already have an account?",
                                style: TextStyle(color: Colors.black87),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(),
                                    ),
                                  );
                                },
                                child: const Text(
                                  "Sign In",
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
