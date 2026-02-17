import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import 'package:my_circle\providers\analytics_provider.dart';

// Generate mocks
@GenerateMocks([
  SupabaseClient,
  RealtimeChannel,
  PostgrestFilterBuilder,
  PostgrestTransformBuilder,
])
import 'analytics_provider_test.mocks.dart';

void main() {
  group('AnalyticsProvider Tests', () {
    late AnalyticsProvider analyticsProvider;
    late MockSupabaseClient mockSupabaseClient;
    late MockRealtimeChannel mockRealtimeChannel;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockRealtimeChannel = MockRealtimeChannel();
      
      analyticsProvider = AnalyticsProvider();
    });

    tearDown(() {
      analyticsProvider.dispose();
    });

    group('Analytics Data Loading', () {
      test('should initialize with default values', () {
        expect(analyticsProvider.isLoading, false);
        expect(analyticsProvider.error, null);
        expect(analyticsProvider.creatorAnalytics, null);
        expect(analyticsProvider.contentPerformance, isEmpty);
        expect(analyticsProvider.revenueData, null);
      });

      test('should set loading state during data fetch', () {
        // Simulate loading state
        analyticsProvider.setLoading(true);
        
        expect(analyticsProvider.isLoading, true);
      });

      test('should set error state when fetch fails', () {
        const errorMessage = 'Failed to load analytics';
        analyticsProvider.setError(errorMessage);
        
        expect(analyticsProvider.error, errorMessage);
        expect(analyticsProvider.isLoading, false);
      });

      test('should clear error state', () {
        analyticsProvider.setError('Test error');
        analyticsProvider.clearError();
        
        expect(analyticsProvider.error, null);
      });
    });

    group('Creator Analytics Management', () {
      test('should update creator analytics', () {
        final mockAnalytics = {
          'totalViews': 1000,
          'totalLikes': 100,
          'totalShares': 50,
          'totalRevenue': 500.0,
          'followerGrowth': 25,
          'engagementRate': 0.15,
        };

        analyticsProvider.updateCreatorAnalytics(mockAnalytics);
        
        expect(analyticsProvider.creatorAnalytics, isNotNull);
        expect(analyticsProvider.creatorAnalytics!['totalViews'], 1000);
        expect(analyticsProvider.creatorAnalytics!['totalLikes'], 100);
      });

      test('should handle null analytics data', () {
        analyticsProvider.updateCreatorAnalytics(null);
        
        expect(analyticsProvider.creatorAnalytics, null);
      });
    });

    group('Content Performance Management', () {
      test('should add content performance data', () {
        final mockContentData = {
          'id': 'content_1',
          'title': 'Test Content',
          'views': 500,
          'likes': 50,
          'shares': 25,
          'revenue': 100.0,
          'engagementRate': 0.1,
          'publishedAt': DateTime.now().toIso8601String(),
        };

        analyticsProvider.addContentPerformance(mockContentData);
        
        expect(analyticsProvider.contentPerformance.length, 1);
        expect(analyticsProvider.contentPerformance.first['id'], 'content_1');
      });

      test('should update existing content performance data', () {
        final initialData = {
          'id': 'content_2',
          'title': 'Test Content 2',
          'views': 200,
          'likes': 20,
          'shares': 10,
          'revenue': 50.0,
        };

        final updatedData = {
          'id': 'content_2',
          'title': 'Updated Content 2',
          'views': 300,
          'likes': 30,
          'shares': 15,
          'revenue': 75.0,
        };

        analyticsProvider.addContentPerformance(initialData);
        analyticsProvider.addContentPerformance(updatedData);
        
        expect(analyticsProvider.contentPerformance.length, 1);
        expect(analyticsProvider.contentPerformance.first['views'], 300);
        expect(analyticsProvider.contentPerformance.first['title'], 'Updated Content 2');
      });

      test('should remove content performance data', () {
        final mockData = {
          'id': 'content_3',
          'title': 'Test Content 3',
          'views': 100,
          'likes': 10,
          'shares': 5,
          'revenue': 25.0,
        };

        analyticsProvider.addContentPerformance(mockData);
        analyticsProvider.removeContentPerformance('content_3');
        
        expect(analyticsProvider.contentPerformance, isEmpty);
      });

      test('should clear all content performance data', () {
        final mockData1 = {
          'id': 'content_4',
          'title': 'Test Content 4',
          'views': 100,
          'likes': 10,
          'shares': 5,
          'revenue': 25.0,
        };

        final mockData2 = {
          'id': 'content_5',
          'title': 'Test Content 5',
          'views': 200,
          'likes': 20,
          'shares': 10,
          'revenue': 50.0,
        };

        analyticsProvider.addContentPerformance(mockData1);
        analyticsProvider.addContentPerformance(mockData2);
        analyticsProvider.clearContentPerformance();
        
        expect(analyticsProvider.contentPerformance, isEmpty);
      });
    });

    group('Revenue Data Management', () {
      test('should update revenue data', () {
        final mockRevenueData = {
          'totalRevenue': 1000.0,
          'monthlyRevenue': 500.0,
          'pendingPayouts': 100.0,
          'totalPayouts': 400.0,
          'lastPayoutDate': DateTime.now().toIso8601String(),
        };

        analyticsProvider.updateRevenueData(mockRevenueData);
        
        expect(analyticsProvider.revenueData, isNotNull);
        expect(analyticsProvider.revenueData!['totalRevenue'], 1000.0);
        expect(analyticsProvider.revenueData!['monthlyRevenue'], 500.0);
      });

      test('should handle null revenue data', () {
        analyticsProvider.updateRevenueData(null);
        
        expect(analyticsProvider.revenueData, null);
      });
    });

    group('Date Range Filtering', () {
      test('should filter content by date range', () {
        final now = DateTime.now();
        final lastWeek = now.subtract(const Duration(days: 7));
        final twoWeeksAgo = now.subtract(const Duration(days: 14));

        final mockData1 = {
          'id': 'content_6',
          'title': 'Recent Content',
          'views': 100,
          'publishedAt': now.toIso8601String(),
        };

        final mockData2 = {
          'id': 'content_7',
          'title': 'Last Week Content',
          'views': 200,
          'publishedAt': lastWeek.toIso8601String(),
        };

        final mockData3 = {
          'id': 'content_8',
          'title': 'Old Content',
          'views': 300,
          'publishedAt': twoWeeksAgo.toIso8601String(),
        };

        analyticsProvider.addContentPerformance(mockData1);
        analyticsProvider.addContentPerformance(mockData2);
        analyticsProvider.addContentPerformance(mockData3);

        final filteredData = analyticsProvider.getContentByDateRange(
          lastWeek.subtract(const Duration(days: 1)),
          now.add(const Duration(days: 1)),
        );

        expect(filteredData.length, 2);
        expect(filteredData.any((data) => data['id'] == 'content_6'), true);
        expect(filteredData.any((data) => data['id'] == 'content_7'), true);
        expect(filteredData.any((data) => data['id'] == 'content_8'), false);
      });

      test('should return empty list for invalid date range', () {
        final mockData = {
          'id': 'content_9',
          'title': 'Test Content',
          'views': 100,
          'publishedAt': DateTime.now().toIso8601String(),
        };

        analyticsProvider.addContentPerformance(mockData);

        final filteredData = analyticsProvider.getContentByDateRange(
          DateTime.now().add(const Duration(days: 1)),
          DateTime.now().add(const Duration(days: 2)),
        );

        expect(filteredData, isEmpty);
      });
    });

    group('Performance Metrics Calculation', () {
      test('should calculate total views correctly', () {
        final mockData1 = {'id': 'content_10', 'views': 100};
        final mockData2 = {'id': 'content_11', 'views': 200};
        final mockData3 = {'id': 'content_12', 'views': 300};

        analyticsProvider.addContentPerformance(mockData1);
        analyticsProvider.addContentPerformance(mockData2);
        analyticsProvider.addContentPerformance(mockData3);

        expect(analyticsProvider.getTotalViews(), 600);
      });

      test('should calculate total likes correctly', () {
        final mockData1 = {'id': 'content_13', 'likes': 50};
        final mockData2 = {'id': 'content_14', 'likes': 75};
        final mockData3 = {'id': 'content_15', 'likes': 125};

        analyticsProvider.addContentPerformance(mockData1);
        analyticsProvider.addContentPerformance(mockData2);
        analyticsProvider.addContentPerformance(mockData3);

        expect(analyticsProvider.getTotalLikes(), 250);
      });

      test('should calculate average engagement rate', () {
        final mockData1 = {'id': 'content_16', 'engagementRate': 0.1};
        final mockData2 = {'id': 'content_17', 'engagementRate': 0.2};
        final mockData3 = {'id': 'content_18', 'engagementRate': 0.3};

        analyticsProvider.addContentPerformance(mockData1);
        analyticsProvider.addContentPerformance(mockData2);
        analyticsProvider.addContentPerformance(mockData3);

        expect(analyticsProvider.getAverageEngagementRate(), 0.2);
      });

      test('should handle empty content list for metrics', () {
        expect(analyticsProvider.getTotalViews(), 0);
        expect(analyticsProvider.getTotalLikes(), 0);
        expect(analyticsProvider.getAverageEngagementRate(), 0.0);
      });
    });

    group('Real-time Updates', () {
      test('should handle real-time analytics updates', () {
        final mockUpdate = {
          'type': 'analytics_update',
          'data': {
            'totalViews': 1500,
            'totalLikes': 150,
          },
        };

        analyticsProvider.handleRealtimeUpdate(mockUpdate);

        expect(analyticsProvider.creatorAnalytics, isNotNull);
        expect(analyticsProvider.creatorAnalytics!['totalViews'], 1500);
        expect(analyticsProvider.creatorAnalytics!['totalLikes'], 150);
      });

      test('should handle real-time content updates', () {
        final mockUpdate = {
          'type': 'content_update',
          'data': {
            'id': 'content_19',
            'title': 'Updated Content',
            'views': 750,
            'likes': 75,
          },
        };

        analyticsProvider.handleRealtimeUpdate(mockUpdate);

        expect(analyticsProvider.contentPerformance.length, 1);
        expect(analyticsProvider.contentPerformance.first['id'], 'content_19');
        expect(analyticsProvider.contentPerformance.first['views'], 750);
      });
    });

    group('Error Handling', () {
      test('should handle missing required fields gracefully', () {
        final invalidData = {
          'id': 'content_20',
          // Missing other required fields
        };

        expect(() => analyticsProvider.addContentPerformance(invalidData), 
               returnsNormally);
      });

      test('should handle invalid engagement rate', () {
        final mockData = {
          'id': 'content_21',
          'title': 'Test Content',
          'views': 100,
          'engagementRate': 'invalid_rate',
        };

        analyticsProvider.addContentPerformance(mockData);

        expect(analyticsProvider.contentPerformance.length, 1);
        expect(analyticsProvider.contentPerformance.first['engagementRate'], 'invalid_rate');
      });
    });

    group('Listener Notifications', () {
      test('should notify listeners when analytics change', () {
        bool notified = false;
        analyticsProvider.addListener(() => notified = true);

        final mockAnalytics = {'totalViews': 1000};
        analyticsProvider.updateCreatorAnalytics(mockAnalytics);

        expect(notified, true);
      });

      test('should notify listeners when content performance changes', () {
        bool notified = false;
        analyticsProvider.addListener(() => notified = true);

        final mockData = {
          'id': 'content_22',
          'title': 'Test Content',
          'views': 100,
        };

        analyticsProvider.addContentPerformance(mockData);

        expect(notified, true);
      });

      test('should notify listeners when loading state changes', () {
        bool notified = false;
        analyticsProvider.addListener(() => notified = true);

        analyticsProvider.setLoading(true);

        expect(notified, true);
      });
    });
  });
}
