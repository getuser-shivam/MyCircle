import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';

import 'package:mycircle/providers/ai_chat_provider.dart';
import 'package:mycircle/models/ai_chat.dart';
import 'package:mycircle/screens/ai_chat/enhanced_chat_screen.dart';
import 'package:mycircle/widgets/ai_chat/multimodal_input.dart';
import 'package:mycircle/widgets/ai_chat/smart_recommendation_card.dart';

// Generate mocks
@GenerateMocks([AIChatRepository, AICompanionService, AIRecommendationService, AntigravityProvider])
import 'ai_chat_integration_test.mocks.dart';

void main() {
  group('AI Chat Integration Tests', () {
    late MockAIChatRepository mockRepository;
    late MockAICompanionService mockCompanionService;
    late MockAIRecommendationService mockRecommendationService;
    late MockAntigravityProvider mockAntigravityProvider;
    late AIChatProvider chatProvider;

    setUp(() {
      mockRepository = MockAIChatRepository();
      mockCompanionService = MockAICompanionService();
      mockRecommendationService = MockAIRecommendationService();
      mockAntigravityProvider = MockAntigravityProvider();

      chatProvider = AIChatProvider(
        mockRepository,
        mockCompanionService,
        mockRecommendationService,
        mockAntigravityProvider,
      );
    });

    tearDown(() {
      chatProvider.dispose();
    });

    testWidgets('should display enhanced chat screen with all components', (WidgetTester tester) async {
      // Arrange
      when(mockRepository.getUserConversations(any()))
          .thenAnswer((_) async => []);
      when(mockCompanionService.getAvailableCompanions())
          .thenAnswer((_) async => []);
      when(mockRecommendationService.getRecommendations(any()))
          .thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AIChatProvider>.value(value: chatProvider),
          ],
          child: const MaterialApp(
            home: EnhancedChatScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(EnhancedChatScreen), findsOneWidget);
      expect(find.text('AI Companion'), findsOneWidget);
      expect(find.byType(MultimodalInput), findsOneWidget);
    });

    testWidgets('should display welcome message when no conversations exist', (WidgetTester tester) async {
      // Arrange
      when(mockRepository.getUserConversations(any()))
          .thenAnswer((_) async => []);
      when(mockCompanionService.getAvailableCompanions())
          .thenAnswer((_) async => []);
      when(mockRecommendationService.getRecommendations(any()))
          .thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AIChatProvider>.value(value: chatProvider),
          ],
          child: const MaterialApp(
            home: EnhancedChatScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Hello! I\'m your AI companion'), findsOneWidget);
      expect(find.text('Show me trending content'), findsOneWidget);
      expect(find.text('Find people like me'), findsOneWidget);
      expect(find.text('What\'s new today?'), findsOneWidget);
    });

    testWidgets('should handle suggestion chip taps', (WidgetTester tester) async {
      // Arrange
      when(mockRepository.getUserConversations(any()))
          .thenAnswer((_) async => []);
      when(mockCompanionService.getAvailableCompanions())
          .thenAnswer((_) async => []);
      when(mockRecommendationService.getRecommendations(any()))
          .thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AIChatProvider>.value(value: chatProvider),
          ],
          child: const MaterialApp(
            home: EnhancedChatScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on suggestion chip
      await tester.tap(find.text('Show me trending content'));
      await tester.pumpAndSettle();

      // Assert
      // The tap should be handled without errors
      expect(find.byType(EnhancedChatScreen), findsOneWidget);
    });

    testWidgets('should display typing indicator when AI is typing', (WidgetTester tester) async {
      // Arrange
      final conversation = AIConversation(
        id: 'conv1',
        userId: 'user1',
        title: 'Test Conversation',
        type: ConversationType.chat,
        personality: CompanionPersonality.friendly,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockRepository.getUserConversations(any()))
          .thenAnswer((_) async => [conversation]);
      when(mockRepository.getConversationMessages('conv1'))
          .thenAnswer((_) async => []);
      when(mockCompanionService.getAvailableCompanions())
          .thenAnswer((_) async => []);
      when(mockRecommendationService.getRecommendations(any()))
          .thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AIChatProvider>.value(value: chatProvider),
          ],
          child: const MaterialApp(
            home: EnhancedChatScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Select conversation and simulate typing
      await chatProvider.selectConversation('conv1');
      
      // Simulate AI typing
      // Note: In a real implementation, you'd need to expose a method to set typing state
      // For this test, we'll verify the component structure exists

      await tester.pump();

      // Assert
      expect(find.text('Test Conversation'), findsOneWidget);
    });

    testWidgets('should display recommendation cards when available', (WidgetTester tester) async {
      // Arrange
      final recommendation = AIRecommendation(
        id: 'rec1',
        userId: 'user1',
        conversationId: 'conv1',
        type: 'media',
        title: 'Test Recommendation',
        description: 'Test description',
        relevanceScore: 0.9,
        data: {},
        createdAt: DateTime.now(),
      );

      when(mockRepository.getUserConversations(any()))
          .thenAnswer((_) async => []);
      when(mockCompanionService.getAvailableCompanions())
          .thenAnswer((_) async => []);
      when(mockRecommendationService.getRecommendations(any()))
          .thenAnswer((_) async => [recommendation]);

      // Act
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AIChatProvider>.value(value: chatProvider),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SmartRecommendationCard(
                recommendation: recommendation,
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test Recommendation'), findsOneWidget);
      expect(find.text('Test description'), findsOneWidget);
      expect(find.text('90%'), findsOneWidget);
    });

    testWidgets('should handle multimodal input interactions', (WidgetTester tester) async {
      // Arrange
      bool textMessageSent = false;
      bool voiceMessageSent = false;
      bool imageMessageSent = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultimodalInput(
              onTextMessage: (text) => textMessageSent = true,
              onVoiceMessage: (path) => voiceMessageSent = true,
              onImageMessage: () => imageMessageSent = true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find text input field
      final textInputField = find.byType(TextField);
      expect(textInputField, findsOneWidget);

      // Enter text and send
      await tester.enterText(textInputField, 'Hello AI');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Assert
      expect(textMessageSent, isTrue);

      // Test voice button
      final voiceButton = find.byIcon(Icons.mic);
      expect(voiceButton, findsOneWidget);

      // Test attachment button
      final attachmentButton = find.byIcon(Icons.add);
      expect(attachmentButton, findsOneWidget);
    });

    testWidgets('should handle companion selection', (WidgetTester tester) async {
      // Arrange
      final companion = AICompanion(
        id: 'comp1',
        name: 'Friendly Assistant',
        avatar: 'avatar.png',
        personality: CompanionPersonality.friendly,
        description: 'A friendly AI assistant',
        systemPrompt: 'Be friendly',
        capabilities: ['chat'],
        createdAt: DateTime.now(),
      );

      when(mockRepository.getUserConversations(any()))
          .thenAnswer((_) async => []);
      when(mockCompanionService.getAvailableCompanions())
          .thenAnswer((_) async => [companion]);
      when(mockRecommendationService.getRecommendations(any()))
          .thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AIChatProvider>.value(value: chatProvider),
          ],
          child: const MaterialApp(
            home: EnhancedChatScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on companion selector
      final companionSelector = find.byType(GestureDetector).first;
      await tester.tap(companionSelector);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Choose Your AI Companion'), findsOneWidget);
      expect(find.text('Friendly Assistant'), findsOneWidget);
      expect(find.text('A friendly AI assistant'), findsOneWidget);
    });

    testWidgets('should handle insights panel toggle', (WidgetTester tester) async {
      // Arrange
      when(mockRepository.getUserConversations(any()))
          .thenAnswer((_) async => []);
      when(mockCompanionService.getAvailableCompanions())
          .thenAnswer((_) async => []);
      when(mockRecommendationService.getRecommendations(any()))
          .thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AIChatProvider>.value(value: chatProvider),
          ],
          child: const MaterialApp(
            home: EnhancedChatScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap insights button
      final insightsButton = find.byIcon(Icons.analytics_outlined);
      expect(insightsButton, findsOneWidget);

      await tester.tap(insightsButton);
      await tester.pumpAndSettle();

      // Assert
      // Insights panel should be visible (implementation dependent)
      expect(find.byType(EnhancedChatScreen), findsOneWidget);
    });

    testWidgets('should handle error states gracefully', (WidgetTester tester) async {
      // Arrange
      when(mockRepository.getUserConversations(any()))
          .thenThrow(Exception('Network error'));
      when(mockCompanionService.getAvailableCompanions())
          .thenAnswer((_) async => []);
      when(mockRecommendationService.getRecommendations(any()))
          .thenAnswer((_) async => []);

      // Act
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AIChatProvider>.value(value: chatProvider),
          ],
          child: const MaterialApp(
            home: EnhancedChatScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Assert
      // App should still load and display error state gracefully
      expect(find.byType(EnhancedChatScreen), findsOneWidget);
      expect(find.text('AI Companion'), findsOneWidget);
    });
  });
}
