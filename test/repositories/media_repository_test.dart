import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import 'package:my_circle\repositories\media_repository.dart';

// Generate mocks
@GenerateMocks([
  SupabaseClient,
  RealtimeChannel,
  PostgrestFilterBuilder,
  PostgrestTransformBuilder,
])
import 'media_repository_test.mocks.dart';

void main() {
  group('MediaRepository Tests', () {
    late MediaRepository mediaRepository;
    late MockSupabaseClient mockSupabaseClient;
    late MockRealtimeChannel mockRealtimeChannel;
    late MockPostgrestFilterBuilder mockFilterBuilder;
    late MockPostgrestTransformBuilder mockTransformBuilder;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockRealtimeChannel = MockRealtimeChannel();
      mockFilterBuilder = MockPostgrestFilterBuilder();
      mockTransformBuilder = MockPostgrestTransformBuilder();
      
      mediaRepository = MediaRepository(mockSupabaseClient);
    });

    group('Media CRUD Operations', () {
      test('should upload media metadata', () async {
        final mediaData = {
          'title': 'Test Media',
          'description': 'A test media file',
          'file_url': 'https://example.com/media.mp4',
          'file_type': 'video',
          'file_size': 1024000,
          'duration': 120.5,
          'thumbnail_url': 'https://example.com/thumbnail.jpg',
          'creator_id': 'creator_1',
          'is_private': false,
          'tags': ['test', 'video'],
        };

        final mockResponse = {
          'id': 'media_1',
          ...mediaData,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        when(mockSupabaseClient.from('media'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.insert(mediaData))
            .thenAnswer((_) async => mockResponse);

        final result = await mediaRepository.uploadMediaMetadata(mediaData);
        
        expect(result, isNotNull);
        expect(result!['id'], 'media_1');
        expect(result['title'], 'Test Media');
        expect(result['creator_id'], 'creator_1');
        verify(mockFilterBuilder.insert(mediaData)).called(1);
      });

      test('should get media by ID', () async {
        final mockMedia = {
          'id': 'media_1',
          'title': 'Test Media',
          'description': 'A test media file',
          'file_url': 'https://example.com/media.mp4',
          'file_type': 'video',
          'creator_id': 'creator_1',
          'is_private': false,
          'tags': ['test', 'video'],
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        when(mockSupabaseClient.from('media'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select())
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.eq('id', 'media_1'))
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.single())
            .thenAnswer((_) async => mockMedia);

        final result = await mediaRepository.getMediaById('media_1');
        
        expect(result, isNotNull);
        expect(result!['id'], 'media_1');
        expect(result['title'], 'Test Media');
        verify(mockTransformBuilder.eq('id', 'media_1')).called(1);
        verify(mockTransformBuilder.single()).called(1);
      });

      test('should handle media not found', () async {
        when(mockSupabaseClient.from('media'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select())
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.eq('id', 'nonexistent'))
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.single())
            .thenThrow(PostgrestException(message: 'No rows found'));

        final result = await mediaRepository.getMediaById('nonexistent');
        
        expect(result, isNull);
      });

      test('should update media metadata', () async {
        final updateData = {
          'title': 'Updated Media',
          'description': 'Updated description',
          'updated_at': DateTime.now().toIso8601String(),
        };

        when(mockSupabaseClient.from('media'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', 'media_1'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.update(updateData))
            .thenAnswer((_) async => []);

        await mediaRepository.updateMediaMetadata('media_1', updateData);
        
        verify(mockFilterBuilder.eq('id', 'media_1')).called(1);
        verify(mockFilterBuilder.update(updateData)).called(1);
      });

      test('should delete media', () async {
        when(mockSupabaseClient.from('media'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('id', 'media_1'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.delete())
            .thenAnswer((_) async => []);

        await mediaRepository.deleteMedia('media_1');
        
        verify(mockFilterBuilder.eq('id', 'media_1')).called(1);
        verify(mockFilterBuilder.delete()).called(1);
      });
    });

    group('Media Query Operations', () {
      test('should get media by creator', () async {
        final mockMedia = [
          {
            'id': 'media_1',
            'title': 'Media 1',
            'creator_id': 'creator_1',
            'created_at': DateTime.now().toIso8601String(),
          },
          {
            'id': 'media_2',
            'title': 'Media 2',
            'creator_id': 'creator_1',
            'created_at': DateTime.now().toIso8601String(),
          },
        ];

        when(mockSupabaseClient.from('media'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select())
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.eq('creator_id', 'creator_1'))
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.order('created_at', descending: true))
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.limit(20))
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.thenAnswer((_) async => mockMedia))
            .thenAnswer((_) async => mockMedia);

        final result = await mediaRepository.getMediaByCreator('creator_1', limit: 20);
        
        expect(result.length, 2);
        expect(result.every((m) => m['creator_id'] == 'creator_1'), true);
        verify(mockTransformBuilder.eq('creator_id', 'creator_1')).called(1);
        verify(mockTransformBuilder.limit(20)).called(1);
      });

      test('should get public media', () async {
        final mockMedia = [
          {
            'id': 'media_1',
            'title': 'Public Media 1',
            'is_private': false,
            'created_at': DateTime.now().toIso8601String(),
          },
          {
            'id': 'media_2',
            'title': 'Public Media 2',
            'is_private': false,
            'created_at': DateTime.now().toIso8601String(),
          },
        ];

        when(mockSupabaseClient.from('media'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select())
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.eq('is_private', false))
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.order('created_at', descending: true))
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.limit(50))
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.thenAnswer((_) async => mockMedia))
            .thenAnswer((_) async => mockMedia);

        final result = await mediaRepository.getPublicMedia(limit: 50);
        
        expect(result.length, 2);
        expect(result.every((m) => m['is_private'] == false), true);
        verify(mockTransformBuilder.eq('is_private', false)).called(1);
        verify(mockTransformBuilder.limit(50)).called(1);
      });

      test('should search media', () async {
        final mockMedia = [
          {
            'id': 'media_1',
            'title': 'Test Video',
            'description': 'A test video for testing',
            'tags': ['test', 'video'],
          },
        ];

        when(mockSupabaseClient.from('media'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select())
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.or('title.ilike.%test%,description.ilike.%test%'))
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.eq('is_private', false))
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.order('created_at', descending: true))
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.limit(10))
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.thenAnswer((_) async => mockMedia))
            .thenAnswer((_) async => mockMedia);

        final result = await mediaRepository.searchMedia('test', limit: 10);
        
        expect(result.length, 1);
        expect(result.first['title'], contains('test'));
        verify(mockTransformBuilder.or('title.ilike.%test%,description.ilike.%test%')).called(1);
      });

      test('should get media by file type', () async {
        final mockMedia = [
          {
            'id': 'media_1',
            'title': 'Video 1',
            'file_type': 'video',
          },
          {
            'id': 'media_2',
            'title': 'Video 2',
            'file_type': 'video',
          },
        ];

        when(mockSupabaseClient.from('media'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select())
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.eq('file_type', 'video'))
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.eq('is_private', false))
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.order('created_at', descending: true))
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.limit(20))
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.thenAnswer((_) async => mockMedia))
            .thenAnswer((_) async => mockMedia);

        final result = await mediaRepository.getMediaByFileType('video', limit: 20);
        
        expect(result.length, 2);
        expect(result.every((m) => m['file_type'] == 'video'), true);
        verify(mockTransformBuilder.eq('file_type', 'video')).called(1);
      });

      test('should get media by tags', () async {
        final mockMedia = [
          {
            'id': 'media_1',
            'title': 'Tagged Media 1',
            'tags': ['music', 'playlist'],
          },
          {
            'id': 'media_2',
            'title': 'Tagged Media 2',
            'tags': ['music', 'favorites'],
          },
        ];

        when(mockSupabaseClient.from('media'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select())
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.contains('tags', ['music']))
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.eq('is_private', false))
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.order('created_at', descending: true))
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.thenAnswer((_) async => mockMedia))
            .thenAnswer((_) async => mockMedia);

        final result = await mediaRepository.getMediaByTags(['music']);
        
        expect(result.length, 2);
        expect(result.every((m) => (m['tags'] as List).contains('music')), true);
        verify(mockTransformBuilder.contains('tags', ['music'])).called(1);
      });
    });

    group('Media Analytics', () {
      test('should increment view count', () async {
        when(mockSupabaseClient.rpc('increment_view_count'))
            .thenAnswer((_) async => {'view_count': 101});

        final result = await mediaRepository.incrementViewCount('media_1');
        
        expect(result, 101);
        verify(mockSupabaseClient.rpc('increment_view_count')).called(1);
      });

      test('should increment like count', () async {
        when(mockSupabaseClient.rpc('increment_like_count'))
            .thenAnswer((_) async => {'like_count': 51});

        final result = await mediaRepository.incrementLikeCount('media_1');
        
        expect(result, 51);
        verify(mockSupabaseClient.rpc('increment_like_count')).called(1);
      });

      test('should increment share count', () async {
        when(mockSupabaseClient.rpc('increment_share_count'))
            .thenAnswer((_) async => {'share_count': 26});

        final result = await mediaRepository.incrementShareCount('media_1');
        
        expect(result, 26);
        verify(mockSupabaseClient.rpc('increment_share_count')).called(1);
      });

      test('should get media analytics', () async {
        final mockAnalytics = {
          'id': 'media_1',
          'view_count': 1000,
          'like_count': 100,
          'share_count': 50,
          'comment_count': 25,
          'download_count': 10,
          'average_watch_time': 85.5,
          'completion_rate': 0.75,
        };

        when(mockSupabaseClient.from('media_analytics'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select())
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.eq('media_id', 'media_1'))
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.single())
            .thenAnswer((_) async => mockAnalytics);

        final result = await mediaRepository.getMediaAnalytics('media_1');
        
        expect(result, isNotNull);
        expect(result!['view_count'], 1000);
        expect(result['like_count'], 100);
        verify(mockTransformBuilder.eq('media_id', 'media_1')).called(1);
      });
    });

    group('Media Interactions', () {
      test('should like media', () async {
        final likeData = {
          'media_id': 'media_1',
          'user_id': 'user_1',
          'created_at': DateTime.now().toIso8601String(),
        };

        when(mockSupabaseClient.from('media_likes'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.insert(likeData))
            .thenAnswer((_) async => {'id': 'like_1'});

        final result = await mediaRepository.likeMedia('media_1', 'user_1');
        
        expect(result, isNotNull);
        expect(result!['id'], 'like_1');
        verify(mockFilterBuilder.insert(likeData)).called(1);
      });

      test('should unlike media', () async {
        when(mockSupabaseClient.from('media_likes'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('media_id', 'media_1'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.eq('user_id', 'user_1'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.delete())
            .thenAnswer((_) async => []);

        await mediaRepository.unlikeMedia('media_1', 'user_1');
        
        verify(mockFilterBuilder.eq('media_id', 'media_1')).called(1);
        verify(mockFilterBuilder.eq('user_id', 'user_1')).called(1);
        verify(mockFilterBuilder.delete()).called(1);
      });

      test('should check if user liked media', () async {
        final mockLike = {
          'id': 'like_1',
          'media_id': 'media_1',
          'user_id': 'user_1',
        };

        when(mockSupabaseClient.from('media_likes'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select())
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.eq('media_id', 'media_1'))
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.eq('user_id', 'user_1'))
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.maybeSingle())
            .thenAnswer((_) async => mockLike);

        final result = await mediaRepository.isUserLikedMedia('media_1', 'user_1');
        
        expect(result, true);
        verify(mockTransformBuilder.eq('media_id', 'media_1')).called(1);
        verify(mockTransformBuilder.eq('user_id', 'user_1')).called(1);
        verify(mockTransformBuilder.maybeSingle()).called(1);
      });

      test('should get user liked media', () async {
        final mockLikedMedia = [
          {
            'media_id': 'media_1',
            'user_id': 'user_1',
            'created_at': DateTime.now().toIso8601String(),
          },
          {
            'media_id': 'media_2',
            'user_id': 'user_1',
            'created_at': DateTime.now().toIso8601String(),
          },
        ];

        when(mockSupabaseClient.from('media_likes'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select())
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.eq('user_id', 'user_1'))
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.order('created_at', descending: true))
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.thenAnswer((_) async => mockLikedMedia))
            .thenAnswer((_) async => mockLikedMedia);

        final result = await mediaRepository.getUserLikedMedia('user_1');
        
        expect(result.length, 2);
        expect(result.every((like) => like['user_id'] == 'user_1'), true);
        verify(mockTransformBuilder.eq('user_id', 'user_1')).called(1);
      });
    });

    group('Real-time Operations', () {
      test('should get media stream for creator', () async {
        final mockMedia = [
          {
            'id': 'media_1',
            'title': 'Stream Media',
            'creator_id': 'creator_1',
            'created_at': DateTime.now().toIso8601String(),
          },
        ];

        when(mockSupabaseClient.from('media'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.stream(primaryKey: ['id']))
            .thenAnswer((_) => Stream.value(mockMedia));
        when(mockFilterBuilder.eq('creator_id', 'creator_1'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.order('created_at', descending: true))
            .thenReturn(mockFilterBuilder);

        final stream = mediaRepository.getMediaStream('creator_1');
        
        expect(stream, isA<Stream<List<Map<String, dynamic>>>>());
        
        final results = await stream.first;
        expect(results.length, 1);
        expect(results.first['creator_id'], 'creator_1');
      });

      test('should get public media stream', () async {
        final mockMedia = [
          {
            'id': 'media_1',
            'title': 'Public Stream Media',
            'is_private': false,
            'created_at': DateTime.now().toIso8601String(),
          },
        ];

        when(mockSupabaseClient.from('media'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.stream(primaryKey: ['id']))
            .thenAnswer((_) => Stream.value(mockMedia));
        when(mockFilterBuilder.eq('is_private', false))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.order('created_at', descending: true))
            .thenReturn(mockFilterBuilder);

        final stream = mediaRepository.getPublicMediaStream();
        
        expect(stream, isA<Stream<List<Map<String, dynamic>>>>());
        
        final results = await stream.first;
        expect(results.length, 1);
        expect(results.first['is_private'], false);
      });
    });

    group('File Operations', () {
      test('should upload file to storage', () async {
        final mockFileData = [1, 2, 3, 4, 5];
        final mockResponse = {
          'Key': 'media/user_1/video.mp4',
          'ETag': '"abc123"',
        };

        when(mockSupabaseClient.storage.from('media'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.upload('user_1/video.mp4', mockFileData))
            .thenAnswer((_) async => mockResponse);

        final result = await mediaRepository.uploadFile('user_1/video.mp4', mockFileData);
        
        expect(result, isNotNull);
        expect(result!['Key'], 'media/user_1/video.mp4');
        verify(mockFilterBuilder.upload('user_1/video.mp4', mockFileData)).called(1);
      });

      test('should delete file from storage', () async {
        when(mockSupabaseClient.storage.from('media'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.remove(['user_1/video.mp4']))
            .thenAnswer((_) async => []);

        await mediaRepository.deleteFile('user_1/video.mp4');
        
        verify(mockFilterBuilder.remove(['user_1/video.mp4'])).called(1);
      });

      test('should get public URL for file', () async {
        final expectedUrl = 'https://example.com/storage/v1/object/public/media/user_1/video.mp4';
        
        when(mockSupabaseClient.storage.from('media'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.getPublicUrl('user_1/video.mp4'))
            .thenReturn(expectedUrl);

        final result = mediaRepository.getPublicUrl('user_1/video.mp4');
        
        expect(result, expectedUrl);
        verify(mockFilterBuilder.getPublicUrl('user_1/video.mp4')).called(1);
      });
    });

    group('Error Handling', () {
      test('should handle database connection errors', () async {
        when(mockSupabaseClient.from('media'))
            .thenThrow(Exception('Connection failed'));

        expect(
          () => mediaRepository.getMediaByCreator('creator_1'),
          throwsException,
        );
      });

      test('should handle invalid media data', () async {
        final invalidData = {
          'invalid': 'data',
        };

        when(mockSupabaseClient.from('media'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.insert(invalidData))
            .thenThrow(PostgrestException(message: 'Invalid data'));

        expect(
          () => mediaRepository.uploadMediaMetadata(invalidData),
          throwsA(isA<PostgrestException>()),
        );
      });

      test('should handle null parameters gracefully', () {
        expect(
          () => mediaRepository.getMediaById(''),
          returnsNormally,
        );
      });
    });

    group('Batch Operations', () {
      test('should get multiple media by IDs', () async {
        final mediaIds = ['media_1', 'media_2', 'media_3'];
        final mockMedia = [
          {'id': 'media_1', 'title': 'Media 1'},
          {'id': 'media_2', 'title': 'Media 2'},
          {'id': 'media_3', 'title': 'Media 3'},
        ];

        when(mockSupabaseClient.from('media'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.select())
            .thenReturn(mockTransformBuilder);
        when(mockFilterBuilder.in_('id', mediaIds))
            .thenReturn(mockFilterBuilder);
        when(mockTransformBuilder.order('created_at', descending: true))
            .thenReturn(mockTransformBuilder);
        when(mockTransformBuilder.thenAnswer((_) async => mockMedia))
            .thenAnswer((_) async => mockMedia);

        final result = await mediaRepository.getMultipleMediaByIds(mediaIds);
        
        expect(result.length, 3);
        expect(result.map((m) => m['id']).toList(), containsAll(mediaIds));
        verify(mockFilterBuilder.in_('id', mediaIds)).called(1);
      });

      test('should delete multiple media', () async {
        final mediaIds = ['media_1', 'media_2'];

        when(mockSupabaseClient.from('media'))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.in_('id', mediaIds))
            .thenReturn(mockFilterBuilder);
        when(mockFilterBuilder.delete())
            .thenAnswer((_) async => []);

        await mediaRepository.deleteMultipleMedia(mediaIds);
        
        verify(mockFilterBuilder.in_('id', mediaIds)).called(1);
        verify(mockFilterBuilder.delete()).called(1);
      });
    });
  });
}
