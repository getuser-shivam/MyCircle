enum MediaType { image, video, gif }

class MediaItem {
  final String id;
  final String title;
  final String description;
  final String url;
  final String thumbnailUrl;
  final String? videoUrl;
  final String duration;
  final int views;
  final int likes;
  final int commentsCount;
  final String category;
  final String authorId;
  final String userName;
  final String userAvatar;
  final DateTime createdAt;
  final List<String> tags;
  final bool isPremium;
  final bool isPrivate;
  final bool isVerified;
  final MediaType type;

  MediaItem({
    required this.id,
    required this.title,
    required this.description,
    required this.url,
    required this.thumbnailUrl,
    this.videoUrl,
    this.duration = '0',
    this.views = 0,
    this.likes = 0,
    this.commentsCount = 0,
    required this.category,
    required this.authorId,
    required this.userName,
    required this.userAvatar,
    required this.createdAt,
    this.tags = const [],
    this.isPremium = false,
    this.isPrivate = false,
    this.isVerified = false,
    required this.type,
  });

  factory MediaItem.fromJson(Map<String, dynamic> data) {
    final authorProfile = data['profiles'] as Map<String, dynamic>?;
    
    return MediaItem(
      id: data['id']?.toString() ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      url: data['url'] ?? '',
      thumbnailUrl: data['thumbnail_url'] ?? '',
      videoUrl: data['video_url'],
      duration: data['duration']?.toString() ?? '0',
      views: data['views_count'] ?? 0,
      likes: data['likes_count'] ?? 0,
      commentsCount: data['comments_count'] ?? 0,
      category: data['category'] ?? 'General',
      authorId: data['author_id'] ?? '',
      userName: authorProfile?['username'] ?? data['user_name'] ?? 'Unknown',
      userAvatar: authorProfile?['avatar_url'] ?? data['user_avatar'] ?? '',
      createdAt: DateTime.parse(data['created_at'] ?? DateTime.now().toIso8601String()),
      tags: List<String>.from(data['tags'] ?? []),
      isPremium: data['is_premium'] ?? false,
      isPrivate: data['is_private'] ?? false,
      isVerified: authorProfile?['is_verified'] ?? data['is_verified'] ?? false,
      type: _parseMediaType(data['type']),
    );
  }

  static MediaType _parseMediaType(String? type) {
    if (type == null) return MediaType.gif;
    switch (type.toLowerCase()) {
      case 'video':
        return MediaType.video;
      case 'image':
        return MediaType.image;
      case 'gif':
      default:
        return MediaType.gif;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'url': url,
      'thumbnail_url': thumbnailUrl,
      'video_url': videoUrl,
      'duration': duration,
      'views_count': views,
      'likes_count': likes,
      'comments_count': commentsCount,
      'category': category,
      'author_id': authorId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'created_at': createdAt.toIso8601String(),
      'tags': tags,
      'is_premium': isPremium,
      'is_private': isPrivate,
      'is_verified': isVerified,
      'type': type.toString().split('.').last,
    };
  }
}
