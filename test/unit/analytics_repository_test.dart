import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_circle/models/analytics.dart';
import 'package:my_circle/repositories/analytics_repository.dart';

import 'analytics_repository_test.mocks.dart';

@GenerateMocks([SupabaseClient, PostgrestFilterBuilder, PostgrestTransformBuilder, RealtimeChannel])
void main() {
  group('AnalyticsRepository', () {
    late AnalyticsRepository repository;
    late MockSupabaseClient mockSupabase;

    setUp(() {
      mockSupabase = MockSupabaseClient();
      repository = AnalyticsRepository(mockSupabase);
    });

    tearDown(() {
      repository.dispose();
    });

    group('getAnalyticsStream', () {
      test('should return stream of analytics data', () async {
        // Arrange
        const creatorId = 'test-creator-id';
        final mockFilterBuilder = MockPostgrestFilterBuilder();
        final mockTransformBuilder = MockPostgrestTransformBuilder();
        final mockChannel = MockRealtimeChannel();

        final analyticsData = [
          {
            'id': '1',
            'creator_id': creatorId,
            'period_date': DateTime.now().toIso8601String(),
            'views': 1000,
            'likes': 100,
            'comments': 50,
            'shares': 25,
            'engagement_rate': 0.175,
            'new_followers': 10,
            'total_revenue': 50.0,
            'demographic_data': {},
            'geographic_data': {},
            'top_content': [],
          }
        ];

        when(mockSupabase.from('creator_analytics'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.stream(primaryKey: ['id']))
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.eq('creator_id', creatorId))
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.order('period_date', descending: true))
            .thenReturn(mockChannel);
        when(mockChannel.map(any))
            .thenAnswer((_) => Stream.value(analyticsData));

        // Act
        final stream = repository.getAnalyticsStream(creatorId);

        // Assert
        expect(stream, isA<Stream<List<CreatorAnalytics>>>());
        
        // Verify the stream emits correct data
        final result = await stream.first;
        expect(result, hasLength(1));
        expect(result.first.creatorId, equals(creatorId));
        expect(result.first.views, equals(1000));

        verify(mockSupabase.from('creator_analytics')).called(1);
        verify(mockFilterBuilder.stream(primaryKey: ['id'])).called(1);
        verify(mockTransformBuilder.eq('creator_id', creatorId)).called(1);
        verify(mockTransformBuilder.order('period_date', descending: true)).called(1);
      });

      test('should handle stream errors', () async {
        // Arrange
        const creatorId = 'test-creator-id';
        final mockFilterBuilder = MockPostgrestFilterBuilder();
        final mockTransformBuilder = MockPostgrestTransformBuilder();
        final mockChannel = MockRealtimeChannel();

        when(mockSupabase.from('creator_analytics'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.stream(primaryKey: ['id']))
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.eq('creator_id', creatorId))
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.order('period_date', descending: true))
            .thenReturn(mockChannel);
        when(mockChannel.map(any))
            .thenThrow(Exception('Stream error'));

        // Act
        final stream = repository.getAnalyticsStream(creatorId);

        // Assert
        expect(stream, emitsError(isA<Exception>()));
      });
    });

    group('getAnalyticsForPeriod', () {
      test('should return analytics for specified period', () async {
        // Arrange
        const creatorId = 'test-creator-id';
        final startDate = DateTime.now().subtract(const Duration(days: 7));
        final endDate = DateTime.now();
        final mockFilterBuilder = MockPostgrestFilterBuilder();

        final analyticsData = [
          {
            'id': '1',
            'creator_id': creatorId,
            'period_date': DateTime.now().toIso8601String(),
            'views': 1000,
            'likes': 100,
            'comments': 50,
            'shares': 25,
            'engagement_rate': 0.175,
            'new_followers': 10,
            'total_revenue': 50.0,
            'demographic_data': {},
            'geographic_data': {},
            'top_content': [],
          }
        ];

        when(mockSupabase.from('creator_analytics'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select())
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('creator_id', creatorId))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.gte('period_date', any))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.lte('period_date', any))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.order('period_date', descending: true))
            .thenAnswer((_) async => analyticsData);

        // Act
        final result = await repository.getAnalyticsForPeriod(creatorId, startDate, endDate);

        // Assert
        expect(result, hasLength(1));
        expect(result.first.creatorId, equals(creatorId));
        expect(result.first.views, equals(1000));

        verify(mockSupabase.from('creator_analytics')).called(1);
        verify(mockFilterBuilder.select()).called(1);
        verify(mockFilterBuilder.eq('creator_id', creatorId)).called(1);
        verify(mockFilterBuilder.gte('period_date', any)).called(1);
        verify(mockFilterBuilder.lte('period_date', any)).called(1);
        verify(mockFilterBuilder.order('period_date', descending: true)).called(1);
      });

      test('should handle repository errors', () async {
        // Arrange
        const creatorId = 'test-creator-id';
        final startDate = DateTime.now().subtract(const Duration(days: 7));
        final endDate = DateTime.now();
        final mockFilterBuilder = MockPostgrestFilterBuilder();

        when(mockSupabase.from('creator_analytics'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select())
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('creator_id', creatorId))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.gte('period_date', any))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.lte('period_date', any))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.order('period_date', descending: true))
            .thenThrow(Exception('Database error'));

        // Act & Assert
        expect(() async => await repository.getAnalyticsForPeriod(creatorId, startDate, endDate),
               throwsException);
      });
    });

    group('getContentPerformance', () {
      test('should return content performance data', () async {
        // Arrange
        const creatorId = 'test-creator-id';
        final mockFilterBuilder = MockPostgrestFilterBuilder();

        final performanceData = [
          {
            'id': '1',
            'media_id': 'media-1',
            'title': 'Test Content',
            'thumbnail_url': 'https://example.com/thumb.jpg',
            'views': 1000,
            'watch_time_seconds': 3600,
            'retention_rate': 0.75,
            'revenue_generated': 25.0,
            'traffic_sources': {},
            'performance_date': DateTime.now().toIso8601String(),
          }
        ];

        when(mockSupabase.from('content_performance'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select())
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('creator_id', creatorId))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.order('performance_date', descending: true))
            .thenAnswer((_) async => performanceData);

        // Act
        final result = await repository.getContentPerformance(creatorId);

        // Assert
        expect(result, hasLength(1));
        expect(result.first.mediaId, equals('media-1'));
        expect(result.first.views, equals(1000));
        expect(result.first.retentionRate, equals(0.75));

        verify(mockSupabase.from('content_performance')).called(1);
        verify(mockFilterBuilder.select()).called(1);
        verify(mockFilterBuilder.eq('creator_id', creatorId)).called(1);
        verify(mockFilterBuilder.order('performance_date', descending: true)).called(1);
      });

      test('should apply limit when specified', () async {
        // Arrange
        const creatorId = 'test-creator-id';
        const limit = 5;
        final mockFilterBuilder = MockPostgrestFilterBuilder();

        final performanceData = [
          {
            'id': '1',
            'media_id': 'media-1',
            'title': 'Test Content',
            'thumbnail_url': 'https://example.com/thumb.jpg',
            'views': 1000,
            'watch_time_seconds': 3600,
            'retention_rate': 0.75,
            'revenue_generated': 25.0,
            'traffic_sources': {},
            'performance_date': DateTime.now().toIso8601String(),
          }
        ];

        when(mockSupabase.from('content_performance'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select())
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('creator_id', creatorId))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.order('performance_date', descending: true))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.limit(limit))
            .thenAnswer((_) async => performanceData);

        // Act
        final result = await repository.getContentPerformance(creatorId, limit: limit);

        // Assert
        expect(result, hasLength(1));
        verify(mockFilterBuilder.limit(limit)).called(1);
      });
    });

    group('getRevenueMetrics', () {
      test('should calculate revenue metrics correctly', () async {
        // Arrange
        const creatorId = 'test-creator-id';
        final mockFilterBuilder = MockPostgrestFilterBuilder();

        final transactionsData = [
          {
            'id': '1',
            'transaction_type': 'ad',
            'amount': 25.0,
            'source': 'Ad Revenue',
            'media_id': 'media-1',
            'metadata': {},
            'transaction_date': DateTime.now().toIso8601String(),
          },
          {
            'id': '2',
            'transaction_type': 'subscription',
            'amount': 15.0,
            'source': 'Subscription',
            'media_id': null,
            'metadata': {},
            'transaction_date': DateTime.now().toIso8601String(),
          },
        ];

        when(mockSupabase.from('revenue_transactions'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select())
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('creator_id', creatorId))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.order('transaction_date', descending: true))
            .thenAnswer((_) async => transactionsData);

        // Act
        final result = await repository.getRevenueMetrics(creatorId);

        // Assert
        expect(result.creatorId, equals(creatorId));
        expect(result.adRevenue, equals(25.0));
        expect(result.subscriptionRevenue, equals(15.0));
        expect(result.sponsorshipRevenue, equals(0.0));
        expect(result.donationRevenue, equals(0.0));
        expect(result.totalRevenue, equals(40.0));
        expect(result.transactions, hasLength(2));

        verify(mockSupabase.from('revenue_transactions')).called(1);
        verify(mockFilterBuilder.select()).called(1);
        verify(mockFilterBuilder.eq('creator_id', creatorId)).called(1);
        verify(mockFilterBuilder.order('transaction_date', descending: true)).called(1);
      });

      test('should apply date filters when provided', () async {
        // Arrange
        const creatorId = 'test-creator-id';
        final startDate = DateTime.now().subtract(const Duration(days: 30));
        final endDate = DateTime.now();
        final mockFilterBuilder = MockPostgrestFilterBuilder();

        when(mockSupabase.from('revenue_transactions'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select())
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('creator_id', creatorId))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.gte('transaction_date', any))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.lte('transaction_date', any))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.order('transaction_date', descending: true))
            .thenAnswer((_) async => []);

        // Act
        await repository.getRevenueMetrics(
          creatorId,
          startDate: startDate,
          endDate: endDate,
        );

        // Assert
        verify(mockFilterBuilder.gte('transaction_date', any)).called(1);
        verify(mockFilterBuilder.lte('transaction_date', any)).called(1);
      });
    });

    group('trackContentView', () {
      test('should track content view successfully', () async {
        // Arrange
        const mediaId = 'test-media-id';
        const userId = 'test-user-id';

        when(mockSupabase.rpc('increment_media_views', params: anyNamed('params')))
            .thenAnswer((_) async {});
        when(mockSupabase.rpc('track_content_view', params: anyNamed('params')))
            .thenAnswer((_) async {});

        // Act & Assert
        expect(() async => await repository.trackContentView(mediaId, userId), 
               returnsNormally);

        verify(mockSupabase.rpc('increment_media_views', params: anyNamed('params'))).called(1);
        verify(mockSupabase.rpc('track_content_view', params: anyNamed('params'))).called(1);
      });

      test('should handle tracking errors gracefully', () async {
        // Arrange
        const mediaId = 'test-media-id';
        const userId = 'test-user-id';

        when(mockSupabase.rpc('increment_media_views', params: anyNamed('params')))
            .thenThrow(Exception('Tracking failed'));

        // Act & Assert
        expect(() async => await repository.trackContentView(mediaId, userId), 
               returnsNormally);

        // Should not throw even on error
      });
    });

    group('trackEngagement', () {
      test('should track engagement successfully', () async {
        // Arrange
        const mediaId = 'test-media-id';
        const userId = 'test-user-id';
        const engagementType = 'like';

        when(mockSupabase.rpc('track_engagement', params: anyNamed('params')))
            .thenAnswer((_) async {});

        // Act & Assert
        expect(() async => await repository.trackEngagement(mediaId, userId, engagementType), 
               returnsNormally);

        verify(mockSupabase.rpc('track_engagement', params: anyNamed('params'))).called(1);
      });

      test('should handle engagement tracking errors gracefully', () async {
        // Arrange
        const mediaId = 'test-media-id';
        const userId = 'test-user-id';
        const engagementType = 'comment';

        when(mockSupabase.rpc('track_engagement', params: anyNamed('params')))
            .thenThrow(Exception('Engagement tracking failed'));

        // Act & Assert
        expect(() async => await repository.trackEngagement(mediaId, userId, engagementType), 
               returnsNormally);

        // Should not throw even on error
      });
    });

    group('updateRevenueMetrics', () {
      test('should update revenue metrics successfully', () async {
        // Arrange
        const creatorId = 'test-creator-id';
        final transaction = RevenueTransaction(
          id: 'test-transaction-id',
          type: RevenueType.ad,
          amount: 25.0,
          source: 'Test Ad',
          timestamp: DateTime.now(),
        );

        final mockFilterBuilder = MockPostgrestFilterBuilder();

        when(mockSupabase.from('revenue_transactions'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.insert(any))
            .thenAnswer((_) async {});

        // Act & Assert
        expect(() async => await repository.updateRevenueMetrics(creatorId, transaction), 
               returnsNormally);

        verify(mockSupabase.from('revenue_transactions')).called(1);
        verify(mockFilterBuilder.insert(any)).called(1);
      });

      test('should handle update errors', () async {
        // Arrange
        const creatorId = 'test-creator-id';
        final transaction = RevenueTransaction(
          id: 'test-transaction-id',
          type: RevenueType.ad,
          amount: 25.0,
          source: 'Test Ad',
          timestamp: DateTime.now(),
        );

        final mockFilterBuilder = MockPostgrestFilterBuilder();

        when(mockSupabase.from('revenue_transactions'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.insert(any))
            .thenThrow(Exception('Update failed'));

        // Act & Assert
        expect(() async => await repository.updateRevenueMetrics(creatorId, transaction), 
               throwsException);
      });
    });

    group('getTopContent', () {
      test('should return top content for specified period', () async {
        // Arrange
        const creatorId = 'test-creator-id';
        const limit = 10;
        final mockFilterBuilder = MockPostgrestFilterBuilder();

        final performanceData = [
          {
            'id': '1',
            'media_id': 'media-1',
            'title': 'Top Content',
            'thumbnail_url': 'https://example.com/thumb.jpg',
            'views': 5000,
            'watch_time_seconds': 18000,
            'retention_rate': 0.85,
            'revenue_generated': 125.0,
            'traffic_sources': {},
            'performance_date': DateTime.now().toIso8601String(),
          }
        ];

        when(mockSupabase.from('content_performance'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select())
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('creator_id', creatorId))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.gte('performance_date', any))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.order('views', descending: true))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.limit(limit))
            .thenAnswer((_) async => performanceData);

        // Act
        final result = await repository.getTopContent(creatorId, AnalyticsPeriod.weekly, limit);

        // Assert
        expect(result, hasLength(1));
        expect(result.first.views, equals(5000));
        expect(result.first.title, equals('Top Content'));

        verify(mockFilterBuilder.gte('performance_date', any)).called(1);
        verify(mockFilterBuilder.order('views', descending: true)).called(1);
        verify(mockFilterBuilder.limit(limit)).called(1);
      });
    });

    group('getDemographicData', () {
      test('should return demographic data', () async {
        // Arrange
        const creatorId = 'test-creator-id';
        final mockFilterBuilder = MockPostgrestFilterBuilder();

        final demographicData = {
          '18-24': 100,
          '25-34': 200,
          '35-44': 150,
        };

        when(mockSupabase.from('creator_analytics'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select('demographic_data'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('creator_id', creatorId))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.order('period_date', descending: true))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.limit(1))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single())
            .thenAnswer((_) async => {'demographic_data': demographicData});

        // Act
        final result = await repository.getDemographicData(creatorId);

        // Assert
        expect(result, equals(demographicData));
        expect(result['18-24'], equals(100));
        expect(result['25-34'], equals(200));

        verify(mockSupabase.from('creator_analytics')).called(1);
        verify(mockFilterBuilder.select('demographic_data')).called(1);
        verify(mockFilterBuilder.eq('creator_id', creatorId)).called(1);
        verify(mockFilterBuilder.order('period_date', descending: true)).called(1);
        verify(mockFilterBuilder.limit(1)).called(1);
        verify(mockFilterBuilder.single()).called(1);
      });

      test('should return empty map on error', () async {
        // Arrange
        const creatorId = 'test-creator-id';
        final mockFilterBuilder = MockPostgrestFilterBuilder();

        when(mockSupabase.from('creator_analytics'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select('demographic_data'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('creator_id', creatorId))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.order('period_date', descending: true))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.limit(1))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single())
            .thenThrow(Exception('No data found'));

        // Act
        final result = await repository.getDemographicData(creatorId);

        // Assert
        expect(result, isEmpty);
      });
    });

    group('getGeographicData', () {
      test('should return geographic data', () async {
        // Arrange
        const creatorId = 'test-creator-id';
        final mockFilterBuilder = MockPostgrestFilterBuilder();

        final geographicData = {
          'US': 0.45,
          'UK': 0.25,
          'CA': 0.15,
        };

        when(mockSupabase.from('creator_analytics'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select('geographic_data'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('creator_id', creatorId))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.order('period_date', descending: true))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.limit(1))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single())
            .thenAnswer((_) async => {'geographic_data': geographicData});

        // Act
        final result = await repository.getGeographicData(creatorId);

        // Assert
        expect(result, equals(geographicData));
        expect(result['US'], equals(0.45));
        expect(result['UK'], equals(0.25));

        verify(mockSupabase.from('creator_analytics')).called(1);
        verify(mockFilterBuilder.select('geographic_data')).called(1);
        verify(mockFilterBuilder.eq('creator_id', creatorId)).called(1);
        verify(mockFilterBuilder.order('period_date', descending: true)).called(1);
        verify(mockFilterBuilder.limit(1)).called(1);
        verify(mockFilterBuilder.single()).called(1);
      });

      test('should return empty map on error', () async {
        // Arrange
        const creatorId = 'test-creator-id';
        final mockFilterBuilder = MockPostgrestFilterBuilder();

        when(mockSupabase.from('creator_analytics'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select('geographic_data'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('creator_id', creatorId))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.order('period_date', descending: true))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.limit(1))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.single())
            .thenThrow(Exception('No data found'));

        // Act
        final result = await repository.getGeographicData(creatorId);

        // Assert
        expect(result, isEmpty);
      });
    });

    group('getPayouts', () {
      test('should return payout data', () async {
        // Arrange
        const creatorId = 'test-creator-id';
        final mockFilterBuilder = MockPostgrestFilterBuilder();

        final payoutsData = [
          {
            'id': '1',
            'creator_id': creatorId,
            'total_amount': 100.0,
            'period_start': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
            'period_end': DateTime.now().toIso8601String(),
            'status': 'paid',
            'payout_method': {'type': 'bank'},
            'processed_at': DateTime.now().toIso8601String(),
          }
        ];

        when(mockSupabase.from('creator_payouts'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select())
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('creator_id', creatorId))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.order('created_at', descending: true))
            .thenAnswer((_) async => payoutsData);

        // Act
        final result = await repository.getPayouts(creatorId);

        // Assert
        expect(result, hasLength(1));
        expect(result.first['total_amount'], equals(100.0));
        expect(result.first['status'], equals('paid'));

        verify(mockSupabase.from('creator_payouts')).called(1);
        verify(mockFilterBuilder.select()).called(1);
        verify(mockFilterBuilder.eq('creator_id', creatorId)).called(1);
        verify(mockFilterBuilder.order('created_at', descending: true)).called(1);
      });

      test('should apply status filter when provided', () async {
        // Arrange
        const creatorId = 'test-creator-id';
        const status = 'pending';
        final mockFilterBuilder = MockPostgrestFilterBuilder();

        when(mockSupabase.from('creator_payouts'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select())
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('creator_id', creatorId))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('status', status))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.order('created_at', descending: true))
            .thenAnswer((_) async => []);

        // Act
        await repository.getPayouts(creatorId, status: status);

        // Assert
        verify(mockFilterBuilder.eq('status', status)).called(1);
      });
    });

    group('saveAnalytics', () {
      test('should save analytics data successfully', () async {
        // Arrange
        final analytics = CreatorAnalytics(
          id: 'test-analytics-id',
          creatorId: 'test-creator-id',
          period: DateTime.now(),
          views: 1000,
          likes: 100,
          comments: 50,
          shares: 25,
          engagementRate: 0.175,
          newFollowers: 10,
          revenue: 50.0,
        );

        final mockFilterBuilder = MockPostgrestFilterBuilder();

        when(mockSupabase.from('creator_analytics'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.upsert(any))
            .thenAnswer((_) async {});

        // Act & Assert
        expect(() async => await repository.saveAnalytics(analytics), returnsNormally);

        verify(mockSupabase.from('creator_analytics')).called(1);
        verify(mockFilterBuilder.upsert(any)).called(1);
      });

      test('should handle save errors', () async {
        // Arrange
        final analytics = CreatorAnalytics(
          id: 'test-analytics-id',
          creatorId: 'test-creator-id',
          period: DateTime.now(),
          views: 1000,
        );

        final mockFilterBuilder = MockPostgrestFilterBuilder();

        when(mockSupabase.from('creator_analytics'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.upsert(any))
            .thenThrow(Exception('Save failed'));

        // Act & Assert
        expect(() async => await repository.saveAnalytics(analytics), throwsException);
      });
    });
  });
}
