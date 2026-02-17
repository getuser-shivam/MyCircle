import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/stream_model.dart';

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
          .order('viewer_count', ascending: false)
          .limit(20);

      return response.map((data) => LiveStream.fromMap(data)).toList();
    } catch (e) {
      throw Exception('Failed to fetch following streams: $e');
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

  Future<void> createStream(LiveStream stream) async {
    try {
      await _supabase.from('streams').insert(stream.toMap());
    } catch (e) {
      throw Exception('Failed to create stream: $e');
    }
  }

  Future<void> updateStream(String streamId, Map<String, dynamic> updates) async {
    try {
      await _supabase
          .from('streams')
          .update(updates)
          .eq('id', streamId);
    } catch (e) {
      throw Exception('Failed to update stream: $e');
    }
  }

  Future<void> deleteStream(String streamId) async {
    try {
      await _supabase
          .from('streams')
          .delete()
          .eq('id', streamId);
    } catch (e) {
      throw Exception('Failed to delete stream: $e');
    }
  }

  Stream<List<LiveStream>> getLiveStreamsStream() {
    try {
      return _supabase
          .from('streams')
          .stream(primaryKey: ['id'])
          .eq('status', 'live')
          .order('viewer_count', ascending: false)
          .map((data) {
            return data
                .map((item) => LiveStream.fromMap(item as Map<String, dynamic>))
                .toList();
          });
    } catch (e) {
      return Stream.error(e);
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

  String _generateStreamKey() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
