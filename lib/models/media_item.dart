

import 'package:cloud_firestore/cloud_firestore.dart';

enum MediaType {
  gif,
  video,
  image,
}

class MediaItem {
  final String id;
  final String title;
  final String? description;
  final String url;
  final String thumbnailUrl;
  final String? videoUrl;
  final String? duration;
  final int views;
  final int likes;
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
    this.description,
    required this.url,
    required this.thumbnailUrl,
    this.videoUrl,
    this.duration,
    required this.views,
    required this.likes,
    required this.category,
    required this.authorId,
    required this.userName,
    required this.userAvatar,
    required this.createdAt,
    this.tags = const [],
    this.isPremium = false,
    this.isPrivate = false,
    this.isVerified = false,
    this.type = MediaType.gif,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    final author = json['author'] ?? {};
    return MediaItem(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      url: json['fileUrl'] ?? json['url'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      videoUrl: json['videoUrl'] ?? json['fileUrl'] ?? json['url'] ?? '',
      duration: json['duration']?.toString() ?? '0',
      views: json['stats']?['views'] ?? json['views'] ?? 0,
      likes: json['stats']?['likes'] ?? json['likes'] ?? 0,
      category: json['category'] ?? 'General',
      authorId: author['id'] ?? author['_id'] ?? json['authorId'] ?? '',
      userName: author['username'] ?? json['authorName'] ?? '',
      userAvatar: author['avatar'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      isPremium: json['isPremium'] ?? false,
      isPrivate: json['isPrivate'] ?? false,
      isVerified: author['isVerified'] ?? false,
      type: _parseMediaType(json['type']),
    );
  }

  factory MediaItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MediaItem(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      url: data['url'] ?? '',
      thumbnailUrl: data['thumbnailUrl'] ?? '',
      videoUrl: data['videoUrl'],
      duration: data['duration']?.toString() ?? '0',
      views: data['views'] ?? 0,
      likes: data['likes'] ?? 0,
      category: data['category'] ?? 'General',
      authorId: data['authorId'] ?? '',
      userName: data['userName'] ?? 'Unknown',
      userAvatar: data['userAvatar'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      tags: List<String>.from(data['tags'] ?? []),
      isPremium: data['isPremium'] ?? false,
      isPrivate: data['isPrivate'] ?? false,
      isVerified: data['isVerified'] ?? false,
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
      'thumbnailUrl': thumbnailUrl,
      'videoUrl': videoUrl,
      'duration': duration,
      'views': views,
      'likes': likes,
      'category': category,
      'authorId': authorId,
      'userName': userName,
      'userAvatar': userAvatar,
      'createdAt': createdAt.toIso8601String(),
      'tags': tags,
      'isPremium': isPremium,
      'isPrivate': isPrivate,
      'isVerified': isVerified,
      'type': type.toString().split('.').last,
    };
  }
}
