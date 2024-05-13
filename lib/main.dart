import 'dart:ui';

import 'package:adda/pages/home_page.dart';
import 'package:adda/pages/sign_in_page.dart';
import 'package:adda/providers/theme_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  
  TextTheme getTextTheme(Color textColor) {
    return TextTheme(
      bodySmall: GoogleFonts.poppins().copyWith(
        color: textColor,
      ),
      bodyMedium: GoogleFonts.robotoMono().copyWith(
        color: textColor,
      ),
      bodyLarge: GoogleFonts.poppins().copyWith(
        color: textColor,
      ),
      headlineMedium: GoogleFonts.oswald().copyWith(
        color: textColor,
      ),
      headlineSmall: GoogleFonts.oswald().copyWith(
        color: textColor,
      ),
      headlineLarge: GoogleFonts.oswald().copyWith(
        color: textColor,
      ),
      labelMedium: GoogleFonts.kanit().copyWith(
        color: textColor,
      ),
      labelSmall: GoogleFonts.kanit().copyWith(
        color: textColor,
      ),
      labelLarge: GoogleFonts.teko().copyWith(
        fontSize: 20,
        color: textColor,
      ),
      titleLarge: GoogleFonts.teko().copyWith(
        fontSize: 20,
        color: textColor,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Adda',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(useMaterial3: true).copyWith(
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Colors.deepPurple,
          unselectedItemColor: Colors.grey,
        ),
        textTheme: getTextTheme(Colors.black),
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            backgroundColor: Colors.black,
            selectedItemColor: Colors.purple.shade100,
            unselectedItemColor: Colors.grey,
          ),
          textTheme: getTextTheme(Colors.white)
      ),
      themeMode: themeProvider.themeMode,
      home:const MyStatelessWidget(),
    );
  }
}

class MyStatelessWidget extends StatelessWidget {
  const MyStatelessWidget({super.key});

  @override
  Widget build(BuildContext context) {

    if (FirebaseAuth.instance.currentUser==null) {
      return const SignInPage();
    }
    else {
      return const HomePage();
    }
  }
}



