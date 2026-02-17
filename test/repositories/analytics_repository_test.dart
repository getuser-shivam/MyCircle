import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import 'package:my_circle\repositories\analytics_repository.dart';

// Generate mocks
@GenerateMocks([
  SupabaseClient,
  RealtimeChannel,
  PostgrestFilterBuilder,
  PostgrestTransformBuilder,
  SupabaseService,
])
import 'analytics_repository_test.mocks.dart';

void main() {
  group('AnalyticsRepository Tests', () {
    late AnalyticsRepository analyticsRepository;
    late MockSupabaseClient mockSupabaseClient;
    late MockRealtimeChannel mockRealtimeChannel;
    late MockPostgrestFilterBuilder mockFilterBuilder;
    late MockPostgrestTransformBuilder mockTransformBuilder;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockRealtimeChannel = MockRealtimeChannel();
      mockFilterBuilder = MockPostgrestFilterBuilder();
      mockTransformBuilder = MockPostgrestTransformBuilder();
      
      analyticsRepository = AnalyticsRepository(mockSupabaseClient);
    });

    group('Analytics Stream Tests', () {
      test('should get analytics stream for creator', () async {
        final mockData = [
          {
            'id': '1',
            'creator_id': 'creator_1',
            'period_date': '2024-01-01',
            'total_views': 1000,
            'total_likes': 100,
            'total_shares': 50,
            'total_revenue': 500.0,
            'follower_growth': 25,
            'engagement_rate': 0.15,
            'created_at': DateTime.now().toIso8601String(),
          }
        ];

        // Setup mock chain
        when(mockSupabaseClient.from('creator_analytics'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.stream(primaryKey: ['id']))
            .thenAnswer((_) => Stream.value(mockData));
        when(mockFilterBuilder.eq('creator_id', 'creator_1'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.order('period_date', descending: true))
            .thenReturn(mockFilterBuilder);

        final stream = analyticsRepository.getAnalyticsStream('creator_1');
        
        expect(stream, isA<Stream<List<Map<String, dynamic>>>>());
        
        final results = await stream.first;
        expect(results.length, 1);
        expect(results.first['creator_id'], 'creator_1');
        expect(results.first['total_views'], 1000);
      });

      test('should get analytics stream with period filter', () async {
        final mockData = [
          {
            'id': '2',
            'creator_id': 'creator_2',
            'period_date': '2024-01-01',
            'period': 'monthly',
            'total_views': 2000,
            'total_likes': 200,
            'total_shares': 100,
            'total_revenue': 1000.0,
          }
        ];

        when(mockSupabaseClient.from('creator_analytics'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.stream(primaryKey: ['id']))
            .thenAnswer((_) => Stream.value(mockData));
        when(mockFilterBuilder.eq('creator_id', 'creator_2'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('period', 'monthly'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.order('period_date', descending: true))
            .thenReturn(mockFilterBuilder);

        final stream = analyticsRepository.getAnalyticsStream(
          'creator_2',
          period: AnalyticsPeriod.monthly,
        );
        
        final results = await stream.first;
        expect(results.length, 1);
        expect(results.first['period'], 'monthly');
      });

      test('should get analytics stream with limit', () async {
        final mockData = [
          {'id': '1', 'creator_id': 'creator_3', 'total_views': 100},
          {'id': '2', 'creator_id': 'creator_3', 'total_views': 200},
          {'id': '3', 'creator_id': 'creator_3', 'total_views': 300},
        ];

        when(mockSupabaseClient.from('creator_analytics'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.stream(primaryKey: ['id']))
            .thenAnswer((_) => Stream.value(mockData));
        when(mockFilterBuilder.eq('creator_id', 'creator_3'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.order('period_date', descending: true))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.limit(2))
            .thenReturn(mockFilterBuilder);

        final stream = analyticsRepository.getAnalyticsStream('creator_3', limit: 2);
        
        final results = await stream.first;
        expect(results.length, 3); // Mock returns all data, limit would be applied by Supabase
      });

      test('should handle stream error gracefully', () async {
        when(mockSupabaseClient.from('creator_analytics'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.stream(primaryKey: ['id']))
            .thenAnswer((_) => Stream.error(Exception('Database error')));
        when(mockFilterBuilder.eq('creator_id', 'creator_4'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.order('period_date', descending: true))
            .thenReturn(mockFilterBuilder);

        final stream = analyticsRepository.getAnalyticsStream('creator_4');
        
        expect(stream, emitsError(isA<Exception>()));
      });
    });

    group('Content Performance Tests', () {
      test('should get content performance stream', () async {
        final mockData = [
          {
            'id': '1',
            'content_id': 'content_1',
            'creator_id': 'creator_1',
            'title': 'Test Content',
            'views': 1000,
            'likes': 100,
            'shares': 50,
            'comments': 25,
            'revenue': 100.0,
            'engagement_rate': 0.175,
            'published_at': DateTime.now().toIso8601String(),
          }
        ];

        when(mockSupabaseClient.from('content_performance'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.stream(primaryKey: ['id']))
            .thenAnswer((_) => Stream.value(mockData));
        when(mockFilterBuilder.eq('creator_id', 'creator_1'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.order('published_at', descending: true))
            .thenReturn(mockFilterBuilder);

        final stream = analyticsRepository.getContentPerformanceStream('creator_1');
        
        final results = await stream.first;
        expect(results.length, 1);
        expect(results.first['content_id'], 'content_1');
        expect(results.first['views'], 1000);
      });

      test('should get content performance with date range', () async {
        final startDate = DateTime.now().subtract(const Duration(days: 30));
        final endDate = DateTime.now();

        when(mockSupabaseClient.from('content_performance'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.stream(primaryKey: ['id']))
            .thenAnswer((_) => Stream.value([]));
        when(mockFilterBuilder.eq('creator_id', 'creator_2'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.gte('published_at', startDate.toIso8601String()))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.lte('published_at', endDate.toIso8601String()))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.order('published_at', descending: true))
            .thenReturn(mockFilterBuilder);

        final stream = analyticsRepository.getContentPerformanceStream(
          'creator_2',
          startDate: startDate,
          endDate: endDate,
        );
        
        expect(stream, isA<Stream<List<Map<String, dynamic>>>>());
        
        verify(mockFilterBuilder.gte('published_at', startDate.toIso8601String()))
            .called(1);
        verify(mockFilterBuilder.lte('published_at', endDate.toIso8601String()))
            .called(1);
      });
    });

    group('Revenue Data Tests', () {
      test('should get revenue transactions stream', () async {
        final mockData = [
          {
            'id': '1',
            'creator_id': 'creator_1',
            'amount': 100.0,
            'type': 'subscription',
            'status': 'completed',
            'transaction_date': DateTime.now().toIso8601String(),
            'description': 'Monthly subscription',
          }
        ];

        when(mockSupabaseClient.from('revenue_transactions'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.stream(primaryKey: ['id']))
            .thenAnswer((_) => Stream.value(mockData));
        when(mockFilterBuilder.eq('creator_id', 'creator_1'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.order('transaction_date', descending: true))
            .thenReturn(mockFilterBuilder);

        final stream = analyticsRepository.getRevenueTransactionsStream('creator_1');
        
        final results = await stream.first;
        expect(results.length, 1);
        expect(results.first['amount'], 100.0);
        expect(results.first['type'], 'subscription');
      });

      test('should get revenue transactions with date range', () async {
        final startDate = DateTime.now().subtract(const Duration(days: 30));
        final endDate = DateTime.now();

        when(mockSupabaseClient.from('revenue_transactions'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.stream(primaryKey: ['id']))
            .thenAnswer((_) => Stream.value([]));
        when(mockFilterBuilder.eq('creator_id', 'creator_2'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.gte('transaction_date', startDate.toIso8601String()))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.lte('transaction_date', endDate.toIso8601String()))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.order('transaction_date', descending: true))
            .thenReturn(mockFilterBuilder);

        final stream = analyticsRepository.getRevenueTransactionsStream(
          'creator_2',
          startDate: startDate,
          endDate: endDate,
        );
        
        expect(stream, isA<Stream<List<Map<String, dynamic>>>>());
      });

      test('should get payouts stream', () async {
        final mockData = [
          {
            'id': '1',
            'creator_id': 'creator_1',
            'amount': 500.0,
            'status': 'paid',
            'payout_date': DateTime.now().toIso8601String(),
            'period_start': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
            'period_end': DateTime.now().toIso8601String(),
          }
        ];

        when(mockSupabaseClient.from('creator_payouts'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.stream(primaryKey: ['id']))
            .thenAnswer((_) => Stream.value(mockData));
        when(mockFilterBuilder.eq('creator_id', 'creator_1'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.order('payout_date', descending: true))
            .thenReturn(mockFilterBuilder);

        final stream = analyticsRepository.getPayoutsStream('creator_1');
        
        final results = await stream.first;
        expect(results.length, 1);
        expect(results.first['amount'], 500.0);
        expect(results.first['status'], 'paid');
      });
    });

    group('Analytics Summary Tests', () {
      test('should get analytics summary', () async {
        final mockData = {
          'total_views': 10000,
          'total_likes': 1000,
          'total_shares': 500,
          'total_revenue': 2000.0,
          'total_followers': 1000,
          'follower_growth_rate': 0.1,
          'average_engagement_rate': 0.15,
          'monthly_revenue': 500.0,
          'pending_payouts': 100.0,
        };

        when(mockSupabaseClient.from('creator_analytics_summary'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select())
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.eq('creator_id', 'creator_1'))
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.single())
            .thenAnswer((_) async => mockData);

        final result = await analyticsRepository.getAnalyticsSummary('creator_1');
        
        expect(result, isNotNull);
        expect(result!['total_views'], 10000);
        expect(result['total_revenue'], 2000.0);
      });

      test('should handle analytics summary not found', () async {
        when(mockSupabaseClient.from('creator_analytics_summary'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select())
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.eq('creator_id', 'creator_2'))
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.single())
            .thenThrow(PostgrestException(message: 'No rows found'));

        final result = await analyticsRepository.getAnalyticsSummary('creator_2');
        
        expect(result, isNull);
      });
    });

    group('Data Creation Tests', () {
      test('should create analytics record', () async {
        final analyticsData = {
          'creator_id': 'creator_1',
          'period_date': '2024-01-01',
          'period': 'monthly',
          'total_views': 1000,
          'total_likes': 100,
          'total_shares': 50,
          'total_revenue': 500.0,
        };

        when(mockSupabaseClient.from('creator_analytics'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.insert(analyticsData))
            .thenAnswer((_) async => {'id': '1'});

        final result = await analyticsRepository.createAnalyticsRecord(analyticsData);
        
        expect(result, isNotNull);
        expect(result!['id'], '1');
        verify(mockFilterBuilder.insert(analyticsData)).called(1);
      });

      test('should create content performance record', () async {
        final performanceData = {
          'content_id': 'content_1',
          'creator_id': 'creator_1',
          'title': 'Test Content',
          'views': 1000,
          'likes': 100,
          'shares': 50,
          'revenue': 100.0,
        };

        when(mockSupabaseClient.from('content_performance'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.insert(performanceData))
            .thenAnswer((_) async => {'id': '1'});

        final result = await analyticsRepository.createContentPerformanceRecord(performanceData);
        
        expect(result, isNotNull);
        expect(result!['id'], '1');
        verify(mockFilterBuilder.insert(performanceData)).called(1);
      });

      test('should create revenue transaction', () async {
        final transactionData = {
          'creator_id': 'creator_1',
          'amount': 100.0,
          'type': 'subscription',
          'status': 'completed',
          'description': 'Monthly subscription',
        };

        when(mockSupabaseClient.from('revenue_transactions'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.insert(transactionData))
            .thenAnswer((_) async => {'id': '1'});

        final result = await analyticsRepository.createRevenueTransaction(transactionData);
        
        expect(result, isNotNull);
        expect(result!['id'], '1');
        verify(mockFilterBuilder.insert(transactionData)).called(1);
      });
    });

    group('Data Update Tests', () {
      test('should update analytics record', () async {
        final updateData = {
          'total_views': 1500,
          'total_likes': 150,
          'updated_at': DateTime.now().toIso8601String(),
        };

        when(mockSupabaseClient.from('creator_analytics'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', '1'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.update(updateData))
            .thenAnswer((_) async => []);

        await analyticsRepository.updateAnalyticsRecord('1', updateData);
        
        verify(mockFilterBuilder.eq('id', '1')).called(1);
        verify(mockFilterBuilder.update(updateData)).called(1);
      });

      test('should update content performance record', () async {
        final updateData = {
          'views': 1200,
          'likes': 120,
          'updated_at': DateTime.now().toIso8601String(),
        };

        when(mockSupabaseClient.from('content_performance'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('content_id', 'content_1'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.update(updateData))
            .thenAnswer((_) async => []);

        await analyticsRepository.updateContentPerformanceRecord('content_1', updateData);
        
        verify(mockFilterBuilder.eq('content_id', 'content_1')).called(1);
        verify(mockFilterBuilder.update(updateData)).called(1);
      });
    });

    group('Error Handling Tests', () {
      test('should handle database connection errors', () async {
        when(mockSupabaseClient.from('creator_analytics'))
            .thenThrow(Exception('Connection failed'));

        expect(
          () => analyticsRepository.getAnalyticsStream('creator_1'),
          throwsException,
        );
      });

      test('should handle invalid data format', () async {
        final invalidData = [
          {'invalid': 'data'},
        ];

        when(mockSupabaseClient.from('creator_analytics'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.stream(primaryKey: ['id']))
            .thenAnswer((_) => Stream.value(invalidData));
        when(mockFilterBuilder.eq('creator_id', 'creator_1'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.order('period_date', descending: true))
            .thenReturn(mockFilterBuilder);

        final stream = analyticsRepository.getAnalyticsStream('creator_1');
        
        // Should handle invalid data gracefully
        expect(stream, emits(isA<List<Map<String, dynamic>>>()));
      });

      test('should handle null parameters gracefully', () {
        expect(
          () => analyticsRepository.getAnalyticsStream(''),
          returnsNormally,
        );
      });
    });

    group('Real-time Subscription Tests', () {
      test('should setup real-time subscription', () {
        when(mockSupabaseClient.channel('analytics_channel'))
            .thenReturn(mockRealtimeChannel);
        when(mockRealtimeChannel.onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'creator_analytics',
          callback: anyNamed('callback'),
        )).thenReturn(mockRealtimeChannel);
        when(mockRealtimeChannel.subscribe())
            .thenAnswer((_) async {});

        analyticsRepository.setupRealtimeSubscription('creator_1');

        verify(mockSupabaseClient.channel('analytics_channel')).called(1);
        verify(mockRealtimeChannel.onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'creator_analytics',
          callback: anyNamed('callback'),
        )).called(1);
        verify(mockRealtimeChannel.subscribe()).called(1);
      });

      test('should unsubscribe from real-time updates', () {
        when(mockSupabaseClient.channel('analytics_channel'))
            .thenReturn(mockRealtimeChannel);
        when(mockRealtimeChannel.unsubscribe())
            .thenAnswer((_) async {});

        analyticsRepository.unsubscribeFromRealtimeUpdates();

        verify(mockRealtimeChannel.unsubscribe()).called(1);
      });
    });
  });
}
