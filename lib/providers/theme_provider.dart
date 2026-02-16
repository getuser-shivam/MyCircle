import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  final SharedPreferences prefs;
  ThemeMode _themeMode = ThemeMode.dark;
  bool _useSystemTheme = false;

  ThemeProvider(this.prefs) {
    _loadThemeSettings();
  }

  ThemeMode get themeMode {
    if (_useSystemTheme) {
      return ThemeMode.system;
    }
    return _themeMode;
  }

  bool get isDarkMode {
    if (_useSystemTheme) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
    return _themeMode == ThemeMode.dark;
  }

  bool get useSystemTheme => _useSystemTheme;

  void _loadThemeSettings() {
    final savedTheme = prefs.getString('theme_mode');
    final useSystem = prefs.getBool('use_system_theme') ?? false;

    setState(() {
      _useSystemTheme = useSystem;
      if (!useSystem && savedTheme != null) {
        _themeMode = savedTheme == 'light' ? ThemeMode.light : ThemeMode.dark;
      }
    });
  }

  void setUseSystemTheme(bool useSystem) {
    _useSystemTheme = useSystem;
    prefs.setBool('use_system_theme', useSystem);
    notifyListeners();
  }

  void toggleTheme() {
    if (_useSystemTheme) {
      // If using system theme, switch to manual dark/light
      setUseSystemTheme(false);
      _themeMode = ThemeMode.dark;
      prefs.setString('theme_mode', 'dark');
    } else {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
      prefs.setString('theme_mode', _themeMode == ThemeMode.light ? 'light' : 'dark');
    }
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _useSystemTheme = false;
    prefs.setString('theme_mode', mode == ThemeMode.light ? 'light' : 'dark');
    prefs.setBool('use_system_theme', false);
    notifyListeners();
  }

  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFFFF9F7), // Softer warm background
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF2D3748),
        elevation: 0,
        centerTitle: true,
        shadowColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: Color(0xFFFF5722),
        unselectedItemColor: Color(0xFF64748B),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFF1A202C), fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.w400),
        displayLarge: TextStyle(color: Color(0xFF1A202C), fontWeight: FontWeight.w700),
        displayMedium: TextStyle(color: Color(0xFF2D3748), fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(color: Color(0xFF1A202C), fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: Color(0xFF1A202C), fontWeight: FontWeight.w600),
      ),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFFF5722), // Vibrant Orange
        secondary: Color(0xFFFFA000), // Rich Amber
        tertiary: Color(0xFFFFC107), // Golden Yellow
        surface: Color(0xFFFFF9F7), // Warm surface
        onPrimary: Colors.white,
        onSecondary: Color(0xFF1A202C),
        onSurface: Color(0xFF2D3748),
        error: Color(0xFFDC2626),
        outline: Color(0xFFE2E8F0),
        surfaceContainerHighest: Color(0xFFF8FAFC),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 4,
        shadowColor: const Color(0xFFFF5722).withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF5722),
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: const Color(0xFFFF5722).withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }

  ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0F0B0A), // Deep warm dark
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A1412),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        shadowColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1A1412),
        selectedItemColor: Color(0xFFFF5722),
        unselectedItemColor: Color(0xFF94A3B8),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFFF8FAFC), fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(color: Color(0xFFE2E8F0), fontWeight: FontWeight.w400),
        displayLarge: TextStyle(color: Color(0xFFF8FAFC), fontWeight: FontWeight.w700),
        displayMedium: TextStyle(color: Color(0xFFE2E8F0), fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(color: Color(0xFFF8FAFC), fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: Color(0xFFF8FAFC), fontWeight: FontWeight.w600),
      ),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFFF5722), // Vibrant Orange
        secondary: Color(0xFFFFA726), // Bright Amber
        tertiary: Color(0xFFFFD54F), // Golden Yellow
        surface: Color(0xFF1A1412), // Warm dark surface
        onPrimary: Colors.white,
        onSecondary: Color(0xFF1A202C),
        onSurface: Color(0xFFF1F5F9),
        error: Color(0xFFEF4444),
        outline: Color(0xFF475569),
        surfaceContainerHighest: Color(0xFF2A1F1D),
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF1A1412),
        elevation: 4,
        shadowColor: const Color(0xFFFF5722).withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF5722),
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: const Color(0xFFFF5722).withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),
    );
  }

  void setState(VoidCallback callback) {
    callback();
    notifyListeners();
  }
}
