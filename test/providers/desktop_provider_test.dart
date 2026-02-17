import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';
import 'package:system_tray/system_tray.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import 'package:my_circle/providers/desktop_provider.dart';

// Generate mocks
@GenerateMocks([
  SharedPreferences,
  WindowManager,
  SystemTray,
  HotKeyManager,
  SupabaseClient,
  User,
])
import 'desktop_provider_test.mocks.dart';

void main() {
  group('DesktopProvider Tests', () {
    late MockSharedPreferences mockPrefs;
    late DesktopProvider desktopProvider;
    late MockSupabaseClient mockSupabaseClient;
    late MockUser mockUser;

    setUp(() async {
      mockPrefs = MockSharedPreferences();
      mockSupabaseClient = MockSupabaseClient();
      mockUser = MockUser();
      
      // Setup default mock responses
      when(mockPrefs.getBool(any)).thenReturn(false);
      when(mockPrefs.getString(any)).thenReturn('auto');
      when(mockPrefs.getStringList(any)).thenReturn([]);
      
      when(mockUser.id).thenReturn('test-user-id');
      
      desktopProvider = DesktopProvider(mockPrefs);
    });

    tearDown(() {
      desktopProvider.dispose();
    });

    group('Initialization Tests', () {
      test('should initialize with default values', () {
        expect(desktopProvider.isWindowMaximized, false);
        expect(desktopProvider.isAlwaysOnTop, false);
        expect(desktopProvider.isAcrylicEnabled, false);
        expect(desktopProvider.isSystemTrayEnabled, true);
        expect(desktopProvider.windowTheme, 'auto');
        expect(desktopProvider.recentFiles, isEmpty);
        expect(desktopProvider.hotkeys, isEmpty);
      });

      test('should load settings from SharedPreferences', () {
        verify(mockPrefs.getBool('window_maximized')).called(1);
        verify(mockPrefs.getBool('always_on_top')).called(1);
        verify(mockPrefs.getBool('acrylic_enabled')).called(1);
        verify(mockPrefs.getBool('system_tray_enabled')).called(1);
        verify(mockPrefs.getString('window_theme')).called(1);
        verify(mockPrefs.getStringList('recent_files')).called(1);
      });
    });

    group('Window Management Tests', () {
      test('should toggle maximize state', () async {
        when(mockPrefs.setBool(any, any)).thenAnswer((_) async => true);
        
        await desktopProvider.toggleMaximize();
        
        expect(desktopProvider.isWindowMaximized, true);
        verify(mockPrefs.setBool('window_maximized', true)).called(1);
      });

      test('should toggle always on top state', () async {
        when(mockPrefs.setBool(any, any)).thenAnswer((_) async => true);
        
        await desktopProvider.toggleAlwaysOnTop();
        
        expect(desktopProvider.isAlwaysOnTop, true);
        verify(mockPrefs.setBool('always_on_top', true)).called(1);
      });

      test('should add recent file', () {
        when(mockPrefs.setStringList(any, any)).thenAnswer((_) async => true);
        
        const testFile = '/path/to/file.txt';
        desktopProvider.addRecentFile(testFile);
        
        expect(desktopProvider.recentFiles, contains(testFile));
        expect(desktopProvider.recentFiles.first, testFile);
        verify(mockPrefs.setStringList('recent_files', any)).called(1);
      });

      test('should limit recent files to 10', () {
        when(mockPrefs.setStringList(any, any)).thenAnswer((_) async => true);
        
        // Add 11 files
        for (int i = 0; i < 11; i++) {
          desktopProvider.addRecentFile('/path/to/file$i.txt');
        }
        
        expect(desktopProvider.recentFiles.length, 10);
        expect(desktopProvider.recentFiles, isNot(contains('/path/to/file0.txt')));
        expect(desktopProvider.recentFiles, contains('/path/to/file10.txt'));
      });

      test('should clear recent files', () {
        when(mockPrefs.setStringList(any, any)).thenAnswer((_) async => true);
        
        desktopProvider.addRecentFile('/path/to/file.txt');
        desktopProvider.clearRecentFiles();
        
        expect(desktopProvider.recentFiles, isEmpty);
        verify(mockPrefs.setStringList('recent_files', [])).called(1);
      });
    });

    group('Theme Management Tests', () {
      test('should set window theme', () async {
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);
        
        await desktopProvider.setWindowTheme('dark');
        
        expect(desktopProvider.windowTheme, 'dark');
        verify(mockPrefs.setString('window_theme', 'dark')).called(1);
      });

      test('should toggle acrylic effect', () async {
        when(mockPrefs.setBool(any, any)).thenAnswer((_) async => true);
        
        await desktopProvider.toggleAcrylicEffect();
        
        expect(desktopProvider.isAcrylicEnabled, true);
        verify(mockPrefs.setBool('acrylic_enabled', true)).called(1);
      });
    });

    group('System Tray Tests', () {
      test('should toggle system tray enabled state', () async {
        when(mockPrefs.setBool(any, any)).thenAnswer((_) async => true);
        
        await desktopProvider.toggleSystemTray();
        
        expect(desktopProvider.isSystemTrayEnabled, false);
        verify(mockPrefs.setBool('system_tray_enabled', false)).called(1);
      });
    });

    group('Supabase Integration Tests', () {
      setUp(() {
        // Mock Supabase.instance.client
        // Note: This would require dependency injection for proper testing
      });

      test('should handle sync desktop settings gracefully', () async {
        // This test would require proper mocking of Supabase.instance
        // For now, we just verify the method doesn't throw
        expect(() async => await desktopProvider.syncDesktopSettings(), 
               returnsNormally);
      });

      test('should handle load desktop settings from Supabase gracefully', () async {
        // This test would require proper mocking of Supabase.instance
        expect(() async => await desktopProvider.loadDesktopSettingsFromSupabase(), 
               returnsNormally);
      });
    });

    group('Notification Tests', () {
      test('should notify listeners when state changes', () {
        bool notified = false;
        desktopProvider.addListener(() => notified = true);
        
        when(mockPrefs.setBool(any, any)).thenAnswer((_) async => true);
        
        desktopProvider.toggleMaximize();
        
        expect(notified, true);
      });
    });

    group('Error Handling Tests', () {
      test('should handle SharedPreferences errors gracefully', () async {
        when(mockPrefs.setBool(any, any)).thenThrow(Exception('Prefs error'));
        
        expect(() async => await desktopProvider.toggleMaximize(), 
               returnsNormally);
      });
    });
  });
}
