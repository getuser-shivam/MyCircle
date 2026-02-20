import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/comment.dart';
import '../services/comment_service.dart';

class CommentProvider extends ChangeNotifier {
  final CommentService _commentService = CommentService();
  final SupabaseClient _supabase = Supabase.instance.client; // Keep for auth checks
  final Map<String, List<Comment>> _comments = {}; // mediaId -> comments
  bool _isLoading = false;
  String? _error;

  Map<String, List<Comment>> get comments => _comments;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchComments(String mediaId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _comments[mediaId] = await _commentService.fetchComments(mediaId);
    } catch (e) {
      _error = e.toString();
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

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _commentService.postComment(
        mediaId: mediaId,
        userId: user.id,
        content: content,
        parentId: parentId,
      );

      // Re-fetch comments after posting
      await fetchComments(mediaId);
    } catch (e) {
      _error = e.toString();
      debugPrint('Error posting comment: $e');
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
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
