import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:mycircle/providers/ai_chat_provider.dart';
import 'package:mycircle/models/ai_chat.dart';

// Generate mocks
@GenerateMocks([AIChatRepository, AICompanionService, AIRecommendationService, AntigravityProvider])
import 'ai_chat_provider_test.mocks.dart';

void main() {
  group('AIChatProvider Tests', () {
    late AIChatProvider provider;
    late MockAIChatRepository mockRepository;
    late MockAICompanionService mockCompanionService;
    late MockAIRecommendationService mockRecommendationService;
    late MockAntigravityProvider mockAntigravityProvider;

    setUp(() {
      mockRepository = MockAIChatRepository();
      mockCompanionService = MockAICompanionService();
      mockRecommendationService = MockAIRecommendationService();
      mockAntigravityProvider = MockAntigravityProvider();

      provider = AIChatProvider(
        mockRepository,
        mockCompanionService,
        mockRecommendationService,
        mockAntigravityProvider,
      );
    });

    tearDown(() {
      provider.dispose();
    });

    test('should initialize with empty state', () {
      expect(provider.conversations, isEmpty);
      expect(provider.currentMessages, isEmpty);
      expect(provider.companions, isEmpty);
      expect(provider.recommendations, isEmpty);
      expect(provider.currentConversation, isNull);
      expect(provider.selectedCompanion, isNull);
      expect(provider.isLoading, isFalse);
      expect(provider.isSendingMessage, isFalse);
      expect(provider.isTyping, isFalse);
      expect(provider.error, isNull);
    });

    test('should load conversations successfully', () async {
      // Arrange
      final mockConversations = [
        AIConversation(
          id: '1',
          userId: 'user1',
          title: 'Test Conversation',
          type: ConversationType.chat,
          personality: CompanionPersonality.friendly,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      when(mockRepository.getUserConversations(any()))
          .thenAnswer((_) async => mockConversations);
      when(mockCompanionService.getAvailableCompanions())
          .thenAnswer((_) async => []);
      when(mockRecommendationService.getRecommendations(any()))
          .thenAnswer((_) async => []);

      // Act
      await provider.initialize();

      // Assert
      expect(provider.conversations, hasLength(1));
      expect(provider.conversations.first.title, 'Test Conversation');
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNull);

      verify(mockRepository.getUserConversations(any())).called(1);
      verify(mockCompanionService.getAvailableCompanions()).called(1);
      verify(mockRecommendationService.getRecommendations(any())).called(1);
    });

    test('should handle initialization error', () async {
      // Arrange
      when(mockRepository.getUserConversations(any()))
          .thenThrow(Exception('Failed to load'));
      when(mockCompanionService.getAvailableCompanions())
          .thenAnswer((_) async => []);
      when(mockRecommendationService.getRecommendations(any()))
          .thenAnswer((_) async => []);

      // Act
      await provider.initialize();

      // Assert
      expect(provider.isLoading, isFalse);
      expect(provider.error, isNotNull);
      expect(provider.error!.contains('Failed to load'), isTrue);
    });

    test('should create new conversation', () async {
      // Arrange
      final newConversation = AIConversation(
        id: '2',
        userId: 'user1',
        title: 'New Conversation',
        type: ConversationType.chat,
        personality: CompanionPersonality.friendly,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockRepository.createConversation(
        userId: anyNamed('userId'),
        title: anyNamed('title'),
        type: anyNamed('type'),
        personality: anyNamed('personality'),
        companionId: anyNamed('companionId'),
      )).thenAnswer((_) async => newConversation);

      // Act
      await provider.createConversation(
        title: 'New Conversation',
        type: ConversationType.chat,
      );

      // Assert
      expect(provider.conversations, contains(newConversation));
      expect(provider.currentConversation, equals(newConversation));

      verify(mockRepository.createConversation(
        userId: anyNamed('userId'),
        title: 'New Conversation',
        type: ConversationType.chat,
        personality: CompanionPersonality.friendly,
        companionId: null,
      )).called(1);
    });

    test('should select conversation', () async {
      // Arrange
      final conversation = AIConversation(
        id: '3',
        userId: 'user1',
        title: 'Select Test',
        type: ConversationType.chat,
        personality: CompanionPersonality.friendly,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final messages = [
        AIMessage(
          id: 'msg1',
          conversationId: '3',
          role: MessageRole.user,
          content: 'Hello',
          createdAt: DateTime.now(),
        ),
      ];

      when(mockRepository.getConversationMessages('3'))
          .thenAnswer((_) async => messages);

      // Act
      await provider.selectConversation('3');

      // Assert
      expect(provider.currentConversation, equals(conversation));
      expect(provider.currentMessages, equals(messages));

      verify(mockRepository.getConversationMessages('3')).called(1);
    });

    test('should send message successfully', () async {
      // Arrange
      final conversation = AIConversation(
        id: '4',
        userId: 'user1',
        title: 'Message Test',
        type: ConversationType.chat,
        personality: CompanionPersonality.friendly,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final userMessage = AIMessage(
        id: 'msg2',
        conversationId: '4',
        role: MessageRole.user,
        content: 'Test message',
        createdAt: DateTime.now(),
      );

      final aiMessage = AIMessage(
        id: 'msg3',
        conversationId: '4',
        role: MessageRole.assistant,
        content: 'AI response',
        createdAt: DateTime.now(),
      );

      when(mockRepository.createMessage(
        conversationId: anyNamed('conversationId'),
        role: anyNamed('role'),
        content: anyNamed('content'),
        metadata: anyNamed('metadata'),
        modelUsed: anyNamed('modelUsed'),
      )).thenAnswer((_) async => userMessage);

      // Act
      provider.selectConversation('4');
      await provider.sendMessage('Test message');

      // Assert
      expect(provider.isSendingMessage, isFalse);
      expect(provider.currentMessages, contains(userMessage));

      verify(mockRepository.createMessage(
        conversationId: '4',
        role: MessageRole.user,
        content: 'Test message',
        metadata: null,
        modelUsed: null,
      )).called(1);
    });

    test('should select companion', () {
      // Arrange
      final companion = AICompanion(
        id: 'comp1',
        name: 'Test Companion',
        avatar: 'avatar.png',
        personality: CompanionPersonality.friendly,
        description: 'Test description',
        systemPrompt: 'Test prompt',
        capabilities: ['chat'],
        createdAt: DateTime.now(),
      );

      // Act
      provider.selectCompanion(companion);

      // Assert
      expect(provider.selectedCompanion, equals(companion));
      expect(provider.selectedPersonality, equals(CompanionPersonality.friendly));
    });

    test('should delete conversation', () async {
      // Arrange
      final conversation = AIConversation(
        id: '5',
        userId: 'user1',
        title: 'Delete Test',
        type: ConversationType.chat,
        personality: CompanionPersonality.friendly,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockRepository.deleteConversation('5'))
          .thenAnswer((_) async {});

      provider.conversations.add(conversation);
      provider.selectConversation('5');

      // Act
      await provider.deleteConversation('5');

      // Assert
      expect(provider.conversations, isNot(contains(conversation)));
      expect(provider.currentConversation, isNull);

      verify(mockRepository.deleteConversation('5')).called(1);
    });

    test('should handle message sending error', () async {
      // Arrange
      final conversation = AIConversation(
        id: '6',
        userId: 'user1',
        title: 'Error Test',
        type: ConversationType.chat,
        personality: CompanionPersonality.friendly,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockRepository.createMessage(
        conversationId: anyNamed('conversationId'),
        role: anyNamed('role'),
        content: anyNamed('content'),
        metadata: anyNamed('metadata'),
        modelUsed: anyNamed('modelUsed'),
      )).thenThrow(Exception('Failed to send message'));

      // Act
      provider.selectConversation('6');
      await provider.sendMessage('Error message');

      // Assert
      expect(provider.isSendingMessage, isFalse);
      expect(provider.error, isNotNull);
      expect(provider.error!.contains('Failed to send message'), isTrue);
    });
  });
}
