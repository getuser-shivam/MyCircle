import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SocialGraphProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  final Set<String> _followingIds = {};
  bool _isLoading = false;

  Set<String> get followingIds => _followingIds;
  bool get isLoading => _isLoading;

  Future<void> fetchFollowing() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final List<dynamic> data = await _supabase
          .from('follows')
          .select('following_id')
          .eq('follower_id', user.id);

      _followingIds.clear();
      for (var item in data) {
        _followingIds.add(item['following_id']);
      }
    } catch (e) {
      LoggerService.debug('Error fetching following: $e', tag: 'SOCIAL');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> followUser(String targetUserId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      await _supabase.from('follows').insert({
        'follower_id': user.id,
        'following_id': targetUserId,
      });
      _followingIds.add(targetUserId);
      notifyListeners();
      
      // Update counters (optional: handle in Supabase via Triggers)
    } catch (e) {
      LoggerService.debug('Error following user: $e', tag: 'SOCIAL');
    }
  }

  Future<void> unfollowUser(String targetUserId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    try {
      await _supabase.from('follows')
          .delete()
          .eq('follower_id', user.id)
          .eq('following_id', targetUserId);
      
      _followingIds.remove(targetUserId);
      notifyListeners();
    } catch (e) {
      LoggerService.debug('Error unfollowing user: $e', tag: 'SOCIAL');
    }
  }

  bool isFollowing(String userId) => _followingIds.contains(userId);
}
