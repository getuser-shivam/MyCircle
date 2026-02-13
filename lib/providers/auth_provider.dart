import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';

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
  });

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User(
      id: doc.id,
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      avatar: data['avatar'] ?? 'https://i.pravatar.cc/300',
      isVerified: data['isVerified'] ?? false,
      isPremium: data['isPremium'] ?? false,
      followersCount: data['followersCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      postsCount: data['postsCount'] ?? 0,
    );
  }
}

class AuthProvider extends ChangeNotifier {
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  User? _currentUser;
  bool _isLoading = false;
  
  User? get currentUser => _currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  bool get isLoading => _isLoading;

  Future<void> initialize() async {
    _auth.authStateChanges().listen((firebaseUser) async {
      if (firebaseUser != null) {
        await _fetchUserProfile(firebaseUser.uid);
      } else {
        _currentUser = null;
        notifyListeners();
      }
    });
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception(e.message);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String username, String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      // Create user in Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document in Firestore
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'username': username,
          'email': email,
          'avatar': 'https://i.pravatar.cc/300?u=${userCredential.user!.uid}',
          'createdAt': FieldValue.serverTimestamp(),
          'isVerified': false,
          'isPremium': false,
          'followersCount': 0,
          'followingCount': 0,
          'postsCount': 0,
        });

        await userCredential.user!.updateDisplayName(username);
        await _fetchUserProfile(userCredential.user!.uid);
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw Exception(e.message);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> _fetchUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        _currentUser = User.fromFirestore(doc);
        notifyListeners();
      }
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
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    _isLoading = true;
    notifyListeners();

    try {
      final updates = <String, dynamic>{};
      if (username != null) {
        updates['username'] = username;
        await user.updateDisplayName(username);
      }
      if (email != null) {
        updates['email'] = email;
        await user.verifyBeforeUpdateEmail(email);
      }
      if (avatar != null) {
        updates['avatar'] = avatar;
        await user.updatePhotoURL(avatar);
      }
      if (bio != null) {
        updates['bio'] = bio;
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(user.uid).update(updates);
        await _fetchUserProfile(user.uid);
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
