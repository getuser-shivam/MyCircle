import 'package:flutter_test/flutter_test.dart';

/// Enhanced test configuration for the new logic layer
class TestConfigEnhanced {
  // Test timeout duration
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration longTimeout = Duration(seconds: 60);
  
  // Mock data generators
  static Map<String, dynamic> createMockMediaItemData({
    String id = '1',
    String title = 'Test Media',
    String description = 'Test Description',
    String url = 'https://example.com/video.mp4',
    String thumbnailUrl = 'https://example.com/thumb.jpg',
    String category = 'Test',
    String authorId = 'user123',
    String userName = 'testuser',
    String userAvatar = 'https://example.com/avatar.jpg',
    String type = 'video',
    int likes = 10,
    int views = 100,
    int commentsCount = 5,
    List<String> tags = const ['test'],
    bool isPremium = false,
    bool isPrivate = false,
    bool isVerified = false,
  }) {
    return {
      'id': id,
      'title': title,
      'description': description,
      'url': url,
      'thumbnail_url': thumbnailUrl,
      'category': category,
      'author_id': authorId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'type': type,
      'likes_count': likes,
      'views_count': views,
      'comments_count': commentsCount,
      'tags': tags,
      'is_premium': isPremium,
      'is_private': isPrivate,
      'created_at': DateTime.now().toIso8601String(),
      'profiles': {
        'username': userName,
        'avatar_url': userAvatar,
        'is_verified': isVerified,
      }
    };
  }

  static Map<String, dynamic> createMockSocialUserData({
    String id = '1',
    String username = 'testuser',
    String avatar = 'https://example.com/avatar.jpg',
    int age = 25,
    String gender = 'other',
    String locationSnippet = 'Nearby',
    double distanceKm = 5.0,
    String status = 'offline',
    bool isVerified = false,
    List<String> interests = const ['test'],
    String? bio,
  }) {
    return {
      'id': id,
      'username': username,
      'avatar': avatar,
      'age': age,
      'gender': gender,
      'location_snippet': locationSnippet,
      'distance_km': distanceKm,
      'status': status,
      'is_verified': isVerified,
      'interests': interests,
      'bio': bio,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  static Map<String, dynamic> createMockStreamData({
    String id = '1',
    String title = 'Test Stream',
    String description = 'Test Stream Description',
    String streamerId = 'streamer123',
    String streamerName = 'teststreamer',
    String streamerAvatar = 'https://example.com/avatar.jpg',
    String thumbnailUrl = 'https://example.com/thumb.jpg',
    String streamUrl = 'https://example.com/stream.mp4',
    String streamKey = 'key123',
    String status = 'live',
    String quality = 'high',
    int viewerCount = 100,
    int maxViewers = 1000,
    String category = 'Test',
    bool isPrivate = false,
    bool isRecorded = true,
    List<String> tags = const ['test'],
    List<String> allowedViewerIds = const [],
    Map<String, dynamic> metadata = const {},
  }) {
    return {
      'id': id,
      'title': title,
      'description': description,
      'streamer_id': streamerId,
      'streamer_name': streamerName,
      'streamer_avatar': streamerAvatar,
      'thumbnail_url': thumbnailUrl,
      'stream_url': streamUrl,
      'stream_key': streamKey,
      'status': status,
      'quality': quality,
      'viewer_count': viewerCount,
      'max_viewers': maxViewers,
      'category': category,
      'is_private': isPrivate,
      'is_recorded': isRecorded,
      'tags': tags,
      'allowed_viewer_ids': allowedViewerIds,
      'metadata': metadata,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'scheduled_at': DateTime.now().toIso8601String(),
      'started_at': DateTime.now().toIso8601String(),
    };
  }

  static Map<String, dynamic> createMockChatMessageData({
    String id = '1',
    String streamId = 'stream1',
    String userId = 'user1',
    String username = 'testuser',
    String message = 'Hello World',
  }) {
    return {
      'id': id,
      'stream_id': streamId,
      'user_id': userId,
      'username': username,
      'message': message,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  // Test helpers
  static void setUpTestEnvironment() {
    TestWidgetsFlutterBinding.ensureInitialized();
  }

  static Future<void> waitForAsyncOperations() async {
    await Future.delayed(const Duration(milliseconds: 100));
  }

  static void expectNoErrors(List<dynamic> errors) {
    expect(errors, isEmpty);
  }

  static void expectErrorType<T>(dynamic error) {
    expect(error, isA<T>());
  }

  static void expectErrorMessageContains(dynamic error, String expectedMessage) {
    expect(error.toString(), contains(expectedMessage));
  }
}

/// Custom test matchers
class CustomMatchers {
  static Matcher isValidMediaItem() => predicate((dynamic item) {
    return item != null &&
           item.id != null &&
           item.title != null &&
           item.url != null &&
           item.thumbnailUrl != null &&
           item.category != null &&
           item.authorId != null &&
           item.userName != null &&
           item.userAvatar != null &&
           item.createdAt != null &&
           item.type != null;
  }, 'is a valid MediaItem');

  static Matcher isValidSocialUser() => predicate((dynamic user) {
    return user != null &&
           user.id != null &&
           user.username != null &&
           user.avatar != null &&
           user.age != null &&
           user.gender != null &&
           user.locationSnippet != null &&
           user.distanceKm != null &&
           user.status != null &&
           user.isVerified != null &&
           user.interests != null;
  }, 'is a valid SocialUser');

  static Matcher isValidLiveStream() => predicate((dynamic stream) {
    return stream != null &&
           stream.id != null &&
           stream.title != null &&
           stream.description != null &&
           stream.streamerId != null &&
           stream.streamerName != null &&
           stream.streamerAvatar != null &&
           stream.thumbnailUrl != null &&
           stream.streamUrl != null &&
           stream.streamKey != null &&
           stream.status != null &&
           stream.quality != null &&
           stream.viewerCount != null &&
           stream.maxViewers != null &&
           stream.scheduledAt != null &&
           stream.startedAt != null &&
           stream.tags != null &&
           stream.category != null &&
           stream.isPrivate != null &&
           stream.isRecorded != null &&
           stream.latitude != null &&
           stream.longitude != null &&
           stream.allowedViewerIds != null &&
           stream.metadata != null &&
           stream.createdAt != null &&
           stream.updatedAt != null;
  }, 'is a valid LiveStream');
}

/// Test data factory
class TestDataFactory {
  static List<Map<String, dynamic>> createMockMediaItemList(int count) {
    return List.generate(count, (index) => TestConfigEnhanced.createMockMediaItemData(
      id: (index + 1).toString(),
      title: 'Test Media ${index + 1}',
    ));
  }

  static List<Map<String, dynamic>> createMockSocialUserList(int count) {
    return List.generate(count, (index) => TestConfigEnhanced.createMockSocialUserData(
      id: (index + 1).toString(),
      username: 'testuser${index + 1}',
    ));
  }

  static List<Map<String, dynamic>> createMockStreamList(int count) {
    return List.generate(count, (index) => TestConfigEnhanced.createMockStreamData(
      id: (index + 1).toString(),
      title: 'Test Stream ${index + 1}',
    ));
  }

  static List<Map<String, dynamic>> createMockChatMessageList(int count) {
    return List.generate(count, (index) => TestConfigEnhanced.createMockChatMessageData(
      id: (index + 1).toString(),
      message: 'Message ${index + 1}',
    ));
  }
}
