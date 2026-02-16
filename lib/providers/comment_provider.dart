import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/comment.dart';

class CommentProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Map<String, List<Comment>> _comments = {}; // mediaId -> comments
  bool _isLoading = false;

  Map<String, List<Comment>> get comments => _comments;
  bool get isLoading => _isLoading;

  Future<void> fetchComments(String mediaId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<dynamic> data = await _supabase
          .from('comments')
          .select('*, profiles(username, avatar_url)')
          .eq('media_id', mediaId)
          .order('created_at', ascending: true);

      _comments[mediaId] = data.map((item) => Comment.fromMap(item)).toList();
    } catch (e) {
      debugPrint('Error fetching comments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> postComment({
    required String mediaId,
    required String content,
    String? parentId,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      await _supabase.from('comments').insert({
        'media_id': mediaId,
        'user_id': user.id,
        'content': content,
        'parent_id': parentId,
      });

      // Update local state or re-fetch
      await fetchComments(mediaId);
    } catch (e) {
      debugPrint('Error posting comment: $e');
      rethrow;
    }
  }

  Future<void> likeComment(String commentId, String mediaId) async {
    try {
      // In a real app, use a RPC call or a formal likes table
      // Here we just increment for demo purposes
      await _supabase.rpc('increment_comment_likes', params: {'row_id': commentId});
      await fetchComments(mediaId);
    } catch (e) {
      debugPrint('Error liking comment: $e');
    }
  }
}
