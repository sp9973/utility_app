import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  String email = '';
  String password = '';
  bool rememberMe = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                SizedBox(height: 40),

                Icon(Icons.account_balance, size: 80, color: Colors.orange),
                SizedBox(height: 16),

                Text(
                  'Smart Utility Monitor',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                SizedBox(height: 9),
                Text(
                  'Your city, your voice, your change',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),

                SizedBox(height: 42),

                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Email is required';
                    if (!val.contains('@')) return 'Enter valid email';
                    return null;
                  },
                  onSaved: (val) => email = val!.trim(),
                ),

                SizedBox(height: 26),

                TextFormField(
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty)
                      return 'Password is required';
                    if (val.length < 6) return 'Minimum 6 characters';
                    return null;
                  },
                  onSaved: (val) => password = val!.trim(),
                ),

                SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: rememberMe,
                          onChanged: (val) {
                            setState(() {
                              rememberMe = val!;
                            });
                          },
                        ),
                        Text('Remember me'),
                      ],
                    ),

                    TextButton(
                      onPressed: () {
                        // Navigate to Forgot Password Screen later abhi  api nhi hai
                      },
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 24),

                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();

                      // TODO: Add API call here
                      print(
                        'Email: $email, Password: $password, Remember Me: $rememberMe',
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text('Sign In', style: TextStyle(color: Colors.blue)),
                ),

                SizedBox(height: 26),

                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/signup');
                  },
                  child: Text(
                    "Don't have an account?  Sign Up",
                    style: TextStyle(
                      color: Color.fromARGB(255, 119, 21, 184),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
