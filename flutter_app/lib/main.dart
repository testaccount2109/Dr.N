import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const DrNApp());
}

class DrNApp extends StatelessWidget {
  const DrNApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dr.N',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00E676),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          backgroundColor: Color(0xFF1A1A2E),
        ),
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
        cardTheme: CardTheme(
          color: const Color(0xFF1A1A2E),
          elevation: 4,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}