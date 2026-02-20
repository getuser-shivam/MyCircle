import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/media_item.dart';
import '../models/social_user.dart';
import '../models/stream_model.dart';
import '../models/stream_chat_model.dart';
import '../models/stream_viewer_model.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance => _instance ??= SupabaseService._();
  SupabaseService._();

  final SupabaseClient _client = Supabase.instance.client;
  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SupabaseClient get client => _client;

  // Authentication
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  Future<AuthResponse> signUpWithEmail(String email, String password, String username) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );
      
      // Create user profile
      if (response.user != null) {
        await _createUserProfile(response.user!.id, username, email);
      }
      
      return response;
    } catch (e) {
      throw Exception('Failed to sign up: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  Future<User?> getCurrentUser() async {
    try {
      return _client.auth.currentUser;
    } catch (e) {
      throw Exception('Failed to get current user: $e');
    }
  }

  Future<void> _createUserProfile(String userId, String username, String email) async {
    try {
      await _client.from('users').insert({
        'id': userId,
        'username': username,
        'email': email,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to create user profile: $e');
    }
  }

  // Media Operations
  Future<List<MediaItem>> getMediaItems({
    int limit = 20,
    int offset = 0,
    String? category,
    String? searchQuery,
  }) async {
    try {
      var query = _client
          .from('media_items')
          .select('*')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      if (category != null && category.isNotEmpty) {
        query = query.eq('category', category);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('title.ilike.%$searchQuery%,description.ilike.%$searchQuery%');
      }

      final response = await query;
      return response.map((item) => MediaItem.fromMap(item)).toList();
    } catch (e) {
      throw Exception('Failed to fetch media items: $e');
    }
  }

  Future<MediaItem?> getMediaItem(String id) async {
    try {
      final response = await _client
          .from('media_items')
          .select('*')
          .eq('id', id)
          .single();
      
      return MediaItem.fromMap(response);
    } catch (e) {
      throw Exception('Failed to fetch media item: $e');
    }
  }

  Future<MediaItem> uploadMediaItem(MediaItem mediaItem) async {
    try {
      final response = await _client
          .from('media_items')
          .insert(mediaItem.toMap())
          .select()
          .single();
      
      return MediaItem.fromMap(response);
    } catch (e) {
      throw Exception('Failed to upload media item: $e');
    }
  }

  Future<void> deleteMediaItem(String id) async {
    try {
      await _client.from('media_items').delete().eq('id', id);
    } catch (e) {
      throw Exception('Failed to delete media item: $e');
    }
  }

  Future<void> likeMediaItem(String mediaId, String userId) async {
    try {
      await _client.from('media_likes').insert({
        'media_id': mediaId,
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update like count
      await _client.rpc('increment_like_count', params: {'media_id': mediaId});
    } catch (e) {
      throw Exception('Failed to like media item: $e');
    }
  }

  Future<void> unlikeMediaItem(String mediaId, String userId) async {
    try {
      await _client
          .from('media_likes')
          .delete()
          .eq('media_id', mediaId)
          .eq('user_id', userId);

      // Update like count
      await _client.rpc('decrement_like_count', params: {'media_id': mediaId});
    } catch (e) {
      throw Exception('Failed to unlike media item: $e');
    }
  }

  // User Operations
  Future<SocialUser> getUserProfile(String userId) async {
    try {
      final response = await _client
          .from('users')
          .select('*')
          .eq('id', userId)
          .single();
      
      return SocialUser.fromMap(response);
    } catch (e) {
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  Future<void> updateUserProfile(SocialUser user) async {
    try {
      await _client
          .from('users')
          .update(user.toMap())
          .eq('id', user.id);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  Future<List<SocialUser>> getNearbyUsers({
    double? latitude,
    double? longitude,
    double radius = 50.0, // km
    int limit = 20,
  }) async {
    try {
      var query = _client
          .from('users')
          .select('*')
          .limit(limit);

      if (latitude != null && longitude != null) {
        // Use PostGIS for location-based queries
        query = query.rpc('get_nearby_users', params: {
          'lat': latitude,
          'lng': longitude,
          'radius_km': radius,
        });
      }

      final response = await query;
      return response.map((user) => SocialUser.fromMap(user)).toList();
    } catch (e) {
      throw Exception('Failed to fetch nearby users: $e');
    }
  }

  Future<void> followUser(String followerId, String followingId) async {
    try {
      await _client.from('user_follows').insert({
        'follower_id': followerId,
        'following_id': followingId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to follow user: $e');
    }
  }

  Future<void> unfollowUser(String followerId, String followingId) async {
    try {
      await _client
          .from('user_follows')
          .delete()
          .eq('follower_id', followerId)
          .eq('following_id', followingId);
    } catch (e) {
      throw Exception('Failed to unfollow user: $e');
    }
  }

  Future<List<SocialUser>> getFollowingUsers(String userId) async {
    try {
      final response = await _client
          .from('user_follows')
          .select('users!inner(*)')
          .eq('follower_id', userId);
      
      return response.map((item) => SocialUser.fromMap(item['users'])).toList();
    } catch (e) {
      throw Exception('Failed to fetch following users: $e');
    }
  }

  // Streaming Operations
  Future<List<LiveStream>> getLiveStreams({
    StreamStatus? status,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = _client
          .from('live_streams')
          .select('*')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      if (status != null) {
        query = query.eq('status', status.name);
      }

      final response = await query;
      return response.map((stream) => LiveStream.fromMap(stream)).toList();
    } catch (e) {
      throw Exception('Failed to fetch live streams: $e');
    }
  }

  Future<LiveStream> createStream(LiveStream stream) async {
    try {
      final response = await _client
          .from('live_streams')
          .insert(stream.toMap())
          .select()
          .single();
      
      return LiveStream.fromMap(response);
    } catch (e) {
      throw Exception('Failed to create stream: $e');
    }
  }

  Future<void> updateStream(LiveStream stream) async {
    try {
      await _client
          .from('live_streams')
          .update(stream.toMap())
          .eq('id', stream.id);
    } catch (e) {
      throw Exception('Failed to update stream: $e');
    }
  }

  Future<void> endStream(String streamId) async {
    try {
      await _client
          .from('live_streams')
          .update({'status': 'ended', 'ended_at': DateTime.now().toIso8601String()})
          .eq('id', streamId);
    } catch (e) {
      throw Exception('Failed to end stream: $e');
    }
  }

  // Chat Operations
  Future<List<StreamChatMessage>> getStreamMessages(String streamId) async {
    try {
      final response = await _client
          .from('stream_chat_messages')
          .select('*')
          .eq('stream_id', streamId)
          .order('created_at', ascending: true);
      
      return response.map((message) => StreamChatMessage.fromMap(message)).toList();
    } catch (e) {
      throw Exception('Failed to fetch stream messages: $e');
    }
  }

  Future<StreamChatMessage> sendStreamMessage(StreamChatMessage message) async {
    try {
      final response = await _client
          .from('stream_chat_messages')
          .insert(message.toMap())
          .select()
          .single();
      
      return StreamChatMessage.fromMap(response);
    } catch (e) {
      throw Exception('Failed to send stream message: $e');
    }
  }

  // Real-time Subscriptions
  Stream<List<MediaItem>> subscribeToMediaItems({String? category}) {
    var query = _client
        .from('media_items')
        .select('*')
        .order('created_at', ascending: false);

    if (category != null && category.isNotEmpty) {
      query = query.eq('category', category);
    }

    return query.asStream().map((data) => 
        data.map((item) => MediaItem.fromMap(item)).toList());
  }

  Stream<List<LiveStream>> subscribeToLiveStreams() {
    return _client
        .from('live_streams')
        .select('*')
        .eq('status', 'live')
        .asStream()
        .map((data) => data.map((stream) => LiveStream.fromMap(stream)).toList());
  }

  Stream<List<StreamChatMessage>> subscribeToStreamMessages(String streamId) {
    return _client
        .from('stream_chat_messages')
        .select('*')
        .eq('stream_id', streamId)
        .order('created_at', ascending: true)
        .asStream()
        .map((data) => data.map((message) => StreamChatMessage.fromMap(message)).toList());
  }

  // File Upload
  Future<String> uploadFile(File file, String bucket, {String? folder}) async {
    try {
      final fileName = file.path.split('/').last;
      final path = folder != null ? '$folder/$fileName' : fileName;
      
      final response = await _client.storage
          .from(bucket)
          .upload(path, file);
      
      return response;
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  Future<String> getPublicUrl(String bucket, String path) async {
    try {
      final response = _client.storage
          .from(bucket)
          .getPublicUrl(path);
      
      return response;
    } catch (e) {
      throw Exception('Failed to get public URL: $e');
    }
  }

  // Analytics
  Future<void> trackEvent(String eventName, Map<String, dynamic> properties) async {
    try {
      final user = _client.auth.currentUser;
      await _client.from('analytics_events').insert({
        'event_name': eventName,
        'properties': properties,
        'user_id': user?.id,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to track event: $e');
    }
  }

  // Notifications
  Future<void> createNotification({
    required String userId,
    required String title,
    required String body,
    String? type,
    Map<String, dynamic>? data,
  }) async {
    try {
      await _client.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type,
        'data': data,
        'read': false,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to create notification: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    try {
      final response = await _client
          .from('notifications')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      
      return response;
    } catch (e) {
      throw Exception('Failed to fetch notifications: $e');
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _client
          .from('notifications')
          .update({'read': true, 'read_at': DateTime.now().toIso8601String()})
          .eq('id', notificationId);
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  // Search
  Future<List<Map<String, dynamic>>> searchContent(String query, {
    List<String>? types,
    int limit = 20,
  }) async {
    try {
      final response = await _client.rpc('search_content', params: {
        'search_query': query,
        'content_types': types ?? ['media', 'users', 'streams'],
        'limit': limit,
      });
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to search content: $e');
    }
  }

  // Cache Management
  Future<void> clearCache() async {
    try {
      await _prefs?.clear();
    } catch (e) {
      throw Exception('Failed to clear cache: $e');
    }
  }

  Future<void> cacheData(String key, dynamic data) async {
    try {
      await _prefs?.setString(key, data.toString());
    } catch (e) {
      throw Exception('Failed to cache data: $e');
    }
  }

  Future<String?> getCachedData(String key) async {
    try {
      return _prefs?.getString(key);
    } catch (e) {
      throw Exception('Failed to get cached data: $e');
    }
  }
}
