import 'package:flutter/material.dart';
import 'screens/signup_screen/login_screen.dart';

void main() {
  runApp(const CareMeApp());
}

class CareMeApp extends StatelessWidget {
  const CareMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareMe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'SF Pro Display',
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF7BB8F0)),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
