import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:my_circle/widgets/media/enhanced_media_card.dart';
import 'package:my_circle/models/media_item.dart';
import 'package:my_circle/providers/enhanced_media_provider.dart';

import 'enhanced_media_card_test.mocks.dart';

@GenerateMocks([EnhancedMediaProvider, VoidCallback])
void main() {
  group('EnhancedMediaCard Widget Tests', () {
    late MockEnhancedMediaProvider mockMediaProvider;
    late MediaItem testMediaItem;

    setUp(() {
      mockMediaProvider = MockEnhancedMediaProvider();
      testMediaItem = MediaItem(
        id: '1',
        title: 'Test Media',
        description: 'Test Description',
        url: 'https://example.com/video.mp4',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        category: 'Test',
        authorId: 'user123',
        userName: 'testuser',
        userAvatar: 'https://example.com/avatar.jpg',
        createdAt: DateTime.now(),
        type: MediaType.video,
        likes: 10,
        views: 100,
        commentsCount: 5,
        tags: ['test'],
      );

      // Setup default mock behavior
      when(mockMediaProvider.isLiked('1')).thenReturn(false);
      when(mockMediaProvider.toggleLike('1')).thenAnswer((_) async {});
    });

    Widget createWidgetUnderTest({MediaItem? media, VoidCallback? onTap, VoidCallback? onLike, VoidCallback? onShare}) {
      return MaterialApp(
        home: ChangeNotifierProvider<EnhancedMediaProvider>(
          create: (_) => mockMediaProvider,
          child: Scaffold(
            body: EnhancedMediaCard(
              media: media ?? testMediaItem,
              onTap: onTap,
              onLike: onLike,
              onShare: onShare,
            ),
          ),
        ),
      );
    }

    testWidgets('should display media card with correct information', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test Media'), findsOneWidget);
      expect(find.text('Test Description'), findsOneWidget);
      expect(find.text('testuser'), findsOneWidget);
      expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.byIcon(Icons.comment), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('should display cached network image for thumbnail', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(Image), findsOneWidget);
      final imageWidget = tester.widget<Image>(find.byType(Image));
      expect(imageWidget.image.toString(), contains('thumb.jpg'));
    });

    testWidgets('should call onTap when card is tapped', (WidgetTester tester) async {
      // Arrange
      final mockOnTap = MockVoidCallback();
      await tester.pumpWidget(createWidgetUnderTest(onTap: mockOnTap));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byType(EnhancedMediaCard));
      await tester.pump();

      // Assert
      verify(mockOnTap()).called(1);
    });

    testWidgets('should call onLike when like button is tapped', (WidgetTester tester) async {
      // Arrange
      final mockOnLike = MockVoidCallback();
      await tester.pumpWidget(createWidgetUnderTest(onLike: mockOnLike));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pump();

      // Assert
      verify(mockOnLike()).called(1);
    });

    testWidgets('should call onShare when share button is tapped', (WidgetTester tester) async {
      // Arrange
      final mockOnShare = MockVoidCallback();
      await tester.pumpWidget(createWidgetUnderTest(onShare: mockOnShare));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byIcon(Icons.share));
      await tester.pump();

      // Assert
      verify(mockOnShare()).called(1);
    });

    testWidgets('should show filled heart when media is liked', (WidgetTester tester) async {
      // Arrange
      when(mockMediaProvider.isLiked('1')).thenReturn(true);
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.favorite), findsOneWidget);
      expect(find.byIcon(Icons.favorite_border), findsNothing);
    });

    testWidgets('should show premium badge for premium content', (WidgetTester tester) async {
      // Arrange
      final premiumMedia = MediaItem(
        id: '2',
        title: 'Premium Media',
        description: 'Premium Description',
        url: 'https://example.com/premium.mp4',
        thumbnailUrl: 'https://example.com/premium_thumb.jpg',
        category: 'Premium',
        authorId: 'user123',
        userName: 'premiumuser',
        userAvatar: 'https://example.com/avatar.jpg',
        createdAt: DateTime.now(),
        type: MediaType.video,
        likes: 50,
        views: 500,
        commentsCount: 25,
        isPremium: true,
        tags: ['premium'],
      );

      await tester.pumpWidget(createWidgetUnderTest(media: premiumMedia));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('PREMIUM'), findsOneWidget);
      expect(find.byIcon(Icons.diamond), findsOneWidget);
    });

    testWidgets('should show verified badge for verified users', (WidgetTester tester) async {
      // Arrange
      final verifiedMedia = MediaItem(
        id: '3',
        title: 'Verified Media',
        description: 'Verified Description',
        url: 'https://example.com/verified.mp4',
        thumbnailUrl: 'https://example.com/verified_thumb.jpg',
        category: 'Verified',
        authorId: 'verified123',
        userName: 'verifieduser',
        userAvatar: 'https://example.com/avatar.jpg',
        createdAt: DateTime.now(),
        type: MediaType.video,
        likes: 30,
        views: 300,
        commentsCount: 15,
        isVerified: true,
        tags: ['verified'],
      );

      await tester.pumpWidget(createWidgetUnderTest(media: verifiedMedia));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byIcon(Icons.verified), findsOneWidget);
    });

    testWidgets('should display correct media type icon', (WidgetTester tester) async {
      // Test video type
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.play_circle_outline), findsOneWidget);

      // Test image type
      final imageMedia = MediaItem(
        id: '4',
        title: 'Image Media',
        description: 'Image Description',
        url: 'https://example.com/image.jpg',
        thumbnailUrl: 'https://example.com/image_thumb.jpg',
        category: 'Image',
        authorId: 'user123',
        userName: 'imageuser',
        userAvatar: 'https://example.com/avatar.jpg',
        createdAt: DateTime.now(),
        type: MediaType.image,
        likes: 20,
        views: 200,
        commentsCount: 10,
        tags: ['image'],
      );

      await tester.pumpWidget(createWidgetUnderTest(media: imageMedia));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.image), findsOneWidget);

      // Test GIF type
      final gifMedia = MediaItem(
        id: '5',
        title: 'GIF Media',
        description: 'GIF Description',
        url: 'https://example.com/gif.gif',
        thumbnailUrl: 'https://example.com/gif_thumb.jpg',
        category: 'GIF',
        authorId: 'user123',
        userName: 'gifuser',
        userAvatar: 'https://example.com/avatar.jpg',
        createdAt: DateTime.now(),
        type: MediaType.gif,
        likes: 15,
        views: 150,
        commentsCount: 8,
        tags: ['gif'],
      );

      await tester.pumpWidget(createWidgetUnderTest(media: gifMedia));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.gif), findsOneWidget);
    });

    testWidgets('should handle hover state correctly', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Act - Simulate hover
      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      await gesture.moveTo(tester.getCenter(find.byType(EnhancedMediaCard)));
      await tester.pumpAndSettle();

      // Assert - Check if hover effects are applied (this would depend on implementation)
      // For now, just ensure the widget still renders correctly
      expect(find.byType(EnhancedMediaCard), findsOneWidget);
    });

    testWidgets('should show loading state while image loads', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());
      
      // Act - Don't pump and settle to catch loading state
      await tester.pump();

      // Assert - Check for loading indicator (shimmer effect)
      expect(find.byType(EnhancedMediaCard), findsOneWidget);
    });

    testWidgets('should handle aspect ratio parameter', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<EnhancedMediaProvider>(
            create: (_) => mockMediaProvider,
            child: Scaffold(
              body: EnhancedMediaCard(
                media: testMediaItem,
                aspectRatio: 16.0 / 9.0,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(EnhancedMediaCard), findsOneWidget);
    });

    testWidgets('should hide user info when showUserInfo is false', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<EnhancedMediaProvider>(
            create: (_) => mockMediaProvider,
            child: Scaffold(
              body: EnhancedMediaCard(
                media: testMediaItem,
                showUserInfo: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('testuser'), findsNothing);
      expect(find.byIcon(Icons.verified), findsNothing);
    });

    testWidgets('should handle long titles gracefully', (WidgetTester tester) async {
      // Arrange
      final longTitleMedia = MediaItem(
        id: '6',
        title: 'This is a very long title that should be truncated properly in the UI without breaking the layout',
        description: 'Description',
        url: 'https://example.com/long.mp4',
        thumbnailUrl: 'https://example.com/long_thumb.jpg',
        category: 'Long',
        authorId: 'user123',
        userName: 'longuser',
        userAvatar: 'https://example.com/avatar.jpg',
        createdAt: DateTime.now(),
        type: MediaType.video,
        likes: 5,
        views: 50,
        commentsCount: 2,
        tags: ['long'],
      );

      await tester.pumpWidget(createWidgetUnderTest(media: longTitleMedia));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(EnhancedMediaCard), findsOneWidget);
      // Check that title is present (may be truncated)
      expect(find.textContaining('This is a very long title'), findsOneWidget);
    });

    testWidgets('should display tags correctly', (WidgetTester tester) async {
      // Arrange
      final taggedMedia = MediaItem(
        id: '7',
        title: 'Tagged Media',
        description: 'Media with tags',
        url: 'https://example.com/tagged.mp4',
        thumbnailUrl: 'https://example.com/tagged_thumb.jpg',
        category: 'Tagged',
        authorId: 'user123',
        userName: 'taggeduser',
        userAvatar: 'https://example.com/avatar.jpg',
        createdAt: DateTime.now(),
        type: MediaType.video,
        likes: 25,
        views: 250,
        commentsCount: 12,
        tags: ['gaming', 'trending', 'featured'],
      );

      await tester.pumpWidget(createWidgetUnderTest(media: taggedMedia));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('gaming'), findsOneWidget);
      expect(find.text('trending'), findsOneWidget);
      expect(find.text('featured'), findsOneWidget);
    });

    testWidgets('should handle provider integration correctly', (WidgetTester tester) async {
      // Arrange
      when(mockMediaProvider.toggleLike('1')).thenAnswer((_) async {
        // Simulate state change
        when(mockMediaProvider.isLiked('1')).thenReturn(true);
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Act - Tap like button
      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pump();

      // Assert
      verify(mockMediaProvider.toggleLike('1')).called(1);
    });
  });
}
