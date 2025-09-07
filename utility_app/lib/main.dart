import 'package:flutter/material.dart';

import 'features/auth/views/login_screen.dart';
import 'features/auth/views/signup_screen.dart';
import 'features/auth/views/splash_screen.dart';
import 'routing/app_routes.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Utility Monitor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),

      // all routes hai yahan to understand
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.signup: (context) => const SignupScreen(),
        AppRoutes.login: (context) => const LoginScreen(),
      },
    );
  }
}
