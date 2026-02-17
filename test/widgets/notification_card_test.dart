import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';

import 'package:my_circle\widgets\notifications\notification_card.dart';
import 'package:my_circle\providers\notification_provider.dart';

import '../providers/notification_provider_test.dart';

@GenerateMocks([VoidCallback])
import 'notification_card_test.mocks.dart';

void main() {
  group('NotificationCard Widget Tests', () {
    late AppNotification testNotification;
    late MockVoidCallback mockOnTap;
    late MockVoidCallback mockOnDismiss;

    setUp(() {
      mockOnTap = MockVoidCallback();
      mockOnDismiss = MockVoidCallback();
      
      testNotification = const AppNotification(
        id: '1',
        title: 'Test Notification',
        body: 'This is a test notification body',
        type: 'info',
        timestamp: null,
        isRead: false,
      );
    });

    Widget createWidgetUnderTest({AppNotification? notification}) {
      return MaterialApp(
        home: Scaffold(
          body: NotificationCard(
            notification: notification ?? testNotification,
            onTap: mockOnTap.call,
            onDismiss: mockOnDismiss.call,
          ),
        ),
      );
    }

    testWidgets('should display notification title and body', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Test Notification'), findsOneWidget);
      expect(find.text('This is a test notification body'), findsOneWidget);
    });

    testWidgets('should display icon based on notification type', (WidgetTester tester) async {
      final likeNotification = const AppNotification(
        id: '2',
        title: 'Like Notification',
        body: 'Someone liked your content',
        type: 'like',
        timestamp: null,
      );

      await tester.pumpWidget(createWidgetUnderTest(notification: likeNotification));

      expect(find.byIcon(Icons.favorite), findsOneWidget);
    });

    testWidgets('should display comment icon for comment type', (WidgetTester tester) async {
      final commentNotification = const AppNotification(
        id: '3',
        title: 'Comment Notification',
        body: 'Someone commented on your content',
        type: 'comment',
        timestamp: null,
      );

      await tester.pumpWidget(createWidgetUnderTest(notification: commentNotification));

      expect(find.byIcon(Icons.comment), findsOneWidget);
    });

    testWidgets('should display follow icon for follow type', (WidgetTester tester) async {
      final followNotification = const AppNotification(
        id: '4',
        title: 'Follow Notification',
        body: 'Someone followed you',
        type: 'follow',
        timestamp: null,
      );

      await tester.pumpWidget(createWidgetUnderTest(notification: followNotification));

      expect(find.byIcon(Icons.person_add), findsOneWidget);
    });

    testWidgets('should display info icon for unknown type', (WidgetTester tester) async {
      final unknownNotification = const AppNotification(
        id: '5',
        title: 'Unknown Notification',
        body: 'Unknown notification type',
        type: 'unknown',
        timestamp: null,
      );

      await tester.pumpWidget(createWidgetUnderTest(notification: unknownNotification));

      expect(find.byIcon(Icons.info), findsOneWidget);
    });

    testWidgets('should apply bold font weight for unread notifications', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final titleText = tester.widget<Text>(find.text('Test Notification'));
      expect(titleText.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('should apply normal font weight for read notifications', (WidgetTester tester) async {
      final readNotification = const AppNotification(
        id: '6',
        title: 'Read Notification',
        body: 'This notification is read',
        type: 'info',
        timestamp: null,
        isRead: true,
      );

      await tester.pumpWidget(createWidgetUnderTest(notification: readNotification));

      final titleText = tester.widget<Text>(find.text('Read Notification'));
      expect(titleText.style?.fontWeight, FontWeight.normal);
    });

    testWidgets('should display dismiss button', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.close), findsOneWidget);
    });

    testWidgets('should call onTap when card is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.byType(Card));
      await tester.pump();

      verify(mockOnTap.call()).called(1);
    });

    testWidgets('should call onDismiss when dismiss button is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();

      verify(mockOnDismiss.call()).called(1);
    });

    testWidgets('should truncate long body text', (WidgetTester tester) async {
      final longNotification = const AppNotification(
        id: '7',
        title: 'Long Notification',
        body: 'This is a very long notification body that should be truncated because it exceeds the maximum number of lines allowed for the subtitle text widget in the notification card',
        type: 'info',
        timestamp: null,
      );

      await tester.pumpWidget(createWidgetUnderTest(notification: longNotification));

      final subtitleText = tester.widget<Text>(find.byType(Text).last);
      expect(subtitleText.maxLines, 2);
      expect(subtitleText.overflow, TextOverflow.ellipsis);
    });

    testWidgets('should have correct margin and elevation', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.margin, const EdgeInsets.symmetric(horizontal: 16, vertical: 4));
      expect(card.elevation, 1.0); // Default Card elevation
    });

    testWidgets('should handle empty notification body gracefully', (WidgetTester tester) async {
      final emptyNotification = const AppNotification(
        id: '8',
        title: 'Empty Body Notification',
        body: '',
        type: 'info',
        timestamp: null,
      );

      await tester.pumpWidget(createWidgetUnderTest(notification: emptyNotification));

      expect(find.text('Empty Body Notification'), findsOneWidget);
      expect(find.text(''), findsOneWidget); // Empty body text
    });

    testWidgets('should have correct colors for different notification types', (WidgetTester tester) async {
      final testCases = [
        {'type': 'like', 'color': Colors.red},
        {'type': 'comment', 'color': Colors.blue},
        {'type': 'follow', 'color': Colors.green},
        {'type': 'info', 'color': Colors.grey},
      ];

      for (final testCase in testCases) {
        final notification = AppNotification(
          id: testCase['type'].toString(),
          title: '${testCase['type']} Notification',
          body: 'Test body',
          type: testCase['type'].toString(),
          timestamp: null,
        );

        await tester.pumpWidget(createWidgetUnderTest(notification: notification));
        
        final icon = tester.widget<Icon>(find.byType(Icon));
        expect(icon.color, testCase['color']);
        
        await tester.pumpWidget(Container()); // Reset for next iteration
      }
    });

    testWidgets('should be wrapped in InkWell for tap feedback', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('should handle null timestamp gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(NotificationCard), findsOneWidget);
      // Should not throw any exceptions
    });

    testWidgets('should work with Provider context', (WidgetTester tester) async {
      final notificationProvider = NotificationProvider();
      
      await tester.pumpWidget(
        ChangeNotifierProvider<NotificationProvider>(
          create: (_) => notificationProvider,
          child: MaterialApp(
            home: Scaffold(
              body: NotificationCard(
                notification: testNotification,
                onTap: mockOnTap.call,
                onDismiss: mockOnDismiss.call,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(NotificationCard), findsOneWidget);
      expect(find.text('Test Notification'), findsOneWidget);
    });

    testWidgets('should handle rapid tap interactions', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Rapid taps
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byType(Card));
        await tester.pump();
      }

      verify(mockOnTap.call()).called(5);
    });

    testWidgets('should handle rapid dismiss interactions', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Rapid dismiss taps
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byIcon(Icons.close));
        await tester.pump();
      }

      verify(mockOnDismiss.call()).called(3);
    });
  });
}
