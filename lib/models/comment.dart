class Comment {
  final String id;
  final String mediaId;
  final String userId;
  final String content;
  final String? parentId;
  final int likesCount;
  final DateTime createdAt;
  final String? userName;
  final String? userAvatar;

  Comment({
    required this.id,
    required this.mediaId,
    required this.userId,
    required this.content,
    this.parentId,
    this.likesCount = 0,
    required this.createdAt,
    this.userName,
    this.userAvatar,
  });

  factory Comment.fromJson(Map<String, dynamic> data) {
    return Comment(
      id: data['id']?.toString() ?? '',
      mediaId: data['media_id']?.toString() ?? '',
      userId: data['user_id']?.toString() ?? '',
      content: data['content'] ?? '',
      parentId: data['parent_id']?.toString(),
      likesCount: data['likes_count'] ?? 0,
      createdAt: DateTime.parse(data['created_at'] ?? DateTime.now().toIso8601String()),
      userName: data['profiles']?['username'] ?? 'User',
      userAvatar: data['profiles']?['avatar_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'media_id': mediaId,
      'user_id': userId,
      'content': content,
      'parent_id': parentId,
      'likes_count': likesCount,
      'created_at': createdAt.toIso8601String(),
      'user_name': userName,
      'user_avatar': userAvatar,
    };
  }
}
