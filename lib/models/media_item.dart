

class MediaItem {
  final String id;
  final String title;
  final String? description;
  final String? thumbnailUrl;
  final String? videoUrl;
  final String? duration;
  final int views;
  final int likes;
  final String category;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final List<String> tags;
  final bool isPremium;
  final bool isPrivate;

  MediaItem({
    required this.id,
    required this.title,
    this.description,
    this.thumbnailUrl,
    this.videoUrl,
    this.duration,
    required this.views,
    required this.likes,
    required this.category,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    this.tags = const [],
    this.isPremium = false,
    this.isPrivate = false,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      duration: json['duration'] as String?,
      views: json['views'] as int? ?? 0,
      likes: json['likes'] as int? ?? 0,
      category: json['category'] as String? ?? 'General',
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      isPremium: json['isPremium'] as bool? ?? false,
      isPrivate: json['isPrivate'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
      'videoUrl': videoUrl,
      'duration': duration,
      'views': views,
      'likes': likes,
      'category': category,
      'authorId': authorId,
      'authorName': authorName,
      'createdAt': createdAt.toIso8601String(),
      'tags': tags,
      'isPremium': isPremium,
      'isPrivate': isPrivate,
    };
  }

  MediaItem copyWith({
    String? id,
    String? title,
    String? description,
    String? thumbnailUrl,
    String? videoUrl,
    String? duration,
    int? views,
    int? likes,
    String? category,
    String? authorId,
    String? authorName,
    DateTime? createdAt,
    List<String>? tags,
    bool? isPremium,
    bool? isPrivate,
  }) {
    return MediaItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      duration: duration ?? this.duration,
      views: views ?? this.views,
      likes: likes ?? this.likes,
      category: category ?? this.category,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      tags: tags ?? this.tags,
      isPremium: isPremium ?? this.isPremium,
      isPrivate: isPrivate ?? this.isPrivate,
    );
  }
}
