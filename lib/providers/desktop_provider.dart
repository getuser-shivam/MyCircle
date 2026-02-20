import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';
import 'package:system_tray/system_tray.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/security/logger_service.dart';

class DesktopProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  bool _isWindowMaximized = false;
  bool _isAlwaysOnTop = false;
  bool _isAcrylicEnabled = false;
  bool _isSystemTrayEnabled = true;
  String _windowTheme = 'auto'; // auto, light, dark
  List<String> _recentFiles = [];
  Map<String, HotKey> _hotkeys = {};
  
  // Getters
  bool get isWindowMaximized => _isWindowMaximized;
  bool get isAlwaysOnTop => _isAlwaysOnTop;
  bool get isAcrylicEnabled => _isAcrylicEnabled;
  bool get isSystemTrayEnabled => _isSystemTrayEnabled;
  String get windowTheme => _windowTheme;
  List<String> get recentFiles => List.unmodifiable(_recentFiles);
  Map<String, HotKey> get hotkeys => Map.unmodifiable(_hotkeys);

  DesktopProvider(this._prefs) {
    _loadDesktopSettings();
    _initializeDesktopFeatures();
  }

  Future<void> _loadDesktopSettings() async {
    _isWindowMaximized = _prefs.getBool('window_maximized') ?? false;
    _isAlwaysOnTop = _prefs.getBool('always_on_top') ?? false;
    _isAcrylicEnabled = _prefs.getBool('acrylic_enabled') ?? false;
    _isSystemTrayEnabled = _prefs.getBool('system_tray_enabled') ?? true;
    _windowTheme = _prefs.getString('window_theme') ?? 'auto';
    _recentFiles = _prefs.getStringList('recent_files') ?? [];
    notifyListeners();
  }

  Future<void> _initializeDesktopFeatures() async {
    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || 
                     defaultTargetPlatform == TargetPlatform.macOS ||
                     defaultTargetPlatform == TargetPlatform.linux)) {
      await _setupWindowManager();
      await _setupSystemTray();
      await _setupHotkeys();
      await _setupAcrylicEffect();
    }
  }

  // Window Management
  Future<void> _setupWindowManager() async {
    await windowManager.ensureInitialized();
    
    WindowOptions windowOptions = WindowOptions(
      size: const Size(1200, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      
      // Apply saved window state
      if (_isWindowMaximized) {
        await windowManager.maximize();
      }
      if (_isAlwaysOnTop) {
        await windowManager.setAlwaysOnTop(true);
      }
    });

    // Listen to window events
    windowManager.addListener(_WindowListener());
  }

  Future<void> toggleMaximize() async {
    if (_isWindowMaximized) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
    _isWindowMaximized = !_isWindowMaximized;
    await _prefs.setBool('window_maximized', _isWindowMaximized);
    notifyListeners();
  }

  Future<void> toggleAlwaysOnTop() async {
    _isAlwaysOnTop = !_isAlwaysOnTop;
    await windowManager.setAlwaysOnTop(_isAlwaysOnTop);
    await _prefs.setBool('always_on_top', _isAlwaysOnTop);
    notifyListeners();
  }

  Future<void> minimizeToTray() async {
    await windowManager.hide();
    if (_isSystemTrayEnabled) {
      _showTrayNotification('MyCircle', 'Minimized to system tray');
    }
  }

  Future<void> closeWindow() async {
    await windowManager.close();
  }

  // System Tray
  Future<void> _setupSystemTray() async {
    if (!_isSystemTrayEnabled) return;

    final SystemTray systemTray = SystemTray();
    final Menu menu = Menu();

    await systemTray.initSystemTray(
      iconPath: 'assets/icons/app_icon.ico',
      toolTip: 'MyCircle',
    );

    menu = Menu(items: [
      MenuItem(label: 'Show', onClick: (menuItem) => _restoreWindow()),
      MenuItem(label: 'Minimize to Tray', onClick: (menuItem) => minimizeToTray()),
      MenuSeparator(),
      MenuItem(label: 'Settings', onClick: (menuItem) => _openSettings()),
      MenuSeparator(),
      MenuItem(label: 'Exit', onClick: (menuItem) => _exitApp()),
    ]);

    await systemTray.setContextMenu(menu);
    systemTray.registerSystemTrayEventHandler((eventName) {
      LoggerService.debug('eventName: $eventName', tag: 'DESKTOP');
    });
  }

  Future<void> _restoreWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _openSettings() async {
    // Navigate to settings screen
    LoggerService.debug('Opening settings...', tag: 'DESKTOP');
  }

  Future<void> _exitApp() async {
    await windowManager.close();
  }

  Future<void> toggleSystemTray() async {
    _isSystemTrayEnabled = !_isSystemTrayEnabled;
    await _prefs.setBool('system_tray_enabled', _isSystemTrayEnabled);
    
    if (_isSystemTrayEnabled) {
      await _setupSystemTray();
    } else {
      await SystemTray().destroySystemTray();
    }
    notifyListeners();
  }

  // Hotkeys
  Future<void> _setupHotkeys() async {
    // Global hotkeys
    _hotkeys['show_hide'] = HotKey(
      KeyCode.keyQ,
      modifiers: [KeyModifier.control, KeyModifier.shift],
      scope: HotKeyScope.system,
    );

    _hotkeys['new_media'] = HotKey(
      KeyCode.keyN,
      modifiers: [KeyModifier.control, KeyModifier.shift],
      scope: HotKeyScope.system,
    );

    _hotkeys['search'] = HotKey(
      KeyCode.keyF,
      modifiers: [KeyModifier.control],
      scope: HotKeyScope.inapp,
    );

    _hotkeys['settings'] = HotKey(
      KeyCode.keyComma,
      modifiers: [KeyModifier.control],
      scope: HotKeyScope.inapp,
    );

    // Register hotkeys
    for (final entry in _hotkeys.entries) {
      await hotKeyManager.register(
        entry.value,
        keyDownHandler: (hotKey) => _handleHotkey(entry.key),
      );
    }
  }

  void _handleHotkey(String hotkeyId) {
    switch (hotkeyId) {
      case 'show_hide':
        _toggleWindowVisibility();
        break;
      case 'new_media':
        _openMediaUpload();
        break;
      case 'search':
        _openSearch();
        break;
      case 'settings':
        _openSettings();
        break;
    }
  }

  Future<void> _toggleWindowVisibility() async {
    if (await windowManager.isVisible()) {
      await minimizeToTray();
    } else {
      await _restoreWindow();
    }
  }

  void _openMediaUpload() {
    // Navigate to media upload screen
    LoggerService.debug('Opening media upload...', tag: 'DESKTOP');
  }

  void _openSearch() {
    // Open search dialog
    LoggerService.debug('Opening search...', tag: 'DESKTOP');
  }

  // Acrylic Effect (Windows 11)
  Future<void> _setupAcrylicEffect() async {
    if (defaultTargetPlatform == TargetPlatform.windows && _isAcrylicEnabled) {
      await Window.setEffect(
        effect: WindowEffect.acrylic,
        color: Colors.black.withValues(alpha: 0.5),
      );
    }
  }

  Future<void> toggleAcrylicEffect() async {
    _isAcrylicEnabled = !_isAcrylicEnabled;
    await _prefs.setBool('acrylic_enabled', _isAcrylicEnabled);
    
    if (defaultTargetPlatform == TargetPlatform.windows) {
      if (_isAcrylicEnabled) {
        await Window.setEffect(
          effect: WindowEffect.acrylic,
          color: Colors.black.withValues(alpha: 0.5),
        );
      } else {
        await Window.setEffect(effect: WindowEffect.disabled);
      }
    }
    notifyListeners();
  }

  // File Management
  void addRecentFile(String filePath) {
    _recentFiles.remove(filePath); // Remove if exists
    _recentFiles.insert(0, filePath); // Add to beginning
    
    // Keep only last 10 files
    if (_recentFiles.length > 10) {
      _recentFiles = _recentFiles.take(10).toList();
    }
    
    _prefs.setStringList('recent_files', _recentFiles);
    notifyListeners();
  }

  void clearRecentFiles() {
    _recentFiles.clear();
    _prefs.setStringList('recent_files', _recentFiles);
    notifyListeners();
  }

  // Theme Management
  Future<void> setWindowTheme(String theme) async {
    _windowTheme = theme;
    await _prefs.setString('window_theme', theme);
    
    if (defaultTargetPlatform == TargetPlatform.windows) {
      switch (theme) {
        case 'light':
          await Window.setEffect(effect: WindowEffect.disabled);
          break;
        case 'dark':
          await Window.setEffect(
            effect: WindowEffect.solid,
            color: Colors.black,
          );
          break;
        case 'auto':
          if (_isAcrylicEnabled) {
            await _setupAcrylicEffect();
          } else {
            await Window.setEffect(effect: WindowEffect.disabled);
          }
          break;
      }
    }
    notifyListeners();
  }

  // Notifications
  Future<void> _showTrayNotification(String title, String body) async {
    if (_isSystemTrayEnabled) {
      await SystemTray().showNotification(title, body);
    }
  }

  // Supabase Integration
  Future<void> syncDesktopSettings() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final settings = {
          'window_maximized': _isWindowMaximized,
          'always_on_top': _isAlwaysOnTop,
          'acrylic_enabled': _isAcrylicEnabled,
          'system_tray_enabled': _isSystemTrayEnabled,
          'window_theme': _windowTheme,
          'hotkeys': _hotkeys.keys.toList(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        await Supabase.instance.client
            .from('user_desktop_settings')
            .upsert(settings)
            .eq('user_id', user.id);
      }
    } catch (e) {
      LoggerService.error('Error syncing desktop settings: $e', tag: 'DESKTOP');
    }
  }

  Future<void> loadDesktopSettingsFromSupabase() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('user_desktop_settings')
            .select()
            .eq('user_id', user.id)
            .single();

        if (response != null) {
          _isWindowMaximized = response['window_maximized'] ?? false;
          _isAlwaysOnTop = response['always_on_top'] ?? false;
          _isAcrylicEnabled = response['acrylic_enabled'] ?? false;
          _isSystemTrayEnabled = response['system_tray_enabled'] ?? true;
          _windowTheme = response['window_theme'] ?? 'auto';
          
          await _saveAllSettings();
          notifyListeners();
        }
      }
    } catch (e) {
      LoggerService.error('Error loading desktop settings from Supabase: $e', tag: 'DESKTOP');
    }
  }

  Future<void> _saveAllSettings() async {
    await _prefs.setBool('window_maximized', _isWindowMaximized);
    await _prefs.setBool('always_on_top', _isAlwaysOnTop);
    await _prefs.setBool('acrylic_enabled', _isAcrylicEnabled);
    await _prefs.setBool('system_tray_enabled', _isSystemTrayEnabled);
    await _prefs.setString('window_theme', _windowTheme);
  }

  @override
  void dispose() {
    // Dispose hotkeys
    for (final hotkey in _hotkeys.values) {
      hotKeyManager.unregister(hotkey);
    }
    
    // Dispose system tray
    if (_isSystemTrayEnabled) {
      SystemTray().destroySystemTray();
    }
    
    super.dispose();
  }
}

class _WindowListener extends WindowListener {
  @override
  void onWindowEvent(String eventName) {
    LoggerService.debug('Window event: $eventName', tag: 'DESKTOP');
  }

  @override
  void onWindowClose() async {
    // Handle window close event
    LoggerService.debug('Window closing...', tag: 'DESKTOP');
  }

  @override
  void onWindowMaximize() {
    LoggerService.debug('Window maximized', tag: 'DESKTOP');
  }

  @override
  void onWindowUnmaximize() {
    LoggerService.debug('Window unmaximized', tag: 'DESKTOP');
  }

  @override
  void onWindowMinimize() {
    LoggerService.debug('Window minimized', tag: 'DESKTOP');
  }

  @override
  void onWindowRestore() {
    LoggerService.debug('Window restored', tag: 'DESKTOP');
  }
}
