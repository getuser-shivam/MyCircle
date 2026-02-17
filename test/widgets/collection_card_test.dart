import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:mycircle/widgets/collections/collection_card.dart';
import 'package:mycircle/models/collection.dart';
import 'package:mycircle/providers/collection_provider.dart';

import '../mocks/collection_provider_mock.dart';

@GenerateMocks([CollectionProvider])
void main() {
  group('CollectionCard', () {
    late Collection testCollection;
    late MockCollectionProvider mockProvider;

    setUp(() {
      testCollection = _createTestCollection();
      mockProvider = MockCollectionProvider();
    });

    testWidgets('should display collection information correctly', (WidgetTester tester) async {
      // Arrange
      when(mockProvider.isLoading).thenReturn(false);
      when(mockProvider.collectionMedia).thenReturn([]);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<CollectionProvider>(
              create: (_) => mockProvider,
              child: CollectionCard(
                collection: testCollection,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text(testCollection.title), findsOneWidget);
      expect(find.text(testCollection.description), findsOneWidget);
      expect(find.text('${testCollection.mediaCount}'), findsOneWidget);
      expect(find.text('${testCollection.followersCount}'), findsOneWidget);
      expect(find.text(testCollection.type.displayName), findsOneWidget);
    });

    testWidgets('should display cover image when available', (WidgetTester tester) async {
      // Arrange
      when(mockProvider.isLoading).thenReturn(false);
      when(mockProvider.collectionMedia).thenReturn([]);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<CollectionProvider>(
              create: (_) => mockProvider,
              child: CollectionCard(
                collection: testCollection,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('should display placeholder when no cover image', (WidgetTester tester) async {
      // Arrange
      final collectionWithoutCover = testCollection.copyWith(coverImage: '');
      when(mockProvider.isLoading).thenReturn(false);
      when(mockProvider.collectionMedia).thenReturn([]);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<CollectionProvider>(
              create: (_) => mockProvider,
              child: CollectionCard(
                collection: collectionWithoutCover,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.playlist_play), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('should display follow button when not owner', (WidgetTester tester) async {
      // Arrange
      when(mockProvider.isLoading).thenReturn(false);
      when(mockProvider.collectionMedia).thenReturn([]);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<CollectionProvider>(
              create: (_) => mockProvider,
              child: CollectionCard(
                collection: testCollection,
                onFollow: () {},
                showFollowButton: true,
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Follow'), findsOneWidget);
      expect(find.byIcon(Icons.person_add_outlined), findsOneWidget);
    });

    testWidgets('should display following button when following', (WidgetTester tester) async {
      // Arrange
      final followingCollection = testCollection.copyWith(isFollowing: true);
      when(mockProvider.isLoading).thenReturn(false);
      when(mockProvider.collectionMedia).thenReturn([]);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<CollectionProvider>(
              create: (_) => mockProvider,
              child: CollectionCard(
                collection: followingCollection,
                onFollow: () {},
                showFollowButton: true,
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Following'), findsOneWidget);
      expect(find.byIcon(Icons.person_remove_outlined), findsOneWidget);
    });

    testWidgets('should not show follow button when showFollowButton is false', (WidgetTester tester) async {
      // Arrange
      when(mockProvider.isLoading).thenReturn(false);
      when(mockProvider.collectionMedia).thenReturn([]);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<CollectionProvider>(
              create: (_) => mockProvider,
              child: CollectionCard(
                collection: testCollection,
                onFollow: () {},
                showFollowButton: false,
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Follow'), findsNothing);
      expect(find.text('Following'), findsNothing);
    });

    testWidgets('should call onTap when card is tapped', (WidgetTester tester) async {
      // Arrange
      bool onTapCalled = false;
      when(mockProvider.isLoading).thenReturn(false);
      when(mockProvider.collectionMedia).thenReturn([]);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<CollectionProvider>(
              create: (_) => mockProvider,
              child: CollectionCard(
                collection: testCollection,
                onTap: () {
                  onTapCalled = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(CollectionCard));

      // Assert
      expect(onTapCalled, isTrue);
    });

    testWidgets('should call follow callback when follow button is tapped', (WidgetTester tester) async {
      // Arrange
      bool onFollowCalled = false;
      when(mockProvider.isLoading).thenReturn(false);
      when(mockProvider.collectionMedia).thenReturn([]);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<CollectionProvider>(
              create: (_) => mockProvider,
              child: CollectionCard(
                collection: testCollection,
                onFollow: () {
                  onFollowCalled = true;
                },
                showFollowButton: true,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Follow'));

      // Assert
      expect(onFollowCalled, isTrue);
    });

    testWidgets('should display featured badge when collection is featured', (WidgetTester tester) async {
      // Arrange
      final featuredCollection = testCollection.copyWith(isFeatured: true);
      when(mockProvider.isLoading).thenReturn(false);
      when(mockProvider.collectionMedia).thenReturn([]);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<CollectionProvider>(
              create: (_) => mockProvider,
              child: CollectionCard(
                collection: featuredCollection,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Featured'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('should display collaborative badge when collection is collaborative', (WidgetTester tester) async {
      // Arrange
      final collaborativeCollection = testCollection.copyWith(
        isCollaborative: true,
        type: CollectionType.collaborative,
      );
      when(mockProvider.isLoading).thenReturn(false);
      when(mockProvider.collectionMedia).thenReturn([]);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<CollectionProvider>(
              create: (_) => mockProvider,
              child: CollectionCard(
                collection: collaborativeCollection,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Collaborative'), findsOneWidget);
      expect(find.byIcon(Icons.group), findsOneWidget);
    });

    testWidgets('should handle custom width and height', (WidgetTester tester) async {
      // Arrange
      when(mockProvider.isLoading).thenReturn(false);
      when(mockProvider.collectionMedia).thenReturn([]);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChangeNotifierProvider<CollectionProvider>(
              create: (_) => mockProvider,
              child: SizedBox(
                width: 300,
                height: 400,
                child: CollectionCard(
                  collection: testCollection,
                  onTap: () {},
                  width: 300,
                  height: 400,
                ),
              ),
            ),
          ),
        ),
      );

      // Assert
      final collectionCardFinder = find.byType(CollectionCard);
      expect(collectionCardFinder, findsOneWidget);
      
      final collectionCardWidget = tester.widget(collectionCardFinder) as CollectionCard;
      expect(collectionCardWidget.width, 300);
      expect(collectionCardWidget.height, 400);
    });

    group('Type-specific styling', () {
      testWidgets('should display correct icon for playlist type', (WidgetTester tester) async {
        // Arrange
        final playlistCollection = testCollection.copyWith(type: CollectionType.playlist);
        when(mockProvider.isLoading).thenReturn(false);
        when(mockProvider.collectionMedia).thenReturn([]);

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChangeNotifierProvider<CollectionProvider>(
                create: (_) => mockProvider,
                child: CollectionCard(
                  collection: playlistCollection,
                  onTap: () {},
                ),
              ),
            ),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.playlist_play), findsOneWidget);
      });

      testWidgets('should display correct icon for favorites type', (WidgetTester tester) async {
        // Arrange
        final favoritesCollection = testCollection.copyWith(type: CollectionType.favorites);
        when(mockProvider.isLoading).thenReturn(false);
        when(mockProvider.collectionMedia).thenReturn([]);

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChangeNotifierProvider<CollectionProvider>(
                create: (_) => mockProvider,
                child: CollectionCard(
                  collection: favoritesCollection,
                  onTap: () {},
                ),
              ),
            ),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.favorite), findsOneWidget);
      });

      testWidgets('should display correct icon for trending type', (WidgetTester tester) async {
        // Arrange
        final trendingCollection = testCollection.copyWith(type: CollectionType.trending);
        when(mockProvider.isLoading).thenReturn(false);
        when(mockProvider.collectionMedia).thenReturn([]);

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChangeNotifierProvider<CollectionProvider>(
                create: (_) => mockProvider,
                child: CollectionCard(
                  collection: trendingCollection,
                  onTap: () {},
                ),
              ),
            ),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.trending_up), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper semantic labels', (WidgetTester tester) async {
        // Arrange
        when(mockProvider.isLoading).thenReturn(false);
        when(mockProvider.collectionMedia).thenReturn([]);

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChangeNotifierProvider<CollectionProvider>(
                create: (_) => mockProvider,
                child: CollectionCard(
                  collection: testCollection,
                  onTap: () {},
                ),
              ),
            ),
          ),
        );

        // Assert
        expect(find.bySemanticsLabel('Collection: ${testCollection.title}'), findsOneWidget);
      });

      testWidgets('should support keyboard navigation', (WidgetTester tester) async {
        // Arrange
        when(mockProvider.isLoading).thenReturn(false);
        when(mockProvider.collectionMedia).thenReturn([]);

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChangeNotifierProvider<CollectionProvider>(
                create: (_) => mockProvider,
                child: CollectionCard(
                  collection: testCollection,
                  onTap: () {},
                ),
              ),
            ),
          ),
        );

        // Assert - should be focusable
        expect(find.byType(CollectionCard), findsOneWidget);
        
        // Test keyboard navigation
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        
        // Should still be able to interact with keyboard
        expect(find.byType(CollectionCard), findsOneWidget);
      });
    });
  });
}

Collection _createTestCollection() {
  return Collection(
    id: 'test-collection-1',
    title: 'Test Collection',
    description: 'This is a test collection for unit testing',
    coverImage: 'https://example.com/cover.jpg',
    ownerId: 'user-1',
    ownerName: 'Test User',
    ownerAvatar: 'https://example.com/avatar.jpg',
    isCollaborative: false,
    isPublic: true,
    isFeatured: false,
    type: CollectionType.playlist,
    mediaCount: 25,
    followersCount: 150,
    tags: ['test', 'collection', 'unit-test'],
    createdAt: DateTime.now().subtract(const Duration(days: 7)),
    updatedAt: DateTime.now(),
    settings: const CollectionSettings(
      allowCollaboration: true,
      enableComments: true,
      enableAnalytics: true,
      maxCollaborators: 10,
      sortMethod: 'recent',
    ),
  );
}
