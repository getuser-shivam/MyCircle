import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';



class ThemeProvider extends ChangeNotifier {
  final SharedPreferences prefs;
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeProvider(this.prefs) {
    _loadThemeMode();
  }

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  void _loadThemeMode() {
    final savedTheme = prefs.getString('theme_mode');
    if (savedTheme != null) {
      _themeMode = savedTheme == 'light' ? ThemeMode.light : ThemeMode.dark;
      notifyListeners();
    }
  }

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    prefs.setString('theme_mode', _themeMode == ThemeMode.light ? 'light' : 'dark');
    notifyListeners();
  }

  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFFF7F6), // Very light orange/red tint
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFFDD2C00), // Deep Orange A700
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.black),
        bodyMedium: TextStyle(color: Colors.black),
        displayLarge: TextStyle(color: Colors.black),
        displayMedium: TextStyle(color: Colors.black),
      ),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFFF5722), // Firebase Orange
        secondary: Color(0xFFFFA000), // Amber 700
        tertiary: Color(0xFFFFC107), // Amber 500
        surface: Colors.white,
        background: Color(0xFFFFF7F6),
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Color(0xFF212121),
        onBackground: Color(0xFF212121),
        error: Color(0xFFB00020),
      ),
    );
  }

  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F0505), // Very dark red/black
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0F0505),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1A0A0A), // Darker Red/Black
        selectedItemColor: Color(0xFFFF5722), // Firebase Orange
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white),
        displayLarge: TextStyle(color: Colors.white),
        displayMedium: TextStyle(color: Colors.black),
      ),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFF5722), // Firebase Orange
        secondary: Color(0xFFFFCA28), // Amber 400
        tertiary: Color(0xFFFFE082), // Amber 200
        surface: Color(0xFF1E0F0F), // Dark Red/Brown Surface
        background: Color(0xFF0F0505),
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: Color(0xFFFAFAFA),
        onBackground: Color(0xFFFAFAFA),
        error: Color(0xFFCF6679),
      ),
    );
  }
}
