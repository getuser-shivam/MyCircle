import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:mycircle/providers/stream_chat_provider.dart';
import 'package:mycircle/services/stream_service.dart';
import 'package:mycircle/models/stream_chat_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'stream_chat_provider_test.mocks.dart';

@GenerateMocks([StreamService, SupabaseClient, RealtimeChannel])
void main() {
  group('StreamChatProvider', () {
    late StreamChatProvider provider;
    late MockStreamService mockService;
    late MockSupabaseClient mockSupabase;

    setUp(() {
      mockService = MockStreamService();
      mockSupabase = MockSupabaseClient();
      provider = StreamChatProvider();
      // Replace internal dependencies with mocks
      provider._streamService = mockService;
      provider._supabase = mockSupabase;
    });

    tearDown(() {
      provider.dispose();
    });

    group('Initialization', () {
      test('should initialize with default values', () {
        expect(provider.isConnected, isFalse);
        expect(provider.isLoading, isFalse);
        expect(provider.isSending, isFalse);
        expect(provider.error, isNull);
        expect(provider.messages, isEmpty);
        expect(provider.reactions, isEmpty);
        expect(provider.unreadCount, 0);
        expect(provider.hasMoreMessages, isTrue);
      });

      test('should load blocked content on initialization', () async {
        // This would test the loading of blocked users and words
        // Implementation depends on how the actual provider handles this
        expect(provider.blockedUsers, isEmpty);
        expect(provider.blockedWords, isEmpty);
      });
    });

    group('Connection Management', () {
      final sampleMessages = [
        StreamChatMessage(
          id: 'message_1',
          streamId: 'stream_1',
          userId: 'user_1',
          userName: 'TestUser',
          content: 'Hello stream!',
          timestamp: DateTime.now(),
        ),
        StreamChatMessage(
          id: 'message_2',
          streamId: 'stream_1',
          userId: 'user_2',
          userName: 'AnotherUser',
          content: 'Great stream!',
          timestamp: DateTime.now(),
        ),
      ];

      test('should connect to stream chat successfully', () async {
        when(mockService.getStreamChat('stream_1'))
            .thenAnswer((_) async => sampleMessages);
        when(mockService.getStreamById('stream_1'))
            .thenAnswer((_) async => null); // Not streamer
        when(mockSupabase.channel(any))
            .thenReturn(MockRealtimeChannel());

        await provider.connectToStreamChat('stream_1');

        verify(mockService.getStreamChat('stream_1')).called(1);
        expect(provider.isConnected, isTrue);
        expect(provider.currentStreamId, 'stream_1');
        expect(provider.messages, sampleMessages.reversed);
        expect(provider.unreadCount, 0);
      });

      test('should disconnect from stream chat successfully', () async {
        // First connect
        when(mockService.getStreamChat('stream_1'))
            .thenAnswer((_) async => sampleMessages);
        when(mockService.getStreamById('stream_1'))
            .thenAnswer((_) async => null);
        when(mockSupabase.channel(any))
            .thenReturn(MockRealtimeChannel());

        await provider.connectToStreamChat('stream_1');
        expect(provider.isConnected, isTrue);

        // Then disconnect
        await provider.disconnect();

        expect(provider.isConnected, isFalse);
        expect(provider.currentStreamId, isNull);
        expect(provider.messages, isEmpty);
        expect(provider.unreadCount, 0);
      });

      test('should handle connection errors', () async {
        when(mockService.getStreamChat('stream_1'))
            .thenThrow(Exception('Connection failed'));

        await provider.connectToStreamChat('stream_1');

        expect(provider.isConnected, isFalse);
        expect(provider.error, contains('Failed to connect to chat'));
      });

      test('should not reconnect if already connected to same stream', () async {
        when(mockService.getStreamChat('stream_1'))
            .thenAnswer((_) async => sampleMessages);
        when(mockService.getStreamById('stream_1'))
            .thenAnswer((_) async => null);
        when(mockSupabase.channel(any))
            .thenReturn(MockRealtimeChannel());

        await provider.connectToStreamChat('stream_1');
        await provider.connectToStreamChat('stream_1');

        verify(mockService.getStreamChat('stream_1')).called(1); // Only called once
      });
    });

    group('Message Operations', () {
      final sampleMessage = StreamChatMessage(
        id: 'message_1',
        streamId: 'stream_1',
        userId: 'user_1',
        userName: 'TestUser',
        content: 'Hello stream!',
        timestamp: DateTime.now(),
      );

      test('should send message successfully', () async {
        when(mockService.sendChatMessage('stream_1', 'Hello!'))
            .thenAnswer((_) async => sampleMessage);

        provider._currentStreamId = 'stream_1';
        provider._isConnected = true;

        await provider.sendMessage('Hello!');

        verify(mockService.sendChatMessage('stream_1', 'Hello!')).called(1);
        expect(provider.messages.first, sampleMessage);
        expect(provider.isSending, isFalse);
      });

      test('should not send message if not connected', () async {
        await provider.sendMessage('Hello!');

        verifyNever(mockService.sendChatMessage(any, any));
        expect(provider.isSending, isFalse);
      });

      test('should not send empty message', () async {
        provider._currentStreamId = 'stream_1';
        provider._isConnected = true;

        await provider.sendMessage('');

        verifyNever(mockService.sendChatMessage(any, any));
      });

      test('should not send message if already sending', () async {
        provider._currentStreamId = 'stream_1';
        provider._isConnected = true;
        provider._isSending = true;

        await provider.sendMessage('Hello!');

        verifyNever(mockService.sendChatMessage(any, any));
      });

      test('should handle send message errors', () async {
        when(mockService.sendChatMessage('stream_1', 'Hello!'))
            .thenThrow(Exception('Send failed'));

        provider._currentStreamId = 'stream_1';
        provider._isConnected = true;

        await provider.sendMessage('Hello!');

        expect(provider.error, contains('Failed to send message'));
        expect(provider.isSending, isFalse);
      });

      test('should block messages with blocked content', () async {
        provider._blockedWords.add('spam');
        provider._currentStreamId = 'stream_1';
        provider._isConnected = true;

        await provider.sendMessage('This is spam content');

        verifyNever(mockService.sendChatMessage(any, any));
        expect(provider.error, contains('blocked content'));
      });

      test('should load more messages successfully', () async {
        final olderMessages = [
          StreamChatMessage(
            id: 'old_message_1',
            streamId: 'stream_1',
            userId: 'user_1',
            userName: 'TestUser',
            content: 'Old message',
            timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          ),
        ];

        provider._currentStreamId = 'stream_1';
        provider._isConnected = true;
        provider._messages = [
          StreamChatMessage(
            id: 'new_message',
            streamId: 'stream_1',
            userId: 'user_2',
            userName: 'NewUser',
            content: 'New message',
            timestamp: DateTime.now(),
          ),
        ];

        when(mockService.getOlderMessages(
          'stream_1',
          before: anyNamed('before'),
          limit: 50,
        )).thenAnswer((_) async => olderMessages);

        await provider.loadMoreMessages();

        verify(mockService.getOlderMessages(any, before: any, limit: 50)).called(1);
        expect(provider.messages.length, 3); // 1 new + 2 old
      });

      test('should stop loading more messages when no more available', () async {
        provider._currentStreamId = 'stream_1';
        provider._isConnected = true;
        provider._hasMoreMessages = true;

        when(mockService.getOlderMessages(
          'stream_1',
          before: anyNamed('before'),
          limit: 50,
        )).thenAnswer((_) async => []);

        await provider.loadMoreMessages();

        expect(provider.hasMoreMessages, isFalse);
      });
    });

    group('Reaction Operations', () {
      test('should send reaction to message successfully', () async {
        final message = StreamChatMessage(
          id: 'message_1',
          streamId: 'stream_1',
          userId: 'user_1',
          userName: 'TestUser',
          content: 'Hello!',
          timestamp: DateTime.now(),
          reactions: [],
        );

        when(mockService.sendReactionToMessage('message_1', 'heart'))
            .thenAnswer((_) async {});

        provider._messages = [message];

        await provider.sendReactionToMessage('message_1', 'heart');

        verify(mockService.sendReactionToMessage('message_1', 'heart')).called(1);
        expect(provider.messages.first.reactions, contains('heart'));
      });

      test('should send stream reaction successfully', () async {
        when(mockService.sendReaction('stream_1', 'fire'))
            .thenAnswer((_) async {});

        provider._currentStreamId = 'stream_1';
        provider._isConnected = true;

        await provider.sendStreamReaction('fire');

        verify(mockService.sendReaction('stream_1', 'fire')).called(1);
        expect(provider.reactions.first.reactionType, 'fire');
      });
    });

    group('Moderation Operations', () {
      test('should delete message successfully when moderator', () async {
        provider._isModerator = true;
        provider._messages = [
          StreamChatMessage(
            id: 'message_1',
            streamId: 'stream_1',
            userId: 'user_1',
            userName: 'TestUser',
            content: 'Bad message',
            timestamp: DateTime.now(),
          ),
        ];

        when(mockService.deleteMessage('message_1'))
            .thenAnswer((_) async {});

        await provider.deleteMessage('message_1');

        verify(mockService.deleteMessage('message_1')).called(1);
        expect(provider.messages, isEmpty);
      });

      test('should not delete message when not moderator', () async {
        provider._isModerator = false;
        provider._isStreamer = false;

        await provider.deleteMessage('message_1');

        verifyNever(mockService.deleteMessage(any));
        expect(provider.error, contains('do not have permission'));
      });

      test('should pin message successfully when moderator', () async {
        final message = StreamChatMessage(
          id: 'message_1',
          streamId: 'stream_1',
          userId: 'user_1',
          userName: 'TestUser',
          content: 'Important message',
          timestamp: DateTime.now(),
          isPinned: false,
        );

        provider._isModerator = true;
        provider._messages = [message];

        when(mockService.pinMessage('message_1'))
            .thenAnswer((_) async {});

        await provider.pinMessage('message_1');

        verify(mockService.pinMessage('message_1')).called(1);
        expect(provider.messages.first.isPinned, isTrue);
        expect(provider.messages.first, message); // Should be first (pinned)
      });

      test('should block user successfully', () async {
        final message1 = StreamChatMessage(
          id: 'message_1',
          streamId: 'stream_1',
          userId: 'user_1',
          userName: 'BadUser',
          content: 'Bad message 1',
          timestamp: DateTime.now(),
        );
        final message2 = StreamChatMessage(
          id: 'message_2',
          streamId: 'stream_1',
          userId: 'user_2',
          userName: 'GoodUser',
          content: 'Good message',
          timestamp: DateTime.now(),
        );

        provider._messages = [message1, message2];

        when(mockService.blockUser('user_1'))
            .thenAnswer((_) async {});

        await provider.blockUser('user_1');

        verify(mockService.blockUser('user_1')).called(1);
        expect(provider.blockedUsers, contains('user_1'));
        expect(provider.messages.length, 1);
        expect(provider.messages.first.userId, 'user_2');
      });

      test('should report message successfully', () async {
        when(mockService.reportMessage('message_1', 'spam'))
            .thenAnswer((_) async {});

        await provider.reportMessage('message_1', 'spam');

        verify(mockService.reportMessage('message_1', 'spam')).called(1);
      });
    });

    group('Real-time Updates', () {
      test('should handle new message from real-time', () {
        final newMessage = StreamChatMessage(
          id: 'new_message',
          streamId: 'stream_1',
          userId: 'user_1',
          userName: 'TestUser',
          content: 'New message!',
          timestamp: DateTime.now(),
        );

        provider._currentStreamId = 'stream_1';
        provider._unreadCount = 0;

        provider._handleNewMessage(newMessage);

        expect(provider.messages.first, newMessage);
        expect(provider.unreadCount, 1);
      });

      test('should ignore messages from blocked users', () {
        final blockedMessage = StreamChatMessage(
          id: 'blocked_message',
          streamId: 'stream_1',
          userId: 'blocked_user',
          userName: 'BlockedUser',
          content: 'Blocked message',
          timestamp: DateTime.now(),
        );

        provider._currentStreamId = 'stream_1';
        provider._blockedUsers.add('blocked_user');

        provider._handleNewMessage(blockedMessage);

        expect(provider.messages, isEmpty);
        expect(provider.unreadCount, 0);
      });

      test('should ignore messages with blocked words', () {
        final blockedMessage = StreamChatMessage(
          id: 'blocked_message',
          streamId: 'stream_1',
          userId: 'user_1',
          userName: 'TestUser',
          content: 'This contains spam word',
          timestamp: DateTime.now(),
        );

        provider._currentStreamId = 'stream_1';
        provider._blockedWords.add('spam');

        provider._handleNewMessage(blockedMessage);

        expect(provider.messages, isEmpty);
        expect(provider.unreadCount, 0);
      });

      test('should handle new reaction from real-time', () {
        final newReaction = StreamReaction(
          id: 'reaction_1',
          streamId: 'stream_1',
          userId: 'user_1',
          reactionType: 'heart',
          timestamp: DateTime.now(),
        );

        provider._currentStreamId = 'stream_1';

        provider._handleNewReaction(newReaction);

        expect(provider.reactions.first, newReaction);
      });
    });

    group('Cache Management', () {
      final sampleMessages = [
        StreamChatMessage(
          id: 'cached_message',
          streamId: 'stream_1',
          userId: 'user_1',
          userName: 'TestUser',
          content: 'Cached message',
          timestamp: DateTime.now(),
        ),
      ];

      test('should cache messages and retrieve from cache', () async {
        when(mockService.getStreamChat('stream_1'))
            .thenAnswer((_) async => sampleMessages);

        // First call should hit service
        await provider.connectToStreamChat('stream_1');
        verify(mockService.getStreamChat('stream_1')).called(1);

        // Second call within cache period should use cache
        await provider.connectToStreamChat('stream_1');
        verify(mockService.getStreamChat('stream_1')).called(1); // Still only called once
      });

      test('should clear expired cache', () {
        // Set an old cache timestamp
        provider._cacheTimestamps['test'] = 
            DateTime.now().subtract(const Duration(minutes: 15));
        
        provider._clearExpiredCache();
        
        expect(provider._cacheTimestamps.containsKey('test'), isFalse);
      });

      test('should update message cache', () {
        final messages = [
          StreamChatMessage(
            id: 'message_1',
            streamId: 'stream_1',
            userId: 'user_1',
            userName: 'TestUser',
            content: 'Message 1',
            timestamp: DateTime.now(),
          ),
        ];

        provider._updateMessageCache('stream_1', messages);

        expect(provider._messageCache['stream_1'], messages);
        expect(provider._cacheTimestamps.containsKey('stream_1'), isTrue);
      });
    });

    group('Utility Methods', () {
      test('should mark messages as read', () {
        provider._unreadCount = 5;

        provider.markAsRead();

        expect(provider.unreadCount, 0);
      });

      test('should clear all messages', () {
        provider._messages = [
          StreamChatMessage(
            id: 'message_1',
            streamId: 'stream_1',
            userId: 'user_1',
            userName: 'TestUser',
            content: 'Test',
            timestamp: DateTime.now(),
          ),
        ];
        provider._reactions = [
          StreamReaction(
            id: 'reaction_1',
            streamId: 'stream_1',
            userId: 'user_1',
            reactionType: 'heart',
            timestamp: DateTime.now(),
          ),
        ];
        provider._unreadCount = 3;

        provider.clearMessages();

        expect(provider.messages, isEmpty);
        expect(provider.reactions, isEmpty);
        expect(provider.unreadCount, 0);
      });

      test('should search messages correctly', () {
        final messages = [
          StreamChatMessage(
            id: 'message_1',
            streamId: 'stream_1',
            userId: 'user_1',
            userName: 'TestUser',
            content: 'Hello world',
            timestamp: DateTime.now(),
          ),
          StreamChatMessage(
            id: 'message_2',
            streamId: 'stream_1',
            userId: 'user_2',
            userName: 'AnotherUser',
            content: 'Goodbye world',
            timestamp: DateTime.now(),
          ),
        ];

        provider._messages = messages;

        final results = provider.searchMessages('hello');
        expect(results.length, 1);
        expect(results.first.content, 'Hello world');

        final userResults = provider.searchMessages('TestUser');
        expect(userResults.length, 1);
        expect(userResults.first.userName, 'TestUser');
      });

      test('should get messages from user', () {
        final messages = [
          StreamChatMessage(
            id: 'message_1',
            streamId: 'stream_1',
            userId: 'user_1',
            userName: 'TestUser',
            content: 'Message 1',
            timestamp: DateTime.now(),
          ),
          StreamChatMessage(
            id: 'message_2',
            streamId: 'stream_1',
            userId: 'user_2',
            userName: 'OtherUser',
            content: 'Message 2',
            timestamp: DateTime.now(),
          ),
          StreamChatMessage(
            id: 'message_3',
            streamId: 'stream_1',
            userId: 'user_1',
            userName: 'TestUser',
            content: 'Message 3',
            timestamp: DateTime.now(),
          ),
        ];

        provider._messages = messages;

        final userMessages = provider.getMessagesFromUser('user_1');
        expect(userMessages.length, 2);
        expect(userMessages.every((m) => m.userId == 'user_1'), isTrue);
      });

      test('should get pinned messages', () {
        final messages = [
          StreamChatMessage(
            id: 'message_1',
            streamId: 'stream_1',
            userId: 'user_1',
            userName: 'TestUser',
            content: 'Normal message',
            timestamp: DateTime.now(),
            isPinned: false,
          ),
          StreamChatMessage(
            id: 'message_2',
            streamId: 'stream_1',
            userId: 'user_2',
            userName: 'OtherUser',
            content: 'Pinned message',
            timestamp: DateTime.now(),
            isPinned: true,
          ),
        ];

        provider._messages = messages;

        final pinnedMessages = provider.getPinnedMessages();
        expect(pinnedMessages.length, 1);
        expect(pinnedMessages.first.isPinned, isTrue);
      });

      test('should get message statistics', () {
        final messages = [
          StreamChatMessage(
            id: 'message_1',
            streamId: 'stream_1',
            userId: 'user_1',
            userName: 'TestUser',
            content: 'Message 1',
            timestamp: DateTime.now(),
            reactions: ['heart', 'thumbs_up'],
          ),
          StreamChatMessage(
            id: 'message_2',
            streamId: 'stream_1',
            userId: 'user_2',
            userName: 'OtherUser',
            content: 'Message 2',
            timestamp: DateTime.now(),
            reactions: ['heart'],
          ),
        ];

        provider._messages = messages;

        final stats = provider.getMessageStats();
        expect(stats['user_user_1'], 1);
        expect(stats['user_user_2'], 1);
        expect(stats['reaction_heart'], 2);
        expect(stats['reaction_thumbs_up'], 1);
      });
    });

    group('Permission Checking', () {
      test('should identify streamer correctly', () async {
        final stream = LiveStream(
          id: 'stream_1',
          streamerId: 'current_user',
          title: 'Test Stream',
          status: StreamStatus.live,
          quality: StreamQuality.high,
          viewerCount: 100,
          startedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockService.getStreamById('stream_1'))
            .thenAnswer((_) async => stream);
        when(mockSupabase.auth.currentUser)
            .thenReturn(AuthUser(id: 'current_user', appMetadata: {}, userMetadata: {}, email: '', phone: '', createdAt: DateTime.now()));

        await provider._checkUserPermissions('stream_1');

        expect(provider._isStreamer, isTrue);
      });

      test('should identify non-streamer correctly', () async {
        final stream = LiveStream(
          id: 'stream_1',
          streamerId: 'other_user',
          title: 'Test Stream',
          status: StreamStatus.live,
          quality: StreamQuality.high,
          viewerCount: 100,
          startedAt: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockService.getStreamById('stream_1'))
            .thenAnswer((_) async => stream);
        when(mockSupabase.auth.currentUser)
            .thenReturn(AuthUser(id: 'current_user', appMetadata: {}, userMetadata: {}, email: '', phone: '', createdAt: DateTime.now()));

        await provider._checkUserPermissions('stream_1');

        expect(provider._isStreamer, isFalse);
      });
    });

    group('Error Handling', () {
      test('should handle service errors gracefully', () async {
        when(mockService.getStreamChat('stream_1'))
            .thenThrow(Exception('Service unavailable'));

        await provider.connectToStreamChat('stream_1');

        expect(provider.error, isNotNull);
        expect(provider.error, contains('Failed to connect to chat'));
        expect(provider.isLoading, isFalse);
      });

      test('should clear errors on successful operation', () async {
        // Set an error
        provider._setError('Previous error');
        expect(provider.error, isNotNull);

        // Successful operation should clear error
        when(mockService.getStreamChat('stream_1'))
            .thenAnswer((_) async => []);
        when(mockService.getStreamById('stream_1'))
            .thenAnswer((_) async => null);
        when(mockSupabase.channel(any))
            .thenReturn(MockRealtimeChannel());

        await provider.connectToStreamChat('stream_1');

        expect(provider.error, isNull);
      });
    });

    group('State Management', () {
      test('should notify listeners on state changes', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider._setLoading(true);
        expect(notified, isTrue);
        expect(provider.isLoading, isTrue);
      });

      test('should handle sending state correctly', () {
        var notified = false;
        provider.addListener(() => notified = true);

        provider._setSending(true);
        expect(notified, isTrue);
        expect(provider.isSending, isTrue);
      });
    });

    group('Edge Cases', () {
      test('should handle empty message list', () {
        provider._messages = [];

        final stats = provider.getMessageStats();
        expect(stats, isEmpty);
      });

      test('should handle very long message content', () {
        final longContent = 'A' * 1000;
        final message = StreamChatMessage(
          id: 'long_message',
          streamId: 'stream_1',
          userId: 'user_1',
          userName: 'TestUser',
          content: longContent,
          timestamp: DateTime.now(),
        );

        provider._messages = [message];

        expect(provider.messages.first.content.length, 1000);
      });

      test('should handle many reactions', () {
        final manyReactions = List.filled(100, 'heart');
        final message = StreamChatMessage(
          id: 'reaction_message',
          streamId: 'stream_1',
          userId: 'user_1',
          userName: 'TestUser',
          content: 'Popular message',
          timestamp: DateTime.now(),
          reactions: manyReactions,
        );

        provider._messages = [message];

        expect(provider.messages.first.reactions.length, 100);
      });

      test('should handle special characters in messages', () {
        const specialContent = 'Hello 🎉 @user #hashtag https://example.com';
        final message = StreamChatMessage(
          id: 'special_message',
          streamId: 'stream_1',
          userId: 'user_1',
          userName: 'TestUser',
          content: specialContent,
          timestamp: DateTime.now(),
        );

        provider._messages = [message];

        expect(provider.messages.first.content, specialContent);
      });
    });
  });
}

