import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import '../../../lib/core/windows/windows_enterprise_manager.dart';

/// Windows Enterprise Manager Tests
/// 
/// Tests Windows-specific enterprise features for stability,
/// performance monitoring, and system integration.
@GenerateMocks([WindowsEnterpriseManager])
import 'windows_enterprise_manager_test.mocks.dart';

void main() {
  group('Windows Enterprise Manager Tests', () {
    late MockWindowsEnterpriseManager mockWindowsManager;

    setUp(() {
      mockWindowsManager = MockWindowsEnterpriseManager();
    });

    tearDown(() {
      WindowsEnterpriseManager.dispose();
    });

    group('Initialization', () {
      testWidgets('should initialize successfully', (WidgetTester tester) async {
        await WindowsEnterpriseManager.initialize();
        
        // Verify initialization state
        expect(WindowsEnterpriseManager._isInitialized, isTrue);
      });

      testWidgets('should handle initialization failure gracefully', (WidgetTester tester) async {
        when(mockWindowsManager.initialize()).thenThrow(Exception('Initialization failed'));
        
        await WindowsEnterpriseManager.initialize();
        
        verify(mockWindowsManager.initialize()).called(1);
      });
    });

    group('High DPI Support', () {
      testWidgets('should enable high DPI awareness', (WidgetTester tester) async {
        await WindowsEnterpriseManager.initialize();
        
        // Verify high DPI is enabled
        final stats = WindowsEnterpriseManager.getMemoryStats();
        expect(stats['high_dpi_aware'], isTrue);
      });
    });

    group('Memory Monitoring', () {
      testWidgets('should enable memory monitoring', (WidgetTester tester) async {
        WindowsEnterpriseManager.setMemoryMonitoring(true);
        
        final stats = WindowsEnterpriseManager.getMemoryStats();
        expect(stats['monitoring_enabled'], isTrue);
      });

      testWidgets('should disable memory monitoring', (WidgetTester tester) async {
        WindowsEnterpriseManager.setMemoryMonitoring(false);
        
        final stats = WindowsEnterpriseManager.getMemoryStats();
        expect(stats['monitoring_enabled'], isFalse);
      });

      testWidgets('should track memory usage', (WidgetTester tester) async {
        WindowsEnterpriseManager.setMemoryMonitoring(true);
        
        // Wait for monitoring cycle
        await tester.pump(Duration(milliseconds: 100));
        
        final stats = WindowsEnterpriseManager.getMemoryStats();
        expect(stats['memory_mb'], isA<int>());
        expect(stats['memory_mb'], greaterThan(0));
      });
    });

    group('System Events', () {
      testWidgets('should handle system suspend event', (WidgetTester tester) async {
        await WindowsEnterpriseManager.initialize();
        
        // Simulate system suspend
        WindowListener.notifyListeners('suspend');
        
        // Verify event was handled
        // In real test, you'd verify background operations were paused
      });

      testWidgets('should handle system resume event', (WidgetTester tester) async {
        await WindowsEnterpriseManager.initialize();
        
        // Simulate system resume
        WindowListener.notifyListeners('resume');
        
        // Verify event was handled
        // In real test, you'd verify background operations were resumed
      });

      testWidgets('should handle low power event', (WidgetTester tester) async {
        await WindowsEnterpriseManager.initialize();
        
        // Simulate low power
        WindowListener.notifyListeners('low_power');
        
        // Verify power saving mode was enabled
        final stats = WindowsEnterpriseManager.getMemoryStats();
        expect(stats['monitoring_interval_seconds'], equals(60)); // 1 minute interval
      });
    });

    group('Memory Cleanup', () {
      testWidgets('should trigger memory cleanup on critical usage', (WidgetTester tester) async {
        await WindowsEnterpriseManager.initialize();
        
        // Simulate critical memory usage
        // This would trigger cleanup in real scenario
        
        // Verify cleanup was triggered
        // In real test, you'd mock high memory usage
      });
    });

    group('Disposal', () {
      testWidgets('should dispose properly', (WidgetTester tester) async {
        await WindowsEnterpriseManager.initialize();
        
        WindowsEnterpriseManager.dispose();
        
        // Verify cleanup
        expect(WindowsEnterpriseManager._isInitialized, isFalse);
      });
    });

    group('Performance Metrics', () {
      testWidgets('should provide accurate memory statistics', (WidgetTester tester) async {
        await WindowsEnterpriseManager.initialize();
        
        final stats = WindowsEnterpriseManager.getMemoryStats();
        
        expect(stats, containsAll([
          'memory_mb',
          'monitoring_enabled',
          'high_dpi_aware',
          'monitoring_interval_seconds',
        ]));
        
        expect(stats['memory_mb'], isA<int>());
        expect(stats['monitoring_enabled'], isA<bool>());
        expect(stats['high_dpi_aware'], isA<bool>());
        expect(stats['monitoring_interval_seconds'], isA<int>());
      });
    });

    group('Error Handling', () {
      testWidgets('should handle memory monitoring errors gracefully', (WidgetTester tester) async {
        when(mockWindowsManager._checkMemoryUsage()).thenThrow(Exception('Memory check failed'));
        
        await WindowsEnterpriseManager._checkMemoryUsage();
        
        verify(mockWindowsManager._checkMemoryUsage()).called(1);
      });

      testWidgets('should handle system event errors gracefully', (WidgetTester tester) async {
        when(mockWindowsManager._setupSystemEventHandlers()).thenThrow(Exception('Event setup failed'));
        
        await WindowsEnterpriseManager._setupSystemEventHandlers();
        
        verify(mockWindowsManager._setupSystemEventHandlers()).called(1);
      });
    });
  });
}
