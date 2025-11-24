import 'package:flutter/material.dart';

// A simple global variable that holds the current theme mode.
// By default, it follows the System settings.
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);
