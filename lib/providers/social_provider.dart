import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/social_user.dart';

class SocialProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<SocialUser> _nearbyUsers = [];
  bool _isLoading = false;

  List<SocialUser> get nearbyUsers => _nearbyUsers;
  bool get isLoading => _isLoading;

  Future<void> loadNearbyUsers() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Real-time stream for users
      _supabase.from('users').stream(primaryKey: ['id']).limit(50).listen((data) {
        _nearbyUsers = data.map((item) => SocialUser.fromMap(item)).toList();
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error loading nearby users: $e');
      _isLoading = false;
      notifyListeners();
    }
  }
}

