import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_circle/models/analytics.dart';
import 'package:my_circle/widgets/analytics/analytics_overview_card.dart';

void main() {
  group('AnalyticsOverviewCard', () {
    testWidgets('should display analytics data correctly', (WidgetTester tester) async {
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

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnalyticsOverviewCard(
              analytics: analytics,
              title: 'Test Analytics',
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Test Analytics'), findsOneWidget);
      expect(find.text('1000'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
      expect(find.text('\$50.00'), findsOneWidget);
      expect(find.text('Views'), findsOneWidget);
      expect(find.text('Likes'), findsOneWidget);
      expect(find.text('Comments'), findsOneWidget);
      expect(find.text('Revenue'), findsOneWidget);
    });

    testWidgets('should display in compact mode', (WidgetTester tester) async {
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

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnalyticsOverviewCard(
              analytics: analytics,
              isCompact: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(GridView), findsNothing); // Compact mode uses Wrap
      expect(find.text('1000'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
      expect(find.text('\$50.00'), findsOneWidget);
    });

    testWidgets('should hide trend indicator when showTrend is false', (WidgetTester tester) async {
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

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnalyticsOverviewCard(
              analytics: analytics,
              showTrend: false,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.trending_up), findsNothing);
      expect(find.byIcon(Icons.trending_down), findsNothing);
    });

    testWidgets('should display period badge correctly', (WidgetTester tester) async {
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

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnalyticsOverviewCard(
              analytics: analytics,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Today'), findsOneWidget);
    });

    testWidgets('should display metric icons correctly', (WidgetTester tester) async {
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

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnalyticsOverviewCard(
              analytics: analytics,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.favorite_outline), findsOneWidget);
      expect(find.byIcon(Icons.comment_outlined), findsOneWidget);
      expect(find.byIcon(Icons.attach_money), findsOneWidget);
    });

    testWidgets('should format period correctly for different dates', (WidgetTester tester) async {
      // Test yesterday
      final yesterdayAnalytics = CreatorAnalytics(
        id: 'test-analytics-id',
        creatorId: 'test-creator-id',
        period: DateTime.now().subtract(const Duration(days: 1)),
        views: 1000,
        likes: 100,
        comments: 50,
        shares: 25,
        engagementRate: 0.175,
        newFollowers: 10,
        revenue: 50.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnalyticsOverviewCard(
              analytics: yesterdayAnalytics,
            ),
          ),
        ),
      );

      expect(find.text('Yesterday'), findsOneWidget);

      // Test 5 days ago
      final fiveDaysAgoAnalytics = CreatorAnalytics(
        id: 'test-analytics-id',
        creatorId: 'test-creator-id',
        period: DateTime.now().subtract(const Duration(days: 5)),
        views: 1000,
        likes: 100,
        comments: 50,
        shares: 25,
        engagementRate: 0.175,
        newFollowers: 10,
        revenue: 50.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnalyticsOverviewCard(
              analytics: fiveDaysAgoAnalytics,
            ),
          ),
        ),
      );

      expect(find.text('5 days ago'), findsOneWidget);
    });

    testWidgets('should handle zero values correctly', (WidgetTester tester) async {
      // Arrange
      final analytics = CreatorAnalytics(
        id: 'test-analytics-id',
        creatorId: 'test-creator-id',
        period: DateTime.now(),
        views: 0,
        likes: 0,
        comments: 0,
        shares: 0,
        engagementRate: 0.0,
        newFollowers: 0,
        revenue: 0.0,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnalyticsOverviewCard(
              analytics: analytics,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('0'), findsMultiple); // Multiple zero values
      expect(find.text('\$0.00'), findsOneWidget);
    });

    testWidgets('should handle large numbers correctly', (WidgetTester tester) async {
      // Arrange
      final analytics = CreatorAnalytics(
        id: 'test-analytics-id',
        creatorId: 'test-creator-id',
        period: DateTime.now(),
        views: 1000000,
        likes: 50000,
        comments: 25000,
        shares: 10000,
        engagementRate: 0.085,
        newFollowers: 5000,
        revenue: 5000.75,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnalyticsOverviewCard(
              analytics: analytics,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('1000000'), findsOneWidget);
      expect(find.text('50000'), findsOneWidget);
      expect(find.text('25000'), findsOneWidget);
      expect(find.text('10000'), findsOneWidget);
      expect(find.text('\$5000.75'), findsOneWidget);
    });

    testWidgets('should use RepaintBoundary for performance', (WidgetTester tester) async {
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

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnalyticsOverviewCard(
              analytics: analytics,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(RepaintBoundary), findsOneWidget);
    });

    testWidgets('should display custom title when provided', (WidgetTester tester) async {
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

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnalyticsOverviewCard(
              analytics: analytics,
              title: 'Custom Analytics Title',
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Custom Analytics Title'), findsOneWidget);
      expect(find.text('Analytics Overview'), findsNothing);
    });

    testWidgets('should display default title when none provided', (WidgetTester tester) async {
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

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnalyticsOverviewCard(
              analytics: analytics,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Analytics Overview'), findsOneWidget);
    });
  });
}
