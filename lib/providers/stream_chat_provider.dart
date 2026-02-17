import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/stream_chat_model.dart';
import '../../models/stream_viewer_model.dart';
import '../../services/stream_service.dart';

class StreamChatProvider extends ChangeNotifier {
  final StreamService _streamService = StreamService();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Chat State
  List<StreamChatMessage> _messages = [];
  List<StreamReaction> _reactions = [];
  bool _isConnected = false;
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;
  int _unreadCount = 0;
  String? _currentStreamId;
  
  // Real-time Subscription
  RealtimeChannel? _chatChannel;
  RealtimeChannel? _reactionChannel;
  
  // Pagination
  static const int _pageSize = 50;
  bool _hasMoreMessages = true;
  int _currentPage = 1;
  
  // Cache Management
  final Map<String, List<StreamChatMessage>> _messageCache = {};
  final Map<String, List<StreamReaction>> _reactionCache = {};
  static const Duration _cacheExpiry = Duration(minutes: 10);
  final Map<String, DateTime> _cacheTimestamps = {};

  // Moderation State
  Set<String> _blockedUsers = {};
  Set<String> _blockedWords = {};
  bool _isModerator = false;
  bool _isStreamer = false;

  // Getters
  List<StreamChatMessage> get messages => _messages;
  List<StreamReaction> get reactions => _reactions;
  bool get isConnected => _isConnected;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _error;
  int get unreadCount => _unreadCount;
  String? get currentStreamId => _currentStreamId;
  bool get hasMoreMessages => _hasMoreMessages;
  Set<String> get blockedUsers => _blockedUsers;
  Set<String> get blockedWords => _blockedWords;
  bool get isModerator => _isModerator;
  bool get isStreamer => _isStreamer;

  StreamChatProvider() {
    _loadBlockedContent();
  }

