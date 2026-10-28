import 'package:flutter/material.dart';

import 'features/auth/buyer_auth_screen.dart';

void main() {
  runApp(const NuvoraBuyerApp());
}

class NuvoraBuyerApp extends StatelessWidget {
  const NuvoraBuyerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nuvora Buyer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff542261)),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xfff8f5f8),
        ),
      ),
      home: const BuyerAuthScreen(),
    );
  }
}
