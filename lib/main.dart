import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const RideHailingApp());
}

class RideHailingApp extends StatelessWidget {
  const RideHailingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RideApp - Ứng dụng đặt xe',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