  // Connection Management
  Future<void> connectToStreamChat(String streamId) async {
    if (_currentStreamId == streamId && _isConnected) return;

    await disconnect(); // Disconnect from previous stream

    _setLoading(true);
    _clearError();

    try {
      _currentStreamId = streamId;
      
      // Check user permissions
      await _checkUserPermissions(streamId);
      
      // Load initial messages from cache or service
      await _loadInitialMessages(streamId);
      
      // Load initial reactions
      await _loadInitialReactions(streamId);
      
      // Set up real-time listeners
      await _setupRealtimeListeners(streamId);
      
      _isConnected = true;
      _unreadCount = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('Connect to stream chat error: $e');
      _setError('Failed to connect to chat: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> disconnect() async {
    try {
      _isConnected = false;
      _currentStreamId = null;
      _messages.clear();
      _reactions.clear();
      _unreadCount = 0;
      
      // Clean up real-time listeners
      await _cleanupRealtimeListeners();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Disconnect from chat error: $e');
    }
  }

  // Message Operations
  Future<void> sendMessage(String content) async {
    if (!_isConnected || _currentStreamId == null || content.trim().isEmpty) {
      return;
    }

    if (_isSending) return; // Prevent duplicate sends

    // Check if message is blocked
    if (_isMessageBlocked(content)) {
      _setError('Message contains blocked content');
      return;
    }

    _setSending(true);
    _clearError();

    try {
      final message = await _streamService.sendChatMessage(
        _currentStreamId!,
        content.trim(),
      );
      
      // Add message to local list immediately for better UX
      _messages.insert(0, message);
      
      // Update cache
      _updateMessageCache(_currentStreamId!, _messages);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Send message error: $e');
      _setError('Failed to send message: $e');
    } finally {
      _setSending(false);
    }
  }

  Future<void> loadMoreMessages() async {
    if (!_isConnected || _currentStreamId == null || _isLoading || !_hasMoreMessages) {
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final oldestMessage = _messages.isNotEmpty ? _messages.last : null;
      final olderMessages = await _streamService.getOlderMessages(
        _currentStreamId!,
        before: oldestMessage?.timestamp,
        limit: _pageSize,
      );
      
      if (olderMessages.isEmpty) {
        _hasMoreMessages = false;
      } else {
        _messages.addAll(olderMessages.reversed);
        _updateMessageCache(_currentStreamId!, _messages);
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Load more messages error: $e');
      _setError('Failed to load more messages: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Reaction Operations
  Future<void> sendReactionToMessage(String messageId, String reactionType) async {
    try {
      await _streamService.sendReactionToMessage(messageId, reactionType);
      
      // Update local message
      final messageIndex = _messages.indexWhere((m) => m.id == messageId);
      if (messageIndex != -1) {
        final message = _messages[messageIndex];
        if (!message.reactions.contains(reactionType)) {
          _messages[messageIndex] = message.copyWith(
            reactions: [...message.reactions, reactionType],
          );
          _updateMessageCache(_currentStreamId!, _messages);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Send reaction to message error: $e');
      _setError('Failed to send reaction: $e');
    }
  }

  Future<void> sendStreamReaction(String reactionType) async {
    if (!_isConnected || _currentStreamId == null) {
      return;
    }

    try {
      await _streamService.sendReaction(_currentStreamId!, reactionType);
      
      // Add to local reactions list
      final reaction = StreamReaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        streamId: _currentStreamId!,
        userId: _supabase.auth.currentUser?.id ?? '',
        reactionType: reactionType,
        timestamp: DateTime.now(),
      );
      
      _reactions.insert(0, reaction);
      _updateReactionCache(_currentStreamId!, _reactions);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Send stream reaction error: $e');
      _setError('Failed to send reaction: $e');
    }
  }

  // Moderation Operations
  Future<void> deleteMessage(String messageId) async {
    if (!_isModerator && !_isStreamer) {
      _setError('You do not have permission to delete messages');
      return;
    }

    try {
      await _streamService.deleteMessage(messageId);
      
      // Remove from local list
      _messages.removeWhere((m) => m.id == messageId);
      _updateMessageCache(_currentStreamId!, _messages);
      notifyListeners();
    } catch (e) {
      debugPrint('Delete message error: $e');
      _setError('Failed to delete message: $e');
    }
  }

  Future<void> pinMessage(String messageId) async {
    if (!_isModerator && !_isStreamer) {
      _setError('You do not have permission to pin messages');
      return;
    }

    try {
      await _streamService.pinMessage(messageId);
      
      // Update local message
      final messageIndex = _messages.indexWhere((m) => m.id == messageId);
      if (messageIndex != -1) {
        _messages[messageIndex] = _messages[messageIndex].copyWith(
          isPinned: true,
        );
        
        // Move pinned message to top
        final pinnedMessage = _messages.removeAt(messageIndex);
        _messages.insert(0, pinnedMessage);
        
        _updateMessageCache(_currentStreamId!, _messages);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Pin message error: $e');
      _setError('Failed to pin message: $e');
    }
  }

  Future<void> blockUser(String userId) async {
    try {
      await _streamService.blockUser(userId);
      _blockedUsers.add(userId);
      
      // Remove all messages from this user
      _messages.removeWhere((m) => m.userId == userId);
      _updateMessageCache(_currentStreamId!, _messages);
      notifyListeners();
    } catch (e) {
      debugPrint('Block user error: $e');
      _setError('Failed to block user: $e');
    }
  }

  Future<void> reportMessage(String messageId, String reason) async {
    try {
      await _streamService.reportMessage(messageId, reason);
    } catch (e) {
      debugPrint('Report message error: $e');
      _setError('Failed to report message: $e');
    }
  }

  // Utility Methods
  void markAsRead() {
    _unreadCount = 0;
    notifyListeners();
  }

  void clearMessages() {
    _messages.clear();
    _reactions.clear();
    _unreadCount = 0;
    notifyListeners();
  }

  List<StreamChatMessage> searchMessages(String query) {
    if (query.isEmpty) return _messages;
    
    final lowerQuery = query.toLowerCase();
    return _messages.where((message) {
      return message.content.toLowerCase().contains(lowerQuery) ||
             message.userName.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  List<StreamChatMessage> getMessagesFromUser(String userId) {
    return _messages.where((message) => message.userId == userId).toList();
  }

  List<StreamChatMessage> getPinnedMessages() {
    return _messages.where((message) => message.isPinned).toList();
  }

  Map<String, int> getMessageStats() {
    final stats = <String, int>{};
    
    for (final message in _messages) {
      // Count messages by user
      final userKey = 'user_${message.userId}';
      stats[userKey] = (stats[userKey] ?? 0) + 1;
      
      // Count reactions
      for (final reaction in message.reactions) {
        final reactionKey = 'reaction_$reaction';
        stats[reactionKey] = (stats[reactionKey] ?? 0) + 1;
      }
    }
    
    return stats;
  }

  // Private Methods
  Future<void> _checkUserPermissions(String streamId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Check if user is streamer
      final stream = await _streamService.getStreamById(streamId);
      _isStreamer = stream?.streamerId == userId;

      // Check if user is moderator (this would typically come from a separate table)
      // For now, we'll assume verified users are moderators
      _isModerator = false; // Implement based on your moderation system
    } catch (e) {
      debugPrint('Check user permissions error: $e');
    }
  }

  Future<void> _loadInitialMessages(String streamId) async {
    // Check cache first
    if (_messageCache.containsKey(streamId)) {
      final timestamp = _cacheTimestamps[streamId];
      if (timestamp != null && 
          DateTime.now().difference(timestamp) < _cacheExpiry) {
        _messages = _messageCache[streamId]!;
        return;
      }
    }

    // Load from service
    final messages = await _streamService.getStreamChat(streamId);
    _messages = messages.reversed.toList(); // Show newest first
    _updateMessageCache(streamId, _messages);
  }

  Future<void> _loadInitialReactions(String streamId) async {
    // Check cache first
    if (_reactionCache.containsKey(streamId)) {
      final timestamp = _cacheTimestamps['reactions_$streamId'];
      if (timestamp != null && 
          DateTime.now().difference(timestamp) < _cacheExpiry) {
        _reactions = _reactionCache[streamId]!;
        return;
      }
    }

    // Load from service (implement this method in StreamService)
    _reactions = []; // For now, empty until implemented
    _updateReactionCache(streamId, _reactions);
  }

  Future<void> _setupRealtimeListeners(String streamId) async {
    try {
      // Listen for new messages
      _chatChannel = _supabase.channel('stream_chat_$streamId');
      _chatChannel?.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'stream_chat_messages',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'stream_id',
          value: streamId,
        ),
        callback: (payload) {
          _handleNewMessage(StreamChatMessage.fromMap(payload.newRecord));
        },
      ).subscribe();

      // Listen for new reactions
      _reactionChannel = _supabase.channel('stream_reactions_$streamId');
      _reactionChannel?.onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'stream_reactions',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'stream_id',
          value: streamId,
        ),
        callback: (payload) {
          _handleNewReaction(StreamReaction.fromMap(payload.newRecord));
        },
      ).subscribe();
    } catch (e) {
      debugPrint('Setup realtime listeners error: $e');
    }
  }

  Future<void> _cleanupRealtimeListeners() async {
    try {
      await _chatChannel?.unsubscribe();
      await _reactionChannel?.unsubscribe();
      _chatChannel = null;
      _reactionChannel = null;
    } catch (e) {
      debugPrint('Cleanup realtime listeners error: $e');
    }
  }

  void _handleNewMessage(StreamChatMessage message) {
    if (message.streamId == _currentStreamId) {
      // Check if message is from blocked user
      if (_blockedUsers.contains(message.userId)) {
        return;
      }

      // Check if message contains blocked words
      if (_isMessageBlocked(message.content)) {
        return;
      }

      _messages.insert(0, message);
      _updateMessageCache(_currentStreamId!, _messages);
      
      // Only increment unread count if user is not focused on chat
      _unreadCount++;
      
      notifyListeners();
    }
  }

  void _handleNewReaction(StreamReaction reaction) {
    if (reaction.streamId == _currentStreamId) {
      _reactions.insert(0, reaction);
      _updateReactionCache(_currentStreamId!, _reactions);
      notifyListeners();
    }
  }

  bool _isMessageBlocked(String content) {
    final lowerContent = content.toLowerCase();
    
    // Check for blocked words
    for (final word in _blockedWords) {
      if (lowerContent.contains(word.toLowerCase())) {
        return true;
      }
    }
    
    return false;
  }

  Future<void> _loadBlockedContent() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      // Load blocked users (implement this in your service)
      _blockedUsers = {}; // For now, empty
      
      // Load blocked words (implement this in your service)
      _blockedWords = {}; // For now, empty
    } catch (e) {
      debugPrint('Load blocked content error: $e');
    }
  }

  void _updateMessageCache(String streamId, List<StreamChatMessage> messages) {
    _messageCache[streamId] = messages;
    _cacheTimestamps[streamId] = DateTime.now();
  }

  void _updateReactionCache(String streamId, List<StreamReaction> reactions) {
    _reactionCache[streamId] = reactions;
    _cacheTimestamps['reactions_$streamId'] = DateTime.now();
  }

  void _clearExpiredCache() {
    final now = DateTime.now();
    _cacheTimestamps.removeWhere((key, timestamp) {
      if (now.difference(timestamp) > _cacheExpiry) {
        if (key.startsWith('reactions_')) {
          _reactionCache.remove(key.substring(11)); // Remove 'reactions_' prefix
        } else {
          _messageCache.remove(key);
        }
        return true;
      }
      return false;
    });
  }

  // State Management
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setSending(bool sending) {
    _isSending = sending;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _cleanupRealtimeListeners();
    super.dispose();
  }
}
