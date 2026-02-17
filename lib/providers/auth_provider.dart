import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../models/social_user.dart';
import '../repositories/auth_repository.dart';
import '../repositories/user_repository.dart';
import '../services/supabase_service.dart';
import '../core/errors/app_exceptions.dart';

class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;
  
  // State
  supabase.User? _currentUser;
  SocialUser? _userProfile;
  bool _isAuthenticated = false;
  
  // Loading states
  bool _isLoading = false;
  bool _isSigningIn = false;
  bool _isSigningUp = false;
  bool _isLoadingProfile = false;
  
  // Error handling
  String? _error;
  String? _signInError;
  String? _signUpError;
  String? _profileError;

  AuthProvider() 
    : _authRepository = AuthRepository(SupabaseService.instance),
      _userRepository = UserRepository(SupabaseService.instance);

  // Getters
  supabase.User? get currentUser => _currentUser;
  SocialUser? get userProfile => _userProfile;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoggedIn => _currentUser != null;
  bool get isLoading => _isLoading;
  bool get isSigningIn => _isSigningIn;
  bool get isSigningUp => _isSigningUp;
  bool get isLoadingProfile => _isLoadingProfile;
  String? get error => _error;
  String? get signInError => _signInError;
  String? get signUpError => _signUpError;
  String? get profileError => _profileError;

  Future<void> initialize() async {
    try {
      _setLoading(true);
      final session = _authRepository.currentSession;
      
      if (session != null) {
        await _fetchUserProfile(session.user.id);
        _isAuthenticated = true;
      }
      
      _authRepository.onAuthStateChange.listen((data) async {
        final supabase.AuthChangeEvent event = data.event;
        final supabase.Session? currentSession = data.session;

        if (event == supabase.AuthChangeEvent.signedIn && currentSession != null) {
          await _fetchUserProfile(currentSession.user.id);
          _isAuthenticated = true;
        } else if (event == supabase.AuthChangeEvent.signedOut) {
          _currentUser = null;
          _userProfile = null;
          _isAuthenticated = false;
        }
        
        notifyListeners();
      });
    } on AuthException catch (e) {
      _setError('Failed to initialize authentication: ${e.message}');
    } catch (e) {
      _setError('An unexpected error occurred during initialization');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setSigningIn(true);
      _clearErrors();

      final response = await _authRepository.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _currentUser = response.user;
        await _fetchUserProfile(response.user!.id);
        _isAuthenticated = true;
      }
    } on AuthException catch (e) {
      _setSignInError(e.message);
    } catch (e) {
      _setSignInError('An unexpected error occurred during sign in');
    } finally {
      _setSigningIn(false);
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      _setSigningUp(true);
      _clearErrors();

      final response = await _authRepository.signUp(
        email: email,
        password: password,
        username: username,
      );

      if (response.user != null) {
        _currentUser = response.user;
        _isAuthenticated = true;
        
        // Create user profile
        await _createUserProfile(response.user!.id, username);
      }
    } on AuthException catch (e) {
      _setSignUpError(e.message);
    } catch (e) {
      _setSignUpError('An unexpected error occurred during sign up');
    } finally {
      _setSigningUp(false);
    }
  }

  Future<void> signOut() async {
    try {
      _setLoading(true);
      await _authRepository.signOut();
      
      _currentUser = null;
      _userProfile = null;
      _isAuthenticated = false;
      _clearErrors();
    } on AuthException catch (e) {
      _setError('Failed to sign out: ${e.message}');
    } catch (e) {
      _setError('Failed to sign out');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearErrors();
      
      await _authRepository.resetPassword(email);
    } on AuthException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Failed to reset password');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProfile({
    String? username,
    String? bio,
    String? avatarUrl,
  }) async {
    if (_currentUser == null) return;
    
    try {
      _setLoadingProfile(true);
      _clearProfileError();

      final updatedProfile = await _userRepository.updateProfile(
        userId: _currentUser!.id,
        username: username,
        bio: bio,
        avatarUrl: avatarUrl,
      );

      if (updatedProfile != null) {
        _userProfile = updatedProfile;
      }
    } on AuthException catch (e) {
      _setProfileError(e.message);
    } catch (e) {
      _setProfileError('Failed to update profile');
    } finally {
      _setLoadingProfile(false);
    }
  }

  Future<void> _fetchUserProfile(String userId) async {
    try {
      _userProfile = await _userRepository.getUserProfile(userId);
    } catch (e) {
      // Don't set error for profile fetch, just log it
      debugPrint('Failed to fetch user profile: $e');
    }
  }

  Future<void> _createUserProfile(String userId, String username) async {
    try {
      _userProfile = await _userRepository.createProfile(
        userId: userId,
        username: username,
      );
    } catch (e) {
      debugPrint('Failed to create user profile: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setSigningIn(bool signingIn) {
    _isSigningIn = signingIn;
    notifyListeners();
  }

  void _setSigningUp(bool signingUp) {
    _isSigningUp = signingUp;
    notifyListeners();
  }

  void _setLoadingProfile(bool loading) {
    _isLoadingProfile = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _setSignInError(String? error) {
    _signInError = error;
    notifyListeners();
  }

  void _setSignUpError(String? error) {
    _signUpError = error;
    notifyListeners();
  }

  void _setProfileError(String? error) {
    _profileError = error;
    notifyListeners();
  }

  void _clearErrors() {
    _error = null;
    _signInError = null;
    _signUpError = null;
    _profileError = null;
  }

  void _clearProfileError() {
    _profileError = null;
  }
}
