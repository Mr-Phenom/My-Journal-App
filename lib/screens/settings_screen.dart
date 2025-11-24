import 'package:flutter/material.dart';
import 'package:life_journal/managers/theme_manager.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // We use ValueListenableBuilder here too, just to update the
    // radio buttons visually when the selection changes.
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ValueListenableBuilder<ThemeMode>(
        valueListenable: themeNotifier,
        builder: (context, currentMode, child) {
          return ListView(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  "Appearance",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
              RadioListTile<ThemeMode>(
                title: const Text("System Default"),
                subtitle: const Text("Follows your phone's settings"),
                value: ThemeMode.system,
                groupValue: currentMode,
                onChanged: (value) {
                  if (value != null) themeNotifier.value = value;
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text("Light Mode"),
                value: ThemeMode.light,
                groupValue: currentMode,
                onChanged: (value) {
                  if (value != null) themeNotifier.value = value;
                },
              ),
              RadioListTile<ThemeMode>(
                title: const Text("Dark Mode"),
                value: ThemeMode.dark,
                groupValue: currentMode,
                onChanged: (value) {
                  if (value != null) themeNotifier.value = value;
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
