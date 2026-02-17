import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:my_circle/domain/entities/stream_entity.dart';
import 'package:my_circle/domain/repositories/stream_repository_interface.dart';
import 'package:my_circle/domain/usecases/get_live_streams_usecase.dart';

import 'get_live_streams_usecase_test.mocks.dart';

@GenerateMocks([StreamRepositoryInterface])
void main() {
  group('GetLiveStreamsUseCase', () {
    late GetLiveStreamsUseCase useCase;
    late MockStreamRepositoryInterface mockRepository;

    setUp(() {
      mockRepository = MockStreamRepositoryInterface();
      useCase = GetLiveStreamsUseCase(mockRepository);
    });

    group('execute', () {
      final testStreams = [
        StreamEntity(
          id: '1',
          title: 'Test Stream 1',
          description: 'Description 1',
          streamerId: 'user1',
          streamerUsername: 'streamer1',
          status: StreamStatus.live,
          viewerCount: 100,
          category: 'gaming',
          quality: StreamQuality.high,
          tags: ['gaming', 'live'],
          isPrivate: false,
          isRecorded: true,
          maxViewers: 500,
          latitude: 0.0,
          longitude: 0.0,
        ),
        StreamEntity(
          id: '2',
          title: 'Test Stream 2',
          description: 'Description 2',
          streamerId: 'user2',
          streamerUsername: 'streamer2',
          status: StreamStatus.live,
          viewerCount: 200,
          category: 'music',
          quality: StreamQuality.medium,
          tags: ['music', 'live'],
          isPrivate: false,
          isRecorded: true,
          maxViewers: 1000,
          latitude: 0.0,
          longitude: 0.0,
        ),
      ];

      test('should return live streams when repository call succeeds', () async {
        // Arrange
        when(mockRepository.getLiveStreams(
          limit: 20,
          page: 1,
          category: null,
        )).thenAnswer((_) async => testStreams);

        // Act
        final result = await useCase.execute();

        // Assert
        expect(result, equals(testStreams));
        verify(mockRepository.getLiveStreams(
          limit: 20,
          page: 1,
          category: null,
        )).called(1);
      });

      test('should return filtered streams by category', () async {
        // Arrange
        when(mockRepository.getLiveStreams(
          limit: 20,
          page: 1,
          category: 'gaming',
        )).thenAnswer((_) async => testStreams);

        // Act
        final result = await useCase.execute(category: 'gaming');

        // Assert
        expect(result, equals(testStreams));
        verify(mockRepository.getLiveStreams(
          limit: 20,
          page: 1,
          category: 'gaming',
        )).called(1);
      });

      test('should validate limit parameter', () async {
        // Act & Assert
        expect(
          () => useCase.execute(limit: 0),
          throwsA(isA<ArgumentError>()),
        );

        expect(
          () => useCase.execute(limit: 101),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should validate page parameter', () async {
        // Act & Assert
        expect(
          () => useCase.execute(page: 0),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should handle repository exception', () async {
        // Arrange
        when(mockRepository.getLiveStreams(
          limit: 20,
          page: 1,
          category: null,
        )).thenThrow(Exception('Repository error'));

        // Act & Assert
        expect(
          () => useCase.execute(),
          throwsException,
        );
      });

      test('should filter out non-live streams', () async {
        // Arrange
        final mixedStreams = [
          testStreams[0],
          StreamEntity(
            id: '3',
            title: 'Scheduled Stream',
            description: 'Description 3',
            streamerId: 'user3',
            streamerUsername: 'streamer3',
            status: StreamStatus.scheduled, // Not live
            viewerCount: 0,
            category: 'education',
            quality: StreamQuality.auto,
            tags: ['education'],
            isPrivate: false,
            isRecorded: true,
            maxViewers: 200,
            latitude: 0.0,
            longitude: 0.0,
          ),
          testStreams[1],
        ];

        when(mockRepository.getLiveStreams(
          limit: 20,
          page: 1,
          category: null,
        )).thenAnswer((_) async => mixedStreams);

        // Act
        final result = await useCase.execute();

        // Assert
        expect(result.length, equals(2));
        expect(result[0].status, equals(StreamStatus.live));
        expect(result[1].status, equals(StreamStatus.live));
      });

      test('should respect pagination limits', () async {
        // Arrange
        when(mockRepository.getLiveStreams(
          limit: 50,
          page: 2,
          category: null,
        )).thenAnswer((_) async => testStreams);

        // Act
        final result = await useCase.execute(limit: 50, page: 2);

        // Assert
        expect(result, equals(testStreams));
        verify(mockRepository.getLiveStreams(
          limit: 50,
          page: 2,
          category: null,
        )).called(1);
      });
    });
  });
}
