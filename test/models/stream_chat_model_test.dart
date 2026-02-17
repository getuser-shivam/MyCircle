import 'package:flutter_test/flutter_test.dart';
import 'package:mycircle/models/stream_chat_model.dart';

void main() {
  group('StreamReaction', () {
    final now = DateTime.now();
    
    final sampleReaction = StreamReaction(
      id: 'reaction_1',
      streamId: 'stream_1',
      userId: 'user_1',
      reactionType: 'heart',
      timestamp: now,
    );

    test('should create StreamReaction with all required fields', () {
      expect(sampleReaction.id, 'reaction_1');
      expect(sampleReaction.streamId, 'stream_1');
      expect(sampleReaction.userId, 'user_1');
      expect(sampleReaction.reactionType, 'heart');
      expect(sampleReaction.timestamp, now);
    });

    test('should convert to map correctly', () {
      final map = sampleReaction.toMap();
      
      expect(map['id'], 'reaction_1');
      expect(map['stream_id'], 'stream_1');
      expect(map['user_id'], 'user_1');
      expect(map['reaction_type'], 'heart');
      expect(map['timestamp'], now.toIso8601String());
    });

    test('should create from map correctly', () {
      final map = sampleReaction.toMap();
      final reactionFromMap = StreamReaction.fromMap(map);
      
      expect(reactionFromMap.id, sampleReaction.id);
      expect(reactionFromMap.streamId, sampleReaction.streamId);
      expect(reactionFromMap.userId, sampleReaction.userId);
      expect(reactionFromMap.reactionType, sampleReaction.reactionType);
      expect(reactionFromMap.timestamp, sampleReaction.timestamp);
    });

    test('copyWith should create new instance with updated values', () {
      final updatedReaction = sampleReaction.copyWith(
        reactionType: 'fire',
        timestamp: now.add(const Duration(minutes: 1)),
      );

      expect(updatedReaction.id, sampleReaction.id); // unchanged
      expect(updatedReaction.reactionType, 'fire'); // changed
      expect(updatedReaction.timestamp, isNot(sampleReaction.timestamp)); // changed
    });

    test('equality should work correctly', () {
      final reaction1 = sampleReaction;
      final reaction2 = StreamReaction.fromMap(sampleReaction.toMap());
      final reaction3 = sampleReaction.copyWith(reactionType: 'different');

      expect(reaction1, equals(reaction2));
      expect(reaction1, isNot(equals(reaction3)));
    });

    test('should handle null values in fromMap', () {
      final map = {
        'id': 'reaction_2',
        'stream_id': 'stream_2',
        'user_id': 'user_2',
        'reaction_type': 'like',
        'timestamp': now.toIso8601String(),
      };

      final reaction = StreamReaction.fromMap(map);
      expect(reaction.id, 'reaction_2');
      expect(reaction.reactionType, 'like');
    });
  });

  group('StreamChatMessage', () {
    final now = DateTime.now();
    
    final sampleMessage = StreamChatMessage(
      id: 'message_1',
      streamId: 'stream_1',
      userId: 'user_1',
      userName: 'TestUser',
      userAvatar: 'https://example.com/avatar.jpg',
      content: 'Hello stream!',
      timestamp: now,
      reactions: ['heart', 'thumbs_up'],
      isPinned: false,
      isDeleted: false,
      isFromStaff: false,
      isModerator: false,
    );

    test('should create StreamChatMessage with all required fields', () {
      expect(sampleMessage.id, 'message_1');
      expect(sampleMessage.streamId, 'stream_1');
      expect(sampleMessage.userId, 'user_1');
      expect(sampleMessage.userName, 'TestUser');
      expect(sampleMessage.content, 'Hello stream!');
      expect(sampleMessage.reactions, ['heart', 'thumbs_up']);
    });

    test('should convert to map correctly', () {
      final map = sampleMessage.toMap();
      
      expect(map['id'], 'message_1');
      expect(map['stream_id'], 'stream_1');
      expect(map['user_id'], 'user_1');
      expect(map['user_name'], 'TestUser');
      expect(map['content'], 'Hello stream!');
      expect(map['reactions'], ['heart', 'thumbs_up']);
      expect(map['is_pinned'], false);
      expect(map['is_deleted'], false);
    });

    test('should create from map correctly', () {
      final map = sampleMessage.toMap();
      final messageFromMap = StreamChatMessage.fromMap(map);
      
      expect(messageFromMap.id, sampleMessage.id);
      expect(messageFromMap.streamId, sampleMessage.streamId);
      expect(messageFromMap.userId, sampleMessage.userId);
      expect(messageFromMap.userName, sampleMessage.userName);
      expect(messageFromMap.content, sampleMessage.content);
      expect(messageFromMap.reactions, sampleMessage.reactions);
    });

    test('should handle null values in fromMap', () {
      final map = {
        'id': 'message_2',
        'stream_id': 'stream_2',
        'user_id': 'user_2',
        'user_name': 'User2',
        'content': 'Another message',
        'timestamp': now.toIso8601String(),
      };

      final message = StreamChatMessage.fromMap(map);
      expect(message.id, 'message_2');
      expect(message.userAvatar, ''); // default empty string
      expect(message.reactions, []); // default empty list
      expect(message.isPinned, false); // default false
      expect(message.isDeleted, false); // default false
    });

    test('copyWith should create new instance with updated values', () {
      final updatedMessage = sampleMessage.copyWith(
        content: 'Updated content',
        reactions: ['fire'],
        isPinned: true,
      );

      expect(updatedMessage.id, sampleMessage.id); // unchanged
      expect(updatedMessage.content, 'Updated content'); // changed
      expect(updatedMessage.reactions, ['fire']); // changed
      expect(updatedMessage.isPinned, true); // changed
      expect(updatedMessage.userName, sampleMessage.userName); // unchanged
    });

    test('equality should work correctly', () {
      final message1 = sampleMessage;
      final message2 = StreamChatMessage.fromMap(sampleMessage.toMap());
      final message3 = sampleMessage.copyWith(content: 'Different');

      expect(message1, equals(message2));
      expect(message1, isNot(equals(message3)));
    });

    group('Computed Properties', () {
      test('isRecent should return true for recent messages', () {
        final recentMessage = sampleMessage.copyWith(
          timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
        );
        expect(recentMessage.isRecent, isTrue);
      });

      test('isRecent should return false for old messages', () {
        final oldMessage = sampleMessage.copyWith(
          timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        );
        expect(oldMessage.isRecent, isFalse);
      });

      test('hasReactions should return true for messages with reactions', () {
        final messageWithReactions = sampleMessage.copyWith(reactions: ['heart']);
        expect(messageWithReactions.hasReactions, isTrue);
      });

      test('hasReactions should return false for messages without reactions', () {
        final messageWithoutReactions = sampleMessage.copyWith(reactions: []);
        expect(messageWithoutReactions.hasReactions, isFalse);
      });

      test('reactionCount should return correct count', () {
        final message = sampleMessage.copyWith(reactions: ['heart', 'heart', 'thumbs_up']);
        expect(message.reactionCount, 3);
      });

      test('reactionCount should return 0 for no reactions', () {
        final message = sampleMessage.copyWith(reactions: []);
        expect(message.reactionCount, 0);
      });
    });

    group('Helper Methods', () {
      test('addReaction should add new reaction', () {
        final message = sampleMessage.copyWith(reactions: ['heart']);
        final updatedMessage = message.addReaction('thumbs_up');
        
        expect(updatedMessage.reactions, contains('heart'));
        expect(updatedMessage.reactions, contains('thumbs_up'));
        expect(updatedMessage.reactions.length, 2);
      });

      test('addReaction should not duplicate existing reaction', () {
        final message = sampleMessage.copyWith(reactions: ['heart']);
        final updatedMessage = message.addReaction('heart');
        
        expect(updatedMessage.reactions, ['heart']); // still only one
      });

      test('removeReaction should remove existing reaction', () {
        final message = sampleMessage.copyWith(reactions: ['heart', 'thumbs_up']);
        final updatedMessage = message.removeReaction('heart');
        
        expect(updatedMessage.reactions, isNot(contains('heart')));
        expect(updatedMessage.reactions, contains('thumbs_up'));
        expect(updatedMessage.reactions.length, 1);
      });

      test('removeReaction should handle non-existent reaction', () {
        final message = sampleMessage.copyWith(reactions: ['heart']);
        final updatedMessage = message.removeReaction('thumbs_up');
        
        expect(updatedMessage.reactions, ['heart']); // unchanged
      });

      test('togglePin should change pin status', () {
        final message = sampleMessage.copyWith(isPinned: false);
        final pinnedMessage = message.togglePin();
        
        expect(pinnedMessage.isPinned, isTrue);
        
        final unpinnedMessage = pinnedMessage.togglePin();
        expect(unpinnedMessage.isPinned, isFalse);
      });

      test('markAsDeleted should set deleted status', () {
        final message = sampleMessage.copyWith(isDeleted: false);
        final deletedMessage = message.markAsDeleted();
        
        expect(deletedMessage.isDeleted, isTrue);
      });
    });

    group('Edge Cases', () {
      test('should handle empty content', () {
        final message = sampleMessage.copyWith(content: '');
        expect(message.content, isEmpty);
      });

      test('should handle very long content', () {
        final longContent = 'A' * 1000;
        final message = sampleMessage.copyWith(content: longContent);
        expect(message.content.length, 1000);
      });

      test('should handle empty reactions list', () {
        final message = sampleMessage.copyWith(reactions: []);
        expect(message.reactions, isEmpty);
        expect(message.hasReactions, isFalse);
        expect(message.reactionCount, 0);
      });

      test('should handle many reactions', () {
        final manyReactions = List.filled(100, 'heart');
        final message = sampleMessage.copyWith(reactions: manyReactions);
        expect(message.reactions.length, 100);
        expect(message.reactionCount, 100);
      });

      test('should handle special characters in content', () {
        const specialContent = 'Hello 🎉 @user #hashtag https://example.com';
        final message = sampleMessage.copyWith(content: specialContent);
        expect(message.content, specialContent);
      });

      test('should handle null user avatar', () {
        final message = sampleMessage.copyWith(userAvatar: '');
        expect(message.userAvatar, isEmpty);
      });
    });

    group('Validation', () {
      test('should validate required fields', () {
        expect(() => StreamChatMessage(
          id: '', // invalid empty id
          streamId: 'stream_1',
          userId: 'user_1',
          userName: 'Test',
          content: 'Hello',
          timestamp: now,
        ), throwsA(anything));

        expect(() => StreamChatMessage(
          id: 'message_1',
          streamId: '', // invalid empty stream_id
          userId: 'user_1',
          userName: 'Test',
          content: 'Hello',
          timestamp: now,
        ), throwsA(anything));
      });

      test('should handle invalid timestamp in fromMap', () {
        final map = {
          'id': 'message_invalid',
          'stream_id': 'stream_1',
          'user_id': 'user_1',
          'user_name': 'Test',
          'content': 'Hello',
          'timestamp': 'invalid_date',
        };

        expect(() => StreamChatMessage.fromMap(map), throwsA(anything));
      });
    });

    group('Message Types', () {
      test('should identify staff messages', () {
        final staffMessage = sampleMessage.copyWith(isFromStaff: true);
        expect(staffMessage.isFromStaff, isTrue);
      });

      test('should identify moderator messages', () {
        final modMessage = sampleMessage.copyWith(isModerator: true);
        expect(modMessage.isModerator, isTrue);
      });

      test('should identify pinned messages', () {
        final pinnedMessage = sampleMessage.copyWith(isPinned: true);
        expect(pinnedMessage.isPinned, isTrue);
      });

      test('should identify deleted messages', () {
        final deletedMessage = sampleMessage.copyWith(isDeleted: true);
        expect(deletedMessage.isDeleted, isTrue);
      });
    });
  });
}
