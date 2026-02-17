import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mycircle/repositories/collection_repository.dart';
import 'package:mycircle/models/collection.dart';
import 'package:mycircle/models/media_item.dart';

import '../mocks/supabase_client_mock.dart';

@GenerateMocks([SupabaseClient])
void main() {
  group('CollectionRepository', () {
    late CollectionRepository repository;
    late MockSupabaseClient mockSupabaseClient;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      repository = CollectionRepository(mockSupabaseClient);
    });

    group('getCollections', () {
      final testCollections = [
        _createTestCollection('1', 'Test Collection 1'),
        _createTestCollection('2', 'Test Collection 2'),
      ];

      test('should return collections successfully', () async {
        // Arrange
        final mockResponse = PostgrestResponse(
          data: testCollections.map((c) => c.toJson()).toList(),
        );
        
        when(mockSupabaseClient.from('collections'))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').select(any))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').select(any).eq(any, any))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').select(any).eq(any, any).order(any, ascending: any))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').select(any).eq(any, any).order(any, ascending: any).range(any, any))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await repository.getCollections('user1');

        // Assert
        expect(result.length, 2);
        expect(result.first.id, '1');
        expect(result.first.title, 'Test Collection 1');
      });

      test('should throw CollectionException on error', () async {
        // Arrange
        when(mockSupabaseClient.from('collections'))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').select(any))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').select(any).eq(any, any))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').select(any).eq(any, any).order(any, ascending: any))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').select(any).eq(any, any).order(any, ascending: any).range(any, any))
            .thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => repository.getCollections('user1'),
          throwsA(isA<CollectionException>()),
        );
      });

      test('should handle pagination parameters correctly', () async {
        // Arrange
        final mockResponse = PostgrestResponse(
          data: testCollections.map((c) => c.toJson()).toList(),
        );
        
        when(mockSupabaseClient.from('collections').select(any).eq(any, any).order(any, ascending: any).range(10, 29))
            .thenAnswer((_) async => mockResponse);

        // Act
        await repository.getCollections('user1', limit: 20, offset: 10);

        // Assert
        verify(mockSupabaseClient.from('collections').select(any).eq(any, any).order(any, ascending: any).range(10, 29)).called(1);
      });
    });

    group('getCollection', () {
      final testCollection = _createTestCollection('1', 'Test Collection');

      test('should return single collection successfully', () async {
        // Arrange
        final mockResponse = PostgrestResponse(
          data: testCollection.toJson(),
        );
        
        when(mockSupabaseClient.from('collections'))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').select(any))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').select(any).eq(any, any))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').select(any).eq(any, any).single())
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await repository.getCollection('1');

        // Assert
        expect(result?.id, '1');
        expect(result?.title, 'Test Collection');
      });

      test('should return null when collection not found', () async {
        // Arrange
        when(mockSupabaseClient.from('collections'))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').select(any))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').select(any).eq(any, any))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').select(any).eq(any, any).single())
            .thenThrow(Exception('No rows found'));

        // Act
        final result = await repository.getCollection('nonexistent');

        // Assert
        expect(result, isNull);
      });

      test('should include user following status when userId provided', () async {
        // Arrange
        final collectionWithFollowing = testCollection.copyWith(isFollowing: true);
        final mockResponse = PostgrestResponse(
          data: collectionWithFollowing.toJson(),
        );
        
        when(mockSupabaseClient.from('collections'))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').select(any))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').select(any).eq(any, any))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').select(any).eq(any, any).single())
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await repository.getCollection('1', userId: 'user1');

        // Assert
        expect(result?.isFollowing, isTrue);
      });
    });

    group('createCollection', () {
      final testCollection = _createTestCollection('1', 'New Collection');

      test('should create collection successfully', () async {
        // Arrange
        final mockResponse = PostgrestResponse(
          data: testCollection.toJson(),
        );
        
        when(mockSupabaseClient.from('collections'))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').insert(any))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').insert(any).select(any))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await repository.createCollection(testCollection);

        // Assert
        expect(result.id, '1');
        expect(result.title, 'New Collection');
        verify(mockSupabaseClient.from('collections').insert(any).select(any)).called(1);
      });

      test('should remove id, owner_name, owner_avatar, and is_following from insert data', () async {
        // Arrange
        when(mockSupabaseClient.from('collections'))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').insert(any))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').insert(any).select(any))
            .thenAnswer((_) async => PostgrestResponse(data: testCollection.toJson()));

        // Act
        await repository.createCollection(testCollection);

        // Assert
        final captured = verify(mockSupabaseClient.from('collections').insert(captureAny)).captured;
        final insertData = captured.first as Map<String, dynamic>;
        
        expect(insertData.containsKey('id'), isFalse);
        expect(insertData.containsKey('owner_name'), isFalse);
        expect(insertData.containsKey('owner_avatar'), isFalse);
        expect(insertData.containsKey('is_following'), isFalse);
        expect(insertData.containsKey('title'), isTrue);
        expect(insertData.containsKey('description'), isTrue);
      });

      test('should throw CollectionException on error', () async {
        // Arrange
        when(mockSupabaseClient.from('collections'))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').insert(any))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').insert(any).select(any))
            .thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => repository.createCollection(testCollection),
          throwsA(isA<CollectionException>()),
        );
      });
    });

    group('updateCollection', () {
      final testCollection = _createTestCollection('1', 'Updated Collection');

      test('should update collection successfully', () async {
        // Arrange
        final mockResponse = PostgrestResponse(
          data: testCollection.toJson(),
        );
        
        when(mockSupabaseClient.from('collections'))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').update(any))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').update(any).eq(any, any))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').update(any).eq(any, any).select(any))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await repository.updateCollection('1', {'title': 'Updated Title'});

        // Assert
        expect(result.title, 'Updated Collection');
        verify(mockSupabaseClient.from('collections').update(any).eq('id', '1').select(any)).called(1);
      });

      test('should remove protected fields from update data', () async {
        // Arrange
        when(mockSupabaseClient.from('collections'))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').update(any))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').update(any).eq(any, any))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').update(any).eq(any, any).select(any))
            .thenAnswer((_) async => PostgrestResponse(data: testCollection.toJson()));

        final updateData = {
          'id': 'should-be-removed',
          'owner_id': 'should-be-removed',
          'created_at': 'should-be-removed',
          'title': 'should-remain',
          'description': 'should-remain',
        };

        // Act
        await repository.updateCollection('1', updateData);

        // Assert
        final captured = verify(mockSupabaseClient.from('collections').update(captureAny)).captured;
        final cleanUpdateData = captured.first as Map<String, dynamic>;
        
        expect(cleanUpdateData.containsKey('id'), isFalse);
        expect(cleanUpdateData.containsKey('owner_id'), isFalse);
        expect(cleanUpdateData.containsKey('created_at'), isFalse);
        expect(cleanUpdateData.containsKey('title'), isTrue);
        expect(cleanUpdateData.containsKey('description'), isTrue);
        expect(cleanUpdateData.containsKey('updated_at'), isTrue);
      });
    });

    group('deleteCollection', () {
      test('should delete collection successfully', () async {
        // Arrange
        when(mockSupabaseClient.from('collections'))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').delete())
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').delete().eq(any, any))
            .thenAnswer((_) async => PostgrestResponse(data: null));

        // Act
        await repository.deleteCollection('1');

        // Assert
        verify(mockSupabaseClient.from('collections').delete().eq('id', '1')).called(1);
      });

      test('should throw CollectionException on error', () async {
        // Arrange
        when(mockSupabaseClient.from('collections'))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').delete())
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').delete().eq(any, any))
            .thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => repository.deleteCollection('1'),
          throwsA(isA<CollectionException>()),
        );
      });
    });

    group('addMediaToCollection', () {
      test('should add media to collection successfully', () async {
        // Arrange
        when(mockSupabaseClient.from('collection_media'))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collection_media').insert(any))
            .thenAnswer((_) async => PostgrestResponse(data: null));

        // Act
        await repository.addMediaToCollection('collection1', 'media1', 'user1');

        // Assert
        verify(mockSupabaseClient.from('collection_media').insert(argThat(
          allOf([
            containsPair('collection_id', 'collection1'),
            containsPair('media_id', 'media1'),
            containsPair('added_by', 'user1'),
            containsPair('position', 0),
          ]),
        ))).called(1);
      });

      test('should calculate next position correctly', () async {
        // Arrange
        final mockResponse = PostgrestResponse(
          data: [{'position': 2}], // Max position is 2
        );
        
        when(mockSupabaseClient.from('collection_media'))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collection_media').select(any))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collection_media').select(any).eq(any, any))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collection_media').select(any).eq(any, any).order(any, ascending: any))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collection_media').select(any).eq(any, any).order(any, ascending: any).limit(any))
            .thenAnswer((_) async => mockResponse);
        when(mockSupabaseClient.from('collection_media').insert(any))
            .thenAnswer((_) async => PostgrestResponse(data: null));

        // Act
        await repository.addMediaToCollection('collection1', 'media1', 'user1');

        // Assert
        final captured = verify(mockSupabaseClient.from('collection_media').insert(captureAny)).captured;
        final insertData = captured.first as Map<String, dynamic>;
        expect(insertData['position'], 3); // Next position should be 3
      });
    });

    group('followCollection', () {
      test('should follow collection successfully', () async {
        // Arrange
        when(mockSupabaseClient.from('collection_followers'))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collection_followers').upsert(any, onConflict: any))
            .thenAnswer((_) async => PostgrestResponse(data: null));

        // Act
        await repository.followCollection('collection1', 'user1');

        // Assert
        verify(mockSupabaseClient.from('collection_followers').upsert(argThat(
          allOf([
            containsPair('collection_id', 'collection1'),
            containsPair('user_id', 'user1'),
          ]),
        ), onConflict: 'collection_id,user_id')).called(1);
      });

      test('should throw CollectionException on error', () async {
        // Arrange
        when(mockSupabaseClient.from('collection_followers'))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collection_followers').upsert(any, onConflict: any))
            .thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => repository.followCollection('collection1', 'user1'),
          throwsA(isA<CollectionException>()),
        );
      });
    });

    group('searchCollections', () {
      final testCollections = [
        _createTestCollection('1', 'Search Result 1'),
        _createTestCollection('2', 'Search Result 2'),
      ];

      test('should search collections successfully', () async {
        // Arrange
        final mockResponse = PostgrestResponse(
          data: testCollections.map((c) => c.toJson()).toList(),
        );
        
        when(mockSupabaseClient.from('collections'))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').select(any))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').select(any).eq(any, any))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').select(any).eq(any, any).or(any))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').select(any).eq(any, any).or(any).order(any, ascending: any))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').select(any).eq(any, any).or(any).order(any, ascending: any).range(any, any))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await repository.searchCollections('test query');

        // Assert
        expect(result.length, 2);
        expect(result.first.title, 'Search Result 1');
        verify(mockSupabaseClient.from('collections').select(any).eq(any, any).or(any).order(any, ascending: any).range(0, 19)).called(1);
      });

      test('should build correct search filter', () async {
        // Arrange
        when(mockSupabaseClient.from('collections'))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').select(any))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').select(any).eq(any, any))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').select(any).eq(any, any).or(any))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').select(any).eq(any, any).or(any).order(any, ascending: any))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').select(any).eq(any, any).or(any).order(any, ascending: any).range(any, any))
            .thenAnswer((_) async => PostgrestResponse(data: []));

        // Act
        await repository.searchCollections('test query');

        // Assert
        final captured = verify(mockSupabaseClient.from('collections').select(any).eq(any, any).or(captureAny)).captured;
        final searchFilter = captured.first as String;
        
        expect(searchFilter, contains('title.ilike.%test query%'));
        expect(searchFilter, contains('description.ilike.%test query%'));
      });
    });

    group('getFeaturedCollections', () {
      final testCollections = [
        _createTestCollection('1', 'Featured Collection 1'),
        _createTestCollection('2', 'Featured Collection 2'),
      ];

      test('should get featured collections successfully', () async {
        // Arrange
        final mockResponse = PostgrestResponse(
          data: testCollections.map((c) => c.toJson()).toList(),
        );
        
        when(mockSupabaseClient.from('collections'))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').select(any))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').select(any).eq(any, any))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').select(any).eq(any, any).eq(any, any))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').select(any).eq(any, any).eq(any, any).order(any, ascending: any))
            .thenReturn(PostgrestFilterBuilder());
        when(mockSupabaseClient.from('collections').select(any).eq(any, any).eq(any, any).order(any, ascending: any).limit(any))
            .thenAnswer((_) async => mockResponse);

        // Act
        final result = await repository.getFeaturedCollections(limit: 10);

        // Assert
        expect(result.length, 2);
        verify(mockSupabaseClient.from('collections').select(any).eq(any, any).eq(any, any).order(any, ascending: any).limit(10)).called(1);
      });
    });

    group('Analytics Methods', () {
      test('should track collection view without throwing error', () async {
        // Arrange
        when(mockSupabaseClient.rpc('track_collection_view', params: anyNamed('params')))
            .thenAnswer((_) async => PostgrestResponse(data: null));

        // Act & Assert - should not throw
        await repository.trackCollectionView('collection1');

        verify(mockSupabaseClient.rpc('track_collection_view', params: {'p_collection_id': 'collection1'})).called(1);
      });

      test('should not throw on analytics tracking errors', () async {
        // Arrange
        when(mockSupabaseClient.rpc('track_collection_view', params: anyNamed('params')))
            .thenThrow(Exception('Analytics error'));

        // Act & Assert - should not throw
        await repository.trackCollectionView('collection1');

        verify(mockSupabaseClient.rpc('track_collection_view', params: {'p_collection_id': 'collection1'})).called(1);
      });

      test('should track collection like without throwing error', () async {
        // Arrange
        when(mockSupabaseClient.rpc('track_collection_like', params: anyNamed('params')))
            .thenAnswer((_) async => PostgrestResponse(data: null));

        // Act & Assert - should not throw
        await repository.trackCollectionLike('collection1');

        verify(mockSupabaseClient.rpc('track_collection_like', params: {'p_collection_id': 'collection1'})).called(1);
      });
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
