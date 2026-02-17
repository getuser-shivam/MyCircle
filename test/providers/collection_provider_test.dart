import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:mycircle/providers/collection_provider.dart';
import 'package:mycircle/repositories/collection_repository.dart';
import 'package:mycircle/models/collection.dart';
import 'package:mycircle/models/media_item.dart';

@GenerateMocks([CollectionRepository])
void main() {
  group('CollectionProvider', () {
    late CollectionProvider provider;
    late MockCollectionRepository mockRepository;

    setUp(() {
      mockRepository = MockCollectionRepository();
      provider = CollectionProvider(mockRepository);
    });

    tearDown(() {
      provider.dispose();
    });

    group('Initial State', () {
      test('should initialize with empty state', () {
        expect(provider.myCollections, isEmpty);
        expect(provider.featuredCollections, isEmpty);
        expect(provider.trendingCollections, isEmpty);
        expect(provider.currentCollection, isNull);
        expect(provider.collectionMedia, isEmpty);
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNull);
      });
    });

    group('loadMyCollections', () {
      final testCollections = [
        _createTestCollection('1', 'Test Collection 1'),
        _createTestCollection('2', 'Test Collection 2'),
      ];

      test('should load collections successfully', () async {
        // Arrange
        when(mockRepository.getCollections(any, limit: anyNamed('limit'), offset: anyNamed('offset')))
            .thenAnswer((_) async => testCollections);

        // Act
        await provider.loadMyCollections();

        // Assert
        expect(provider.myCollections, testCollections);
        expect(provider.isLoadingCollections, isFalse);
        expect(provider.collectionsError, isNull);
        verify(mockRepository.getCollections(any, limit: 20, offset: 0)).called(1);
      });

      test('should handle loading state', () async {
        // Arrange
        when(mockRepository.getCollections(any, limit: anyNamed('limit'), offset: anyNamed('offset')))
            .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 100));
          return testCollections;
        });

        // Act
        final loadFuture = provider.loadMyCollections();

        // Assert - should be loading
        expect(provider.isLoadingCollections, isTrue);

        // Wait for completion
        await loadFuture;

        // Assert - should not be loading
        expect(provider.isLoadingCollections, isFalse);
      });

      test('should handle error state', () async {
        // Arrange
        final errorMessage = 'Failed to load collections';
        when(mockRepository.getCollections(any, limit: anyNamed('limit'), offset: anyNamed('offset')))
            .thenThrow(Exception(errorMessage));

        // Act
        await provider.loadMyCollections();

        // Assert
        expect(provider.myCollections, isEmpty);
        expect(provider.isLoadingCollections, isFalse);
        expect(provider.collectionsError, errorMessage);
      });

      test('should refresh collections when refresh=true', () async {
        // Arrange
        when(mockRepository.getCollections(any, limit: anyNamed('limit'), offset: anyNamed('offset')))
            .thenAnswer((_) async => testCollections);

        // Add some existing data
        provider.loadMyCollections();
        await Future.delayed(const Duration(milliseconds: 50));

        // Act
        await provider.loadMyCollections(refresh: true);

        // Assert
        expect(provider.myCollections, testCollections);
        verify(mockRepository.getCollections(any, limit: 20, offset: 0)).called(2);
      });
    });

    group('loadFeaturedCollections', () {
      final testCollections = [
        _createTestCollection('1', 'Featured Collection 1'),
        _createTestCollection('2', 'Featured Collection 2'),
      ];

      test('should load featured collections successfully', () async {
        // Arrange
        when(mockRepository.getFeaturedCollections(limit: anyNamed('limit')))
            .thenAnswer((_) async => testCollections);

        // Act
        await provider.loadFeaturedCollections();

        // Assert
        expect(provider.featuredCollections, testCollections);
        expect(provider.isLoadingFeatured, isFalse);
        expect(provider.featuredError, isNull);
        verify(mockRepository.getFeaturedCollections(limit: 10)).called(1);
      });

      test('should handle error when loading featured collections', () async {
        // Arrange
        final errorMessage = 'Failed to load featured collections';
        when(mockRepository.getFeaturedCollections(limit: anyNamed('limit')))
            .thenThrow(Exception(errorMessage));

        // Act
        await provider.loadFeaturedCollections();

        // Assert
        expect(provider.featuredCollections, isEmpty);
        expect(provider.isLoadingFeatured, isFalse);
        expect(provider.featuredError, errorMessage);
      });
    });

    group('loadCollection', () {
      final testCollection = _createTestCollection('1', 'Test Collection');

      test('should load single collection successfully', () async {
        // Arrange
        when(mockRepository.getCollection(any, userId: anyNamed('userId')))
            .thenAnswer((_) async => testCollection);

        // Act
        await provider.loadCollection('1');

        // Assert
        expect(provider.currentCollection, testCollection);
        expect(provider.isLoadingCurrent, isFalse);
        expect(provider.currentError, isNull);
        verify(mockRepository.getCollection('1', userId: null)).called(1);
      });

      test('should handle null collection', () async {
        // Arrange
        when(mockRepository.getCollection(any, userId: anyNamed('userId')))
            .thenAnswer((_) async => null);

        // Act
        await provider.loadCollection('1');

        // Assert
        expect(provider.currentCollection, isNull);
        expect(provider.isLoadingCurrent, isFalse);
        expect(provider.currentError, isNull);
      });
    });

    group('createCollection', () {
      final testCollection = _createTestCollection('1', 'New Collection');

      test('should create collection successfully', () async {
        // Arrange
        when(mockRepository.createCollection(any))
            .thenAnswer((_) async => testCollection);

        // Act
        await provider.createCollection(testCollection);

        // Assert
        expect(provider.myCollections, contains(testCollection));
        expect(provider.isCreating, isFalse);
        expect(provider.error, isNull);
        verify(mockRepository.createCollection(testCollection)).called(1);
      });

      test('should handle error when creating collection', () async {
        // Arrange
        final errorMessage = 'Failed to create collection';
        when(mockRepository.createCollection(any))
            .thenThrow(Exception(errorMessage));

        // Act
        await provider.createCollection(testCollection);

        // Assert
        expect(provider.isCreating, isFalse);
        expect(provider.error, errorMessage);
      });
    });

    group('updateCollection', () {
      final testCollection = _createTestCollection('1', 'Updated Collection');

      test('should update collection successfully', () async {
        // Arrange
        when(mockRepository.updateCollection(any, any))
            .thenAnswer((_) async => testCollection);

        // Act
        await provider.updateCollection('1', {'title': 'Updated Title'});

        // Assert
        expect(provider.isUpdating, isFalse);
        expect(provider.error, isNull);
        verify(mockRepository.updateCollection('1', {'title': 'Updated Title'})).called(1);
      });

      test('should handle error when updating collection', () async {
        // Arrange
        final errorMessage = 'Failed to update collection';
        when(mockRepository.updateCollection(any, any))
            .thenThrow(Exception(errorMessage));

        // Act
        await provider.updateCollection('1', {'title': 'Updated Title'});

        // Assert
        expect(provider.isUpdating, isFalse);
        expect(provider.error, errorMessage);
      });
    });

    group('deleteCollection', () {
      test('should delete collection successfully', () async {
        // Arrange
        final testCollection = _createTestCollection('1', 'Test Collection');
        provider.loadMyCollections();
        await Future.delayed(const Duration(milliseconds: 50));
        when(mockRepository.deleteCollection(any))
            .thenAnswer((_) async {});

        // Act
        await provider.deleteCollection('1');

        // Assert
        expect(provider.myCollections, isNot(contains(testCollection)));
        expect(provider.isDeleting, isFalse);
        expect(provider.error, isNull);
        verify(mockRepository.deleteCollection('1')).called(1);
      });

      test('should handle error when deleting collection', () async {
        // Arrange
        final errorMessage = 'Failed to delete collection';
        when(mockRepository.deleteCollection(any))
            .thenThrow(Exception(errorMessage));

        // Act
        await provider.deleteCollection('1');

        // Assert
        expect(provider.isDeleting, isFalse);
        expect(provider.error, errorMessage);
      });
    });

    group('addMediaToCollection', () {
      test('should add media to collection successfully', () async {
        // Arrange
        when(mockRepository.addMediaToCollection(any, any, any))
            .thenAnswer((_) async {});

        // Act
        await provider.addMediaToCollection('collection1', 'media1', 'user1');

        // Assert
        expect(provider.error, isNull);
        verify(mockRepository.addMediaToCollection('collection1', 'media1', 'user1')).called(1);
      });

      test('should handle error when adding media to collection', () async {
        // Arrange
        final errorMessage = 'Failed to add media to collection';
        when(mockRepository.addMediaToCollection(any, any, any))
            .thenThrow(Exception(errorMessage));

        // Act
        await provider.addMediaToCollection('collection1', 'media1', 'user1');

        // Assert
        expect(provider.error, errorMessage);
      });
    });

    group('followCollection', () {
      test('should follow collection successfully', () async {
        // Arrange
        when(mockRepository.followCollection(any, any))
            .thenAnswer((_) async {});

        // Act
        await provider.followCollection('collection1', 'user1');

        // Assert
        expect(provider.error, isNull);
        verify(mockRepository.followCollection('collection1', 'user1')).called(1);
      });

      test('should handle error when following collection', () async {
        // Arrange
        final errorMessage = 'Failed to follow collection';
        when(mockRepository.followCollection(any, any))
            .thenThrow(Exception(errorMessage));

        // Act
        await provider.followCollection('collection1', 'user1');

        // Assert
        expect(provider.error, errorMessage);
      });
    });

    group('searchCollections', () {
      final testCollections = [
        _createTestCollection('1', 'Search Result 1'),
        _createTestCollection('2', 'Search Result 2'),
      ];

      test('should search collections successfully', () async {
        // Arrange
        when(mockRepository.searchCollections(any, limit: anyNamed('limit'), offset: anyNamed('offset')))
            .thenAnswer((_) async => testCollections);

        // Act
        await provider.searchCollections('test query');

        // Assert
        expect(provider.searchResults, testCollections);
        expect(provider.isLoadingSearch, isFalse);
        expect(provider.searchError, isNull);
        expect(provider.searchQuery, 'test query');
        expect(provider.isSearching, isTrue);
        verify(mockRepository.searchCollections('test query', limit: 20, offset: 0)).called(1);
      });

      test('should clear search when query is empty', () async {
        // Act
        await provider.searchCollections('');

        // Assert
        expect(provider.searchResults, isEmpty);
        expect(provider.searchQuery, '');
        expect(provider.isSearching, isFalse);
        verifyNever(mockRepository.searchCollections(any, limit: anyNamed('limit'), offset: anyNamed('offset')));
      });

      test('should handle error when searching collections', () async {
        // Arrange
        final errorMessage = 'Failed to search collections';
        when(mockRepository.searchCollections(any, limit: anyNamed('limit'), offset: anyNamed('offset')))
            .thenThrow(Exception(errorMessage));

        // Act
        await provider.searchCollections('test query');

        // Assert
        expect(provider.searchResults, isEmpty);
        expect(provider.isLoadingSearch, isFalse);
        expect(provider.searchError, errorMessage);
      });
    });

    group('clearErrors', () {
      test('should clear all error states', () {
        // Arrange - set some error states
        provider._setError('Test error');
        provider._setError('Test collections error', operation: 'collections');
        provider._setError('Test search error', operation: 'search');

        // Act
        provider.clearErrors();

        // Assert
        expect(provider.error, isNull);
        expect(provider.collectionsError, isNull);
        expect(provider.searchError, isNull);
      });
    });

    group('reset', () {
      test('should reset all state to initial values', () async {
        // Arrange - add some data
        await provider.loadMyCollections();
        await Future.delayed(const Duration(milliseconds: 50));
        provider._setError('Test error');

        // Act
        provider.reset();

        // Assert
        expect(provider.myCollections, isEmpty);
        expect(provider.featuredCollections, isEmpty);
        expect(provider.trendingCollections, isEmpty);
        expect(provider.currentCollection, isNull);
        expect(provider.collectionMedia, isEmpty);
        expect(provider.searchResults, isEmpty);
        expect(provider.searchQuery, '');
        expect(provider.isSearching, isFalse);
        expect(provider.error, isNull);
        expect(provider.collectionsError, isNull);
        expect(provider.searchError, isNull);
      });
    });
  });

  group('Pagination', () {
    late CollectionProvider provider;
    late MockCollectionRepository mockRepository;

    setUp(() {
      mockRepository = MockCollectionRepository();
      provider = CollectionProvider(mockRepository);
    });

    tearDown(() {
      provider.dispose();
    });

    test('should handle pagination correctly', () async {
      // Arrange
      final firstPage = [
        _createTestCollection('1', 'Collection 1'),
        _createTestCollection('2', 'Collection 2'),
      ];
      final secondPage = [
        _createTestCollection('3', 'Collection 3'),
        _createTestCollection('4', 'Collection 4'),
      ];

      when(mockRepository.getCollections(any, limit: 20, offset: 0))
          .thenAnswer((_) async => firstPage);
      when(mockRepository.getCollections(any, limit: 20, offset: 2))
          .thenAnswer((_) async => secondPage);

      // Act
      await provider.loadMyCollections();
      expect(provider.hasMoreCollections, isTrue);

      await provider.loadMyCollections(); // Load next page

      // Assert
      expect(provider.myCollections.length, 4);
      expect(provider.myCollections, containsAll(firstPage));
      expect(provider.myCollections, containsAll(secondPage));
      verify(mockRepository.getCollections(any, limit: 20, offset: 0)).called(1);
      verify(mockRepository.getCollections(any, limit: 20, offset: 2)).called(1);
    });

    test('should set hasMoreCollections to false when last page', () async {
      // Arrange
      final lastPage = [
        _createTestCollection('1', 'Collection 1'),
      ];

      when(mockRepository.getCollections(any, limit: 20, offset: 0))
          .thenAnswer((_) async => lastPage);

      // Act
      await provider.loadMyCollections();

      // Assert
      expect(provider.hasMoreCollections, isFalse);
    });
  });
}

Collection _createTestCollection(String id, String title) {
  return Collection(
    id: id,
    title: title,
    description: 'Test description',
    coverImage: 'https://example.com/cover.jpg',
    ownerId: 'user1',
    ownerName: 'Test User',
    ownerAvatar: 'https://example.com/avatar.jpg',
    type: CollectionType.playlist,
    mediaCount: 10,
    followersCount: 5,
    tags: ['test', 'collection'],
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    updatedAt: DateTime.now(),
    settings: const CollectionSettings(),
  );
}
