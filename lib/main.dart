import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'gamification_logic.dart';

void main() {
  runApp(const PopSlangGoApp());
}

class PopSlangGoApp extends StatelessWidget {
  const PopSlangGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '俚語大冒險',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6B35)),
        useMaterial3: true,
      ),
  home: HomeScreen(
  profile: createUserProfileFromOnboarding(
    userId: 'lincc',
    name: 'Chris',
    birthday: DateTime(1985, 10, 19),
  ),
  monthlyCheckInData: const {},
      ),
    );
  }
}