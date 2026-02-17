import 'package:flutter/foundation.dart';
import 'stream_provider.dart';
import 'stream_chat_provider.dart';

/// Combined provider that manages all streaming-related state
/// This makes it easier to use in widgets and ensures proper coordination
/// between different streaming features.
class StreamCombinedProvider extends ChangeNotifier {
  final StreamProvider _streamProvider;
  final StreamChatProvider _chatProvider;

  StreamCombinedProvider({
    required StreamProvider streamProvider,
    required StreamChatProvider chatProvider,
  })  : _streamProvider = streamProvider,
        _chatProvider = chatProvider {
    // Listen to changes in individual providers
    _streamProvider.addListener(_onStreamProviderChanged);
    _chatProvider.addListener(_onChatProviderChanged);
  }

  // Stream Provider Delegates
  bool get isLoading => _streamProvider.isLoading || _chatProvider.isLoading;
  String? get error => _streamProvider.error ?? _chatProvider.error;
  bool get isStreaming => _streamProvider.isStreaming;
  
  // Stream Data
  List get liveStreams => _streamProvider.liveStreams;
  List get scheduledStreams => _streamProvider.scheduledStreams;
  List get trendingStreams => _streamProvider.trendingStreams;
  List get followingStreams => _streamProvider.followingStreams;
  List get nearbyStreams => _streamProvider.nearbyStreams;
  Map<String, List> get streamsByCategory => _streamProvider.streamsByCategory;
  List get streamHistory => _streamProvider.streamHistory;
  get currentStream => _streamProvider.currentStream;
  List get currentViewers => _streamProvider.currentViewers;
  get streamStats => _streamProvider.streamStats;

  // Chat Data
  List get chatMessages => _chatProvider.messages;
  List get reactions => _chatProvider.reactions;
  bool get isChatConnected => _chatProvider.isConnected;
  bool get isSendingMessage => _chatProvider.isSending;
  int get unreadCount => _chatProvider.unreadCount;
  bool get hasMoreMessages => _chatProvider.hasMoreMessages;
  Set<String> get blockedUsers => _chatProvider.blockedUsers;
  Set<String> get blockedWords => _chatProvider.blockedWords;
  bool get isModerator => _chatProvider.isModerator;
  bool get isStreamer => _chatProvider.isStreamer;

  // Pagination Controllers
  get liveStreamsPagingController => _streamProvider.liveStreamsPagingController;
  get scheduledStreamsPagingController => _streamProvider.scheduledStreamsPagingController;

  // Stream Operations
  Future<void> refreshAll() async {
    await _streamProvider.refreshAll();
  }

  Future<void> refreshLiveStreams() async {
    await _streamProvider.refreshLiveStreams();
  }

  Future<void> refreshScheduledStreams() async {
    await _streamProvider.refreshScheduledStreams();
  }

  Future<void> loadFollowingStreams({bool refresh = false}) async {
    await _streamProvider.loadFollowingStreams(refresh: refresh);
  }

  Future<void> loadNearbyStreams({bool refresh = false}) async {
    await _streamProvider.loadNearbyStreams(refresh: refresh);
  }

  Future<void> loadStreamHistory({bool refresh = false}) async {
    await _streamProvider.loadStreamHistory(refresh: refresh);
  }

  Future<void> loadStreamById(String streamId) async {
    await _streamProvider.loadStreamById(streamId);
  }

  Future<void> loadStreamViewers(String streamId) async {
    await _streamProvider.loadStreamViewers(streamId);
  }

  Future<void> loadStreamAnalytics() async {
    await _streamProvider.loadStreamAnalytics();
  }

  Future<void> joinStream(String streamId) async {
    await _streamProvider.joinStream(streamId);
    // Auto-connect to chat when joining a stream
    await _chatProvider.connectToStreamChat(streamId);
  }

  Future<void> leaveStream() async {
    await _streamProvider.leaveStream();
    await _chatProvider.disconnect();
  }

  Future<void> searchStreams(String query) async {
    _streamProvider.searchStreams(query);
  }

  void selectCategory(String category) {
    _streamProvider.selectCategory(category);
  }

  Future<void> sendReaction(String streamId, String reactionType) async {
    await _streamProvider.sendReaction(streamId, reactionType);
  }

  Future<void> updateStream(String streamId, Map<String, dynamic> data) async {
    await _streamProvider.updateStream(streamId, data);
  }

  // Stream Creation and Management
  Future createStream(Map<String, dynamic> streamData) async {
    return await _streamProvider.createStream(streamData);
  }

  Future<void> startStream(String streamId) async {
    await _streamProvider.startStream(streamId);
  }

  Future<void> endStream(String streamId) async {
    await _streamProvider.endStream(streamId);
  }

  // Chat Operations
  Future<void> connectToChat(String streamId) async {
    await _chatProvider.connectToStreamChat(streamId);
  }

  Future<void> disconnectFromChat() async {
    await _chatProvider.disconnect();
  }

  Future<void> sendMessage(String content) async {
    await _chatProvider.sendMessage(content);
  }

  Future<void> loadMoreMessages() async {
    await _chatProvider.loadMoreMessages();
  }

  Future<void> sendReactionToMessage(String messageId, String reactionType) async {
    await _chatProvider.sendReactionToMessage(messageId, reactionType);
  }

  Future<void> sendStreamReaction(String reactionType) async {
    await _chatProvider.sendStreamReaction(reactionType);
  }

  // Chat Moderation
  Future<void> deleteMessage(String messageId) async {
    await _chatProvider.deleteMessage(messageId);
  }

  Future<void> pinMessage(String messageId) async {
    await _chatProvider.pinMessage(messageId);
  }

  Future<void> blockUser(String userId) async {
    await _chatProvider.blockUser(userId);
  }

  Future<void> reportMessage(String messageId, String reason) async {
    await _chatProvider.reportMessage(messageId, reason);
  }

  // Chat Utilities
  void markMessagesAsRead() {
    _chatProvider.markAsRead();
  }

  void clearChatMessages() {
    _chatProvider.clearMessages();
  }

  List searchChatMessages(String query) {
    return _chatProvider.searchMessages(query);
  }

  List getMessagesFromUser(String userId) {
    return _chatProvider.getMessagesFromUser(userId);
  }

  List getPinnedMessages() {
    return _chatProvider.getPinnedMessages();
  }

  Map<String, int> getChatMessageStats() {
    return _chatProvider.getMessageStats();
  }

  // Utility Methods
  void clearAll() {
    _streamProvider.clearAll();
    _chatProvider.clearMessages();
  }

  // Stream Status Helpers
  bool get hasActiveStream => currentStream != null;
  bool get isCurrentStreamLive => currentStream?.isLive ?? false;
  bool get isCurrentStreamScheduled => currentStream?.isScheduled ?? false;
  bool get canModerateChat => isModerator || isStreamer;

  // Stream Statistics Helpers
  int get currentViewerCount => currentStream?.viewerCount ?? 0;
  int get peakViewerCount => streamStats?.peakViewers ?? 0;
  double get averageWatchTime => streamStats?.averageWatchTime ?? 0.0;
  double get engagementRate => streamStats?.engagementRate ?? 0.0;

  // Chat Statistics Helpers
  int get totalMessageCount => chatMessages.length;
  int get totalReactionCount => reactions.length;
  bool get hasUnreadMessages => unreadCount > 0;

  // Private Methods
  void _onStreamProviderChanged() {
    notifyListeners();
  }

  void _onChatProviderChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _streamProvider.removeListener(_onStreamProviderChanged);
    _chatProvider.removeListener(_onChatProviderChanged);
    super.dispose();
  }
}
