import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:my_circle/providers/enhanced_media_provider.dart';
import 'package:my_circle/repositories/media_repository.dart';
import 'package:my_circle/models/media_item.dart';

import 'enhanced_media_provider_test.mocks.dart';

@GenerateMocks([MediaRepository, MediaItem])
void main() {
  group('EnhancedMediaProvider', () {
    late EnhancedMediaProvider provider;
    late MockMediaRepository mockMediaRepository;

    setUp(() {
      mockMediaRepository = MockMediaRepository();
      provider = EnhancedMediaProvider();
      provider._mediaRepository = mockMediaRepository;
    });

    group('Initial State', () {
      test('should start with correct initial state', () {
        expect(provider.mediaItems, isEmpty);
        expect(provider.trendingMedia, isEmpty);
        expect(provider.currentMedia, isNull);
        expect(provider.userMedia, isEmpty);
        expect(provider.isLoading, isFalse);
        expect(provider.isLoadingTrending, isFalse);
        expect(provider.hasMore, isTrue);
        expect(provider.error, isNull);
        expect(provider.searchQuery, isEmpty);
        expect(provider.selectedCategory, 'All');
      });
    });

    group('loadMediaItems', () {
      test('should load media items successfully', () async {
        // Arrange
        final mockItems = [
          createMockMediaItem('1', 'Test Media 1'),
          createMockMediaItem('2', 'Test Media 2'),
        ];
        
        when(mockMediaRepository.getMediaItems(
          limit: 20,
          offset: 0,
          category: null,
          searchQuery: null,
        )).thenAnswer((_) async => mockItems);

        // Act
        await provider.loadMediaItems();

        // Assert
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNull);
        expect(provider.mediaItems.length, 2);
        expect(provider.mediaItems[0].title, 'Test Media 1');
        expect(provider.currentPage, 1);
        expect(provider.hasMore, isTrue);
        
        verify(mockMediaRepository.getMediaItems(
          limit: 20,
          offset: 0,
          category: null,
          searchQuery: null,
        )).called(1);
      });

      test('should not load if already loading', () async {
        // Arrange
        provider._isLoading = true;
        
        // Act
        await provider.loadMediaItems();

        // Assert
        verifyNever(mockMediaRepository.getMediaItems(any));
      });

      test('should not load if no more items', () async {
        // Arrange
        provider._hasMore = false;
        
        // Act
        await provider.loadMediaItems();

        // Assert
        verifyNever(mockMediaRepository.getMediaItems(any));
      });

      test('should handle empty response correctly', () async {
        // Arrange
        when(mockMediaRepository.getMediaItems(
          limit: 20,
          offset: 0,
          category: null,
          searchQuery: null,
        )).thenAnswer((_) async => []);

        // Act
        await provider.loadMediaItems();

        // Assert
        expect(provider.mediaItems, isEmpty);
        expect(provider.hasMore, isFalse);
      });

      test('should set error when loading fails', () async {
        // Arrange
        when(mockMediaRepository.getMediaItems(any))
            .thenThrow(Exception('Network error'));

        // Act
        await provider.loadMediaItems();

        // Assert
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNotNull);
        expect(provider.error, contains('Failed to load media items'));
        expect(provider.mediaItems, isEmpty);
      });

      test('should apply category filter', () async {
        // Arrange
        provider.setCategory('Gaming');
        when(mockMediaRepository.getMediaItems(
          limit: 20,
          offset: 0,
          category: 'Gaming',
          searchQuery: null,
        )).thenAnswer((_) async => []);

        // Act
        await provider.loadMediaItems();

        // Assert
        verify(mockMediaRepository.getMediaItems(
          limit: 20,
          offset: 0,
          category: 'Gaming',
          searchQuery: null,
        )).called(1);
      });

      test('should apply search query', () async {
        // Arrange
        provider.setSearchQuery('test query');
        when(mockMediaRepository.getMediaItems(
          limit: 20,
          offset: 0,
          category: null,
          searchQuery: 'test query',
        )).thenAnswer((_) async => []);

        // Act
        await provider.loadMediaItems();

        // Assert
        verify(mockMediaRepository.getMediaItems(
          limit: 20,
          offset: 0,
          category: null,
          searchQuery: 'test query',
        )).called(1);
      });

      test('should refresh when refresh=true', () async {
        // Arrange
        provider._currentPage = 2;
        provider._hasMore = false;
        provider._mediaItems = [createMockMediaItem('1', 'Old Item')];
        
        when(mockMediaRepository.getMediaItems(
          limit: 20,
          offset: 0,
          category: null,
          searchQuery: null,
        )).thenAnswer((_) async => [createMockMediaItem('2', 'New Item')]);

        // Act
        await provider.loadMediaItems(refresh: true);

        // Assert
        expect(provider.currentPage, 1);
        expect(provider.hasMore, isTrue);
        expect(provider.mediaItems.length, 1);
        expect(provider.mediaItems[0].title, 'New Item');
      });

      test('should handle pagination correctly', () async {
        // Arrange - first page
        when(mockMediaRepository.getMediaItems(
          limit: 20,
          offset: 0,
          category: null,
          searchQuery: null,
        )).thenAnswer((_) async => [createMockMediaItem('1', 'Item 1')]);

        await provider.loadMediaItems();

        // Arrange - second page
        when(mockMediaRepository.getMediaItems(
          limit: 20,
          offset: 20,
          category: null,
          searchQuery: null,
        )).thenAnswer((_) async => [createMockMediaItem('2', 'Item 2')]);

        // Act
        await provider.loadMediaItems();

        // Assert
        expect(provider.currentPage, 2);
        expect(provider.mediaItems.length, 2);
        expect(provider.mediaItems[0].title, 'Item 1');
        expect(provider.mediaItems[1].title, 'Item 2');
      });
    });

    group('loadTrendingMedia', () {
      test('should load trending media successfully', () async {
        // Arrange
        final mockTrending = [
          createMockMediaItem('1', 'Trending 1'),
          createMockMediaItem('2', 'Trending 2'),
        ];
        
        when(mockMediaRepository.getTrendingMedia(limit: 20))
            .thenAnswer((_) async => mockTrending);

        // Act
        await provider.loadTrendingMedia();

        // Assert
        expect(provider.isLoadingTrending, isFalse);
        expect(provider.trendingError, isNull);
        expect(provider.trendingMedia.length, 2);
        expect(provider.trendingMedia[0].title, 'Trending 1');
        
        verify(mockMediaRepository.getTrendingMedia(limit: 20)).called(1);
      });

      test('should set error when trending load fails', () async {
        // Arrange
        when(mockMediaRepository.getTrendingMedia(any))
            .thenThrow(Exception('Trending load failed'));

        // Act
        await provider.loadTrendingMedia();

        // Assert
        expect(provider.isLoadingTrending, isFalse);
        expect(provider.trendingError, isNotNull);
        expect(provider.trendingError, contains('Failed to load trending media'));
        expect(provider.trendingMedia, isEmpty);
      });
    });

    group('loadMediaItem', () {
      test('should load specific media item successfully', () async {
        // Arrange
        final mockItem = createMockMediaItem('1', 'Specific Item');
        when(mockMediaRepository.getMediaItem('1'))
            .thenAnswer((_) async => mockItem);

        // Act
        await provider.loadMediaItem('1');

        // Assert
        expect(provider.isLoadingCurrent, isFalse);
        expect(provider.currentError, isNull);
        expect(provider.currentMedia, isNotNull);
        expect(provider.currentMedia!.id, '1');
        expect(provider.currentMedia!.title, 'Specific Item');
        
        verify(mockMediaRepository.getMediaItem('1')).called(1);
      });

      test('should set error when specific item load fails', () async {
        // Arrange
        when(mockMediaRepository.getMediaItem('999'))
            .thenThrow(Exception('Item not found'));

        // Act
        await provider.loadMediaItem('999');

        // Assert
        expect(provider.isLoadingCurrent, isFalse);
        expect(provider.currentError, isNotNull);
        expect(provider.currentError, contains('Failed to load media item'));
        expect(provider.currentMedia, isNull);
      });
    });

    group('loadUserMedia', () {
      test('should load user media successfully', () async {
        // Arrange
        final mockUserMedia = [
          createMockMediaItem('1', 'User Item 1'),
          createMockMediaItem('2', 'User Item 2'),
        ];
        
        when(mockMediaRepository.getUserMedia('user123', limit: 20))
            .thenAnswer((_) async => mockUserMedia);

        // Act
        await provider.loadUserMedia('user123');

        // Assert
        expect(provider.isLoadingUserMedia, isFalse);
        expect(provider.userMediaError, isNull);
        expect(provider.userMedia.length, 2);
        expect(provider.userMedia[0].title, 'User Item 1');
        
        verify(mockMediaRepository.getUserMedia('user123', limit: 20)).called(1);
      });

      test('should set error when user media load fails', () async {
        // Arrange
        when(mockMediaRepository.getUserMedia(any, limit: anyNamed('limit')))
            .thenThrow(Exception('User media load failed'));

        // Act
        await provider.loadUserMedia('user123');

        // Assert
        expect(provider.isLoadingUserMedia, isFalse);
        expect(provider.userMediaError, isNotNull);
        expect(provider.userMediaError, contains('Failed to load user media'));
        expect(provider.userMedia, isEmpty);
      });
    });

    group('toggleLike', () {
      test('should like media item successfully', () async {
        // Arrange
        final mockItem = createMockMediaItem('1', 'Likeable Item');
        mockItem.likes = 10;
        
        provider._mediaItems = [mockItem];
        provider._likedMedia['1'] = false;
        
        when(mockMediaRepository.likeMediaItem('1')).thenAnswer((_) async {});

        // Act
        await provider.toggleLike('1');

        // Assert
        expect(provider.isLiked('1'), isTrue);
        expect(provider.mediaItems[0].likes, 11); // Incremented
        verify(mockMediaRepository.likeMediaItem('1')).called(1);
      });

      test('should unlike media item successfully', () async {
        // Arrange
        final mockItem = createMockMediaItem('1', 'Likeable Item');
        mockItem.likes = 10;
        
        provider._mediaItems = [mockItem];
        provider._likedMedia['1'] = true;
        
        when(mockMediaRepository.unlikeMediaItem('1')).thenAnswer((_) async {});

        // Act
        await provider.toggleLike('1');

        // Assert
        expect(provider.isLiked('1'), isFalse);
        expect(provider.mediaItems[0].likes, 9); // Decremented
        verify(mockMediaRepository.unlikeMediaItem('1')).called(1);
      });

      test('should revert like status on error', () async {
        // Arrange
        final mockItem = createMockMediaItem('1', 'Likeable Item');
        provider._mediaItems = [mockItem];
        provider._likedMedia['1'] = false;
        
        when(mockMediaRepository.likeMediaItem('1'))
            .thenThrow(Exception('Like failed'));

        // Act
        await provider.toggleLike('1');

        // Assert
        expect(provider.isLiked('1'), isFalse); // Reverted
        expect(() => provider.toggleLike('1'), throwsException);
      });
    });

    group('Search and Filter', () {
      test('should set search query and reload', () async {
        // Arrange
        when(mockMediaRepository.getMediaItems(
          limit: 20,
          offset: 0,
          category: null,
          searchQuery: 'new query',
        )).thenAnswer((_) async => []);

        // Act
        provider.setSearchQuery('new query');

        // Assert
        expect(provider.searchQuery, 'new query');
        verify(mockMediaRepository.getMediaItems(
          limit: 20,
          offset: 0,
          category: null,
          searchQuery: 'new query',
        )).called(1);
      });

      test('should set category and reload', () async {
        // Arrange
        when(mockMediaRepository.getMediaItems(
          limit: 20,
          offset: 0,
          category: 'Gaming',
          searchQuery: null,
        )).thenAnswer((_) async => []);

        // Act
        provider.setCategory('Gaming');

        // Assert
        expect(provider.selectedCategory, 'Gaming');
        verify(mockMediaRepository.getMediaItems(
          limit: 20,
          offset: 0,
          category: 'Gaming',
          searchQuery: null,
        )).called(1);
      });

      test('should clear filters and reload', () async {
        // Arrange
        provider._searchQuery = 'test';
        provider._selectedCategory = 'Gaming';
        
        when(mockMediaRepository.getMediaItems(
          limit: 20,
          offset: 0,
          category: null,
          searchQuery: null,
        )).thenAnswer((_) async => []);

        // Act
        provider.clearFilters();

        // Assert
        expect(provider.searchQuery, isEmpty);
        expect(provider.selectedCategory, 'All');
        verify(mockMediaRepository.getMediaItems(
          limit: 20,
          offset: 0,
          category: null,
          searchQuery: null,
        )).called(1);
      });
    });

    group('Utility Methods', () {
      test('should refresh all data', () async {
        // Arrange
        when(mockMediaRepository.getMediaItems(
          limit: 20,
          offset: 0,
          category: null,
          searchQuery: null,
        )).thenAnswer((_) async => []);
        when(mockMediaRepository.getTrendingMedia(limit: 20))
            .thenAnswer((_) async => []);

        // Act
        provider.refresh();

        // Assert
        verify(mockMediaRepository.getMediaItems(
          limit: 20,
          offset: 0,
          category: null,
          searchQuery: null,
        )).called(1);
        verify(mockMediaRepository.getTrendingMedia(limit: 20)).called(1);
      });

      test('should clear current media', () {
        // Arrange
        provider._currentMedia = createMockMediaItem('1', 'Current');
        provider._currentError = 'Some error';

        // Act
        provider.clearCurrentMedia();

        // Assert
        expect(provider.currentMedia, isNull);
        expect(provider.currentError, isNull);
      });
    });
  });
}

