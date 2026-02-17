import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/stream_model.dart';
import '../models/stream_chat_model.dart';
import '../models/stream_viewer_model.dart';

class StreamService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Stream CRUD Operations
  Future<List<LiveStream>> getLiveStreams({
    int limit = 20,
    int page = 1,
    String? category,
  }) async {
    try {
      final query = _supabase
          .from('streams')
          .select('''
            *,
            profiles!streamer_id (
              username,
              avatar_url
            )
          ''')
          .eq('status', 'live')
          .order('viewer_count', ascending: false)
          .range((page - 1) * limit, page * limit - 1);

      if (category != null) {
        query = query.eq('category', category);
      }

      final response = await query;
      return response.map((data) => LiveStream.fromMap(data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch live streams: $e');
    }
  }

  Future<List<LiveStream>> getScheduledStreams({
    int limit = 20,
    int page = 1,
  }) async {
    try {
      final response = await _supabase
          .from('streams')
          .select('''
            *,
            profiles!streamer_id (
              username,
              avatar_url
            )
          ''')
          .eq('status', 'scheduled')
          .order('scheduled_at', ascending: true)
          .range((page - 1) * limit, page * limit - 1);

      return response.map((data) => LiveStream.fromMap(data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch scheduled streams: $e');
    }
  }

  Future<List<LiveStream>> getTrendingStreams() async {
    try {
      final response = await _supabase
          .from('streams')
          .select('''
            *,
            profiles!streamer_id (
              username,
              avatar_url
            )
          ''')
          .eq('status', 'live')
          .order('viewer_count', ascending: false)
          .limit(10);

      return response.map((data) => LiveStream.fromMap(data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch trending streams: $e');
    }
  }

  Future<List<LiveStream>> getFollowingStreams() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('streams')
          .select('''
            *,
            profiles!streamer_id (
              username,
              avatar_url
            )
          ''')
          .in('status', ['live', 'scheduled'])
          .order('viewer_count', ascending: false);

      return response.map((data) => LiveStream.fromMap(data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch following streams: $e');
    }
  }

  Future<List<LiveStream>> getNearbyStreams(
    double latitude,
    double longitude,
    double radiusKm,
  ) async {
    try {
      // This would typically use PostGIS for spatial queries
      // For now, we'll use a simple approximation
      final response = await _supabase
          .from('streams')
          .select('''
            *,
            profiles!streamer_id (
              username,
              avatar_url
            )
          ''')
          .eq('status', 'live')
          .order('viewer_count', ascending: false)
          .limit(20);

      return response.map((data) => LiveStream.fromMap(data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch nearby streams: $e');
    }
  }

  Future<List<LiveStream>> getStreamsByCategory(String category) async {
    try {
      final response = await _supabase
          .from('streams')
          .select('''
            *,
            profiles!streamer_id (
              username,
              avatar_url
            )
          ''')
          .eq('category', category)
          .eq('status', 'live')
          .order('viewer_count', ascending: false)
          .limit(20);

      return response.map((data) => LiveStream.fromMap(data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch streams by category: $e');
    }
  }

  Future<LiveStream?> getStreamById(String streamId) async {
    try {
      final response = await _supabase
          .from('streams')
          .select('''
            *,
            profiles!streamer_id (
              username,
              avatar_url
            )
          ''')
          .eq('id', streamId)
          .single();

      return LiveStream.fromMap(response);
    } catch (e) {
      throw Exception('Failed to fetch stream: $e');
    }
  }

  Future<LiveStream> createStream(Map<String, dynamic> streamData) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Prepare stream data
      final data = {
        'streamer_id': userId,
        'title': streamData['title'],
        'description': streamData['description'] ?? '',
        'category': streamData['category'],
        'quality': streamData['quality'].value,
        'tags': streamData['tags'] ?? [],
        'max_viewers': streamData['maxViewers'],
        'is_private': streamData['isPrivate'] ?? false,
        'is_recorded': streamData['isRecorded'] ?? true,
        'scheduled_at': streamData['scheduledAt']?.toIso8601String(),
        'allowed_viewer_ids': streamData['allowedViewerIds'] ?? [],
        'status': streamData['scheduledAt'] != null ? 'scheduled' : 'live',
        'started_at': streamData['scheduledAt'] == null 
            ? DateTime.now().toIso8601String() 
            : null,
        'stream_key': _generateStreamKey(),
        'latitude': streamData['latitude'] ?? 0.0,
        'longitude': streamData['longitude'] ?? 0.0,
        'location_name': streamData['locationName'],
      };

      // Upload thumbnail if provided
      if (streamData['thumbnailImage'] != null) {
        final thumbnailUrl = await _uploadThumbnail(streamData['thumbnailImage']);
        data['thumbnail_url'] = thumbnailUrl;
      }

      final response = await _supabase
          .from('streams')
          .insert(data)
          .select('''
            *,
            profiles!streamer_id (
              username,
              avatar_url
            )
          ''')
          .single();

      return LiveStream.fromMap(response);
    } catch (e) {
      throw Exception('Failed to create stream: $e');
    }
  }

  Future<LiveStream> updateStream(String streamId, Map<String, dynamic> data) async {
    try {
      final response = await _supabase
          .from('streams')
          .update(data)
          .eq('id', streamId)
          .select('''
            *,
            profiles!streamer_id (
              username,
              avatar_url
            )
          ''')
          .single();

      return LiveStream.fromMap(response);
    } catch (e) {
      throw Exception('Failed to update stream: $e');
    }
  }

  Future<void> deleteStream(String streamId) async {
    try {
      await _supabase.from('streams').delete().eq('id', streamId);
    } catch (e) {
      throw Exception('Failed to delete stream: $e');
    }
  }

  // Stream Control
  Future<void> startStream(String streamId) async {
    try {
      await _supabase
          .from('streams')
          .update({
            'status': 'live',
            'started_at': DateTime.now().toIso8601String(),
          })
          .eq('id', streamId);
    } catch (e) {
      throw Exception('Failed to start stream: $e');
    }
  }

  Future<void> endStream(String streamId) async {
    try {
      await _supabase
          .from('streams')
          .update({
            'status': 'ended',
            'ended_at': DateTime.now().toIso8601String(),
          })
          .eq('id', streamId);
    } catch (e) {
      throw Exception('Failed to end stream: $e');
    }
  }

  Future<String> generateStreamKey(String streamId) async {
    try {
      final streamKey = _generateStreamKey();
      await _supabase
          .from('streams')
          .update({'stream_key': streamKey})
          .eq('id', streamId);
      
      return streamKey;
    } catch (e) {
      throw Exception('Failed to generate stream key: $e');
    }
  }

  // Viewers and Chat
  Future<List<StreamViewer>> getStreamViewers(String streamId) async {
    try {
      final response = await _supabase
          .from('stream_viewers')
          .select('''
            *,
            profiles!user_id (
              username,
              avatar_url
            )
          ''')
          .eq('stream_id', streamId)
          .order('joined_at', ascending: false);

      return response.map((data) => StreamViewer.fromMap(data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch stream viewers: $e');
    }
  }

  Future<void> joinStream(String streamId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase.from('stream_viewers').upsert({
        'stream_id': streamId,
        'user_id': userId,
        'joined_at': DateTime.now().toIso8601String(),
        'role': 'viewer',
      });

      // Increment viewer count
      await _supabase.rpc('increment_viewer_count', params: {'stream_id': streamId});
    } catch (e) {
      throw Exception('Failed to join stream: $e');
    }
  }

  Future<void> leaveStream(String streamId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase
          .from('stream_viewers')
          .delete()
          .eq('stream_id', streamId)
          .eq('user_id', userId);

      // Decrement viewer count
      await _supabase.rpc('decrement_viewer_count', params: {'stream_id': streamId});
    } catch (e) {
      throw Exception('Failed to leave stream: $e');
    }
  }

  Future<List<StreamChatMessage>> getStreamChat(String streamId) async {
    try {
      final response = await _supabase
          .from('stream_chat_messages')
          .select('''
            *,
            profiles!user_id (
              username,
              avatar_url
            )
          ''')
          .eq('stream_id', streamId)
          .order('created_at', ascending: false)
          .limit(50);

      return response.map((data) => StreamChatMessage.fromMap(data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch stream chat: $e');
    }
  }

  Future<StreamChatMessage> sendChatMessage(String streamId, String content) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('stream_chat_messages')
          .insert({
            'stream_id': streamId,
            'user_id': userId,
            'content': content,
          })
          .select('''
            *,
            profiles!user_id (
              username,
              avatar_url
            )
          ''')
          .single();

      return StreamChatMessage.fromMap(response);
    } catch (e) {
      throw Exception('Failed to send chat message: $e');
    }
  }

  Future<void> sendReaction(String streamId, String reactionType) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase.from('stream_reactions').insert({
        'stream_id': streamId,
        'user_id': userId,
        'reaction_type': reactionType,
      });
    } catch (e) {
      throw Exception('Failed to send reaction: $e');
    }
  }

  // Search and Discovery
  Future<List<LiveStream>> searchStreams(String query) async {
    try {
      final response = await _supabase
          .from('streams')
          .select('''
            *,
            profiles!streamer_id (
              username,
              avatar_url
            )
          ''')
          .or('title.ilike.%$query%,description.ilike.%$query%,tags.cs.{${query.toLowerCase()}}')
          .eq('status', 'live')
          .order('viewer_count', ascending: false)
          .limit(20);

      return response.map((data) => LiveStream.fromMap(data)).toList();
    } catch (e) {
      throw Exception('Failed to search streams: $e');
    }
  }

  // Analytics and History
  Future<StreamViewerStats> getStreamStats(String streamId) async {
    try {
      final response = await _supabase
          .from('stream_viewer_stats')
          .select('*')
          .eq('stream_id', streamId)
          .single();

      return StreamViewerStats.fromMap(response);
    } catch (e) {
      throw Exception('Failed to fetch stream stats: $e');
    }
  }

  Future<List<LiveStream>> getUserStreamHistory() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('streams')
          .select('''
            *,
            profiles!streamer_id (
              username,
              avatar_url
            )
          ''')
          .eq('streamer_id', userId)
          .in('status', ['ended', 'cancelled'])
          .order('created_at', ascending: false)
          .limit(50);

      return response.map((data) => LiveStream.fromMap(data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch stream history: $e');
    }
  }

  // Moderation
  Future<void> deleteMessage(String messageId) async {
    try {
      await _supabase
          .from('stream_chat_messages')
          .update({'is_deleted': true})
          .eq('id', messageId);
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  Future<void> pinMessage(String messageId) async {
    try {
      await _supabase
          .from('stream_chat_messages')
          .update({'is_pinned': true})
          .eq('id', messageId);
    } catch (e) {
      throw Exception('Failed to pin message: $e');
    }
  }

  Future<void> blockUser(String userId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('User not authenticated');

      await _supabase.from('blocked_users').insert({
        'blocker_id': currentUserId,
        'blocked_id': userId,
      });
    } catch (e) {
      throw Exception('Failed to block user: $e');
    }
  }

  Future<void> reportMessage(String messageId, String reason) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await _supabase.from('message_reports').insert({
        'message_id': messageId,
        'reporter_id': userId,
        'reason': reason,
      });
    } catch (e) {
      throw Exception('Failed to report message: $e');
    }
  }

  // Helper Methods
  String _generateStreamKey() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecond.toString().substring(0, 6);
    return 'live_${timestamp}_$random';
  }

  Future<String> _uploadThumbnail(File imageFile) async {
    try {
      final fileName = 'stream_thumbnails/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await imageFile.readAsBytes();
      
      await _supabase.storage.from('stream-thumbnails').uploadBinary(
        fileName,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );

      final response = _supabase.storage.from('stream-thumbnails').getPublicUrl(fileName);
      return response;
    } catch (e) {
      throw Exception('Failed to upload thumbnail: $e');
    }
  }

  // Additional chat methods
  Future<List<StreamChatMessage>> getOlderMessages(
    String streamId, {
    DateTime? before,
    int limit = 50,
  }) async {
    try {
      var query = _supabase
          .from('stream_chat_messages')
          .select('''
            *,
            profiles!user_id (
              username,
              avatar_url
            )
          ''')
          .eq('stream_id', streamId)
          .order('created_at', ascending: false)
          .limit(limit);

      if (before != null) {
        query = query.lt('created_at', before.toIso8601String());
      }

      final response = await query;
      return response.map((data) => StreamChatMessage.fromMap(data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch older messages: $e');
    }
  }

  Future<void> sendReactionToMessage(String messageId, String reactionType) async {
    try {
      await _supabase.from('message_reactions').insert({
        'message_id': messageId,
        'reaction_type': reactionType,
      });
    } catch (e) {
      throw Exception('Failed to send reaction to message: $e');
    }
  }
}
