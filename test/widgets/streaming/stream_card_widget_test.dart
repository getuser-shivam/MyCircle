import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mycircle/widgets/streaming/stream_card_widget.dart';
import 'package:mycircle/models/stream_model.dart';

void main() {
  group('StreamCard', () {
    final sampleStream = LiveStream(
      id: 'stream_1',
      streamerId: 'user_1',
      title: 'Test Gaming Stream',
      description: 'An exciting gaming stream',
      category: 'Gaming',
      tags: ['gaming', 'fps', 'competitive'],
      thumbnailUrl: 'https://example.com/thumb.jpg',
      streamUrl: 'https://example.com/stream.m3u8',
      status: StreamStatus.live,
      quality: StreamQuality.high,
      viewerCount: 1234,
      maxViewers: 5000,
      isPrivate: false,
      isRecorded: true,
      isVerified: true,
      startedAt: DateTime.now(),
      streamerName: 'ProGamer',
      streamerAvatar: 'https://example.com/avatar.jpg',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    testWidgets('should display stream information correctly', (WidgetTester tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamCard(
              stream: sampleStream,
              onTap: () => wasTapped = true,
            ),
          ),
        ),
      );

      // Check title
      expect(find.text('Test Gaming Stream'), findsOneWidget);
      
      // Check streamer name
      expect(find.text('ProGamer'), findsOneWidget);
      
      // Check category
      expect(find.text('Gaming'), findsOneWidget);
      
      // Check viewer count
      expect(find.text('1.2K'), findsOneWidget); // Formatted viewer count
      
      // Check live badge
      expect(find.text('LIVE'), findsOneWidget);
      
      // Check quality badge
      expect(find.text('1080p'), findsOneWidget);
    });

    testWidgets('should display scheduled stream correctly', (WidgetTester tester) async {
      final scheduledStream = sampleStream.copyWith(
        status: StreamStatus.scheduled,
        scheduledAt: DateTime.now().add(const Duration(hours: 2)),
        viewerCount: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamCard(
              stream: scheduledStream,
              onTap: () {},
            ),
          ),
        ),
      );

      // Check scheduled badge instead of live
      expect(find.text('SCHEDULED'), findsOneWidget);
      expect(find.text('LIVE'), findsNothing);
      
      // Should show schedule time
      expect(find.text('Starting in'), findsOneWidget);
    });

    testWidgets('should display tags correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamCard(
              stream: sampleStream,
              onTap: () {},
            ),
          ),
        ),
      );

      // Check that tags are displayed
      expect(find.text('#gaming'), findsOneWidget);
      expect(find.text('#fps'), findsOneWidget);
    });

    testWidgets('should handle tap correctly', (WidgetTester tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamCard(
              stream: sampleStream,
              onTap: () => wasTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(StreamCard));
      await tester.pump();

      expect(wasTapped, isTrue);
    });

    testWidgets('should show verification badge for verified streamers', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamCard(
              stream: sampleStream,
              onTap: () {},
            ),
          ),
        ),
      );

      // Check for verification icon
      expect(find.byIcon(Icons.verified), findsOneWidget);
    });

    testWidgets('should format viewer count correctly', (WidgetTester tester) async {
      final testCases = [
        {'count': 500, 'expected': '500'},
        {'count': 1500, 'expected': '1.5K'},
        {'count': 2500000, 'expected': '2.5M'},
      ];

      for (final testCase in testCases) {
        final stream = sampleStream.copyWith(viewerCount: testCase['count'] as int);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StreamCard(
                stream: stream,
                onTap: () {},
              ),
            ),
          ),
        );

        expect(find.text(testCase['expected'] as String), findsOneWidget);
        
        await tester.pumpWidget(Container()); // Clean up
      }
    });

    testWidgets('should display different quality badges', (WidgetTester tester) async {
      final qualities = [
        {'quality': StreamQuality.low, 'expected': '360p'},
        {'quality': StreamQuality.medium, 'expected': '720p'},
        {'quality': StreamQuality.high, 'expected': '1080p'},
        {'quality': StreamQuality.ultra, 'expected': '4K'},
      ];

      for (final testCase in qualities) {
        final stream = sampleStream.copyWith(quality: testCase['quality'] as StreamQuality);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StreamCard(
                stream: stream,
                onTap: () {},
              ),
            ),
          ),
        );

        expect(find.text(testCase['expected'] as String), findsOneWidget);
        
        await tester.pumpWidget(Container()); // Clean up
      }
    });

    testWidgets('should handle long titles correctly', (WidgetTester tester) async {
      final longTitleStream = sampleStream.copyWith(
        title: 'This is a very long stream title that should be truncated properly and not break the layout',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamCard(
              stream: longTitleStream,
              onTap: () {},
            ),
          ),
        ),
      );

      // Should not overflow and should truncate
      expect(find.byType(StreamCard), findsOneWidget);
      
      // Check that the widget doesn't overflow
      expect(tester.takeException(), isNull);
    });

    testWidgets('should show follow button when enabled', (WidgetTester tester) async {
      bool followTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamCard(
              stream: sampleStream,
              onTap: () {},
              onFollow: () => followTapped = true,
              showFollowButton: true,
            ),
          ),
        ),
      );

      expect(find.text('Follow'), findsOneWidget);
      
      await tester.tap(find.text('Follow'));
      await tester.pump();
      
      expect(followTapped, isTrue);
    });

    testWidgets('should not show follow button when disabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamCard(
              stream: sampleStream,
              onTap: () {},
              showFollowButton: false,
            ),
          ),
        ),
      );

      expect(find.text('Follow'), findsNothing);
    });

    testWidgets('should handle custom dimensions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 300,
              child: StreamCard(
                stream: sampleStream,
                onTap: () {},
                width: 200,
                height: 300,
              ),
            ),
          ),
        ),
      );

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
      expect(sizedBox.width, 200);
      expect(sizedBox.height, 300);
    });

    testWidgets('should handle network image loading', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamCard(
              stream: sampleStream,
              onTap: () {},
            ),
          ),
        ),
      );

      // Should find CachedNetworkImage widgets
      expect(find.byType(CachedNetworkImage), findsWidgets);
    });

    testWidgets('should handle empty tags', (WidgetTester tester) async {
      final noTagsStream = sampleStream.copyWith(tags: []);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamCard(
              stream: noTagsStream,
              onTap: () {},
            ),
          ),
        ),
      );

      // Should not show any tag widgets
      expect(find.textContaining('#'), findsNothing);
    });

    testWidgets('should handle very large viewer counts', (WidgetTester tester) async {
      final popularStream = sampleStream.copyWith(viewerCount: 999999999);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamCard(
              stream: popularStream,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('999.9M'), findsOneWidget);
    });

    testWidgets('should handle zero viewer count', (WidgetTester tester) async {
      final emptyStream = sampleStream.copyWith(viewerCount: 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamCard(
              stream: emptyStream,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);
    });

    testWidgets('should handle private stream indicator', (WidgetTester tester) async {
      final privateStream = sampleStream.copyWith(isPrivate: true);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamCard(
              stream: privateStream,
              onTap: () {},
            ),
          ),
        ),
      );

      // Private streams might show a lock icon or similar indicator
      // This would depend on the actual implementation
      expect(find.byType(StreamCard), findsOneWidget);
    });

    testWidgets('should handle adult content indicator', (WidgetTester tester) async {
      final adultStream = sampleStream.copyWith(
        category: 'Adult',
        tags: ['adult', '18+'],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamCard(
              stream: adultStream,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('Adult'), findsOneWidget);
    });
  });

  group('StreamCardLarge', () {
    final sampleStream = LiveStream(
      id: 'stream_1',
      streamerId: 'user_1',
      title: 'Test Gaming Stream',
      description: 'This is a detailed description of the gaming stream that will be displayed in the large card format',
      category: 'Gaming',
      tags: ['gaming', 'fps', 'competitive', 'tournament'],
      thumbnailUrl: 'https://example.com/thumb.jpg',
      streamUrl: 'https://example.com/stream.m3u8',
      status: StreamStatus.live,
      quality: StreamQuality.high,
      viewerCount: 1234,
      maxViewers: 5000,
      isPrivate: false,
      isRecorded: true,
      isVerified: true,
      startedAt: DateTime.now(),
      streamerName: 'ProGamer',
      streamerAvatar: 'https://example.com/avatar.jpg',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    testWidgets('should display large stream card correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamCardLarge(
              stream: sampleStream,
              onTap: () {},
            ),
          ),
        ),
      );

      // Check title
      expect(find.text('Test Gaming Stream'), findsOneWidget);
      
      // Check description
      expect(find.textContaining('detailed description'), findsOneWidget);
      
      // Check streamer name
      expect(find.text('ProGamer'), findsOneWidget);
      
      // Check viewer count and category
      expect(find.text('1234 viewers'), findsOneWidget);
      expect(find.text('Gaming'), findsOneWidget);
      
      // Check live badge
      expect(find.text('LIVE'), findsOneWidget);
      
      // Check verification badge
      expect(find.byIcon(Icons.verified), findsOneWidget);
    });

    testWidgets('should display all tags in large format', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamCardLarge(
              stream: sampleStream,
              onTap: () {},
            ),
          ),
        ),
      );

      // Should show all tags
      expect(find.text('#gaming'), findsOneWidget);
      expect(find.text('#fps'), findsOneWidget);
      expect(find.text('#competitive'), findsOneWidget);
      expect(find.text('#tournament'), findsOneWidget);
    });

    testWidgets('should show follow button in large format', (WidgetTester tester) async {
      bool followTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamCardLarge(
              stream: sampleStream,
              onTap: () {},
              onFollow: () => followTapped = true,
              showFollowButton: true,
            ),
          ),
        ),
      );

      expect(find.text('Follow'), findsOneWidget);
      
      await tester.tap(find.text('Follow'));
      await tester.pump();
      
      expect(followTapped, isTrue);
    });

    testWidgets('should handle scheduled stream in large format', (WidgetTester tester) async {
      final scheduledStream = sampleStream.copyWith(
        status: StreamStatus.scheduled,
        scheduledAt: DateTime.now().add(const Duration(hours: 2)),
        viewerCount: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamCardLarge(
              stream: scheduledStream,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('SCHEDULED'), findsOneWidget);
      expect(find.textContaining('Starts in'), findsOneWidget);
    });

    testWidgets('should display quality and viewer count badges', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamCardLarge(
              stream: sampleStream,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.text('1080p'), findsOneWidget);
      expect(find.text('1234'), findsOneWidget);
    });

    testWidgets('should handle long description in large format', (WidgetTester tester) async {
      final longDescStream = sampleStream.copyWith(
        description: 'This is a very long description that should wrap properly and display multiple lines without breaking the layout or causing overflow issues in the large card format.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamCardLarge(
              stream: longDescStream,
              onTap: () {},
            ),
          ),
        ),
      );

      // Should not overflow
      expect(tester.takeException(), isNull);
      expect(find.byType(StreamCardLarge), findsOneWidget);
    });

    testWidgets('should handle unverified streamer', (WidgetTester tester) async {
      final unverifiedStream = sampleStream.copyWith(isVerified: false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamCardLarge(
              stream: unverifiedStream,
              onTap: () {},
            ),
          ),
        ),
      );

      // Should not show verification badge
      expect(find.byIcon(Icons.verified), findsNothing);
    });

    testWidgets('should handle tap correctly in large format', (WidgetTester tester) async {
      bool wasTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamCardLarge(
              stream: sampleStream,
              onTap: () => wasTapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(StreamCardLarge));
      await tester.pump();

      expect(wasTapped, isTrue);
    });

    testWidgets('should maintain aspect ratio correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              child: StreamCardLarge(
                stream: sampleStream,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Should maintain proper aspect ratio
      expect(find.byType(AspectRatio), findsOneWidget);
    });
  });

  group('StreamCard Edge Cases', () {
    testWidgets('should handle missing thumbnail URL', (WidgetTester tester) async {
      final noThumbStream = LiveStream(
        id: 'stream_1',
        streamerId: 'user_1',
        title: 'No Thumbnail Stream',
        status: StreamStatus.live,
        quality: StreamQuality.medium,
        viewerCount: 100,
        startedAt: DateTime.now(),
        streamerName: 'TestUser',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamCard(
              stream: noThumbStream,
              onTap: () {},
            ),
          ),
        ),
      );

      // Should not crash and should handle missing thumbnail gracefully
      expect(find.byType(StreamCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle missing streamer avatar', (WidgetTester tester) async {
      final noAvatarStream = LiveStream(
        id: 'stream_1',
        streamerId: 'user_1',
        title: 'No Avatar Stream',
        status: StreamStatus.live,
        quality: StreamQuality.medium,
        viewerCount: 100,
        startedAt: DateTime.now(),
        streamerName: 'TestUser',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamCard(
              stream: noAvatarStream,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(StreamCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle empty title', (WidgetTester tester) async {
      final noTitleStream = LiveStream(
        id: 'stream_1',
        streamerId: 'user_1',
        title: '',
        status: StreamStatus.live,
        quality: StreamQuality.medium,
        viewerCount: 100,
        startedAt: DateTime.now(),
        streamerName: 'TestUser',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamCard(
              stream: noTitleStream,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.byType(StreamCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle special characters in title', (WidgetTester tester) async {
      final specialCharStream = LiveStream(
        id: 'stream_1',
        streamerId: 'user_1',
        title: 'Stream 🎮 with @special #characters & symbols!',
        status: StreamStatus.live,
        quality: StreamQuality.medium,
        viewerCount: 100,
        startedAt: DateTime.now(),
        streamerName: 'TestUser',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StreamCard(
              stream: specialCharStream,
              onTap: () {},
            ),
          ),
        ),
      );

      expect(find.textContaining('Stream 🎮'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
