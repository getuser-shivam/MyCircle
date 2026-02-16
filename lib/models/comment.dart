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

  factory Comment.fromMap(Map<String, dynamic> data) {
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
}
