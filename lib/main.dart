import 'package:flutter/material.dart';
import 'package:life_journal/managers/theme_manager.dart';
import 'package:life_journal/screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    const Color seedColor = Color.fromARGB(255, 189, 83, 124);

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'Life Journal',
          theme: ThemeData().copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color.fromARGB(255, 64, 142, 145),
            ),
          ),
          darkTheme: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Color.fromARGB(255, 141, 110, 99),
              brightness: Brightness.dark,
            ),
          ),
          themeMode: currentMode,
          home: HomeScreen(),
        );
      },
    );
  }
}
