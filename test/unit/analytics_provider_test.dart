import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:my_circle/models/analytics.dart';
import 'package:my_circle/providers/analytics_provider.dart';
import 'package:my_circle/repositories/analytics_repository.dart';

import 'analytics_provider_test.mocks.dart';

@GenerateMocks([AnalyticsRepository])
void main() {
  group('AnalyticsProvider', () {
    late AnalyticsProvider provider;
    late MockAnalyticsRepository mockRepository;

    setUp(() {
      mockRepository = MockAnalyticsRepository();
      provider = AnalyticsProvider(repository: mockRepository);
    });

    tearDown(() {
      provider.dispose();
    });

    group('loadCreatorAnalytics', () {
      test('should load analytics data successfully', () async {
        // Arrange
        const creatorId = 'test-creator-id';
        final analyticsData = [
          CreatorAnalytics(
            id: '1',
            creatorId: creatorId,
            period: DateTime.now(),
            views: 1000,
            likes: 100,
            comments: 50,
            shares: 25,
            engagementRate: 0.175,
            newFollowers: 10,
            revenue: 50.0,
          ),
        ];

        when(mockRepository.getAnalyticsStream(creatorId, period: anyNamed('period')))
            .thenAnswer((_) => Stream.value(analyticsData));
        when(mockRepository.getContentPerformance(creatorId))
            .thenAnswer((_) async => []);
        when(mockRepository.getRevenueMetrics(creatorId))
            .thenAnswer((_) async => MonetizationMetrics(
              id: '1',
              creatorId: creatorId,
              totalRevenue: 50.0,
              period: DateTime.now(),
            ));
        when(mockRepository.getDemographicData(creatorId))
            .thenAnswer((_) async => {});
        when(mockRepository.getGeographicData(creatorId))
            .thenAnswer((_) async => {});
        when(mockRepository.getPayouts(creatorId))
            .thenAnswer((_) async => []);

        // Act
        await provider.loadCreatorAnalytics(creatorId);

        // Assert
        expect(provider.currentCreatorId, equals(creatorId));
        expect(provider.analyticsData, equals(analyticsData));
        expect(provider.isLoadingAnalytics, isFalse);
        expect(provider.analyticsError, isNull);

        verify(mockRepository.getAnalyticsStream(creatorId, period: anyNamed('period'))).called(1);
        verify(mockRepository.getContentPerformance(creatorId)).called(1);
        verify(mockRepository.getRevenueMetrics(creatorId)).called(1);
        verify(mockRepository.getDemographicData(creatorId)).called(1);
        verify(mockRepository.getGeographicData(creatorId)).called(1);
        verify(mockRepository.getPayouts(creatorId)).called(1);
      });

      test('should handle loading errors', () async {
        // Arrange
        const creatorId = 'test-creator-id';
        final errorMessage = 'Failed to load analytics';

        when(mockRepository.getAnalyticsStream(creatorId, period: anyNamed('period')))
            .thenThrow(Exception(errorMessage));

        // Act
        await provider.loadCreatorAnalytics(creatorId);

        // Assert
        expect(provider.isLoadingAnalytics, isFalse);
        expect(provider.analyticsError, equals(errorMessage));
        expect(provider.analyticsData, isEmpty);
      });

      test('should not reload if same parameters are used', () async {
        // Arrange
        const creatorId = 'test-creator-id';
        final analyticsData = [
          CreatorAnalytics(
            id: '1',
            creatorId: creatorId,
            period: DateTime.now(),
            views: 1000,
          ),
        ];

        when(mockRepository.getAnalyticsStream(creatorId, period: anyNamed('period')))
            .thenAnswer((_) => Stream.value(analyticsData));
        when(mockRepository.getContentPerformance(any))
            .thenAnswer((_) async => []);
        when(mockRepository.getRevenueMetrics(any))
            .thenAnswer((_) async => MonetizationMetrics(
              id: '1',
              creatorId: creatorId,
              totalRevenue: 50.0,
              period: DateTime.now(),
            ));
        when(mockRepository.getDemographicData(any))
            .thenAnswer((_) async => {});
        when(mockRepository.getGeographicData(any))
            .thenAnswer((_) async => {});
        when(mockRepository.getPayouts(any))
            .thenAnswer((_) async => []);

        // Act
        await provider.loadCreatorAnalytics(creatorId);
        await provider.loadCreatorAnalytics(creatorId); // Second call with same parameters

        // Assert
        verify(mockRepository.getAnalyticsStream(creatorId, period: anyNamed('period'))).called(1);
      });
    });

    group('updatePeriodFilter', () {
      test('should update period and reload data', () async {
        // Arrange
        const creatorId = 'test-creator-id';
        final analyticsData = [
          CreatorAnalytics(
            id: '1',
            creatorId: creatorId,
            period: DateTime.now(),
            views: 1000,
          ),
        ];

        when(mockRepository.getAnalyticsStream(creatorId, period: anyNamed('period')))
            .thenAnswer((_) => Stream.value(analyticsData));
        when(mockRepository.getContentPerformance(any))
            .thenAnswer((_) async => []);
        when(mockRepository.getRevenueMetrics(any))
            .thenAnswer((_) async => MonetizationMetrics(
              id: '1',
              creatorId: creatorId,
              totalRevenue: 50.0,
              period: DateTime.now(),
            ));
        when(mockRepository.getDemographicData(any))
            .thenAnswer((_) async => {});
        when(mockRepository.getGeographicData(any))
            .thenAnswer((_) async => {});
        when(mockRepository.getPayouts(any))
            .thenAnswer((_) async => []);

        await provider.loadCreatorAnalytics(creatorId);

        // Act
        await provider.updatePeriodFilter(AnalyticsPeriod.weekly);

        // Assert
        expect(provider.selectedPeriod, equals(AnalyticsPeriod.weekly));
        verify(mockRepository.getAnalyticsStream(creatorId, period: AnalyticsPeriod.weekly)).called(1);
      });

      test('should not reload if same period is selected', () async {
        // Arrange
        const creatorId = 'test-creator-id';
        final analyticsData = [
          CreatorAnalytics(
            id: '1',
            creatorId: creatorId,
            period: DateTime.now(),
            views: 1000,
          ),
        ];

        when(mockRepository.getAnalyticsStream(creatorId, period: anyNamed('period')))
            .thenAnswer((_) => Stream.value(analyticsData));
        when(mockRepository.getContentPerformance(any))
            .thenAnswer((_) async => []);
        when(mockRepository.getRevenueMetrics(any))
            .thenAnswer((_) async => MonetizationMetrics(
              id: '1',
              creatorId: creatorId,
              totalRevenue: 50.0,
              period: DateTime.now(),
            ));
        when(mockRepository.getDemographicData(any))
            .thenAnswer((_) async => {});
        when(mockRepository.getGeographicData(any))
            .thenAnswer((_) async => {});
        when(mockRepository.getPayouts(any))
            .thenAnswer((_) async => []);

        await provider.loadCreatorAnalytics(creatorId, period: AnalyticsPeriod.monthly);

        // Act
        await provider.updatePeriodFilter(AnalyticsPeriod.monthly); // Same period

        // Assert
        verify(mockRepository.getAnalyticsStream(creatorId, period: AnalyticsPeriod.monthly)).called(1);
      });
    });

    group('trackContentView', () {
      test('should track content view without throwing errors', () async {
        // Arrange
        const mediaId = 'test-media-id';
        const userId = 'test-user-id';

        when(mockRepository.trackContentView(mediaId, userId))
            .thenAnswer((_) async {});

        // Act & Assert
        expect(() async => await provider.trackContentView(mediaId, userId), returnsNormally);

        verify(mockRepository.trackContentView(mediaId, userId)).called(1);
      });

      test('should handle tracking errors gracefully', () async {
        // Arrange
        const mediaId = 'test-media-id';
        const userId = 'test-user-id';

        when(mockRepository.trackContentView(mediaId, userId))
            .thenThrow(Exception('Tracking failed'));

        // Act & Assert
        expect(() async => await provider.trackContentView(mediaId, userId), returnsNormally);

        verify(mockRepository.trackContentView(mediaId, userId)).called(1);
      });
    });

    group('trackEngagement', () {
      test('should track engagement without throwing errors', () async {
        // Arrange
        const mediaId = 'test-media-id';
        const userId = 'test-user-id';
        const engagementType = 'like';

        when(mockRepository.trackEngagement(mediaId, userId, engagementType))
            .thenAnswer((_) async {});

        // Act & Assert
        expect(() async => await provider.trackEngagement(mediaId, userId, engagementType), 
               returnsNormally);

        verify(mockRepository.trackEngagement(mediaId, userId, engagementType)).called(1);
      });
    });

    group('recordRevenueTransaction', () {
      test('should record revenue transaction and refresh metrics', () async {
        // Arrange
        const creatorId = 'test-creator-id';
        final transaction = RevenueTransaction(
          id: 'test-transaction-id',
          type: RevenueType.ad,
          amount: 10.0,
          source: 'Test Ad',
          timestamp: DateTime.now(),
        );

        final updatedMetrics = MonetizationMetrics(
          id: '1',
          creatorId: creatorId,
          totalRevenue: 60.0,
          period: DateTime.now(),
        );

        when(mockRepository.updateRevenueMetrics(creatorId, transaction))
            .thenAnswer((_) async {});
        when(mockRepository.getRevenueMetrics(creatorId))
            .thenAnswer((_) async => updatedMetrics);

        // Set initial state
        provider._currentCreatorId = creatorId;

        // Act
        await provider.recordRevenueTransaction(transaction);

        // Assert
        verify(mockRepository.updateRevenueMetrics(creatorId, transaction)).called(1);
        verify(mockRepository.getRevenueMetrics(creatorId)).called(1);
        expect(provider.revenueMetrics?.totalRevenue, equals(60.0));
      });

      test('should handle recording errors', () async {
        // Arrange
        const creatorId = 'test-creator-id';
        final transaction = RevenueTransaction(
          id: 'test-transaction-id',
          type: RevenueType.ad,
          amount: 10.0,
          source: 'Test Ad',
          timestamp: DateTime.now(),
        );

        when(mockRepository.updateRevenueMetrics(creatorId, transaction))
            .thenThrow(Exception('Recording failed'));

        // Set initial state
        provider._currentCreatorId = creatorId;

        // Act
        await provider.recordRevenueTransaction(transaction);

        // Assert
        expect(provider.revenueError, isNotNull);
        expect(provider.revenueError, contains('Recording failed'));
      });
    });

    group('getters and computed properties', () {
      test('should calculate total views correctly', () {
        // Arrange
        final analyticsData = [
          CreatorAnalytics(
            id: '1',
            creatorId: 'test',
            period: DateTime.now(),
            views: 1000,
          ),
          CreatorAnalytics(
            id: '2',
            creatorId: 'test',
            period: DateTime.now(),
            views: 2000,
          ),
        ];

        provider._analyticsData = analyticsData;

        // Act & Assert
        expect(provider.totalViews, equals(3000));
      });

      test('should calculate total revenue correctly', () {
        // Arrange
        final analyticsData = [
          CreatorAnalytics(
            id: '1',
            creatorId: 'test',
            period: DateTime.now(),
            revenue: 50.0,
          ),
          CreatorAnalytics(
            id: '2',
            creatorId: 'test',
            period: DateTime.now(),
            revenue: 75.0,
          ),
        ];

        provider._analyticsData = analyticsData;

        // Act & Assert
        expect(provider.totalRevenue, equals(125.0));
      });

      test('should calculate average engagement rate correctly', () {
        // Arrange
        final analyticsData = [
          CreatorAnalytics(
            id: '1',
            creatorId: 'test',
            period: DateTime.now(),
            engagementRate: 0.1,
          ),
          CreatorAnalytics(
            id: '2',
            creatorId: 'test',
            period: DateTime.now(),
            engagementRate: 0.2,
          ),
        ];

        provider._analyticsData = analyticsData;

        // Act & Assert
        expect(provider.averageEngagementRate, equals(0.15));
      });

      test('should return current analytics', () {
        // Arrange
        final analyticsData = [
          CreatorAnalytics(
            id: '1',
            creatorId: 'test',
            period: DateTime.now(),
            views: 1000,
          ),
          CreatorAnalytics(
            id: '2',
            creatorId: 'test',
            period: DateTime.now().subtract(const Duration(days: 1)),
            views: 500,
          ),
        ];

        provider._analyticsData = analyticsData;

        // Act & Assert
        expect(provider.currentAnalytics?.views, equals(1000));
      });

      test('should return null current analytics when empty', () {
        // Arrange
        provider._analyticsData = [];

        // Act & Assert
        expect(provider.currentAnalytics, isNull);
      });
    });

    group('clearData', () {
      test('should clear all data and reset state', () {
        // Arrange
        provider._currentCreatorId = 'test-creator';
        provider._analyticsData = [
          CreatorAnalytics(
            id: '1',
            creatorId: 'test',
            period: DateTime.now(),
            views: 1000,
          ),
        ];
        provider._revenueMetrics = MonetizationMetrics(
          id: '1',
          creatorId: 'test',
          totalRevenue: 50.0,
          period: DateTime.now(),
        );
        provider._isLoading = true;
        provider._analyticsError = 'Some error';

        // Act
        provider.clearData();

        // Assert
        expect(provider.currentCreatorId, isNull);
        expect(provider.analyticsData, isEmpty);
        expect(provider.revenueMetrics, isNull);
        expect(provider.isLoading, isFalse);
        expect(provider.analyticsError, isNull);
        expect(provider.selectedPeriod, equals(AnalyticsPeriod.monthly));
      });
    });

    group('getPerformanceTrend', () {
      test('should return performance trend data', () {
        // Arrange
        final analyticsData = [
          CreatorAnalytics(
            id: '1',
            creatorId: 'test',
            period: DateTime.now(),
            views: 1000,
          ),
          CreatorAnalytics(
            id: '2',
            creatorId: 'test',
            period: DateTime.now().subtract(const Duration(days: 1)),
            views: 800,
          ),
          CreatorAnalytics(
            id: '3',
            creatorId: 'test',
            period: DateTime.now().subtract(const Duration(days: 2)),
            views: 600,
          ),
        ];

        provider._analyticsData = analyticsData;

        // Act
        final trend = provider.getPerformanceTrend('views', 3);

        // Assert
        expect(trend, hasLength(3));
        expect(trend, equals([600.0, 800.0, 1000.0]));
      });

      test('should return empty list when insufficient data', () {
        // Arrange
        provider._analyticsData = [
          CreatorAnalytics(
            id: '1',
            creatorId: 'test',
            period: DateTime.now(),
            views: 1000,
          ),
        ];

        // Act
        final trend = provider.getPerformanceTrend('views', 3);

        // Assert
        expect(trend, isEmpty);
      });
    });

    group('getAnalyticsForDateRange', () {
      test('should filter analytics by date range', () {
        // Arrange
        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));
        final twoDaysAgo = now.subtract(const Duration(days: 2));

        final analyticsData = [
          CreatorAnalytics(
            id: '1',
            creatorId: 'test',
            period: now,
            views: 1000,
          ),
          CreatorAnalytics(
            id: '2',
            creatorId: 'test',
            period: yesterday,
            views: 800,
          ),
          CreatorAnalytics(
            id: '3',
            creatorId: 'test',
            period: twoDaysAgo,
            views: 600,
          ),
        ];

        provider._analyticsData = analyticsData;

        // Act
        final filtered = provider.getAnalyticsForDateRange(yesterday, now);

        // Assert
        expect(filtered, hasLength(2));
        expect(filtered[0].views, equals(1000));
        expect(filtered[1].views, equals(800));
      });
    });
  });
}
