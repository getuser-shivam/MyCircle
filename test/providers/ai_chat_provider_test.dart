import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../lib/models/ai_chat.dart';
import '../../lib/providers/ai_chat_provider.dart';
import '../../lib/providers/antigravity_provider.dart';
import '../../lib/services/ai_chat_service.dart';

// Generate mocks
@GenerateMocks([
  AIChatRepository,
  AICompanionService,
  AIRecommendationService,
  AntigravityProvider,
  SupabaseClient,
  User,
])
import 'ai_chat_provider_test.mocks.dart';

void main() {
  group('AIChatProvider Tests', () {
    late AIChatProvider provider;
    late MockAIChatRepository mockChatRepository;
    late MockAICompanionService mockCompanionService;
    late MockAIRecommendationService mockRecommendationService;
    late MockAntigravityProvider mockAntigravityProvider;
    late MockSupabaseClient mockSupabaseClient;
    late MockUser mockUser;

    setUp(() {
      mockChatRepository = MockAIChatRepository();
      mockCompanionService = MockAICompanionService();
      mockRecommendationService = MockAIRecommendationService();
      mockAntigravityProvider = MockAntigravityProvider();
      mockSupabaseClient = MockSupabaseClient();
      mockUser = MockUser();

      provider = AIChatProvider(
        mockChatRepository,
        mockCompanionService,
        mockRecommendationService,
        mockAntigravityProvider,
      );

      // Setup default mock behaviors
      when(mockUser.id).thenReturn('user123');
      when(mockSupabaseClient.auth.currentUser).thenReturn(mockUser);
      when(mockAntigravityProvider.selectedModel).thenReturn('antigravity-v1');
    });

    group('Initialization', () {
      test('should initialize successfully with all data loaded', () async {
        // Arrange
        final mockConversations = [
          AIConversation(
            id: 'conv1',
            userId: 'user123',
            title: 'Test Conversation',
            type: ConversationType.chat,
            personality: CompanionPersonality.friendly,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          )
        ];

        final mockCompanions = [
          AICompanion(
            id: 'comp1',
            name: 'Friendly Bot',
            avatar: 'avatar_url',
            personality: CompanionPersonality.friendly,
            description: 'A friendly companion',
            systemPrompt: 'You are friendly',
            capabilities: ['chat'],
            createdAt: DateTime.now(),
          )
        ];

        final mockRecommendations = [
          AIRecommendation(
            id: 'rec1',
            userId: 'user123',
            conversationId: 'conv1',
            type: 'media',
            title: 'Recommended Content',
            description: 'Check this out',
            data: {},
            relevanceScore: 0.9,
            createdAt: DateTime.now(),
          )
        ];

        when(mockChatRepository.getUserConversations('user123'))
            .thenAnswer((_) async => mockConversations);
        when(mockChatRepository.getConversationStream('user123'))
            .thenAnswer((_) => Stream.value(mockConversations));
        when(mockCompanionService.getAvailableCompanions())
            .thenAnswer((_) async => mockCompanions);
        when(mockRecommendationService.getRecommendations('user123'))
            .thenAnswer((_) async => mockRecommendations);

        // Act
        await provider.initialize();

        // Assert
        expect(provider.conversations, mockConversations);
        expect(provider.companions, mockCompanions);
        expect(provider.recommendations, mockRecommendations);
        expect(provider.isLoading, false);
        expect(provider.error, null);
      });

      test('should handle initialization error gracefully', () async {
        // Arrange
        when(mockChatRepository.getUserConversations('user123'))
            .thenThrow(Exception('Database error'));

        // Act
        await provider.initialize();

        // Assert
        expect(provider.isLoading, false);
        expect(provider.error, isNotNull);
        expect(provider.error, contains('Database error'));
      });
    });

    group('Conversation Management', () {
      test('should create conversation successfully', () async {
        // Arrange
        final newConversation = AIConversation(
          id: 'conv1',
          userId: 'user123',
          title: 'New Conversation',
          type: ConversationType.chat,
          personality: CompanionPersonality.friendly,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        when(mockChatRepository.createConversation(
          userId: 'user123',
          title: 'New Conversation',
          type: ConversationType.chat,
          personality: CompanionPersonality.friendly,
          companionId: null,
        )).thenAnswer((_) async => newConversation);

        when(mockChatRepository.getConversationMessages('conv1'))
            .thenAnswer((_) async => []);
        when(mockChatRepository.getMessageStream('conv1'))
            .thenAnswer((_) => Stream.value([]));

        // Act
        await provider.createConversation(
          title: 'New Conversation',
          type: ConversationType.chat,
          personality: CompanionPersonality.friendly,
        );

        // Assert
        expect(provider.conversations.contains(newConversation), true);
        expect(provider.currentConversation, newConversation);
        expect(provider.isLoading, false);
      });

      test('should handle conversation creation error', () async {
        // Arrange
        when(mockChatRepository.createConversation(
          userId: anyNamed('userId'),
          title: anyNamed('title'),
          type: anyNamed('type'),
          personality: anyNamed('personality'),
          companionId: anyNamed('companionId'),
        )).thenThrow(Exception('Creation failed'));

        // Act
        await provider.createConversation(
          title: 'Test',
          type: ConversationType.chat,
        );

        // Assert
        expect(provider.error, isNotNull);
        expect(provider.error, contains('Creation failed'));
        expect(provider.isLoading, false);
      });

      test('should select conversation successfully', () async {
        // Arrange
        final conversation = AIConversation(
          id: 'conv1',
          userId: 'user123',
          title: 'Test Conversation',
          type: ConversationType.chat,
          personality: CompanionPersonality.friendly,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final messages = [
          AIMessage(
            id: 'msg1',
            conversationId: 'conv1',
            role: MessageRole.user,
            content: 'Hello',
            createdAt: DateTime.now(),
          )
        ];

        provider._conversations = [conversation];
        when(mockChatRepository.getConversationMessages('conv1'))
            .thenAnswer((_) async => messages);
        when(mockChatRepository.getMessageStream('conv1'))
            .thenAnswer((_) => Stream.value(messages));

        // Act
        await provider.selectConversation('conv1');

        // Assert
        expect(provider.currentConversation, conversation);
        expect(provider.currentMessages, messages);
        expect(provider.isLoading, false);
      });

      test('should delete conversation successfully', () async {
        // Arrange
        final conversation = AIConversation(
          id: 'conv1',
          userId: 'user123',
          title: 'Test Conversation',
          type: ConversationType.chat,
          personality: CompanionPersonality.friendly,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        provider._conversations = [conversation];
        provider._currentConversation = conversation;

        when(mockChatRepository.deleteConversation('conv1'))
            .thenAnswer((_) async {});

        // Act
        await provider.deleteConversation('conv1');

        // Assert
        expect(provider.conversations.contains(conversation), false);
        expect(provider.currentConversation, null);
        expect(provider.currentMessages, isEmpty);
      });
    });

    group('Message Management', () {
      test('should send message successfully', () async {
        // Arrange
        final conversation = AIConversation(
          id: 'conv1',
          userId: 'user123',
          title: 'Test Conversation',
          type: ConversationType.chat,
          personality: CompanionPersonality.friendly,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final userMessage = AIMessage(
          id: 'msg1',
          conversationId: 'conv1',
          role: MessageRole.user,
          content: 'Hello',
          createdAt: DateTime.now(),
        );

        final aiMessage = AIMessage(
          id: 'msg2',
          conversationId: 'conv1',
          role: MessageRole.assistant,
          content: 'Hi there!',
          createdAt: DateTime.now(),
        );

        provider._currentConversation = conversation;
        provider._currentMessages = [];

        when(mockChatRepository.createMessage(
          conversationId: 'conv1',
          role: MessageRole.user,
          content: 'Hello',
        )).thenAnswer((_) async => userMessage);

        when(mockChatRepository.createMessage(
          conversationId: 'conv1',
          role: MessageRole.assistant,
          content: 'Hi there!',
          modelUsed: 'antigravity-v1',
        )).thenAnswer((_) async => aiMessage);

        when(mockCompanionService.getSystemPrompt(CompanionPersonality.friendly))
            .thenReturn('You are friendly');

        when(mockAntigravityProvider.processQuery(any))
            .thenAnswer((_) async {});

        when(mockRecommendationService.createRecommendation(
          userId: anyNamed('userId'),
          conversationId: anyNamed('conversationId'),
          type: anyNamed('type'),
          title: anyNamed('title'),
          description: anyNamed('description'),
          data: anyNamed('data'),
          relevanceScore: anyNamed('relevanceScore'),
        )).thenAnswer((_) async => AIRecommendation(
          id: 'rec1',
          userId: 'user123',
          conversationId: 'conv1',
          type: 'media',
          title: 'Test',
          description: 'Test',
          data: {},
          relevanceScore: 0.8,
          createdAt: DateTime.now(),
        ));

        // Act
        await provider.sendMessage('Hello');

        // Assert
        expect(provider.isSendingMessage, false);
        expect(provider.isTyping, false);
        expect(provider.currentMessages.length, 2); // User + AI message
        expect(provider.error, null);
      });

      test('should handle send message error gracefully', () async {
        // Arrange
        final conversation = AIConversation(
          id: 'conv1',
          userId: 'user123',
          title: 'Test Conversation',
          type: ConversationType.chat,
          personality: CompanionPersonality.friendly,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        provider._currentConversation = conversation;

        when(mockChatRepository.createMessage(
          conversationId: anyNamed('conversationId'),
          role: anyNamed('role'),
          content: anyNamed('content'),
        )).thenThrow(Exception('Message send failed'));

        // Act
        await provider.sendMessage('Hello');

        // Assert
        expect(provider.isSendingMessage, false);
        expect(provider.isTyping, false);
        expect(provider.error, isNotNull);
        expect(provider.error, contains('Message send failed'));
      });

      test('should not send empty message', () async {
        // Arrange
        final conversation = AIConversation(
          id: 'conv1',
          userId: 'user123',
          title: 'Test Conversation',
          type: ConversationType.chat,
          personality: CompanionPersonality.friendly,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        provider._currentConversation = conversation;

        // Act
        await provider.sendMessage('');

        // Assert
        verifyNever(mockChatRepository.createMessage(
          conversationId: anyNamed('conversationId'),
          role: anyNamed('role'),
          content: anyNamed('content'),
        ));
      });
    });

    group('Companion Management', () {
      test('should select companion successfully', () async {
        // Arrange
        final companion = AICompanion(
          id: 'comp1',
          name: 'Friendly Bot',
          avatar: 'avatar_url',
          personality: CompanionPersonality.friendly,
          description: 'A friendly companion',
          systemPrompt: 'You are friendly',
          capabilities: ['chat'],
          createdAt: DateTime.now(),
        );

        // Act
        provider.selectCompanion(companion);

        // Assert
        expect(provider.selectedCompanion, companion);
        expect(provider.selectedPersonality, CompanionPersonality.friendly);
      });

      test('should set personality successfully', () async {
        // Act
        provider.setPersonality(CompanionPersonality.professional);

        // Assert
        expect(provider.selectedPersonality, CompanionPersonality.professional);
      });

      test('should increment companion usage successfully', () async {
        // Arrange
        final companion = AICompanion(
          id: 'comp1',
          name: 'Friendly Bot',
          avatar: 'avatar_url',
          personality: CompanionPersonality.friendly,
          description: 'A friendly companion',
          systemPrompt: 'You are friendly',
          capabilities: ['chat'],
          usageCount: 5,
          createdAt: DateTime.now(),
        );

        provider._companions = [companion];
        when(mockCompanionService.incrementCompanionUsage('comp1'))
            .thenAnswer((_) async {});

        // Act
        await provider.incrementCompanionUsage('comp1');

        // Assert
        expect(provider.companions.first.usageCount, 6);
      });
    });

    group('Recommendation Management', () {
      test('should mark recommendation as viewed successfully', () async {
        // Arrange
        final recommendation = AIRecommendation(
          id: 'rec1',
          userId: 'user123',
          conversationId: 'conv1',
          type: 'media',
          title: 'Test Recommendation',
          description: 'Test',
          data: {},
          relevanceScore: 0.8,
          createdAt: DateTime.now(),
        );

        provider._recommendations = [recommendation];
        when(mockRecommendationService.markRecommendationViewed('rec1'))
            .thenAnswer((_) async {});

        // Act
        await provider.markRecommendationViewed('rec1');

        // Assert
        expect(provider.recommendations.first.isViewed, true);
      });

      test('should mark recommendation as interacted successfully', () async {
        // Arrange
        final recommendation = AIRecommendation(
          id: 'rec1',
          userId: 'user123',
          conversationId: 'conv1',
          type: 'media',
          title: 'Test Recommendation',
          description: 'Test',
          data: {},
          relevanceScore: 0.8,
          createdAt: DateTime.now(),
        );

        provider._recommendations = [recommendation];
        when(mockRecommendationService.markRecommendationInteracted('rec1'))
            .thenAnswer((_) async {});

        // Act
        await provider.markRecommendationInteracted('rec1');

        // Assert
        expect(provider.recommendations.first.isInteracted, true);
      });
    });

    group('Utility Methods', () {
      test('should clear error successfully', () {
        // Arrange
        provider._error = 'Test error';

        // Act
        provider.clearError();

        // Assert
        expect(provider.error, null);
      });

      test('should refresh provider successfully', () async {
        // Arrange
        when(mockChatRepository.getUserConversations('user123'))
            .thenAnswer((_) async => []);
        when(mockChatRepository.getConversationStream('user123'))
            .thenAnswer((_) => Stream.value([]));
        when(mockCompanionService.getAvailableCompanions())
            .thenAnswer((_) async => []);
        when(mockRecommendationService.getRecommendations('user123'))
            .thenAnswer((_) async => []);

        // Act
        provider.refresh();

        // Assert
        verify(mockChatRepository.getUserConversations('user123')).called(1);
        verify(mockCompanionService.getAvailableCompanions()).called(1);
        verify(mockRecommendationService.getRecommendations('user123')).called(1);
      });
    });
  });
}

// Extension to access private members for testing
extension AIChatProviderTestExtension on AIChatProvider {
  set _conversations(List<AIConversation> conversations) {
    // This would need to be implemented via a test-friendly approach
    // For now, we'll assume the provider has a way to set this for testing
  }
  
  set _currentConversation(AIConversation? conversation) {
    // This would need to be implemented via a test-friendly approach
  }
  
  set _currentMessages(List<AIMessage> messages) {
    // This would need to be implemented via a test-friendly approach
  }
  
  set _companions(List<AICompanion> companions) {
    // This would need to be implemented via a test-friendly approach
  }
  
  set _recommendations(List<AIRecommendation> recommendations) {
    // This would need to be implemented via a test-friendly approach
  }
  
  set _error(String? error) {
    // This would need to be implemented via a test-friendly approach
  }
}
