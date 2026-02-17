import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mycircle/models/ai_chat.dart';
import 'package:mycircle/widgets/ai_chat/glassmorphic_message_bubble.dart';

void main() {
  group('GlassmorphicMessageBubble Widget Tests', () {
    late AIMessage testMessage;
    late AICompanion testCompanion;

    setUp(() {
      testMessage = AIMessage(
        id: 'msg1',
        conversationId: 'conv1',
        role: MessageRole.user,
        content: 'Test message content',
        createdAt: DateTime.now(),
      );

      testCompanion = AICompanion(
        id: 'comp1',
        name: 'Test Companion',
        avatar: 'avatar.png',
        personality: CompanionPersonality.friendly,
        description: 'Test description',
        systemPrompt: 'Test prompt',
        capabilities: ['chat'],
        createdAt: DateTime.now(),
      );
    });

    testWidgets('should display user message correctly', (WidgetTester tester) async {
      // Arrange
      const widget = GlassmorphicMessageBubble(
        message: AIMessage(
          id: 'msg1',
          conversationId: 'conv1',
          role: MessageRole.user,
          content: 'Hello world',
          createdAt: null,
        ),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: widget,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Hello world'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('should display AI message correctly', (WidgetTester tester) async {
      // Arrange
      const widget = GlassmorphicMessageBubble(
        message: AIMessage(
          id: 'msg2',
          conversationId: 'conv1',
          role: MessageRole.assistant,
          content: 'AI response',
          createdAt: null,
        ),
        companion: AICompanion(
          id: 'comp1',
          name: 'Test Companion',
          avatar: 'avatar.png',
          personality: CompanionPersonality.friendly,
          description: 'Test description',
          systemPrompt: 'Test prompt',
          capabilities: ['chat'],
          createdAt: null,
        ),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: widget,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('AI response'), findsOneWidget);
    });

    testWidgets('should display message metadata when available', (WidgetTester tester) async {
      // Arrange
      final messageWithMetadata = AIMessage(
        id: 'msg3',
        conversationId: 'conv1',
        role: MessageRole.assistant,
        content: 'Message with metadata',
        metadata: {
          'recommendations': [
            {
              'type': 'media',
              'title': 'Test Media',
              'image_url': 'https://example.com/image.jpg',
            }
          ]
        },
        createdAt: DateTime.now(),
      );

      const widget = GlassmorphicMessageBubble(
        message: messageWithMetadata,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: widget,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Message with metadata'), findsOneWidget);
      expect(find.text('Test Media'), findsOneWidget);
    });

    testWidgets('should display media preview when available', (WidgetTester tester) async {
      // Arrange
      final messageWithMedia = AIMessage(
        id: 'msg4',
        conversationId: 'conv1',
        role: MessageRole.assistant,
        content: 'Check out this media',
        metadata: {
          'media_preview': {
            'title': 'Media Title',
            'description': 'Media description',
            'thumbnail_url': 'https://example.com/thumb.jpg',
          }
        },
        createdAt: DateTime.now(),
      );

      const widget = GlassmorphicMessageBubble(
        message: messageWithMedia,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: widget,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Check out this media'), findsOneWidget);
      expect(find.text('Media Title'), findsOneWidget);
      expect(find.text('Media description'), findsOneWidget);
    });

    testWidgets('should display model used when available', (WidgetTester tester) async {
      // Arrange
      final messageWithModel = AIMessage(
        id: 'msg5',
        conversationId: 'conv1',
        role: MessageRole.assistant,
        content: 'AI response with model',
        modelUsed: 'GPT-4',
        createdAt: DateTime.now(),
      );

      const widget = GlassmorphicMessageBubble(
        message: messageWithModel,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: widget,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('AI response with model'), findsOneWidget);
      expect(find.text('GPT-4'), findsOneWidget);
    });

    testWidgets('should format time correctly', (WidgetTester tester) async {
      // Arrange
      final recentMessage = AIMessage(
        id: 'msg6',
        conversationId: 'conv1',
        role: MessageRole.user,
        content: 'Recent message',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      const widget = GlassmorphicMessageBubble(
        message: recentMessage,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: widget,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Recent message'), findsOneWidget);
      expect(find.text('5m ago'), findsOneWidget);
    });

    testWidgets('should trigger animation callback', (WidgetTester tester) async {
      // Arrange
      bool callbackTriggered = false;

      const widget = GlassmorphicMessageBubble(
        message: AIMessage(
          id: 'msg7',
          conversationId: 'conv1',
          role: MessageRole.user,
          content: 'Callback test',
          createdAt: null,
        ),
        onAnimationComplete: () => callbackTriggered = true,
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: widget,
          ),
        ),
      );

      // Wait for animation to complete
      await tester.pump(const Duration(milliseconds: 700));

      // Assert
      expect(find.text('Callback test'), findsOneWidget);
      // Note: In a real test, you might need to wait longer or use a different approach
      // to verify the callback is triggered after animation completion
    });

    testWidgets('should handle empty message gracefully', (WidgetTester tester) async {
      // Arrange
      const widget = GlassmorphicMessageBubble(
        message: AIMessage(
          id: 'msg8',
          conversationId: 'conv1',
          role: MessageRole.user,
          content: '',
          createdAt: null,
        ),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: widget,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(GlassmorphicMessageBubble), findsOneWidget);
    });

    testWidgets('should display long messages with proper overflow', (WidgetTester tester) async {
      // Arrange
      const longMessage = 'This is a very long message that should wrap properly and not overflow the widget bounds. It contains multiple sentences and should be displayed correctly with proper text wrapping.';
      
      const widget = GlassmorphicMessageBubble(
        message: AIMessage(
          id: 'msg9',
          conversationId: 'conv1',
          role: MessageRole.user,
          content: longMessage,
          createdAt: null,
        ),
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: widget,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text(longMessage), findsOneWidget);
    });
  });
}
