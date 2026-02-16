import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class User {
  final String id;
  final String username;
  final String email;
  final String avatar;
  final String role; // 'user', 'creator', 'moderator', 'admin'
  final bool isVerified;
  final bool isPremium;
  final int followersCount;
  final int followingCount;
  final int postsCount;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.avatar,
    this.role = 'user',
    this.isVerified = false,
    this.isPremium = false,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
  });

  factory User.fromMap(Map<String, dynamic> data, {String? role}) {
    return User(
      id: data['id'] ?? '',
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      avatar: data['avatar'] ?? 'https://i.pravatar.cc/300',
      role: role ?? data['role'] ?? 'user',
      isVerified: data['is_verified'] ?? false,
      isPremium: data['is_premium'] ?? false,
      followersCount: data['followers_count'] ?? 0,
      followingCount: data['following_count'] ?? 0,
      postsCount: data['posts_count'] ?? 0,
    );
  }
}

class AuthProvider extends ChangeNotifier {
  final supabase.SupabaseClient _supabase = supabase.Supabase.instance.client;
  
  User? _currentUser;
  bool _isLoading = false;
  String? _error;
  
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _supabase.auth.currentUser != null;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> initialize() async {
    final session = _supabase.auth.currentSession;
    if (session != null) {
      await _fetchUserProfile(session.user.id);
    }

    _supabase.auth.onAuthStateChange.listen((data) async {
      final supabase.AuthChangeEvent event = data.event;
      final supabase.Session? currentSession = data.session;

      if (event == supabase.AuthChangeEvent.signedIn && currentSession != null) {
        await _fetchUserProfile(currentSession.user.id);
      } else if (event == supabase.AuthChangeEvent.signedOut) {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } on supabase.AuthException catch (e) {
      _error = e.message;
      throw Exception(e.message);
    } catch (e) {
      _error = e.toString();
      throw Exception(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String username, String email, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'username': username},
      );

      if (response.user != null) {
        // Create user profile in our custom profiles table
        await _supabase.from('profiles').insert({
          'id': response.user!.id,
          'username': username,
          'email': email,
          'avatar_url': 'https://i.pravatar.cc/300?u=${response.user!.id}',
          'is_verified': false,
          'is_premium': false,
          'followers_count': 0,
          'following_count': 0,
          'posts_count': 0,
        });

        // Assign default 'user' role
        await _supabase.from('user_roles').insert({
          'user_id': response.user!.id,
          'role': 'user',
        });

        await _fetchUserProfile(response.user!.id);
      }
    } on supabase.AuthException catch (e) {
      _error = e.message;
      throw Exception(e.message);
    } catch (e) {
      _error = e.toString();
      throw Exception(e.toString());
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
    _currentUser = null;
    _error = null;
    notifyListeners();
  }

  Future<void> _fetchUserProfile(String uid) async {
    try {
      final userData = await _supabase.from('profiles').select().eq('id', uid).single();
      
      // Fetch role
      String role = 'user';
      try {
        final roleData = await _supabase.from('user_roles').select('role').eq('user_id', uid).single();
        role = roleData['role'] ?? 'user';
      } catch (e) {
        debugPrint('Role not found for user $uid, defaulting to user');
      }

      _currentUser = User.fromMap(userData, role: role);
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
    }
  }

  Future<void> updateProfile({
    String? username,
    String? email,
    String? avatar,
    String? bio,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    _isLoading = true;
    notifyListeners();

    try {
      final updates = <String, dynamic>{};
      if (username != null) {
        updates['username'] = username;
      }
      if (email != null) {
        updates['email'] = email;
        await _supabase.auth.updateUser(supabase.UserAttributes(email: email));
      }
      if (avatar != null) {
        updates['avatar_url'] = avatar;
      }
      if (bio != null) {
        updates['bio'] = bio;
      }

      if (updates.isNotEmpty) {
        await _supabase.from('profiles').update(updates).eq('id', user.id);
        await _fetchUserProfile(user.id);
      }
    } catch (e) {
      debugPrint('Update profile error: $e');
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

