import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_theme.dart';
import '../core/constants/app_constants.dart';

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
    final savedTheme = prefs.getString(AppConstants.themeModeKey);
    final useSystem = prefs.getBool(AppConstants.useSystemThemeKey) ?? false;

    setState(() {
      _useSystemTheme = useSystem;
      if (!useSystem && savedTheme != null) {
        _themeMode = savedTheme == 'light' ? ThemeMode.light : ThemeMode.dark;
      }
    });
  }

  void setUseSystemTheme(bool useSystem) {
    _useSystemTheme = useSystem;
    prefs.setBool(AppConstants.useSystemThemeKey, useSystem);
    notifyListeners();
  }

  void toggleTheme() {
    if (_useSystemTheme) {
      setUseSystemTheme(false);
      _themeMode = ThemeMode.dark;
      prefs.setString(AppConstants.themeModeKey, 'dark');
    } else {
      _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
      prefs.setString(AppConstants.themeModeKey, _themeMode == ThemeMode.light ? 'light' : 'dark');
    }
    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    _useSystemTheme = false;
    prefs.setString(AppConstants.themeModeKey, mode == ThemeMode.light ? 'light' : 'dark');
    prefs.setBool(AppConstants.useSystemThemeKey, false);
    notifyListeners();
  }

  void setCustomColorScheme(ColorScheme colorScheme) {
    _customColorScheme = colorScheme;
    notifyListeners();
  }

  // Predefined color themes
  static const Map<String, ColorScheme> colorThemes = {
    'default': AppTheme.sunsetScheme,
    'sunset': AppTheme.sunsetScheme,
    'ocean': AppTheme.oceanScheme,
    'forest': AppTheme.forestScheme,
  };

  // Get theme data based on current mode and color scheme
  ThemeData get lightTheme {
    return AppTheme.lightTheme.copyWith(
      colorScheme: _customColorScheme != _defaultColorScheme 
          ? _customColorScheme.copyWith(brightness: Brightness.light)
          : colorThemes['default']!,
    );
  }

  ThemeData get darkTheme {
    return AppTheme.darkTheme.copyWith(
      colorScheme: _customColorScheme != _defaultColorScheme
          ? _customColorScheme.copyWith(brightness: Brightness.dark)
          : colorThemes['default']!.copyWith(brightness: Brightness.dark),
    );
  }

  // Apply predefined theme
  void applyTheme(String themeName) {
    final theme = colorThemes[themeName];
    if (theme != null) {
      setCustomColorScheme(theme);
    }
  }

  void setState(VoidCallback callback) {
    callback();
    notifyListeners();
  }
}
