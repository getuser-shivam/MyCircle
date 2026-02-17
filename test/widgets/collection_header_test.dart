import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mycircle/widgets/collections/collection_header.dart';
import 'package:mycircle/models/collection.dart';

void main() {
  group('CollectionHeader', () {
    late Collection testCollection;

    setUp(() {
      testCollection = _createTestCollection();
    });

    testWidgets('should display collection title and description', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollectionHeader(
              collection: testCollection,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text(testCollection.title), findsOneWidget);
      expect(find.text(testCollection.description), findsOneWidget);
    });

    testWidgets('should display cover image when available', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollectionHeader(
              collection: testCollection,
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

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollectionHeader(
              collection: collectionWithoutCover,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.playlist_play), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('should display owner information', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollectionHeader(
              collection: testCollection,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text(testCollection.ownerName), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.textContaining('ago'), findsOneWidget);
    });

    testWidgets('should display type chip', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollectionHeader(
              collection: testCollection,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text(testCollection.type.displayName), findsOneWidget);
    });

    testWidgets('should display collaborative badge when collaborative', (WidgetTester tester) async {
      // Arrange
      final collaborativeCollection = testCollection.copyWith(
        isCollaborative: true,
        type: CollectionType.collaborative,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollectionHeader(
              collection: collaborativeCollection,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Collaborative'), findsOneWidget);
      expect(find.byIcon(Icons.group), findsOneWidget);
    });

    testWidgets('should display featured badge when featured', (WidgetTester tester) async {
      // Arrange
      final featuredCollection = testCollection.copyWith(isFeatured: true);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollectionHeader(
              collection: featuredCollection,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Featured'), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
    });

    testWidgets('should display stats correctly', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollectionHeader(
              collection: testCollection,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('${testCollection.mediaCount}'), findsOneWidget);
      expect(find.text('${testCollection.followersCount}'), findsOneWidget);
      expect(find.text('1.2K'), findsOneWidget); // Views from analytics
      expect(find.text('Media Items'), findsOneWidget);
      expect(find.text('Followers'), findsOneWidget);
      expect(find.text('Views'), findsOneWidget);
    });

    testWidgets('should display action buttons when showActions is true', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollectionHeader(
              collection: testCollection,
              showActions: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Play All'), findsOneWidget);
      expect(find.text('Shuffle'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.shuffle), findsOneWidget);
    });

    testWidgets('should not display action buttons when showActions is false', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollectionHeader(
              collection: testCollection,
              showActions: false,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Play All'), findsNothing);
      expect(find.text('Shuffle'), findsNothing);
    });

    testWidgets('should display edit button when onEdit is provided', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollectionHeader(
              collection: testCollection,
              onEdit: () {},
              showActions: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Edit'), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);
    });

    testWidgets('should call onPlayAll when Play All is tapped', (WidgetTester tester) async {
      // Arrange
      bool onPlayAllCalled = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollectionHeader(
              collection: testCollection,
              onPlayAll: () {
                onPlayAllCalled = true;
              },
              showActions: true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Play All'));

      // Assert
      expect(onPlayAllCalled, isTrue);
    });

    testWidgets('should call onShuffle when Shuffle is tapped', (WidgetTester tester) async {
      // Arrange
      bool onShuffleCalled = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollectionHeader(
              collection: testCollection,
              onShuffle: () {
                onShuffleCalled = true;
              },
              showActions: true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Shuffle'));

      // Assert
      expect(onShuffleCalled, isTrue);
    });

    testWidgets('should call onEdit when Edit is tapped', (WidgetTester tester) async {
      // Arrange
      bool onEditCalled = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CollectionHeader(
              collection: testCollection,
              onEdit: () {
                onEditCalled = true;
              },
              showActions: true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Edit'));

      // Assert
      expect(onEditCalled, isTrue);
    });

    group('Date Formatting', () {
      testWidgets('should display "X minutes ago" for recent date', (WidgetTester tester) async {
        // Arrange
        final recentCollection = testCollection.copyWith(
          createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        );

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CollectionHeader(
                collection: recentCollection,
              ),
            ),
          ),
        );

        // Assert
        expect(find.textContaining('5m ago'), findsOneWidget);
      });

      testWidgets('should display "X hours ago" for same day', (WidgetTester tester) async {
        // Arrange
        final hoursAgoCollection = testCollection.copyWith(
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        );

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CollectionHeader(
                collection: hoursAgoCollection,
              ),
            ),
          ),
        );

        // Assert
        expect(find.textContaining('3h ago'), findsOneWidget);
      });

      testWidgets('should display "X days ago" for recent days', (WidgetTester tester) async {
        // Arrange
        final daysAgoCollection = testCollection.copyWith(
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        );

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CollectionHeader(
                collection: daysAgoCollection,
              ),
            ),
          ),
        );

        // Assert
        expect(find.textContaining('2d ago'), findsOneWidget);
      });

      testWidgets('should display "X months ago" for older dates', (WidgetTester tester) async {
        // Arrange
        final monthsAgoCollection = testCollection.copyWith(
          createdAt: DateTime.now().subtract(const Duration(days: 45)),
        );

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CollectionHeader(
                collection: monthsAgoCollection,
              ),
            ),
          ),
        );

        // Assert
        expect(find.textContaining('1mo ago'), findsOneWidget);
      });

      testWidgets('should display "X years ago" for very old dates', (WidgetTester tester) async {
        // Arrange
        final yearsAgoCollection = testCollection.copyWith(
          createdAt: DateTime.now().subtract(const Duration(days: 400)),
        );

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CollectionHeader(
                collection: yearsAgoCollection,
              ),
            ),
          ),
        );

        // Assert
        expect(find.textContaining('1y ago'), findsOneWidget);
      });
    });

    group('Type-specific Icons and Colors', () {
      testWidgets('should display correct icon and color for playlist', (WidgetTester tester) async {
        // Arrange
        final playlistCollection = testCollection.copyWith(type: CollectionType.playlist);

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CollectionHeader(
                collection: playlistCollection,
              ),
            ),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.playlist_play), findsOneWidget);
      });

      testWidgets('should display correct icon and color for favorites', (WidgetTester tester) async {
        // Arrange
        final favoritesCollection = testCollection.copyWith(type: CollectionType.favorites);

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CollectionHeader(
                collection: favoritesCollection,
              ),
            ),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.favorite), findsOneWidget);
      });

      testWidgets('should display correct icon and color for trending', (WidgetTester tester) async {
        // Arrange
        final trendingCollection = testCollection.copyWith(type: CollectionType.trending);

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CollectionHeader(
                collection: trendingCollection,
              ),
            ),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.trending_up), findsOneWidget);
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper semantic labels for stats', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CollectionHeader(
                collection: testCollection,
              ),
            ),
          ),
        );

        // Assert
        expect(find.bySemanticsLabel('Media Items: ${testCollection.mediaCount}'), findsOneWidget);
        expect(find.bySemanticsLabel('Followers: ${testCollection.followersCount}'), findsOneWidget);
        expect(find.bySemanticsLabel('Views: 1.2K'), findsOneWidget);
      });

      testWidgets('should have proper semantic labels for actions', (WidgetTester tester) async {
        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CollectionHeader(
                collection: testCollection,
                onPlayAll: () {},
                onShuffle: () {},
                onEdit: () {},
                showActions: true,
              ),
            ),
          ),
        );

        // Assert
        expect(find.bySemanticsLabel('Play All'), findsOneWidget);
        expect(find.bySemanticsLabel('Shuffle'), findsOneWidget);
        expect(find.bySemanticsLabel('Edit Collection'), findsOneWidget);
      });
    });
  });
}

Collection _createTestCollection() {
  return Collection(
    id: 'test-collection-1',
    title: 'Test Collection Header',
    description: 'This is a test collection for widget testing',
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
    tags: ['test', 'collection', 'widget-test'],
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
