import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import '../../lib/providers/ai_chat_provider.dart';
import '../../lib/providers/antigravity_provider.dart';
import '../../lib/models/ai_chat.dart';
import '../../lib/screens/ai_chat/chat_screens.dart';
import '../../lib/widgets/ai_chat/ai_chat_widgets.dart';

void main() {
  group('AI Chat Widget Tests', () {
    late AIChatProvider mockAIChatProvider;
    late AntigravityProvider mockAntigravityProvider;

    setUp(() {
      mockAIChatProvider = MockAIChatProvider();
      mockAntigravityProvider = MockAntigravityProvider();
    });

    Widget createWidgetUnderTest(Widget child) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AIChatProvider>.value(value: mockAIChatProvider),
          ChangeNotifierProvider<AntigravityProvider>.value(value: mockAntigravityProvider),
        ],
        child: MaterialApp(
          home: child,
        ),
      );
    }

    group('ConversationListScreen Tests', () {
      testWidgets('should display conversation list correctly', (WidgetTester tester) async {
        // Arrange
        final conversations = [
          AIConversation(
            id: 'conv1',
            userId: 'user123',
            title: 'Test Conversation 1',
            type: ConversationType.chat,
            personality: CompanionPersonality.friendly,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            messageCount: 5,
          ),
          AIConversation(
            id: 'conv2',
            userId: 'user123',
            title: 'Test Conversation 2',
            type: ConversationType.recommendation,
            personality: CompanionPersonality.professional,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            messageCount: 3,
          ),
        ];

        when(mockAIChatProvider.conversations).thenReturn(conversations);
        when(mockAIChatProvider.isLoading).thenReturn(false);
        when(mockAIChatProvider.error).thenReturn(null);

        // Act
        await tester.pumpWidget(createWidgetUnderTest(const ConversationListScreen()));

        // Assert
        expect(find.text('Test Conversation 1'), findsOneWidget);
        expect(find.text('Test Conversation 2'), findsOneWidget);
        expect(find.text('5 messages'), findsOneWidget);
        expect(find.text('3 messages'), findsOneWidget);
        expect(find.byIcon(Icons.chat), findsWidgets);
        expect(find.byIcon(Icons.recommend), findsOneWidget);
      });

      testWidgets('should display loading state correctly', (WidgetTester tester) async {
        // Arrange
        when(mockAIChatProvider.conversations).thenReturn([]);
        when(mockAIChatProvider.isLoading).thenReturn(true);
        when(mockAIChatProvider.error).thenReturn(null);

        // Act
        await tester.pumpWidget(createWidgetUnderTest(const ConversationListScreen()));

        // Assert
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Loading conversations...'), findsOneWidget);
      });

      testWidgets('should display error state correctly', (WidgetTester tester) async {
        // Arrange
        when(mockAIChatProvider.conversations).thenReturn([]);
        when(mockAIChatProvider.isLoading).thenReturn(false);
        when(mockAIChatProvider.error).thenReturn('Failed to load conversations');

        // Act
        await tester.pumpWidget(createWidgetUnderTest(const ConversationListScreen()));

        // Assert
        expect(find.text('Failed to load conversations'), findsOneWidget);
        expect(find.byIcon(Icons.error), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      });

      testWidgets('should navigate to chat when conversation tapped', (WidgetTester tester) async {
        // Arrange
        final conversations = [
          AIConversation(
            id: 'conv1',
            userId: 'user123',
            title: 'Test Conversation',
            type: ConversationType.chat,
            personality: CompanionPersonality.friendly,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        when(mockAIChatProvider.conversations).thenReturn(conversations);
        when(mockAIChatProvider.isLoading).thenReturn(false);
        when(mockAIChatProvider.error).thenReturn(null);

        // Act
        await tester.pumpWidget(createWidgetUnderTest(const ConversationListScreen()));
        await tester.tap(find.text('Test Conversation'));
        await tester.pumpAndSettle();

        // Assert
        verify(mockAIChatProvider.selectConversation('conv1')).called(1);
      });

      testWidgets('should create new conversation when FAB tapped', (WidgetTester tester) async {
        // Arrange
        when(mockAIChatProvider.conversations).thenReturn([]);
        when(mockAIChatProvider.isLoading).thenReturn(false);
        when(mockAIChatProvider.error).thenReturn(null);

        // Act
        await tester.pumpWidget(createWidgetUnderTest(const ConversationListScreen()));
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('New Conversation'), findsOneWidget);
        expect(find.text('Create'), findsOneWidget);
      });
    });

    group('ChatScreen Tests', () {
      testWidgets('should display chat interface correctly', (WidgetTester tester) async {
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
            content: 'Hello AI',
            createdAt: DateTime.now(),
          ),
          AIMessage(
            id: 'msg2',
            conversationId: 'conv1',
            role: MessageRole.assistant,
            content: 'Hello! How can I help you?',
            createdAt: DateTime.now(),
          ),
        ];

        when(mockAIChatProvider.currentConversation).thenReturn(conversation);
        when(mockAIChatProvider.currentMessages).thenReturn(messages);
        when(mockAIChatProvider.isSendingMessage).thenReturn(false);
        when(mockAIChatProvider.isTyping).thenReturn(false);

        // Act
        await tester.pumpWidget(createWidgetUnderTest(const ChatScreen()));

        // Assert
        expect(find.text('Test Conversation'), findsOneWidget);
        expect(find.text('Hello AI'), findsOneWidget);
        expect(find.text('Hello! How can I help you?'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
        expect(find.byIcon(Icons.send), findsOneWidget);
      });

      testWidgets('should display typing indicator correctly', (WidgetTester tester) async {
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

        when(mockAIChatProvider.currentConversation).thenReturn(conversation);
        when(mockAIChatProvider.currentMessages).thenReturn([]);
        when(mockAIChatProvider.isSendingMessage).thenReturn(false);
        when(mockAIChatProvider.isTyping).thenReturn(true);

        // Act
        await tester.pumpWidget(createWidgetUnderTest(const ChatScreen()));

        // Assert
        expect(find.text('AI is typing...'), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should send message when send button tapped', (WidgetTester tester) async {
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

        when(mockAIChatProvider.currentConversation).thenReturn(conversation);
        when(mockAIChatProvider.currentMessages).thenReturn([]);
        when(mockAIChatProvider.isSendingMessage).thenReturn(false);
        when(mockAIChatProvider.isTyping).thenReturn(false);

        // Act
        await tester.pumpWidget(createWidgetUnderTest(const ChatScreen()));
        await tester.enterText(find.byType(TextField), 'Test message');
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        // Assert
        verify(mockAIChatProvider.sendMessage('Test message')).called(1);
      });

      testWidgets('should not send empty message', (WidgetTester tester) async {
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

        when(mockAIChatProvider.currentConversation).thenReturn(conversation);
        when(mockAIChatProvider.currentMessages).thenReturn([]);
        when(mockAIChatProvider.isSendingMessage).thenReturn(false);
        when(mockAIChatProvider.isTyping).thenReturn(false);

        // Act
        await tester.pumpWidget(createWidgetUnderTest(const ChatScreen()));
        await tester.tap(find.byIcon(Icons.send));
        await tester.pumpAndSettle();

        // Assert
        verifyNever(mockAIChatProvider.sendMessage(any));
      });
    });

    group('MessageBubble Tests', () {
      testWidgets('should display user message correctly', (WidgetTester tester) async {
        // Arrange
        final message = AIMessage(
          id: 'msg1',
          conversationId: 'conv1',
          role: MessageRole.user,
          content: 'Hello AI',
          createdAt: DateTime.now(),
        );

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MessageBubble(message: message),
            ),
          ),
        );

        // Assert
        expect(find.text('Hello AI'), findsOneWidget);
        expect(find.text('You'), findsOneWidget);
        expect(find.byIcon(Icons.person), findsOneWidget);
      });

      testWidgets('should display AI message correctly', (WidgetTester tester) async {
        // Arrange
        final message = AIMessage(
          id: 'msg1',
          conversationId: 'conv1',
          role: MessageRole.assistant,
          content: 'Hello! How can I help you?',
          createdAt: DateTime.now(),
        );

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MessageBubble(message: message),
            ),
          ),
        );

        // Assert
        expect(find.text('Hello! How can I help you?'), findsOneWidget);
        expect(find.text('AI'), findsOneWidget);
        expect(find.byIcon(Icons.smart_toy), findsOneWidget);
      });

      testWidgets('should display message timestamp correctly', (WidgetTester tester) async {
        // Arrange
        final timestamp = DateTime(2024, 1, 1, 12, 30);
        final message = AIMessage(
          id: 'msg1',
          conversationId: 'conv1',
          role: MessageRole.user,
          content: 'Hello AI',
          createdAt: timestamp,
        );

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MessageBubble(message: message),
            ),
          ),
        );

        // Assert
        expect(find.text('12:30 PM'), findsOneWidget);
      });
    });

    group('CompanionSelector Tests', () {
      testWidgets('should display companion list correctly', (WidgetTester tester) async {
        // Arrange
        final companions = [
          AICompanion(
            id: 'comp1',
            name: 'Friendly Bot',
            avatar: 'avatar1.jpg',
            personality: CompanionPersonality.friendly,
            description: 'A friendly companion',
            systemPrompt: 'You are friendly',
            capabilities: ['chat'],
            createdAt: DateTime.now(),
          ),
          AICompanion(
            id: 'comp2',
            name: 'Professional Bot',
            avatar: 'avatar2.jpg',
            personality: CompanionPersonality.professional,
            description: 'A professional assistant',
            systemPrompt: 'You are professional',
            capabilities: ['chat', 'recommend'],
            createdAt: DateTime.now(),
          ),
        ];

        when(mockAIChatProvider.companions).thenReturn(companions);
        when(mockAIChatProvider.selectedCompanion).thenReturn(null);

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CompanionSelector(),
            ),
          ),
        );

        // Assert
        expect(find.text('Friendly Bot'), findsOneWidget);
        expect(find.text('Professional Bot'), findsOneWidget);
        expect(find.text('A friendly companion'), findsOneWidget);
        expect(find.text('A professional assistant'), findsOneWidget);
        expect(find.byType(CircleAvatar), findsWidgets);
      });

      testWidgets('should select companion when tapped', (WidgetTester tester) async {
        // Arrange
        final companions = [
          AICompanion(
            id: 'comp1',
            name: 'Friendly Bot',
            avatar: 'avatar1.jpg',
            personality: CompanionPersonality.friendly,
            description: 'A friendly companion',
            systemPrompt: 'You are friendly',
            capabilities: ['chat'],
            createdAt: DateTime.now(),
          ),
        ];

        when(mockAIChatProvider.companions).thenReturn(companions);
        when(mockAIChatProvider.selectedCompanion).thenReturn(null);

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CompanionSelector(),
            ),
          ),
        );
        await tester.tap(find.text('Friendly Bot'));
        await tester.pumpAndSettle();

        // Assert
        verify(mockAIChatProvider.selectCompanion(any)).called(1);
      });

      testWidgets('should highlight selected companion', (WidgetTester tester) async {
        // Arrange
        final selectedCompanion = AICompanion(
          id: 'comp1',
          name: 'Friendly Bot',
          avatar: 'avatar1.jpg',
          personality: CompanionPersonality.friendly,
          description: 'A friendly companion',
          systemPrompt: 'You are friendly',
          capabilities: ['chat'],
          createdAt: DateTime.now(),
        );

        final companions = [selectedCompanion];

        when(mockAIChatProvider.companions).thenReturn(companions);
        when(mockAIChatProvider.selectedCompanion).thenReturn(selectedCompanion);

        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CompanionSelector(),
            ),
          ),
        );

        // Assert
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
      });
    });
  });
}

// Mock classes
class MockAIChatProvider extends Mock implements AIChatProvider {}
class MockAntigravityProvider extends Mock implements AntigravityProvider {}
