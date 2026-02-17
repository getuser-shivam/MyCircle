import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:my_circle/providers/enhanced_stream_provider.dart';
import 'package:my_circle/repositories/stream_repository.dart';
import 'package:my_circle/models/stream_model.dart';
import 'package:my_circle/models/stream_chat_model.dart';

import 'enhanced_stream_provider_test.mocks.dart';

@GenerateMocks([StreamRepository, LiveStream, StreamChatMessage])
void main() {
  group('EnhancedStreamProvider', () {
    late EnhancedStreamProvider provider;
    late MockStreamRepository mockStreamRepository;

    setUp(() {
      mockStreamRepository = MockStreamRepository();
      provider = EnhancedStreamProvider();
      provider._streamRepository = mockStreamRepository;
    });

    group('Initial State', () {
      test('should start with correct initial state', () {
        expect(provider.liveStreams, isEmpty);
        expect(provider.userStreams, isEmpty);
        expect(provider.currentStream, isNull);
        expect(provider.chatMessages, isEmpty);
        expect(provider.isLoading, isFalse);
        expect(provider.isCreatingStream, isFalse);
        expect(provider.hasMore, isTrue);
        expect(provider.error, isNull);
        expect(provider.selectedCategory, 'All');
        expect(provider.searchQuery, isEmpty);
      });
    });

    group('loadLiveStreams', () {
      test('should load live streams successfully', () async {
        // Arrange
        final mockStreams = [
          createMockStream('1', 'Live Stream 1'),
          createMockStream('2', 'Live Stream 2'),
        ];
        
        when(mockStreamRepository.getLiveStreams(
          status: StreamStatus.live,
          limit: 20,
          offset: 0,
        )).thenAnswer((_) async => mockStreams);

        // Act
        await provider.loadLiveStreams();

        // Assert
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNull);
        expect(provider.liveStreams.length, 2);
        expect(provider.liveStreams[0].title, 'Live Stream 1');
        expect(provider.currentPage, 1);
        expect(provider.hasMore, isTrue);
        
        verify(mockStreamRepository.getLiveStreams(
          status: StreamStatus.live,
          limit: 20,
          offset: 0,
        )).called(1);
      });

      test('should not load if already loading', () async {
        // Arrange
        provider._isLoading = true;
        
        // Act
        await provider.loadLiveStreams();

        // Assert
        verifyNever(mockStreamRepository.getLiveStreams(any));
      });

      test('should handle empty response correctly', () async {
        // Arrange
        when(mockStreamRepository.getLiveStreams(
          status: StreamStatus.live,
          limit: 20,
          offset: 0,
        )).thenAnswer((_) async => []);

        // Act
        await provider.loadLiveStreams();

        // Assert
        expect(provider.liveStreams, isEmpty);
        expect(provider.hasMore, isFalse);
      });

      test('should set error when loading fails', () async {
        // Arrange
        when(mockStreamRepository.getLiveStreams(any))
            .thenThrow(Exception('Network error'));

        // Act
        await provider.loadLiveStreams();

        // Assert
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNotNull);
        expect(provider.error, contains('Failed to load live streams'));
        expect(provider.liveStreams, isEmpty);
      });

      test('should refresh when refresh=true', () async {
        // Arrange
        provider._currentPage = 2;
        provider._hasMore = false;
        provider._liveStreams = [createMockStream('1', 'Old Stream')];
        
        when(mockStreamRepository.getLiveStreams(
          status: StreamStatus.live,
          limit: 20,
          offset: 0,
        )).thenAnswer((_) async => [createMockStream('2', 'New Stream')]);

        // Act
        await provider.loadLiveStreams(refresh: true);

        // Assert
        expect(provider.currentPage, 1);
        expect(provider.hasMore, isTrue);
        expect(provider.liveStreams.length, 1);
        expect(provider.liveStreams[0].title, 'New Stream');
      });
    });

    group('loadUserStreams', () {
      test('should load user streams successfully', () async {
        // Arrange
        final mockUserStreams = [
          createMockStream('1', 'User Stream 1'),
          createMockStream('2', 'User Stream 2'),
        ];
        
        when(mockStreamRepository.getUserStreams('user123', limit: 20))
            .thenAnswer((_) async => mockUserStreams);

        // Act
        await provider.loadUserStreams('user123');

        // Assert
        expect(provider.isLoadingUserStreams, isFalse);
        expect(provider.userStreamsError, isNull);
        expect(provider.userStreams.length, 2);
        expect(provider.userStreams[0].title, 'User Stream 1');
        
        verify(mockStreamRepository.getUserStreams('user123', limit: 20)).called(1);
      });

      test('should set error when user streams load fails', () async {
        // Arrange
        when(mockStreamRepository.getUserStreams(any, limit: anyNamed('limit')))
            .thenThrow(Exception('User streams load failed'));

        // Act
        await provider.loadUserStreams('user123');

        // Assert
        expect(provider.isLoadingUserStreams, isFalse);
        expect(provider.userStreamsError, isNotNull);
        expect(provider.userStreamsError, contains('Failed to load user streams'));
        expect(provider.userStreams, isEmpty);
      });
    });

    group('loadStream', () {
      test('should load specific stream successfully', () async {
        // Arrange
        final mockStream = createMockStream('1', 'Specific Stream');
        final mockMessages = [
          createMockChatMessage('1', 'Hello'),
          createMockChatMessage('2', 'World'),
        ];
        
        when(mockStreamRepository.getStream('1'))
            .thenAnswer((_) async => mockStream);
        when(mockStreamRepository.getStreamMessages('1'))
            .thenAnswer((_) async => mockMessages);

        // Act
        await provider.loadStream('1');

        // Assert
        expect(provider.isLoadingCurrent, isFalse);
        expect(provider.currentError, isNull);
        expect(provider.currentStream, isNotNull);
        expect(provider.currentStream!.id, '1');
        expect(provider.currentStream!.title, 'Specific Stream');
        expect(provider.chatMessages.length, 2);
        
        verify(mockStreamRepository.getStream('1')).called(1);
        verify(mockStreamRepository.getStreamMessages('1')).called(1);
      });

      test('should set error when specific stream load fails', () async {
        // Arrange
        when(mockStreamRepository.getStream('999'))
            .thenThrow(Exception('Stream not found'));

        // Act
        await provider.loadStream('999');

        // Assert
        expect(provider.isLoadingCurrent, isFalse);
        expect(provider.currentError, isNotNull);
        expect(provider.currentError, contains('Failed to load stream'));
        expect(provider.currentStream, isNull);
      });
    });

    group('createStream', () {
      test('should create stream successfully', () async {
        // Arrange
        final mockStream = createMockStream('1', 'New Stream');
        
        when(mockStreamRepository.createStream(
          title: 'New Stream',
          description: 'New Description',
          thumbnailUrl: 'thumb.jpg',
          streamUrl: 'stream.mp4',
          streamKey: 'key123',
          quality: 'high',
          tags: ['gaming'],
          category: 'Gaming',
          isPrivate: false,
          isRecorded: true,
        )).thenAnswer((_) async => mockStream);

        // Act
        await provider.createStream(
          title: 'New Stream',
          description: 'New Description',
          thumbnailUrl: 'thumb.jpg',
          streamUrl: 'stream.mp4',
          streamKey: 'key123',
          quality: StreamQuality.high,
          tags: ['gaming'],
          category: 'Gaming',
        );

        // Assert
        expect(provider.isCreatingStream, isFalse);
        expect(provider.createError, isNull);
        expect(provider.currentStream, isNotNull);
        expect(provider.currentStream!.title, 'New Stream');
        
        verify(mockStreamRepository.createStream(
          title: 'New Stream',
          description: 'New Description',
          thumbnailUrl: 'thumb.jpg',
          streamUrl: 'stream.mp4',
          streamKey: 'key123',
          quality: 'high',
          tags: ['gaming'],
          category: 'Gaming',
          isPrivate: false,
          isRecorded: true,
        )).called(1);
      });

      test('should set error when stream creation fails', () async {
        // Arrange
        when(mockStreamRepository.createStream(any))
            .thenThrow(Exception('Stream creation failed'));

        // Act
        await provider.createStream(
          title: 'Test Stream',
          description: 'Test Description',
          thumbnailUrl: 'thumb.jpg',
          streamUrl: 'stream.mp4',
          streamKey: 'key123',
          quality: StreamQuality.high,
          tags: [],
          category: 'Test',
        );

        // Assert
        expect(provider.isCreatingStream, isFalse);
        expect(provider.createError, isNotNull);
        expect(provider.createError, contains('Failed to create stream'));
        expect(provider.currentStream, isNull);
      });
    });

    group('updateStream', () {
      test('should update stream successfully', () async {
        // Arrange
        final mockUpdatedStream = createMockStream('1', 'Updated Stream');
        mockUpdatedStream.status = StreamStatus.live;
        
        when(mockStreamRepository.updateStream('1', title: 'Updated Stream'))
            .thenAnswer((_) async => mockUpdatedStream);

        // Act
        await provider.updateStream('1', title: 'Updated Stream');

        // Assert
        verify(mockStreamRepository.updateStream('1', title: 'Updated Stream')).called(1);
      });

      test('should handle update errors', () async {
        // Arrange
        when(mockStreamRepository.updateStream(any, title: anyNamed('title')))
            .thenThrow(Exception('Update failed'));

        // Act & Assert
        expect(
          () => provider.updateStream('1', title: 'Updated Stream'),
          throwsException,
        );
      });
    });

    group('endStream', () {
      test('should end stream successfully', () async {
        // Arrange
        when(mockStreamRepository.endStream('1')).thenAnswer((_) async {});

        // Act
        await provider.endStream('1');

        // Assert
        verify(mockStreamRepository.endStream('1')).called(1);
      });

      test('should handle end stream errors', () async {
        // Arrange
        when(mockStreamRepository.endStream('1'))
            .thenThrow(Exception('End stream failed'));

        // Act & Assert
        expect(
          () => provider.endStream('1'),
          throwsException,
        );
      });
    });

    group('joinStream', () {
      test('should join stream successfully', () async {
        // Arrange
        when(mockStreamRepository.joinStream('1')).thenAnswer((_) async {});

        // Act
        await provider.joinStream('1');

        // Assert
        expect(provider.isJoined('1'), isTrue);
        verify(mockStreamRepository.joinStream('1')).called(1);
      });

      test('should handle join stream errors', () async {
        // Arrange
        when(mockStreamRepository.joinStream('1'))
            .thenThrow(Exception('Join failed'));

        // Act & Assert
        expect(
          () => provider.joinStream('1'),
          throwsException,
        );
        expect(provider.isJoined('1'), isFalse);
      });
    });

    group('leaveStream', () {
      test('should leave stream successfully', () async {
        // Arrange
        provider._joinedStreams['1'] = true;
        when(mockStreamRepository.leaveStream('1')).thenAnswer((_) async {});

        // Act
        await provider.leaveStream('1');

        // Assert
        expect(provider.isJoined('1'), isFalse);
        verify(mockStreamRepository.leaveStream('1')).called(1);
      });

      test('should handle leave stream errors', () async {
        // Arrange
        provider._joinedStreams['1'] = true;
        when(mockStreamRepository.leaveStream('1'))
            .thenThrow(Exception('Leave failed'));

        // Act & Assert
        expect(
          () => provider.leaveStream('1'),
          throwsException,
        );
      });
    });

    group('sendMessage', () {
      test('should send message successfully', () async {
        // Arrange
        final mockStream = createMockStream('1', 'Test Stream');
        final mockMessage = createMockChatMessage('1', 'Hello World');
        
        provider._currentStream = mockStream;
        when(mockStreamRepository.sendStreamMessage(
          streamId: '1',
          message: 'Hello World',
        )).thenAnswer((_) async => mockMessage);

        // Act
        await provider.sendMessage('Hello World');

        // Assert
        expect(provider.chatMessages.length, 1);
        expect(provider.chatMessages[0].message, 'Hello World');
        verify(mockStreamRepository.sendStreamMessage(
          streamId: '1',
          message: 'Hello World',
        )).called(1);
      });

      test('should do nothing when no current stream', () async {
        // Act
        await provider.sendMessage('Test Message');

        // Assert
        verifyNever(mockStreamRepository.sendStreamMessage(
          streamId: anyNamed('streamId'),
          message: anyNamed('message'),
        ));
      });

      test('should handle send message errors', () async {
        // Arrange
        final mockStream = createMockStream('1', 'Test Stream');
        provider._currentStream = mockStream;
        
        when(mockStreamRepository.sendStreamMessage(
          streamId: '1',
          message: 'Test',
        )).thenThrow(Exception('Send failed'));

        // Act & Assert
        expect(
          () => provider.sendMessage('Test'),
          throwsException,
        );
      });
    });

    group('Search and Filter', () {
      test('should set category and reload', () async {
        // Arrange
        when(mockStreamRepository.getLiveStreams(
          status: StreamStatus.live,
          limit: 20,
          offset: 0,
        )).thenAnswer((_) async => []);

        // Act
        provider.setCategory('Gaming');

        // Assert
        expect(provider.selectedCategory, 'Gaming');
        verify(mockStreamRepository.getLiveStreams(
          status: StreamStatus.live,
          limit: 20,
          offset: 0,
        )).called(1);
      });

      test('should clear filters', () {
        // Arrange
        provider._selectedCategory = 'Gaming';
        provider._searchQuery = 'test';

        // Act
        provider.clearFilters();

        // Assert
        expect(provider.selectedCategory, 'All');
        expect(provider.searchQuery, isEmpty);
      });
    });

    group('Utility Methods', () {
      test('should refresh live streams', () async {
        // Arrange
        when(mockStreamRepository.getLiveStreams(
          status: StreamStatus.live,
          limit: 20,
          offset: 0,
        )).thenAnswer((_) async => []);

        // Act
        provider.refresh();

        // Assert
        verify(mockStreamRepository.getLiveStreams(
          status: StreamStatus.live,
          limit: 20,
          offset: 0,
        )).called(1);
      });

      test('should clear current stream', () {
        // Arrange
        provider._currentStream = createMockStream('1', 'Current');
        provider._currentError = 'Some error';
        provider._chatMessages = [createMockChatMessage('1', 'Test')];

        // Act
        provider.clearCurrentStream();

        // Assert
        expect(provider.currentStream, isNull);
        expect(provider.currentError, isNull);
        expect(provider.chatMessages, isEmpty);
      });
    });
  });
}

