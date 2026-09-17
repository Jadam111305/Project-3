import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'A Password Game',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF533827)),
        scaffoldBackgroundColor: const Color(0xFFF1E2CB),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