MediaItem createMockMediaItem(String id, String title) {
  return MediaItem(
    id: id,
    title: title,
    description: 'Test Description',
    url: 'https://example.com/video.mp4',
    thumbnailUrl: 'https://example.com/thumb.jpg',
    category: 'Test',
    authorId: 'user123',
    userName: 'testuser',
    userAvatar: 'https://example.com/avatar.jpg',
    createdAt: DateTime.now(),
    type: MediaType.video,
    likes: 0,
    views: 0,
    commentsCount: 0,
  );
}

// Extension to access private members for testing
extension EnhancedMediaProviderTestExtension on EnhancedMediaProvider {
  set _mediaRepository(MediaRepository repository) => this._mediaRepository = repository;
  set _isLoading(bool loading) => this._isLoading = loading;
  set _hasMore(bool hasMore) => this._hasMore = hasMore;
  set _currentPage(int page) => this._currentPage = page;
  set _mediaItems(List<MediaItem> items) => this._mediaItems = items;
  set _likedMedia(Map<String, bool> likedMedia) => this._likedMedia = likedMedia;
  set _searchQuery(String query) => this._searchQuery = query;
  set _selectedCategory(String category) => this._selectedCategory = category;
  set _currentMedia(MediaItem? media) => this._currentMedia = media;
  set _currentError(String? error) => this._currentError = error;
}
