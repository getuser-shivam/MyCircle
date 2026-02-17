import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  final SharedPreferences prefs;
  ThemeMode _themeMode = ThemeMode.dark;
  bool _useSystemTheme = false;
  ColorScheme _customColorScheme = _defaultColorScheme;

  static const ColorScheme _defaultColorScheme = ColorScheme(
    primary: Color(0xFFFF5722), // Vibrant Orange
    secondary: Color(0xFFFFA000), // Rich Amber
    tertiary: Color(0xFFFFC107), // Golden Yellow
    surface: Color(0xFFFFF9F7),
    error: Color(0xFFDC2626),
    onPrimary: Colors.white,
    onSecondary: Color(0xFF1A202C),
    onSurface: Color(0xFF2D3748),
    onError: Colors.white,
    brightness: Brightness.light,
    outline: Color(0xFFE2E8F0),
    outlineVariant: Color(0xFFCBD5E1),
    surfaceContainerHighest: Color(0xFFF8FAFC),
    surfaceContainerHigh: Color(0xFFF1F5F9),
    surfaceContainerLow: Color(0xFFFAFBFC),
  );

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
  ColorScheme get customColorScheme => _customColorScheme;

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

  void setCustomColorScheme(ColorScheme colorScheme) {
    _customColorScheme = colorScheme;
    notifyListeners();
  }

  // Predefined color themes
  static const Map<String, ColorScheme> colorThemes = {
    'sunset': ColorScheme(
      primary: Color(0xFFFF6B6B),
      secondary: Color(0xFF4ECDC4),
      tertiary: Color(0xFFFFE66D),
      surface: Color(0xFFFFF5F5),
      error: Color(0xFFE63946),
      onPrimary: Colors.white,
      onSecondary: Color(0xFF1A202C),
      onSurface: Color(0xFF2D3748),
      onError: Colors.white,
      brightness: Brightness.light,
      outline: Color(0xFFE2E8F0),
      outlineVariant: Color(0xFFCBD5E1),
      surfaceContainerHighest: Color(0xFFF8FAFC),
    ),
    'ocean': ColorScheme(
      primary: Color(0xFF0077BE),
      secondary: Color(0xFF00A8E8),
      tertiary: Color(0xFF00C9FF),
      surface: Color(0xFFF0F9FF),
      error: Color(0xFFDC2626),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF0F172A),
      onError: Colors.white,
      brightness: Brightness.light,
      outline: Color(0xFFCBD5E1),
      outlineVariant: Color(0xFF94A3B8),
      surfaceContainerHighest: Color(0xFFE0F2FE),
    ),
    'forest': ColorScheme(
      primary: Color(0xFF10B981),
      secondary: Color(0xFF059669),
      tertiary: Color(0xFF34D399),
      surface: Color(0xFFF0FDF4),
      error: Color(0xFFDC2626),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: Color(0xFF064E3B),
      onError: Colors.white,
      brightness: Brightness.light,
      outline: Color(0xFFD1FAE5),
      outlineVariant: Color(0xFFA7F3D0),
      surfaceContainerHighest: Color(0xFFECFDF5),
    ),
  };

  ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _customColorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: _customColorScheme.surface,
        foregroundColor: _customColorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        shadowColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _customColorScheme.primary.withValues(alpha: 0.05),
                _customColorScheme.secondary.withValues(alpha: 0.05),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: _customColorScheme.surface,
        selectedItemColor: _customColorScheme.primary,
        unselectedItemColor: _customColorScheme.outline,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          color: _customColorScheme.onSurface,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.2,
        ),
        bodyMedium: TextStyle(
          color: _customColorScheme.onSurface,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
        ),
        displayLarge: TextStyle(
          color: _customColorScheme.onSurface,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          color: _customColorScheme.onSurface,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
        ),
        headlineMedium: TextStyle(
          color: _customColorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: _customColorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      colorScheme: _customColorScheme,
      cardTheme: CardTheme(
        color: _customColorScheme.surface,
        elevation: 6,
        shadowColor: _customColorScheme.primary.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        surfaceTintColor: _customColorScheme.primary.withValues(alpha: 0.1),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _customColorScheme.primary,
          foregroundColor: _customColorScheme.onPrimary,
          elevation: 3,
          shadowColor: _customColorScheme.primary.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: _customColorScheme.secondary,
          foregroundColor: _customColorScheme.onSecondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _customColorScheme.primary,
          side: BorderSide(color: _customColorScheme.primary, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _customColorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _customColorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _customColorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _customColorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _customColorScheme.surfaceContainerHighest,
        selectedColor: _customColorScheme.primary,
        labelStyle: TextStyle(color: _customColorScheme.onSurface),
        secondaryLabelStyle: TextStyle(color: _customColorScheme.onPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  ThemeData get darkTheme {
    final darkColorScheme = ColorScheme.dark(
      primary: _customColorScheme.primary,
      secondary: _customColorScheme.secondary,
      tertiary: _customColorScheme.tertiary,
      surface: const Color(0xFF0F0B0A),
      error: _customColorScheme.error,
      onPrimary: _customColorScheme.onPrimary,
      onSecondary: _customColorScheme.onSecondary,
      onSurface: const Color(0xFFF1F5F9),
      onError: _customColorScheme.onError,
      brightness: Brightness.dark,
      outline: const Color(0xFF475569),
      outlineVariant: const Color(0xFF334155),
      surfaceContainerHighest: const Color(0xFF2A1F1D),
      surfaceContainerHigh: const Color(0xFF1E1A1A),
      surfaceContainerLow: const Color(0xFF1A1412),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkColorScheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: darkColorScheme.surface,
        foregroundColor: darkColorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        shadowColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                darkColorScheme.primary.withValues(alpha: 0.1),
                darkColorScheme.secondary.withValues(alpha: 0.1),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkColorScheme.surface,
        selectedItemColor: darkColorScheme.primary,
        unselectedItemColor: darkColorScheme.outline,
        type: BottomNavigationBarType.fixed,
        elevation: 12,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
      ),
      textTheme: TextTheme(
        bodyLarge: TextStyle(
          color: darkColorScheme.onSurface,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.2,
        ),
        bodyMedium: TextStyle(
          color: darkColorScheme.onSurface,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.1,
        ),
        displayLarge: TextStyle(
          color: darkColorScheme.onSurface,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        displayMedium: TextStyle(
          color: darkColorScheme.onSurface,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
        ),
        headlineMedium: TextStyle(
          color: darkColorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: darkColorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      colorScheme: darkColorScheme,
      cardTheme: CardTheme(
        color: darkColorScheme.surfaceContainerHigh,
        elevation: 6,
        shadowColor: darkColorScheme.primary.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        surfaceTintColor: darkColorScheme.primary.withValues(alpha: 0.1),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkColorScheme.primary,
          foregroundColor: darkColorScheme.onPrimary,
          elevation: 3,
          shadowColor: darkColorScheme.primary.withValues(alpha: 0.3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: darkColorScheme.secondary,
          foregroundColor: darkColorScheme.onSecondary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkColorScheme.primary,
          side: BorderSide(color: darkColorScheme.primary, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkColorScheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: darkColorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: darkColorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: darkColorScheme.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: darkColorScheme.surfaceContainerHighest,
        selectedColor: darkColorScheme.primary,
        labelStyle: TextStyle(color: darkColorScheme.onSurface),
        secondaryLabelStyle: TextStyle(color: darkColorScheme.onPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void setState(VoidCallback callback) {
    callback();
    notifyListeners();
  }
}
