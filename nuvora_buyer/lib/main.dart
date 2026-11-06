import 'package:flutter/material.dart';

import 'dashboard/mockup_screens/splash_screen.dart'; // adjust to where splash_screen.dart lives

void main() {
  runApp(const NuvoraBuyerApp());
}

class NuvoraBuyerApp extends StatelessWidget {
  const NuvoraBuyerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nuvora Buyer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF143628)),
        useMaterial3: true,
      ),
      home: const MockupSplashScreen(), // splash first, then it goes to login
    );
  }
}