import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() => runApp(const QuickCashApp());

class QuickCashApp extends StatelessWidget {
  const QuickCashApp({super.key});

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF087F5B);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QuickCash',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF6F9F8),
        colorScheme: ColorScheme.fromSeed(seedColor: green),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: green,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
