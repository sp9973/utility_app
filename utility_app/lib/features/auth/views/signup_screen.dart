import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  String fullName = '';
  String email = '';
  String phone = '';
  String password = '';
  String role = 'Citizen';

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
                Icon(
                  Icons.account_balance,
                  size: 80,
                  color: Color.fromARGB(255, 255, 116, 51),
                ),
                SizedBox(height: 16),

                Text(
                  'Smart Utility Monitor',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),

                SizedBox(height: 8),
                Text(
                  'Your city, your voice, your change',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),

                SizedBox(height: 32),

                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty)
                      return 'Full Name is required';
                    return null;
                  },
                  onSaved: (val) => fullName = val!.trim(),
                ),

                SizedBox(height: 16),

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
                    if (!val.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                  onSaved: (val) => email = val!.trim(),
                ),

                SizedBox(height: 16),

                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Phone is required';
                    if (val.length < 10) return 'Enter valid phone number';
                    return null;
                  },
                  onSaved: (val) => phone = val!.trim(),
                ),

                SizedBox(height: 16),

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

                DropdownButtonFormField<String>(
                  value: role,
                  items:
                      ['Citizen', 'Authority', 'Admin']
                          .map(
                            (role) => DropdownMenuItem(
                              value: role,
                              child: Text(role),
                            ),
                          )
                          .toList(),
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (val) => setState(() => role = val!),
                ),

                SizedBox(height: 32),

                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();

                      // TODO: Call signup API here
                      print(
                        'Signup Data: $fullName, $email, $phone, $password, $role',
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Create Account',
                    style: TextStyle(color: Color.fromARGB(255, 119, 21, 184)),
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
