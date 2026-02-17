enum ViewerRole {
  viewer,
  moderator,
  vip;

  String get displayName {
    switch (this) {
      case ViewerRole.viewer:
        return 'Viewer';
      case ViewerRole.moderator:
        return 'Moderator';
      case ViewerRole.vip:
        return 'VIP';
    }
  }

  String get value {
    switch (this) {
      case ViewerRole.viewer:
        return 'viewer';
      case ViewerRole.moderator:
        return 'moderator';
      case ViewerRole.vip:
        return 'vip';
    }
  }
}

class StreamViewer {
  final String userId;
  final String userName;
  final String userAvatar;
  final DateTime joinedAt;
  final bool isModerator;
  final bool isFollowing;
  final ViewerRole role;
  final bool isOnline;
  final DateTime? lastSeenAt;
  final int messagesCount;
  final List<String> reactions;
  final bool isBlocked;
  final Map<String, dynamic> metadata;

  StreamViewer({
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.joinedAt,
    required this.isModerator,
    required this.isFollowing,
    required this.role,
    required this.isOnline,
    this.lastSeenAt,
    this.messagesCount = 0,
    required this.reactions,
    this.isBlocked = false,
    required this.metadata,
  });

  factory StreamViewer.fromMap(Map<String, dynamic> data) {
    return StreamViewer(
      userId: data['user_id']?.toString() ?? '',
      userName: data['user_name'] ?? data['profiles']?['username'] ?? 'User',
      userAvatar: data['user_avatar'] ?? data['profiles']?['avatar_url'] ?? '',
      joinedAt: DateTime.parse(data['joined_at'] ?? DateTime.now().toIso8601String()),
      isModerator: data['is_moderator'] ?? false,
      isFollowing: data['is_following'] ?? false,
      role: _parseRole(data['role']),
      isOnline: data['is_online'] ?? true,
      lastSeenAt: data['last_seen_at'] != null ? DateTime.parse(data['last_seen_at']) : null,
      messagesCount: data['messages_count'] ?? 0,
      reactions: List<String>.from(data['reactions'] ?? []),
      isBlocked: data['is_blocked'] ?? false,
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
    );
  }

  static ViewerRole _parseRole(dynamic role) {
    final value = role?.toString().toLowerCase();
    if (value == 'moderator') return ViewerRole.moderator;
    if (value == 'vip') return ViewerRole.vip;
    return ViewerRole.viewer;
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'joined_at': joinedAt.toIso8601String(),
      'is_moderator': isModerator,
      'is_following': isFollowing,
      'role': role.value,
      'is_online': isOnline,
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'messages_count': messagesCount,
      'reactions': reactions,
      'is_blocked': isBlocked,
      'metadata': metadata,
    };
  }

  StreamViewer copyWith({
    String? userId,
    String? userName,
    String? userAvatar,
    DateTime? joinedAt,
    bool? isModerator,
    bool? isFollowing,
    ViewerRole? role,
    bool? isOnline,
    DateTime? lastSeenAt,
    int? messagesCount,
    List<String>? reactions,
    bool? isBlocked,
    Map<String, dynamic>? metadata,
  }) {
    return StreamViewer(
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userAvatar: userAvatar ?? this.userAvatar,
      joinedAt: joinedAt ?? this.joinedAt,
      isModerator: isModerator ?? this.isModerator,
      isFollowing: isFollowing ?? this.isFollowing,
      role: role ?? this.role,
      isOnline: isOnline ?? this.isOnline,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      messagesCount: messagesCount ?? this.messagesCount,
      reactions: reactions ?? this.reactions,
      isBlocked: isBlocked ?? this.isBlocked,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isStaff => isModerator || role == ViewerRole.moderator;
  bool get isVip => role == ViewerRole.vip;
  bool get isActive => isOnline || (lastSeenAt != null && DateTime.now().difference(lastSeenAt!).inMinutes < 5);
  bool get hasActivity => messagesCount > 0 || reactions.isNotEmpty;

  Duration get watchTime => DateTime.now().difference(joinedAt);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StreamViewer && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;

  @override
  String toString() {
    return 'StreamViewer(userId: $userId, userName: $userName, role: $role, isOnline: $isOnline)';
  }
}

class StreamViewerStats {
  final int totalViewers;
  final int activeViewers;
  final int newViewers;
  final int returningViewers;
  final int moderatorCount;
  final int vipCount;
  final DateTime peakTime;
  final int peakViewers;
  final double averageWatchTime;
  final Map<String, int> viewersByCountry;

  StreamViewerStats({
    required this.totalViewers,
    required this.activeViewers,
    required this.newViewers,
    required this.returningViewers,
    required this.moderatorCount,
    required this.vipCount,
    required this.peakTime,
    required this.peakViewers,
    required this.averageWatchTime,
    required this.viewersByCountry,
  });

  factory StreamViewerStats.fromMap(Map<String, dynamic> data) {
    return StreamViewerStats(
      totalViewers: data['total_viewers'] ?? 0,
      activeViewers: data['active_viewers'] ?? 0,
      newViewers: data['new_viewers'] ?? 0,
      returningViewers: data['returning_viewers'] ?? 0,
      moderatorCount: data['moderator_count'] ?? 0,
      vipCount: data['vip_count'] ?? 0,
      peakTime: DateTime.parse(data['peak_time'] ?? DateTime.now().toIso8601String()),
      peakViewers: data['peak_viewers'] ?? 0,
      averageWatchTime: (data['average_watch_time'] as num?)?.toDouble() ?? 0.0,
      viewersByCountry: Map<String, int>.from(data['viewers_by_country'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'total_viewers': totalViewers,
      'active_viewers': activeViewers,
      'new_viewers': newViewers,
      'returning_viewers': returningViewers,
      'moderator_count': moderatorCount,
      'vip_count': vipCount,
      'peak_time': peakTime.toIso8601String(),
      'peak_viewers': peakViewers,
      'average_watch_time': averageWatchTime,
      'viewers_by_country': viewersByCountry,
    };
  }

  double get engagementRate => totalViewers > 0 ? (activeViewers / totalViewers) * 100 : 0.0;
  double get newViewerRate => totalViewers > 0 ? (newViewers / totalViewers) * 100 : 0.0;

  @override
  String toString() {
    return 'StreamViewerStats(total: $totalViewers, active: $activeViewers, peak: $peakViewers)';
  }
}
