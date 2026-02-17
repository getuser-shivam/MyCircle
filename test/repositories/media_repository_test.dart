import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_circle/models/media_item.dart';
import 'package:my_circle/repositories/media_repository.dart';
import 'package:my_circle/services/supabase_service.dart';

import 'media_repository_test.mocks.dart';

@GenerateMocks([SupabaseService, SupabaseClient, PostgrestFilterBuilder, PostgrestTransformBuilder])
void main() {
  group('MediaRepository', () {
    late MediaRepository repository;
    late MockSupabaseService mockSupabaseService;
    late MockSupabaseClient mockClient;
    late MockPostgrestFilterBuilder mockFilterBuilder;
    late MockPostgrestTransformBuilder mockTransformBuilder;

    setUp(() {
      mockSupabaseService = MockSupabaseService();
      mockClient = MockSupabaseClient();
      mockFilterBuilder = MockPostgrestFilterBuilder();
      mockTransformBuilder = MockPostgrestTransformBuilder();
      
      repository = MediaRepository(mockSupabaseService);
      
      // Setup default mock behavior
      when(mockClient.from('media_items')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.select('*')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.select('*, profiles(*)')).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.order(any, ascending: anyNamed('ascending'))).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.range(any, any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.eq(any, any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.or(any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.limit(any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.gte(any, any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.neq(any, any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.single()).thenReturn(mockTransformBuilder);
      when(mockFilterBuilder.maybeSingle()).thenReturn(mockTransformBuilder);
      when(mockFilterBuilder.insert(any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.update(any)).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.delete()).thenReturn(mockFilterBuilder);
      when(mockFilterBuilder.asStream()).thenReturn(Stream.value([]));
    });

    group('getMediaItems', () {
      test('should return list of media items when successful', () async {
        // Arrange
        final mockData = [
          {
            'id': '1',
            'title': 'Test Media',
            'description': 'Test Description',
            'url': 'https://example.com/video.mp4',
            'thumbnail_url': 'https://example.com/thumb.jpg',
            'category': 'Test',
            'author_id': 'user1',
            'created_at': '2023-01-01T00:00:00Z',
            'type': 'video',
            'views_count': 100,
            'likes_count': 10,
            'comments_count': 5,
            'tags': ['test'],
            'is_premium': false,
            'is_private': false,
            'profiles': {
              'username': 'testuser',
              'avatar_url': 'https://example.com/avatar.jpg',
              'is_verified': true,
            }
          }
        ];
        
        when(mockTransformBuilder.then(any)).thenAnswer((_) async => mockData);

        // Act
        final result = await repository.getMediaItems();

        // Assert
        expect(result, isA<List<MediaItem>>());
        expect(result.length, 1);
        expect(result.first.title, 'Test Media');
        expect(result.first.userName, 'testuser');
        verify(mockFilterBuilder.select('*, profiles(*)')).called(1);
        verify(mockFilterBuilder.order('created_at', ascending: false)).called(1);
        verify(mockFilterBuilder.range(0, 19)).called(1);
      });

      test('should apply category filter when provided', () async {
        // Arrange
        when(mockTransformBuilder.then(any)).thenAnswer((_) async => []);

        // Act
        await repository.getMediaItems(category: 'Gaming');

        // Assert
        verify(mockFilterBuilder.eq('category', 'Gaming')).called(1);
      });

      test('should apply search query when provided', () async {
        // Arrange
        when(mockTransformBuilder.then(any)).thenAnswer((_) async => []);

        // Act
        await repository.getMediaItems(searchQuery: 'test query');

        // Assert
        verify(mockFilterBuilder.or('title.ilike.%test query%,description.ilike.%test query%')).called(1);
      });

      test('should throw exception when request fails', () async {
        // Arrange
        when(mockTransformBuilder.then(any)).thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => repository.getMediaItems(),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Failed to fetch media items'))),
        );
      });
    });

    group('getMediaItem', () {
      test('should return media item when found', () async {
        // Arrange
        final mockData = {
          'id': '1',
          'title': 'Test Media',
          'description': 'Test Description',
          'url': 'https://example.com/video.mp4',
          'thumbnail_url': 'https://example.com/thumb.jpg',
          'category': 'Test',
          'author_id': 'user1',
          'created_at': '2023-01-01T00:00:00Z',
          'type': 'video',
          'profiles': {
            'username': 'testuser',
            'avatar_url': 'https://example.com/avatar.jpg',
          }
        };
        
        when(mockTransformBuilder.then(any)).thenAnswer((_) async => mockData);

        // Act
        final result = await repository.getMediaItem('1');

        // Assert
        expect(result, isNotNull);
        expect(result!.id, '1');
        expect(result.title, 'Test Media');
        verify(mockFilterBuilder.eq('id', '1')).called(1);
        verify(mockFilterBuilder.single()).called(1);
      });

      test('should throw exception when item not found', () async {
        // Arrange
        when(mockTransformBuilder.then(any)).thenThrow(Exception('Item not found'));

        // Act & Assert
        expect(
          () => repository.getMediaItem('999'),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Failed to fetch media item'))),
        );
      });
    });

    group('createMediaItem', () {
      test('should create media item successfully', () async {
        // Arrange
        final mockUser = MockUser();
        when(mockUser.id).thenReturn('user1');
        when(mockClient.auth.currentUser).thenReturn(mockUser);
        
        final mockResponse = {
          'id': '2',
          'title': 'New Media',
          'description': 'New Description',
          'url': 'https://example.com/new.mp4',
          'thumbnail_url': 'https://example.com/new_thumb.jpg',
          'category': 'New',
          'author_id': 'user1',
          'created_at': '2023-01-01T00:00:00Z',
          'type': 'video',
          'profiles': {
            'username': 'testuser',
            'avatar_url': 'https://example.com/avatar.jpg',
          }
        };
        
        when(mockTransformBuilder.then(any)).thenAnswer((_) async => mockResponse);

        // Act
        final result = await repository.createMediaItem(
          title: 'New Media',
          description: 'New Description',
          url: 'https://example.com/new.mp4',
          thumbnailUrl: 'https://example.com/new_thumb.jpg',
          category: 'New',
          tags: ['new'],
          type: MediaType.video,
        );

        // Assert
        expect(result, isA<MediaItem>());
        expect(result.title, 'New Media');
        expect(result.authorId, 'user1');
        verify(mockFilterBuilder.insert(any)).called(1);
        verify(mockFilterBuilder.select('*, profiles(*)')).called(1);
      });

      test('should throw exception when user not authenticated', () async {
        // Arrange
        when(mockClient.auth.currentUser).thenReturn(null);

        // Act & Assert
        expect(
          () => repository.createMediaItem(
            title: 'Test',
            description: 'Test',
            url: 'test.mp4',
            thumbnailUrl: 'test.jpg',
            category: 'Test',
            tags: [],
            type: MediaType.video,
          ),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('User not authenticated'))),
        );
      });
    });

    group('likeMediaItem', () {
      test('should like media item successfully', () async {
        // Arrange
        final mockUser = MockUser();
        when(mockUser.id).thenReturn('user1');
        when(mockClient.auth.currentUser).thenReturn(mockUser);
        when(mockClient.rpc('increment_like_count', params: anyNamed('params')))
            .thenAnswer((_) async {});

        // Act
        await repository.likeMediaItem('media1');

        // Assert
        verify(mockClient.from('media_likes')).called(1);
        verify(mockFilterBuilder.insert({
          'media_id': 'media1',
          'user_id': 'user1',
          'created_at': anyNamed('created_at'),
        })).called(1);
        verify(mockClient.rpc('increment_like_count', params: {'media_id': 'media1'})).called(1);
      });

      test('should throw exception when user not authenticated', () async {
        // Arrange
        when(mockClient.auth.currentUser).thenReturn(null);

        // Act & Assert
        expect(
          () => repository.likeMediaItem('media1'),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('User not authenticated'))),
        );
      });
    });

    group('unlikeMediaItem', () {
      test('should unlike media item successfully', () async {
        // Arrange
        final mockUser = MockUser();
        when(mockUser.id).thenReturn('user1');
        when(mockClient.auth.currentUser).thenReturn(mockUser);
        when(mockClient.rpc('decrement_like_count', params: anyNamed('params')))
            .thenAnswer((_) async {});

        // Act
        await repository.unlikeMediaItem('media1');

        // Assert
        verify(mockClient.from('media_likes')).called(1);
        verify(mockFilterBuilder.delete()).called(1);
        verify(mockFilterBuilder.eq('media_id', 'media1')).called(1);
        verify(mockFilterBuilder.eq('user_id', 'user1')).called(1);
        verify(mockClient.rpc('decrement_like_count', params: {'media_id': 'media1'})).called(1);
      });
    });

    group('getTrendingMedia', () {
      test('should return trending media items', () async {
        // Arrange
        final mockData = [
          {
            'id': '1',
            'title': 'Trending Media',
            'description': 'Trending Description',
            'url': 'https://example.com/trending.mp4',
            'thumbnail_url': 'https://example.com/trending_thumb.jpg',
            'category': 'Trending',
            'author_id': 'user1',
            'created_at': '2023-01-01T00:00:00Z',
            'type': 'video',
            'views_count': 1000,
            'likes_count': 100,
            'profiles': {
              'username': 'trendinguser',
              'avatar_url': 'https://example.com/avatar.jpg',
            }
          }
        ];
        
        when(mockTransformBuilder.then(any)).thenAnswer((_) async => mockData);

        // Act
        final result = await repository.getTrendingMedia();

        // Assert
        expect(result, isA<List<MediaItem>>());
        expect(result.length, 1);
        expect(result.first.title, 'Trending Media');
        verify(mockFilterBuilder.gte('views_count', 100)).called(1);
        verify(mockFilterBuilder.order('views_count', ascending: false)).called(1);
        verify(mockFilterBuilder.order('likes_count', ascending: false)).called(1);
        verify(mockFilterBuilder.limit(20)).called(1);
      });
    });

    group('getUserMedia', () {
      test('should return user media items', () async {
        // Arrange
        final mockData = [
          {
            'id': '1',
            'title': 'User Media',
            'description': 'User Description',
            'url': 'https://example.com/user.mp4',
            'thumbnail_url': 'https://example.com/user_thumb.jpg',
            'category': 'User',
            'author_id': 'user1',
            'created_at': '2023-01-01T00:00:00Z',
            'type': 'video',
            'profiles': {
              'username': 'user',
              'avatar_url': 'https://example.com/avatar.jpg',
            }
          }
        ];
        
        when(mockTransformBuilder.then(any)).thenAnswer((_) async => mockData);

        // Act
        final result = await repository.getUserMedia('user1');

        // Assert
        expect(result, isA<List<MediaItem>>());
        expect(result.length, 1);
        expect(result.first.authorId, 'user1');
        verify(mockFilterBuilder.eq('author_id', 'user1')).called(1);
        verify(mockFilterBuilder.limit(20)).called(1);
      });
    });

    group('deleteMediaItem', () {
      test('should delete media item successfully', () async {
        // Act
        await repository.deleteMediaItem('media1');

        // Assert
        verify(mockFilterBuilder.delete()).called(1);
        verify(mockFilterBuilder.eq('id', 'media1')).called(1);
      });

      test('should throw exception when delete fails', () async {
        // Arrange
        when(mockFilterBuilder.delete()).thenThrow(Exception('Delete failed'));

        // Act & Assert
        expect(
          () => repository.deleteMediaItem('media1'),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Failed to delete media item'))),
        );
      });
    });
  });
}
