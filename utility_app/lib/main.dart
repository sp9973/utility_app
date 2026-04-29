import 'dart:async';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:utility_app/features/auth/views/splash_screen.dart';
import 'package:utility_app/firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:utility_app/core/i18n/language_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // >>> ENABLE APP CHECK PROPERLY (IMPORTANT) <<<
  await FirebaseAppCheck.instance.activate(
    providerAndroid: AndroidPlayIntegrityProvider(),
    providerApple: AppleDeviceCheckProvider(),
    
  );

  // Catch Flutter errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  // Run app inside a zone
  runZonedGuarded(
    () {
      runApp(
        ChangeNotifierProvider(
          create: (_) => LanguageProvider(),
          child: const MyApp(),
        ),
      );
    },
    (error, stack) {
      print("Zoned Error: $error");
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final languageProvider = Provider.of<LanguageProvider>(context);

    return MaterialApp(
      title: 'Smart Public Utility App',
      debugShowCheckedModeBanner: false,
      locale: languageProvider.currentLocale,
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('es'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xfff5f5f5),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: Color(0xFF057060),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
