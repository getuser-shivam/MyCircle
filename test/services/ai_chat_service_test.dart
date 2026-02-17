import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../lib/models/ai_chat.dart';
import '../../lib/services/ai_chat_service.dart';

// Generate mocks
@GenerateMocks([SupabaseClient])
import 'ai_chat_service_test.mocks.dart';

void main() {
  group('AIChatRepository Tests', () {
    late AIChatRepository repository;
    late MockSupabaseClient mockSupabaseClient;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      repository = AIChatRepository(mockSupabaseClient);
    });

    group('Conversation Operations', () {
      test('should get user conversations successfully', () async {
        // Arrange
        final userId = 'user123';
        final mockData = [
          {
            'id': 'conv1',
            'user_id': userId,
            'title': 'Test Conversation',
            'type': 'chat',
            'personality': 'friendly',
            'is_active': true,
            'created_at': '2024-01-01T00:00:00Z',
            'updated_at': '2024-01-01T00:00:00Z',
            'message_count': 5,
          }
        ];

        final mockPostgrestFilter = MockPostgrestFilter();
        final mockPostgrestOrder = MockPostgrestOrder();
        final mockPostgrestBuilder = MockPostgrestBuilder();

        when(mockSupabaseClient.from('ai_conversations'))
            .thenReturn(mockPostgrestFilter);
        when(mockPostgrestFilter.select())
            .thenReturn(mockPostgrestOrder);
        when(mockPostgrestOrder.eq('user_id', userId))
            .thenReturn(mockPostgrestOrder);
        when(mockPostgrestOrder.order('updated_at', ascending: false))
            .thenReturn(mockPostgrestBuilder);
        when(mockPostgrestBuilder)
            .thenAnswer((_) async => mockData);

        // Act
        final result = await repository.getUserConversations(userId);

        // Assert
        expect(result, isA<List<AIConversation>>());
        expect(result.length, 1);
        expect(result.first.title, 'Test Conversation');
        expect(result.first.personality, CompanionPersonality.friendly);
      });

      test('should throw exception when getting conversations fails', () async {
        // Arrange
        final userId = 'user123';
        final mockPostgrestFilter = MockPostgrestFilter();

        when(mockSupabaseClient.from('ai_conversations'))
            .thenReturn(mockPostgrestFilter);
        when(mockPostgrestFilter.select())
            .thenThrow(Exception('Database error'));

        // Act & Assert
        expect(
          () => repository.getUserConversations(userId),
          throwsException,
        );
      });

      test('should create conversation successfully', () async {
        // Arrange
        final userId = 'user123';
        final title = 'New Conversation';
        final type = ConversationType.chat;
        final personality = CompanionPersonality.friendly;

        final mockData = {
          'id': 'conv1',
          'user_id': userId,
          'title': title,
          'type': 'chat',
          'personality': 'friendly',
          'is_active': true,
          'created_at': '2024-01-01T00:00:00Z',
          'updated_at': '2024-01-01T00:00:00Z',
          'message_count': 0,
        };

        final mockPostgrestFilter = MockPostgrestFilter();
        final mockPostgrestBuilder = MockPostgrestBuilder();

        when(mockSupabaseClient.from('ai_conversations'))
            .thenReturn(mockPostgrestFilter);
        when(mockPostgrestFilter.insert(any))
            .thenReturn(mockPostgrestBuilder);
        when(mockPostgrestBuilder.select())
            .thenReturn(mockPostgrestBuilder);
        when(mockPostgrestBuilder.single())
            .thenAnswer((_) async => mockData);

        // Act
        final result = await repository.createConversation(
          userId: userId,
          title: title,
          type: type,
          personality: personality,
        );

        // Assert
        expect(result, isA<AIConversation>());
        expect(result.title, title);
        expect(result.personality, personality);
        expect(result.type, type);
      });

      test('should update conversation successfully', () async {
        // Arrange
        final conversationId = 'conv1';
        final updates = {'title': 'Updated Title'};
        final mockData = {
          'id': conversationId,
          'user_id': 'user123',
          'title': 'Updated Title',
          'type': 'chat',
          'personality': 'friendly',
          'is_active': true,
          'created_at': '2024-01-01T00:00:00Z',
          'updated_at': '2024-01-01T00:00:00Z',
          'message_count': 5,
        };

        final mockPostgrestFilter = MockPostgrestFilter();
        final mockPostgrestBuilder = MockPostgrestBuilder();

        when(mockSupabaseClient.from('ai_conversations'))
            .thenReturn(mockPostgrestFilter);
        when(mockPostgrestFilter.update(updates))
            .thenReturn(mockPostgrestBuilder);
        when(mockPostgrestBuilder.eq('id', conversationId))
            .thenReturn(mockPostgrestBuilder);
        when(mockPostgrestBuilder.select())
            .thenReturn(mockPostgrestBuilder);
        when(mockPostgrestBuilder.single())
            .thenAnswer((_) async => mockData);

        // Act
        final result = await repository.updateConversation(conversationId, updates);

        // Assert
        expect(result, isA<AIConversation>());
        expect(result.title, 'Updated Title');
      });

      test('should delete conversation successfully', () async {
        // Arrange
        final conversationId = 'conv1';
        final mockPostgrestFilter = MockPostgrestFilter();
        final mockPostgrestBuilder = MockPostgrestBuilder();

        when(mockSupabaseClient.from('ai_conversations'))
            .thenReturn(mockPostgrestFilter);
        when(mockPostgrestFilter.delete())
            .thenReturn(mockPostgrestBuilder);
        when(mockPostgrestBuilder.eq('id', conversationId))
            .thenReturn(mockPostgrestBuilder);

        // Act & Assert
        expect(
          () async => await repository.deleteConversation(conversationId),
          returnsNormally,
        );
      });
    });

    group('Message Operations', () {
      test('should get conversation messages successfully', () async {
        // Arrange
        final conversationId = 'conv1';
        final mockData = [
          {
            'id': 'msg1',
            'conversation_id': conversationId,
            'role': 'user',
            'content': 'Hello',
            'is_read': false,
            'created_at': '2024-01-01T00:00:00Z',
          }
        ];

        final mockPostgrestFilter = MockPostgrestFilter();
        final mockPostgrestOrder = MockPostgrestOrder();
        final mockPostgrestBuilder = MockPostgrestBuilder();

        when(mockSupabaseClient.from('ai_messages'))
            .thenReturn(mockPostgrestFilter);
        when(mockPostgrestFilter.select())
            .thenReturn(mockPostgrestOrder);
        when(mockPostgrestOrder.eq('conversation_id', conversationId))
            .thenReturn(mockPostgrestOrder);
        when(mockPostgrestOrder.order('created_at', ascending: false))
            .thenReturn(mockPostgrestBuilder);
        when(mockPostgrestBuilder)
            .thenAnswer((_) async => mockData);

        // Act
        final result = await repository.getConversationMessages(conversationId);

        // Assert
        expect(result, isA<List<AIMessage>>());
        expect(result.length, 1);
        expect(result.first.content, 'Hello');
        expect(result.first.role, MessageRole.user);
      });

      test('should create message successfully', () async {
        // Arrange
        final conversationId = 'conv1';
        final role = MessageRole.user;
        final content = 'Test message';
        final mockData = {
          'id': 'msg1',
          'conversation_id': conversationId,
          'role': 'user',
          'content': content,
          'is_read': false,
          'created_at': '2024-01-01T00:00:00Z',
        };

        final mockPostgrestFilter = MockPostgrestFilter();
        final mockPostgrestBuilder = MockPostgrestBuilder();

        when(mockSupabaseClient.from('ai_messages'))
            .thenReturn(mockPostgrestFilter);
        when(mockPostgrestFilter.insert(any))
            .thenReturn(mockPostgrestBuilder);
        when(mockPostgrestBuilder.select())
            .thenReturn(mockPostgrestBuilder);
        when(mockPostgrestBuilder.single())
            .thenAnswer((_) async => mockData);

        when(mockSupabaseClient.from('ai_conversations'))
            .thenReturn(mockPostgrestFilter);
        when(mockPostgrestFilter.update(any))
            .thenReturn(mockPostgrestBuilder);
        when(mockPostgrestBuilder.eq('id', conversationId))
            .thenReturn(mockPostgrestBuilder);

        // Act
        final result = await repository.createMessage(
          conversationId: conversationId,
          role: role,
          content: content,
        );

        // Assert
        expect(result, isA<AIMessage>());
        expect(result.content, content);
        expect(result.role, role);
        expect(result.conversationId, conversationId);
      });
    });
  });

  group('AICompanionService Tests', () {
    late AICompanionService service;
    late MockSupabaseClient mockSupabaseClient;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      service = AICompanionService(mockSupabaseClient);
    });

    test('should get available companions successfully', () async {
      // Arrange
      final mockData = [
        {
          'id': 'comp1',
          'name': 'Friendly Bot',
          'avatar': 'avatar_url',
          'personality': 'friendly',
          'description': 'A friendly companion',
          'system_prompt': 'You are friendly',
          'capabilities': ['chat', 'recommend'],
          'is_active': true,
          'usage_count': 10,
          'created_at': '2024-01-01T00:00:00Z',
        }
      ];

      final mockPostgrestFilter = MockPostgrestFilter();
      final mockPostgrestOrder = MockPostgrestOrder();
      final mockPostgrestBuilder = MockPostgrestBuilder();

      when(mockSupabaseClient.from('ai_companions'))
          .thenReturn(mockPostgrestFilter);
      when(mockPostgrestFilter.select())
          .thenReturn(mockPostgrestOrder);
      when(mockPostgrestOrder.eq('is_active', true))
          .thenReturn(mockPostgrestOrder);
      when(mockPostgrestOrder.order('usage_count', ascending: false))
          .thenReturn(mockPostgrestBuilder);
      when(mockPostgrestBuilder)
          .thenAnswer((_) async => mockData);

      // Act
      final result = await service.getAvailableCompanions();

      // Assert
      expect(result, isA<List<AICompanion>>());
      expect(result.length, 1);
      expect(result.first.name, 'Friendly Bot');
      expect(result.first.personality, CompanionPersonality.friendly);
    });

    test('should get system prompt for personality', () {
      // Act & Assert
      expect(
        service.getSystemPrompt(CompanionPersonality.friendly),
        contains('friendly'),
      );
      expect(
        service.getSystemPrompt(CompanionPersonality.professional),
        contains('professional'),
      );
      expect(
        service.getSystemPrompt(CompanionPersonality.witty),
        contains('witty'),
      );
    });

    test('should increment companion usage successfully', () async {
      // Arrange
      final companionId = 'comp1';
      final mockPostgrestFilter = MockPostgrestFilter();
      final mockPostgrestBuilder = MockPostgrestBuilder();

      when(mockSupabaseClient.from('ai_companions'))
          .thenReturn(mockPostgrestFilter);
      when(mockPostgrestFilter.update(any))
          .thenReturn(mockPostgrestBuilder);
      when(mockPostgrestBuilder.eq('id', companionId))
          .thenReturn(mockPostgrestBuilder);

      // Act & Assert
      expect(
        () async => await service.incrementCompanionUsage(companionId),
        returnsNormally,
      );
    });
  });

  group('AIRecommendationService Tests', () {
    late AIRecommendationService service;
    late MockSupabaseClient mockSupabaseClient;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      service = AIRecommendationService(mockSupabaseClient);
    });

    test('should get recommendations successfully', () async {
      // Arrange
      final userId = 'user123';
      final mockData = [
        {
          'id': 'rec1',
          'user_id': userId,
          'conversation_id': 'conv1',
          'type': 'media',
          'title': 'Recommended Content',
          'description': 'Check this out',
          'relevance_score': 0.9,
          'is_viewed': false,
          'is_interacted': false,
          'created_at': '2024-01-01T00:00:00Z',
          'data': {},
        }
      ];

      final mockPostgrestFilter = MockPostgrestFilter();
      final mockPostgrestOrder = MockPostgrestOrder();
      final mockPostgrestBuilder = MockPostgrestBuilder();

      when(mockSupabaseClient.from('ai_recommendations'))
          .thenReturn(mockPostgrestFilter);
      when(mockPostgrestFilter.select())
          .thenReturn(mockPostgrestOrder);
      when(mockPostgrestOrder.eq('user_id', userId))
          .thenReturn(mockPostgrestOrder);
      when(mockPostgrestOrder.order('relevance_score', ascending: false))
          .thenReturn(mockPostgrestBuilder);
      when(mockPostgrestBuilder.limit(20))
          .thenReturn(mockPostgrestBuilder);
      when(mockPostgrestBuilder)
          .thenAnswer((_) async => mockData);

      // Act
      final result = await service.getRecommendations(userId);

      // Assert
      expect(result, isA<List<AIRecommendation>>());
      expect(result.length, 1);
      expect(result.first.title, 'Recommended Content');
      expect(result.first.relevanceScore, 0.9);
    });

    test('should create recommendation successfully', () async {
      // Arrange
      final userId = 'user123';
      final conversationId = 'conv1';
      final mockData = {
        'id': 'rec1',
        'user_id': userId,
        'conversation_id': conversationId,
        'type': 'media',
        'title': 'New Recommendation',
        'description': 'Description',
        'relevance_score': 0.8,
        'is_viewed': false,
        'is_interacted': false,
        'created_at': '2024-01-01T00:00:00Z',
        'data': {},
      };

      final mockPostgrestFilter = MockPostgrestFilter();
      final mockPostgrestBuilder = MockPostgrestBuilder();

      when(mockSupabaseClient.from('ai_recommendations'))
          .thenReturn(mockPostgrestFilter);
      when(mockPostgrestFilter.insert(any))
          .thenReturn(mockPostgrestBuilder);
      when(mockPostgrestBuilder.select())
          .thenReturn(mockPostgrestBuilder);
      when(mockPostgrestBuilder.single())
          .thenAnswer((_) async => mockData);

      // Act
      final result = await service.createRecommendation(
        userId: userId,
        conversationId: conversationId,
        type: 'media',
        title: 'New Recommendation',
        description: 'Description',
        data: {},
        relevanceScore: 0.8,
      );

      // Assert
      expect(result, isA<AIRecommendation>());
      expect(result.title, 'New Recommendation');
      expect(result.relevanceScore, 0.8);
    });

    test('should mark recommendation as viewed successfully', () async {
      // Arrange
      final recommendationId = 'rec1';
      final mockPostgrestFilter = MockPostgrestFilter();
      final mockPostgrestBuilder = MockPostgrestBuilder();

      when(mockSupabaseClient.from('ai_recommendations'))
          .thenReturn(mockPostgrestFilter);
      when(mockPostgrestFilter.update({'is_viewed': true}))
          .thenReturn(mockPostgrestBuilder);
      when(mockPostgrestBuilder.eq('id', recommendationId))
          .thenReturn(mockPostgrestBuilder);

      // Act & Assert
      expect(
        () async => await service.markRecommendationViewed(recommendationId),
        returnsNormally,
      );
    });
  });
}

// Mock classes for Postgrest operations
class MockPostgrestFilter extends Mock implements PostgrestFilterBuilder {}
class MockPostgrestOrder extends Mock implements PostgrestOrderBuilder {}
class MockPostgrestBuilder extends Mock implements PostgrestBuilder {}
