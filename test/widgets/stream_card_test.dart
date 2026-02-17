import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:my_circle\widgets\streaming\stream_card_widget.dart';
import 'package:my_circle\models\stream_model.dart';

@GenerateMocks([VoidCallback])
import 'stream_card_test.mocks.dart';

void main() {
  group('StreamCard Widget Tests', () {
    late LiveStream testStream;
    late MockVoidCallback mockOnTap;
    late MockVoidCallback mockOnFollow;

    setUp(() {
      mockOnTap = MockVoidCallback();
      mockOnFollow = MockVoidCallback();
      
      testStream = LiveStream(
        id: '1',
        title: 'Test Stream',
        description: 'This is a test stream',
        thumbnailUrl: 'https://example.com/thumbnail.jpg',
        viewerCount: 150,
        isLive: true,
        streamerId: 'streamer_1',
        streamerName: 'Test Streamer',
        category: 'Gaming',
        tags: ['gaming', 'test'],
        startedAt: DateTime.now(),
      );
    });

    Widget createWidgetUnderTest({
      LiveStream? stream,
      VoidCallback? onTap,
      VoidCallback? onFollow,
      bool showFollowButton = false,
      double? width,
      double? height,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: StreamCard(
            stream: stream ?? testStream,
            onTap: onTap ?? mockOnTap.call,
            onFollow: onFollow ?? mockOnFollow.call,
            showFollowButton: showFollowButton,
            width: width,
            height: height,
          ),
        ),
      );
    }

    testWidgets('should display stream title and description', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Test Stream'), findsOneWidget);
      expect(find.text('This is a test stream'), findsOneWidget);
    });

    testWidgets('should display streamer name', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Test Streamer'), findsOneWidget);
    });

    testWidgets('should display viewer count', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('150'), findsOneWidget);
    });

    testWidgets('should display live indicator when stream is live', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('LIVE'), findsOneWidget);
    });

    testWidgets('should not display live indicator when stream is offline', (WidgetTester tester) async {
      final offlineStream = LiveStream(
        id: '2',
        title: 'Offline Stream',
        description: 'This stream is offline',
        thumbnailUrl: 'https://example.com/thumbnail.jpg',
        viewerCount: 0,
        isLive: false,
        streamerId: 'streamer_2',
        streamerName: 'Offline Streamer',
        category: 'Gaming',
        tags: ['gaming'],
        startedAt: DateTime.now(),
      );

      await tester.pumpWidget(createWidgetUnderTest(stream: offlineStream));

      expect(find.text('LIVE'), findsNothing);
    });

    testWidgets('should display category', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Gaming'), findsOneWidget);
    });

    testWidgets('should display follow button when showFollowButton is true', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(showFollowButton: true));

      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('Follow'), findsOneWidget);
    });

    testWidgets('should not display follow button when showFollowButton is false', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(showFollowButton: false));

      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.text('Follow'), findsNothing);
    });

    testWidgets('should call onTap when card is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      await tester.tap(find.byType(Card));
      await tester.pump();

      verify(mockOnTap.call()).called(1);
    });

    testWidgets('should call onFollow when follow button is tapped', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(showFollowButton: true));

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      verify(mockOnFollow.call()).called(1);
    });

    testWidgets('should display thumbnail image', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets('should handle missing thumbnail gracefully', (WidgetTester tester) async {
      final streamWithoutThumbnail = LiveStream(
        id: '3',
        title: 'No Thumbnail Stream',
        description: 'Stream without thumbnail',
        thumbnailUrl: null,
        viewerCount: 50,
        isLive: true,
        streamerId: 'streamer_3',
        streamerName: 'No Thumbnail Streamer',
        category: 'Music',
        tags: ['music'],
        startedAt: DateTime.now(),
      );

      await tester.pumpWidget(createWidgetUnderTest(stream: streamWithoutThumbnail));

      // Should display placeholder instead of CachedNetworkImage
      expect(find.byType(CachedNetworkImage), findsNothing);
      expect(find.byIcon(Icons.image), findsOneWidget);
    });

    testWidgets('should apply custom width and height', (WidgetTester tester) async {
      const customWidth = 300.0;
      const customHeight = 200.0;

      await tester.pumpWidget(createWidgetUnderTest(
        width: customWidth,
        height: customHeight,
      ));

      final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox));
      expect(sizedBox.width, customWidth);
      expect(sizedBox.height, customHeight);
    });

    testWidgets('should display tags', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('gaming'), findsOneWidget);
      expect(find.text('test'), findsOneWidget);
    });

    testWidgets('should have correct card properties', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.clipBehavior, Clip.antiAlias);
      expect(card.elevation, 4.0);
    });

    testWidgets('should wrap content in InkWell for tap feedback', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('should display viewer count with proper formatting', (WidgetTester tester) async {
      final highViewerStream = LiveStream(
        id: '4',
        title: 'Popular Stream',
        description: 'Very popular stream',
        thumbnailUrl: 'https://example.com/thumbnail.jpg',
        viewerCount: 1500,
        isLive: true,
        streamerId: 'streamer_4',
        streamerName: 'Popular Streamer',
        category: 'Gaming',
        tags: ['gaming', 'popular'],
        startedAt: DateTime.now(),
      );

      await tester.pumpWidget(createWidgetUnderTest(stream: highViewerStream));

      expect(find.text('1.5K'), findsOneWidget); // Should format large numbers
    });

    testWidgets('should handle empty tags list', (WidgetTester tester) async {
      final streamWithoutTags = LiveStream(
        id: '5',
        title: 'No Tags Stream',
        description: 'Stream without tags',
        thumbnailUrl: 'https://example.com/thumbnail.jpg',
        viewerCount: 25,
        isLive: true,
        streamerId: 'streamer_5',
        streamerName: 'No Tags Streamer',
        category: 'Just Chatting',
        tags: [],
        startedAt: DateTime.now(),
      );

      await tester.pumpWidget(createWidgetUnderTest(stream: streamWithoutTags));

      // Should not display any tag chips
      expect(find.byType(Chip), findsNothing);
    });

    testWidgets('should handle long titles gracefully', (WidgetTester tester) async {
      final longTitleStream = LiveStream(
        id: '6',
        title: 'This is a very long stream title that should be truncated because it exceeds the available space in the stream card widget',
        description: 'Stream with long title',
        thumbnailUrl: 'https://example.com/thumbnail.jpg',
        viewerCount: 100,
        isLive: true,
        streamerId: 'streamer_6',
        streamerName: 'Long Title Streamer',
        category: 'Gaming',
        tags: ['gaming'],
        startedAt: DateTime.now(),
      );

      await tester.pumpWidget(createWidgetUnderTest(stream: longTitleStream));

      final titleText = tester.widget<Text>(find.textContaining('This is a very long stream title'));
      expect(titleText.maxLines, 1);
      expect(titleText.overflow, TextOverflow.ellipsis);
    });

    testWidgets('should handle null onFollow gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        showFollowButton: true,
        onFollow: null,
      ));

      expect(find.byType(ElevatedButton), findsOneWidget);
      
      // Tapping should not throw an exception
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
    });

    testWidgets('should display live indicator with correct styling', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final liveText = tester.widget<Text>(find.text('LIVE'));
      expect(liveText.style?.color, Colors.red);
      expect(liveText.style?.fontWeight, FontWeight.bold);
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

    testWidgets('should handle rapid follow interactions', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(showFollowButton: true));

      // Rapid follow taps
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byType(ElevatedButton));
        await tester.pump();
      }

      verify(mockOnFollow.call()).called(3);
    });

    testWidgets('should display viewer count icon', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });

    testWidgets('should display category chip', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(Chip), findsAtLeastNWidgets(1)); // At least category chip
      
      final categoryChip = tester.widget<Chip>(find.byType(Chip).first);
      expect(categoryChip.label, isA<Text>());
      final labelText = categoryChip.label as Text;
      expect(labelText.data, 'Gaming');
    });
  });
}
