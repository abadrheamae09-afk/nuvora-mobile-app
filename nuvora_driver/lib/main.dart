import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nuvora_driver/core/theme/nuvora_theme.dart';
import 'package:nuvora_driver/features/auth/screens/driver_start_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const NuvoraDriverApp());
}

class NuvoraDriverApp extends StatelessWidget {
  const NuvoraDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nuvora Driver',
      debugShowCheckedModeBanner: false,
      theme: NuvoraTheme.light(),
      home: const DriverStartScreen(),
    );
  }
}
