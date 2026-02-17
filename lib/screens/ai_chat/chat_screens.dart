import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ai_chat_provider.dart';
import '../providers/antigravity_provider.dart';
import '../models/ai_chat.dart';
import '../widgets/ai_chat/message_bubble.dart';
import '../widgets/ai_chat/companion_selector.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<AIChatProvider>(
          builder: (context, provider, child) {
            final conversation = provider.currentConversation;
            return Text(
              conversation?.title ?? 'AI Chat',
              style: const TextStyle(fontWeight: FontWeight.w600),
            );
          },
        ),
        actions: [
          Consumer<AIChatProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: const Icon(Icons.person_outline),
                onPressed: () => _showCompanionSelector(context),
              );
            },
          ),
        ],
      ),
      body: Consumer<AIChatProvider>(
        builder: (context, provider, child) {
          if (provider.currentConversation == null) {
            return const Center(
              child: Text('Select a conversation to start chatting'),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.currentMessages.length + (provider.isTyping ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == provider.currentMessages.length && provider.isTyping) {
                      return _buildTypingIndicator();
                    }

                    final message = provider.currentMessages[index];
                    return MessageBubble(message: message);
                  },
                ),
              ),
              _buildMessageInput(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(width: 48),
          CircularProgressIndicator(strokeWidth: 2),
          SizedBox(width: 12),
          Text('AI is typing...'),
        ],
      ),
    );
  }

  Widget _buildMessageInput(AIChatProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (value) => _sendMessage(provider),
            ),
          ),
          const SizedBox(width: 12),
          if (provider.isSendingMessage)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              onPressed: () => _sendMessage(provider),
              icon: const Icon(Icons.send),
              style: IconButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
        ],
      ),
    );
  }

  void _sendMessage(AIChatProvider provider) {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    provider.sendMessage(text);
    _messageController.clear();
    _scrollToBottom();
  }

  void _showCompanionSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select AI Companion',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: CompanionSelector(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ConversationListScreen extends StatelessWidget {
  const ConversationListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chat'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer<AIChatProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading conversations...'),
                ],
              ),
            );
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    provider.error!,
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: provider.refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (provider.conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start a new conversation with an AI companion',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: provider.conversations.length,
            itemBuilder: (context, index) {
              final conversation = provider.conversations[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getPersonalityColor(conversation.personality),
                    child: Icon(
                      _getPersonalityIcon(conversation.personality),
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    conversation.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${conversation.messageCount} messages • ${conversation.personality.displayName}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _selectConversation(context, conversation.id),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createNewConversation(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Color _getPersonalityColor(CompanionPersonality personality) {
    switch (personality) {
      case CompanionPersonality.friendly:
        return Colors.green;
      case CompanionPersonality.professional:
        return Colors.blue;
      case CompanionPersonality.witty:
        return Colors.purple;
      case CompanionPersonality.supportive:
        return Colors.orange;
      case CompanionPersonality.analytical:
        return Colors.grey;
    }
  }

  IconData _getPersonalityIcon(CompanionPersonality personality) {
    switch (personality) {
      case CompanionPersonality.friendly:
        return Icons.sentiment_very_satisfied;
      case CompanionPersonality.professional:
        return Icons.business;
      case CompanionPersonality.witty:
        return Icons.sentiment_very_satisfied;
      case CompanionPersonality.supportive:
        return Icons.favorite;
      case CompanionPersonality.analytical:
        return Icons.psychology;
    }
  }

  void _selectConversation(BuildContext context, String conversationId) {
    final provider = Provider.of<AIChatProvider>(context, listen: false);
    provider.selectConversation(conversationId);
    
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatScreen()),
    );
  }

  void _createNewConversation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Conversation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const TextField(
              decoration: InputDecoration(
                labelText: 'Conversation Title',
                hintText: 'Enter a title for your conversation',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ConversationType>(
              decoration: const InputDecoration(
                labelText: 'Conversation Type',
              ),
              value: ConversationType.chat,
              items: ConversationType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.displayName),
                );
              }).toList(),
              onChanged: (value) {},
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CompanionPersonality>(
              decoration: const InputDecoration(
                labelText: 'AI Personality',
              ),
              value: CompanionPersonality.friendly,
              items: CompanionPersonality.values.map((personality) {
                return DropdownMenuItem(
                  value: personality,
                  child: Text(personality.displayName),
                );
              }).toList(),
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Create conversation logic here
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
