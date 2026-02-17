class StreamChatMessage {
  final String id;
  final String streamId;
  final String userId;
  final String userName;
  final String userAvatar;
  final String content;
  final bool isModerator;
  final bool isStreamer;
  final DateTime timestamp;
  final String? parentMessageId;
  final List<String> reactions;
  final bool isDeleted;
  final bool isPinned;

  StreamChatMessage({
    required this.id,
    required this.streamId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.content,
    required this.isModerator,
    required this.isStreamer,
    required this.timestamp,
    this.parentMessageId,
    required this.reactions,
    this.isDeleted = false,
    this.isPinned = false,
  });

  factory StreamChatMessage.fromMap(Map<String, dynamic> data) {
    return StreamChatMessage(
      id: data['id']?.toString() ?? '',
      streamId: data['stream_id']?.toString() ?? '',
      userId: data['user_id']?.toString() ?? '',
      userName: data['user_name'] ?? data['profiles']?['username'] ?? 'User',
      userAvatar: data['user_avatar'] ?? data['profiles']?['avatar_url'] ?? '',
      content: data['content'] ?? '',
      isModerator: data['is_moderator'] ?? false,
      isStreamer: data['is_streamer'] ?? false,
      timestamp: DateTime.parse(data['created_at'] ?? DateTime.now().toIso8601String()),
      parentMessageId: data['parent_message_id']?.toString(),
      reactions: List<String>.from(data['reactions'] ?? []),
      isDeleted: data['is_deleted'] ?? false,
      isPinned: data['is_pinned'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'stream_id': streamId,
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'content': content,
      'is_moderator': isModerator,
      'is_streamer': isStreamer,
      'parent_message_id': parentMessageId,
      'reactions': reactions,
      'is_deleted': isDeleted,
      'is_pinned': isPinned,
      'created_at': timestamp.toIso8601String(),
    };
  }

  StreamChatMessage copyWith({
    String? id,
    String? streamId,
    String? userId,
    String? userName,
    String? userAvatar,
    String? content,
    bool? isModerator,
    bool? isStreamer,
    DateTime? timestamp,
    String? parentMessageId,
    List<String>? reactions,
    bool? isDeleted,
    bool? isPinned,
  }) {
    return StreamChatMessage(
      id: id ?? this.id,
      streamId: streamId ?? this.streamId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      content: content ?? this.content,
      isModerator: isModerator ?? this.isModerator,
      isStreamer: isStreamer ?? this.isStreamer,
      timestamp: timestamp ?? this.timestamp,
      parentMessageId: parentMessageId ?? this.parentMessageId,
      reactions: reactions ?? this.reactions,
      isDeleted: isDeleted ?? this.isDeleted,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  bool get isReply => parentMessageId != null;
  bool get isFromStaff => isModerator || isStreamer;
  bool get hasReactions => reactions.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StreamChatMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'StreamChatMessage(id: $id, userName: $userName, content: ${content.length > 50 ? content.substring(0, 50) + "..." : content})';
  }
}

class StreamReaction {
  final String id;
  final String streamId;
  final String userId;
  final String reactionType;
  final DateTime timestamp;
  final String? userName;
  final String? userAvatar;

  StreamReaction({
    required this.id,
    required this.streamId,
    required this.userId,
    required this.reactionType,
    required this.timestamp,
    this.userName,
    this.userAvatar,
  });

  factory StreamReaction.fromMap(Map<String, dynamic> data) {
    return StreamReaction(
      id: data['id']?.toString() ?? '',
      streamId: data['stream_id']?.toString() ?? '',
      userId: data['user_id']?.toString() ?? '',
      reactionType: data['reaction_type'] ?? '',
      timestamp: DateTime.parse(data['created_at'] ?? DateTime.now().toIso8601String()),
      userName: data['user_name'] ?? data['profiles']?['username'],
      userAvatar: data['user_avatar'] ?? data['profiles']?['avatar_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'stream_id': streamId,
      'user_id': userId,
      'reaction_type': reactionType,
      'user_name': userName,
      'user_avatar': userAvatar,
      'created_at': timestamp.toIso8601String(),
    };
  }

  StreamReaction copyWith({
    String? id,
    String? streamId,
    String? userId,
    String? reactionType,
    DateTime? timestamp,
    String? userName,
    String? userAvatar,
  }) {
    return StreamReaction(
      id: id ?? this.id,
      streamId: streamId ?? this.streamId,
      userId: userId ?? this.userId,
      reactionType: reactionType ?? this.reactionType,
      timestamp: timestamp ?? this.timestamp,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StreamReaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'StreamReaction(id: $id, userId: $userId, reactionType: $reactionType)';
  }
}
