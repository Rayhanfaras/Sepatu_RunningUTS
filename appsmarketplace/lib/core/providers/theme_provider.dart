import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = false; // ← state: false = light, true = dark
  // Getter
  bool get isDark => _isDark;
  // Menghasilkan ThemeMode yang akan dibaca MaterialApp
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;
  // ↑ jika gelap ↑ jika terang
  // Satu-satunya fungsi: balik kondisi
  void toggle() {
    _isDark = !_isDark; // true → false, false → true
    notifyListeners(); // ← beritahu semua widget yang listen
  }
}
