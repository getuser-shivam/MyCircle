import 'package:flutter_test/flutter_test.dart';

/// Configuration for streaming feature tests
class StreamingTestConfig {
  /// Default timeout for async operations
  static const Duration defaultTimeout = Duration(seconds: 30);
  
  /// Timeout for network operations
  static const Duration networkTimeout = Duration(seconds: 10);
  
  /// Timeout for UI animations
  static const Duration animationTimeout = Duration(seconds: 5);
  
  /// Number of items to generate for performance tests
  static const int performanceTestItemCount = 1000;
  
  /// Number of items to generate for stress tests
  static const int stressTestItemCount = 10000;
  
  /// Maximum retry attempts for flaky tests
  static const int maxRetryAttempts = 3;
  
  /// Test data constants
  static const String testStreamId = 'test_stream_1';
  static const String testUserId = 'test_user_1';
  static const String testUserName = 'TestUser';
  static const String testCategory = 'Gaming';
  static const String testTitle = 'Test Stream';
  
  /// Mock server URLs
  static const String mockStreamUrl = 'https://mock.example.com/stream.m3u8';
  static const String mockThumbnailUrl = 'https://mock.example.com/thumb.jpg';
  static const String mockAvatarUrl = 'https://mock.example.com/avatar.jpg';
  
  /// Test file paths
  static const String testImageAsset = 'test/assets/test_image.jpg';
  static const String testVideoAsset = 'test/assets/test_video.mp4';
  
  /// Performance thresholds (in milliseconds)
  static const int maxWidgetBuildTime = 100;
  static const int maxScreenLoadTime = 500;
  static const int maxProviderUpdateTime = 50;
  
  /// Memory usage thresholds (in MB)
  static const int maxMemoryUsage = 100;
  static const int maxLeakedObjects = 10;
}

/// Custom test configuration for different test environments
enum TestEnvironment {
  development,
  staging,
  production,
  ci,
}

/// Test configuration manager
class TestConfigManager {
  static TestEnvironment _environment = TestEnvironment.development;
  
  static TestEnvironment get environment => _environment;
  
  static void setEnvironment(TestEnvironment env) {
    _environment = env;
  }
  
  /// Gets timeout based on current environment
  static Duration getTimeout({Duration? custom}) {
    if (custom != null) return custom;
    
    switch (_environment) {
      case TestEnvironment.ci:
        return const Duration(seconds: 60);
      case TestEnvironment.production:
        return const Duration(seconds: 45);
      case TestEnvironment.staging:
        return const Duration(seconds: 30);
      case TestEnvironment.development:
      default:
        return StreamingTestConfig.defaultTimeout;
    }
  }
  
  /// Gets performance thresholds based on environment
  static int getPerformanceThreshold(String metric) {
    switch (_environment) {
      case TestEnvironment.ci:
        // More lenient thresholds for CI
        switch (metric) {
          case 'widget_build':
            return 200;
          case 'screen_load':
            return 1000;
          case 'provider_update':
            return 100;
          default:
            return 500;
        }
      case TestEnvironment.production:
        // Stricter thresholds for production
        switch (metric) {
          case 'widget_build':
            return 50;
          case 'screen_load':
            return 250;
          case 'provider_update':
            return 25;
          default:
            return 100;
        }
      default:
        // Default thresholds
        switch (metric) {
          case 'widget_build':
            return StreamingTestConfig.maxWidgetBuildTime;
          case 'screen_load':
            return StreamingTestConfig.maxScreenLoadTime;
          case 'provider_update':
            return StreamingTestConfig.maxProviderUpdateTime;
          default:
            return 250;
        }
    }
  }
}

/// Test utilities for configuration
class TestUtils {
  /// Sets up test environment based on environment variables
  static void setupTestEnvironment() {
    const env = String.fromEnvironment('TEST_ENV', defaultValue: 'development');
    
    switch (env.toLowerCase()) {
      case 'ci':
        TestConfigManager.setEnvironment(TestEnvironment.ci);
        break;
      case 'production':
        TestConfigManager.setEnvironment(TestEnvironment.production);
        break;
      case 'staging':
        TestConfigManager.setEnvironment(TestEnvironment.staging);
        break;
      case 'development':
      default:
        TestConfigManager.setEnvironment(TestEnvironment.development);
        break;
    }
  }
  
  /// Prints test configuration
  static void printTestConfig() {
    print('=== Test Configuration ===');
    print('Environment: ${TestConfigManager.environment}');
    print('Default Timeout: ${TestConfigManager.getTimeout()}');
    print('Widget Build Threshold: ${TestConfigManager.getPerformanceThreshold('widget_build')}ms');
    print('Screen Load Threshold: ${TestConfigManager.getPerformanceThreshold('screen_load')}ms');
    print('Provider Update Threshold: ${TestConfigManager.getPerformanceThreshold('provider_update')}ms');
    print('========================');
  }
}
