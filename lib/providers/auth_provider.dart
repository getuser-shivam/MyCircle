import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class User {
  final String id;
  final String username;
  final String email;
  final String avatar;
  final bool isVerified;
  final bool isPremium;
  final int followersCount;
  final int followingCount;
  final int postsCount;
  final Map<String, dynamic> stats;
  final Map<String, dynamic> preferences;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.avatar,
    this.isVerified = false,
    this.isPremium = false,
    this.followersCount = 0,
    this.followingCount = 0,
    this.postsCount = 0,
    this.stats = const {},
    this.preferences = const {},
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'] ?? '',
      isVerified: json['isVerified'] ?? false,
      isPremium: json['isPremium'] ?? false,
      followersCount: json['followerCount'] ?? json['followersCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      postsCount: json['postCount'] ?? json['postsCount'] ?? 0,
      stats: json['stats'] ?? {},
      preferences: json['preferences'] ?? {},
    );
  }
}

class AuthProvider extends ChangeNotifier {
  final String baseUrl = 'http://localhost:5000/api';
  User? _currentUser;
  String? _token;
  String? _refreshToken;
  bool _isLoading = false;
  bool _isLoggedIn = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get token => _token;

  // Load saved tokens on startup
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    _refreshToken = prefs.getString('refresh_token');

    if (_token != null) {
      try {
        await getProfile();
      } catch (e) {
        // Token expired, logout
        await logout();
      }
    }
  }

  Future<void> _saveTokens() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token != null) {
      await prefs.setString('auth_token', _token!);
    }
    if (_refreshToken != null) {
      await prefs.setString('refresh_token', _refreshToken!);
    }
  }

  Future<void> _clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
    _token = null;
    _refreshToken = null;
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        _token = data['data']['token'];
        _refreshToken = data['data']['refreshToken'];
        _currentUser = User.fromJson(data['data']['user']);
        _isLoggedIn = true;

        await _saveTokens();
      } else {
        throw Exception(data['message'] ?? 'Login failed');
      }
    } catch (error) {
      debugPrint('Login error: $error');
      throw error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String username, String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success']) {
        _token = data['data']['token'];
        _refreshToken = data['data']['refreshToken'];
        _currentUser = User.fromJson(data['data']['user']);
        _isLoggedIn = true;

        await _saveTokens();
      } else {
        throw Exception(data['message'] ?? 'Registration failed');
      }
    } catch (error) {
      debugPrint('Registration error: $error');
      throw error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Call logout endpoint if needed
      _currentUser = null;
      _isLoggedIn = false;
      await _clearTokens();
    } catch (error) {
      debugPrint('Logout error: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> getProfile() async {
    if (_token == null) throw Exception('Not authenticated');

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        _currentUser = User.fromJson(data['data']['user']);
        _isLoggedIn = true;
      } else {
        throw Exception(data['message'] ?? 'Failed to get profile');
      }
    } catch (error) {
      debugPrint('Get profile error: $error');
      throw error;
    }
  }

  Future<void> updateProfile({
    String? username,
    String? email,
    String? avatar,
    String? bio,
  }) async {
    if (_token == null) throw Exception('Not authenticated');

    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/auth/profile'),
        headers: {
          'Authorization': 'Bearer $_token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          if (username != null) 'username': username,
          if (email != null) 'email': email,
          if (avatar != null) 'avatar': avatar,
          if (bio != null) 'bio': bio,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        _currentUser = User.fromJson(data['data']['user']);
      } else {
        throw Exception(data['message'] ?? 'Failed to update profile');
      }
    } catch (error) {
      debugPrint('Update profile error: $error');
      throw error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshToken() async {
    if (_refreshToken == null) throw Exception('No refresh token');

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'refreshToken': _refreshToken,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success']) {
        _token = data['data']['token'];
        _refreshToken = data['data']['refreshToken'];
        await _saveTokens();
      } else {
        // Refresh failed, logout
        await logout();
        throw Exception('Session expired');
      }
    } catch (error) {
      await logout();
      throw error;
    }
  }
}