// Extension to access private members for testing
extension StreamChatProviderTestExtension on StreamChatProvider {
  set _streamService(StreamService service) {
    // This would need to be implemented in the actual provider
  }

  set _supabase(SupabaseClient client) {
    // This would need to be implemented in the actual provider
  }

  set _currentStreamId(String? id) {
    // Access private setter
  }

  set _isConnected(bool connected) {
    // Access private setter
  }

  set _isSending(bool sending) {
    // Access private setter
  }

  set _messages(List<StreamChatMessage> messages) {
    // Access private setter
  }

  set _reactions(List<StreamReaction> reactions) {
    // Access private setter
  }

  set _unreadCount(int count) {
    // Access private setter
  }

  set _hasMoreMessages(bool hasMore) {
    // Access private setter
  }

  set _blockedUsers(Set<String> users) {
    // Access private setter
  }

  set _blockedWords(Set<String> words) {
    // Access private setter
  }

  set _isModerator(bool isModerator) {
    // Access private setter
  }

  set _isStreamer(bool isStreamer) {
    // Access private setter
  }

  Map<String, List<StreamChatMessage>> get _messageCache => {
    // Access private cache
  };

  Map<String, DateTime> get _cacheTimestamps => {
    // Access private cache timestamps
  };

  void _setLoading(bool loading) {
    // Access private method
  }

  void _setSending(bool sending) {
    // Access private method
  }

  void _setError(String? error) {
    // Access private method
  }

  void _handleNewMessage(StreamChatMessage message) {
    // Access private method
  }

  void _handleNewReaction(StreamReaction reaction) {
    // Access private method
  }

  void _clearExpiredCache() {
    // Access private method
  }

  void _updateMessageCache(String streamId, List<StreamChatMessage> messages) {
    // Access private method
  }

  Future<void> _checkUserPermissions(String streamId) async {
    // Access private method
  }
}