LiveStream createMockStream(String id, String title) {
  return LiveStream(
    id: id,
    title: title,
    description: 'Test Description',
    streamerId: 'streamer123',
    streamerName: 'teststreamer',
    streamerAvatar: 'https://example.com/avatar.jpg',
    thumbnailUrl: 'https://example.com/thumb.jpg',
    streamUrl: 'https://example.com/stream.mp4',
    streamKey: 'key123',
    status: StreamStatus.live,
    quality: StreamQuality.high,
    viewerCount: 100,
    maxViewers: 1000,
    scheduledAt: DateTime.now(),
    startedAt: DateTime.now(),
    tags: ['test'],
    category: 'Test',
    isPrivate: false,
    isRecorded: true,
    latitude: 0.0,
    longitude: 0.0,
    allowedViewerIds: [],
    metadata: {},
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

StreamChatMessage createMockChatMessage(String id, String message) {
  return StreamChatMessage(
    id: id,
    streamId: 'stream1',
    userId: 'user1',
    username: 'testuser',
    message: message,
    createdAt: DateTime.now(),
  );
}

// Extension to access private members for testing
extension EnhancedStreamProviderTestExtension on EnhancedStreamProvider {
  set _streamRepository(StreamRepository repository) => this._streamRepository = repository;
  set _isLoading(bool loading) => this._isLoading = loading;
  set _hasMore(bool hasMore) => this._hasMore = hasMore;
  set _currentPage(int page) => this._currentPage = page;
  set _liveStreams(List<LiveStream> streams) => this._liveStreams = streams;
  set _joinedStreams(Map<String, bool> joined) => this._joinedStreams = joined;
  set _selectedCategory(String category) => this._selectedCategory = category;
  set _searchQuery(String query) => this._searchQuery = query;
  set _currentStream(LiveStream? stream) => this._currentStream = stream;
  set _currentError(String? error) => this._currentError = error;
  set _chatMessages(List<StreamChatMessage> messages) => this._chatMessages = messages;
}
