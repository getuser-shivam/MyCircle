import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_circle/models/analytics.dart';
import 'package:my_circle/widgets/analytics/content_performance_widget.dart';

void main() {
  group('ContentPerformanceWidget', () {
    testWidgets('should display content performance data correctly', (WidgetTester tester) async {
      // Arrange
      final content = [
        ContentPerformance(
          id: '1',
          mediaId: 'media-1',
          title: 'Test Video',
          thumbnailUrl: 'https://example.com/thumb1.jpg',
          views: 1000,
          watchTime: 3600.0,
          retentionRate: 0.75,
          revenueGenerated: 25.0,
          performanceDate: DateTime.now(),
        ),
        ContentPerformance(
          id: '2',
          mediaId: 'media-2',
          title: 'Another Video',
          thumbnailUrl: 'https://example.com/thumb2.jpg',
          views: 500,
          watchTime: 1800.0,
          retentionRate: 0.60,
          revenueGenerated: 15.0,
          performanceDate: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentPerformanceWidget(
              content: content,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Top Performing Content'), findsOneWidget);
      expect(find.text('Test Video'), findsOneWidget);
      expect(find.text('Another Video'), findsOneWidget);
      expect(find.text('1000'), findsOneWidget);
      expect(find.text('500'), findsOneWidget);
      expect(find.text('3600s'), findsOneWidget);
      expect(find.text('1800s'), findsOneWidget);
      expect(find.text('\$25.00'), findsOneWidget);
      expect(find.text('\$15.00'), findsOneWidget);
    });

    testWidgets('should limit items when maxItems is provided', (WidgetTester tester) async {
      // Arrange
      final content = [
        ContentPerformance(
          id: '1',
          mediaId: 'media-1',
          title: 'Video 1',
          thumbnailUrl: 'https://example.com/thumb1.jpg',
          views: 1000,
          performanceDate: DateTime.now(),
        ),
        ContentPerformance(
          id: '2',
          mediaId: 'media-2',
          title: 'Video 2',
          thumbnailUrl: 'https://example.com/thumb2.jpg',
          views: 500,
          performanceDate: DateTime.now(),
        ),
        ContentPerformance(
          id: '3',
          mediaId: 'media-3',
          title: 'Video 3',
          thumbnailUrl: 'https://example.com/thumb3.jpg',
          views: 250,
          performanceDate: DateTime.now(),
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentPerformanceWidget(
              content: content,
              maxItems: 2,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Video 1'), findsOneWidget);
      expect(find.text('Video 2'), findsOneWidget);
      expect(find.text('Video 3'), findsNothing);
      expect(find.text('View All Content'), findsOneWidget);
    });

    testWidgets('should hide details when showDetails is false', (WidgetTester tester) async {
      // Arrange
      final content = [
        ContentPerformance(
          id: '1',
          mediaId: 'media-1',
          title: 'Test Video',
          thumbnailUrl: 'https://example.com/thumb1.jpg',
          views: 1000,
          watchTime: 3600.0,
          retentionRate: 0.75,
          revenueGenerated: 25.0,
          performanceDate: DateTime.now(),
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentPerformanceWidget(
              content: content,
              showDetails: false,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('3600s'), findsNothing);
      expect(find.text('\$25.00'), findsNothing);
      expect(find.text('75.0%'), findsNothing);
    });

    testWidgets('should display rank badges correctly', (WidgetTester tester) async {
      // Arrange
      final content = [
        ContentPerformance(
          id: '1',
          mediaId: 'media-1',
          title: 'First Video',
          thumbnailUrl: 'https://example.com/thumb1.jpg',
          views: 1000,
          performanceDate: DateTime.now(),
        ),
        ContentPerformance(
          id: '2',
          mediaId: 'media-2',
          title: 'Second Video',
          thumbnailUrl: 'https://example.com/thumb2.jpg',
          views: 500,
          performanceDate: DateTime.now(),
        ),
        ContentPerformance(
          id: '3',
          mediaId: 'media-3',
          title: 'Third Video',
          thumbnailUrl: 'https://example.com/thumb3.jpg',
          views: 250,
          performanceDate: DateTime.now(),
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentPerformanceWidget(
              content: content,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('should handle empty content list', (WidgetTester tester) async {
      // Arrange
      final content = <ContentPerformance>[];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentPerformanceWidget(
              content: content,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('No performance data available'), findsOneWidget);
      expect(find.text('Start creating content to see performance metrics'), findsOneWidget);
      expect(find.byIcon(Icons.bar_chart), findsOneWidget);
    });

    testWidgets('should call onItemTap when item is tapped', (WidgetTester tester) async {
      // Arrange
      final content = [
        ContentPerformance(
          id: '1',
          mediaId: 'media-1',
          title: 'Test Video',
          thumbnailUrl: 'https://example.com/thumb1.jpg',
          views: 1000,
          performanceDate: DateTime.now(),
        ),
      ];

      ContentPerformance? tappedContent;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentPerformanceWidget(
              content: content,
              onItemTap: (content) {
                tappedContent = content;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Test Video'));
      await tester.pump();

      // Assert
      expect(tappedContent, isNotNull);
      expect(tappedContent!.id, equals('1'));
      expect(tappedContent!.title, equals('Test Video'));
    });

    testWidgets('should display metric chips correctly', (WidgetTester tester) async {
      // Arrange
      final content = [
        ContentPerformance(
          id: '1',
          mediaId: 'media-1',
          title: 'Test Video',
          thumbnailUrl: 'https://example.com/thumb1.jpg',
          views: 1000,
          watchTime: 3600.0,
          revenueGenerated: 25.0,
          performanceDate: DateTime.now(),
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentPerformanceWidget(
              content: content,
              showDetails: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.timer), findsOneWidget);
      expect(find.byIcon(Icons.attach_money), findsOneWidget);
    });

    testWidgets('should format dates correctly', (WidgetTester tester) async {
      // Arrange
      final content = [
        ContentPerformance(
          id: '1',
          mediaId: 'media-1',
          title: 'Today Video',
          thumbnailUrl: 'https://example.com/thumb1.jpg',
          views: 1000,
          performanceDate: DateTime.now(),
        ),
        ContentPerformance(
          id: '2',
          mediaId: 'media-2',
          title: 'Yesterday Video',
          thumbnailUrl: 'https://example.com/thumb2.jpg',
          views: 500,
          performanceDate: DateTime.now().subtract(const Duration(days: 1)),
        ),
        ContentPerformance(
          id: '3',
          mediaId: 'media-3',
          title: '5 Days Ago Video',
          thumbnailUrl: 'https://example.com/thumb3.jpg',
          views: 250,
          performanceDate: DateTime.now().subtract(const Duration(days: 5)),
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentPerformanceWidget(
              content: content,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Yesterday'), findsOneWidget);
      expect(find.text('5 days ago'), findsOneWidget);
    });

    testWidgets('should use RepaintBoundary for performance', (WidgetTester tester) async {
      // Arrange
      final content = [
        ContentPerformance(
          id: '1',
          mediaId: 'media-1',
          title: 'Test Video',
          thumbnailUrl: 'https://example.com/thumb1.jpg',
          views: 1000,
          performanceDate: DateTime.now(),
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentPerformanceWidget(
              content: content,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(RepaintBoundary), findsOneWidget);
    });

    testWidgets('should display engagement and revenue metrics in detailed view', (WidgetTester tester) async {
      // Arrange
      final content = [
        ContentPerformance(
          id: '1',
          mediaId: 'media-1',
          title: 'Test Video',
          thumbnailUrl: 'https://example.com/thumb1.jpg',
          views: 1000,
          watchTime: 3600.0,
          retentionRate: 0.75,
          revenueGenerated: 25.0,
          performanceDate: DateTime.now(),
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentPerformanceWidget(
              content: content,
              showDetails: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Engagement'), findsOneWidget);
      expect(find.text('Revenue'), findsOneWidget);
      expect(find.text('75.0%'), findsOneWidget);
      expect(find.text('\$25.00'), findsOneWidget);
    });

    testWidgets('should handle large numbers correctly', (WidgetTester tester) async {
      // Arrange
      final content = [
        ContentPerformance(
          id: '1',
          mediaId: 'media-1',
          title: 'Popular Video',
          thumbnailUrl: 'https://example.com/thumb1.jpg',
          views: 1000000,
          watchTime: 3600000.0,
          retentionRate: 0.85,
          revenueGenerated: 2500.50,
          performanceDate: DateTime.now(),
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentPerformanceWidget(
              content: content,
              showDetails: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('1000000'), findsOneWidget);
      expect(find.text('3600000s'), findsOneWidget);
      expect(find.text('85.0%'), findsOneWidget);
      expect(find.text('\$2500.50'), findsOneWidget);
    });

    testWidgets('should display period selector when showDetails is true', (WidgetTester tester) async {
      // Arrange
      final content = [
        ContentPerformance(
          id: '1',
          mediaId: 'media-1',
          title: 'Test Video',
          thumbnailUrl: 'https://example.com/thumb1.jpg',
          views: 1000,
          performanceDate: DateTime.now(),
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentPerformanceWidget(
              content: content,
              showDetails: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(DropdownButton<AnalyticsPeriod>), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget); // Default period
    });

    testWidgets('should hide period selector when showDetails is false', (WidgetTester tester) async {
      // Arrange
      final content = [
        ContentPerformance(
          id: '1',
          mediaId: 'media-1',
          title: 'Test Video',
          thumbnailUrl: 'https://example.com/thumb1.jpg',
          views: 1000,
          performanceDate: DateTime.now(),
        ),
      ];

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ContentPerformanceWidget(
              content: content,
              showDetails: false,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(DropdownButton<AnalyticsPeriod>), findsNothing);
    });
  });
}
