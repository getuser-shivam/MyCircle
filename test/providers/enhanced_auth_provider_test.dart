import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_circle/providers/enhanced_auth_provider.dart';
import 'package:my_circle/repositories/auth_repository.dart';
import 'package:my_circle/repositories/user_repository.dart';
import 'package:my_circle/models/social_user.dart';

import 'enhanced_auth_provider_test.mocks.dart';

@GenerateMocks([AuthRepository, UserRepository, AuthResponse, User, SocialUser, AuthState])
void main() {
  group('EnhancedAuthProvider', () {
    late EnhancedAuthProvider provider;
    late MockAuthRepository mockAuthRepository;
    late MockUserRepository mockUserRepository;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockUserRepository = MockUserRepository();
      provider = EnhancedAuthProvider();
      
      // Override the repositories for testing
      provider._authRepository = mockAuthRepository;
      provider._userRepository = mockUserRepository;
    });

    group('Initial State', () {
      test('should start with correct initial state', () {
        expect(provider.currentUser, isNull);
        expect(provider.userProfile, isNull);
        expect(provider.isAuthenticated, isFalse);
        expect(provider.isLoading, isFalse);
        expect(provider.isSigningIn, isFalse);
        expect(provider.isSigningUp, isFalse);
        expect(provider.error, isNull);
      });
    });

    group('signInWithEmail', () {
      test('should sign in successfully and load user profile', () async {
        // Arrange
        final mockResponse = MockAuthResponse();
        final mockUser = MockUser();
        final mockProfile = MockSocialUser();
        
        when(mockUser.id).thenReturn('user123');
        when(mockResponse.user).thenReturn(mockUser);
        when(mockAuthRepository.signInWithEmail(any, any))
            .thenAnswer((_) async => mockResponse);
        when(mockUserRepository.getUserProfile('user123'))
            .thenAnswer((_) async => mockProfile);
        when(mockProfile.id).thenReturn('user123');
        when(mockProfile.username).thenReturn('testuser');

        // Act
        await provider.signInWithEmail('test@example.com', 'password123');

        // Assert
        expect(provider.isSigningIn, isFalse);
        expect(provider.signInError, isNull);
        expect(provider.currentUser, mockUser);
        expect(provider.userProfile, mockProfile);
        expect(provider.isAuthenticated, isTrue);
        
        verify(mockAuthRepository.signInWithEmail('test@example.com', 'password123')).called(1);
        verify(mockUserRepository.getUserProfile('user123')).called(1);
      });

      test('should set error when sign in fails', () async {
        // Arrange
        when(mockAuthRepository.signInWithEmail(any, any))
            .thenThrow(Exception('Invalid credentials'));

        // Act
        await provider.signInWithEmail('test@example.com', 'wrongpassword');

        // Assert
        expect(provider.isSigningIn, isFalse);
        expect(provider.signInError, isNotNull);
        expect(provider.signInError, contains('Failed to sign in'));
        expect(provider.currentUser, isNull);
        expect(provider.isAuthenticated, isFalse);
      });

      test('should set loading state during sign in', () async {
        // Arrange
        final completer = Completer<AuthResponse>();
        when(mockAuthRepository.signInWithEmail(any, any))
            .thenAnswer((_) => completer.future);

        // Act
        final future = provider.signInWithEmail('test@example.com', 'password123');
        
        // Assert loading state
        expect(provider.isSigningIn, isTrue);
        
        // Complete the future
        final mockResponse = MockAuthResponse();
        final mockUser = MockUser();
        when(mockUser.id).thenReturn('user123');
        when(mockResponse.user).thenReturn(mockUser);
        when(mockUserRepository.getUserProfile('user123'))
            .thenAnswer((_) async => MockSocialUser());
        
        completer.complete(mockResponse);
        await future;
        
        // Assert final state
        expect(provider.isSigningIn, isFalse);
      });
    });

    group('signUpWithEmail', () {
      test('should sign up successfully and load user profile', () async {
        // Arrange
        final mockResponse = MockAuthResponse();
        final mockUser = MockUser();
        final mockProfile = MockSocialUser();
        
        when(mockUser.id).thenReturn('user123');
        when(mockResponse.user).thenReturn(mockUser);
        when(mockAuthRepository.signUpWithEmail(any, any, any))
            .thenAnswer((_) async => mockResponse);
        when(mockUserRepository.getUserProfile('user123'))
            .thenAnswer((_) async => mockProfile);

        // Act
        await provider.signUpWithEmail('test@example.com', 'password123', 'testuser');

        // Assert
        expect(provider.isSigningUp, isFalse);
        expect(provider.signUpError, isNull);
        expect(provider.currentUser, mockUser);
        expect(provider.userProfile, mockProfile);
        expect(provider.isAuthenticated, isTrue);
        
        verify(mockAuthRepository.signUpWithEmail('test@example.com', 'password123', 'testuser')).called(1);
        verify(mockUserRepository.getUserProfile('user123')).called(1);
      });

      test('should set error when sign up fails', () async {
        // Arrange
        when(mockAuthRepository.signUpWithEmail(any, any, any))
            .thenThrow(Exception('Email already exists'));

        // Act
        await provider.signUpWithEmail('test@example.com', 'password123', 'testuser');

        // Assert
        expect(provider.isSigningUp, isFalse);
        expect(provider.signUpError, isNotNull);
        expect(provider.signUpError, contains('Failed to sign up'));
        expect(provider.currentUser, isNull);
        expect(provider.isAuthenticated, isFalse);
      });
    });

    group('signInWithGoogle', () {
      test('should initiate Google sign in', () async {
        // Arrange
        when(mockAuthRepository.signInWithGoogle())
            .thenAnswer((_) async {});

        // Act
        await provider.signInWithGoogle();

        // Assert
        expect(provider.isSigningIn, isFalse);
        expect(provider.signInError, isNull);
        verify(mockAuthRepository.signInWithGoogle()).called(1);
      });

      test('should set error when Google sign in fails', () async {
        // Arrange
        when(mockAuthRepository.signInWithGoogle())
            .thenThrow(Exception('Google sign in failed'));

        // Act
        await provider.signInWithGoogle();

        // Assert
        expect(provider.isSigningIn, isFalse);
        expect(provider.signInError, isNotNull);
        expect(provider.signInError, contains('Failed to sign in with Google'));
      });
    });

    group('signOut', () {
      test('should sign out successfully and clear user data', () async {
        // Arrange - set initial authenticated state
        final mockUser = MockUser();
        final mockProfile = MockSocialUser();
        when(mockUser.id).thenReturn('user123');
        when(mockProfile.id).thenReturn('user123');
        
        provider._currentUser = mockUser;
        provider._userProfile = mockProfile;
        provider._isAuthenticated = true;
        
        when(mockAuthRepository.signOut()).thenAnswer((_) async {});

        // Act
        await provider.signOut();

        // Assert
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNull);
        expect(provider.currentUser, isNull);
        expect(provider.userProfile, isNull);
        expect(provider.isAuthenticated, isFalse);
        
        verify(mockAuthRepository.signOut()).called(1);
      });

      test('should set error when sign out fails', () async {
        // Arrange
        when(mockAuthRepository.signOut()).thenThrow(Exception('Sign out failed'));

        // Act
        await provider.signOut();

        // Assert
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNotNull);
        expect(provider.error, contains('Failed to sign out'));
      });
    });

    group('updateProfile', () {
      test('should update profile successfully', () async {
        // Arrange
        final mockUser = MockUser();
        final mockUpdatedProfile = MockSocialUser();
        
        when(mockUser.id).thenReturn('user123');
        when(mockUserRepository.updateUserProfile(
          userId: 'user123',
          username: 'newuser',
          bio: 'new bio',
        )).thenAnswer((_) async => mockUpdatedProfile);
        
        provider._currentUser = mockUser;

        // Act
        await provider.updateProfile(
          username: 'newuser',
          bio: 'new bio',
        );

        // Assert
        expect(provider.isLoadingProfile, isFalse);
        expect(provider.profileError, isNull);
        expect(provider.userProfile, mockUpdatedProfile);
        
        verify(mockUserRepository.updateUserProfile(
          userId: 'user123',
          username: 'newuser',
          bio: 'new bio',
        )).called(1);
      });

      test('should set error when profile update fails', () async {
        // Arrange
        final mockUser = MockUser();
        when(mockUser.id).thenReturn('user123');
        when(mockUserRepository.updateUserProfile(any))
            .thenThrow(Exception('Update failed'));
        
        provider._currentUser = mockUser;

        // Act
        await provider.updateProfile(username: 'newuser');

        // Assert
        expect(provider.isLoadingProfile, isFalse);
        expect(provider.profileError, isNotNull);
        expect(provider.profileError, contains('Failed to update profile'));
      });

      test('should do nothing when user not authenticated', () async {
        // Arrange
        provider._currentUser = null;

        // Act
        await provider.updateProfile(username: 'newuser');

        // Assert
        verifyNever(mockUserRepository.updateUserProfile(any));
      });
    });

    group('refreshProfile', () {
      test('should refresh user profile successfully', () async {
        // Arrange
        final mockUser = MockUser();
        final mockProfile = MockSocialUser();
        
        when(mockUser.id).thenReturn('user123');
        when(mockUserRepository.getUserProfile('user123'))
            .thenAnswer((_) async => mockProfile);
        
        provider._currentUser = mockUser;

        // Act
        await provider.refreshProfile();

        // Assert
        expect(provider.userProfile, mockProfile);
        verify(mockUserRepository.getUserProfile('user123')).called(1);
      });

      test('should do nothing when user not authenticated', () async {
        // Arrange
        provider._currentUser = null;

        // Act
        await provider.refreshProfile();

        // Assert
        verifyNever(mockUserRepository.getUserProfile(any));
      });
    });

    group('resetPassword', () {
      test('should reset password successfully', () async {
        // Arrange
        when(mockAuthRepository.resetPassword(any)).thenAnswer((_) async {});

        // Act
        await provider.resetPassword('test@example.com');

        // Assert
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNull);
        verify(mockAuthRepository.resetPassword('test@example.com')).called(1);
      });

      test('should set error when password reset fails', () async {
        // Arrange
        when(mockAuthRepository.resetPassword(any))
            .thenThrow(Exception('Email not found'));

        // Act
        await provider.resetPassword('invalid@example.com');

        // Assert
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNotNull);
        expect(provider.error, contains('Failed to reset password'));
      });
    });

    group('updatePassword', () {
      test('should update password successfully', () async {
        // Arrange
        when(mockAuthRepository.updatePassword(any)).thenAnswer((_) async {});

        // Act
        await provider.updatePassword('newpassword123');

        // Assert
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNull);
        verify(mockAuthRepository.updatePassword('newpassword123')).called(1);
      });

      test('should set error when password update fails', () async {
        // Arrange
        when(mockAuthRepository.updatePassword(any))
            .thenThrow(Exception('Password too weak'));

        // Act
        await provider.updatePassword('weak');

        // Assert
        expect(provider.isLoading, isFalse);
        expect(provider.error, isNotNull);
        expect(provider.error, contains('Failed to update password'));
      });
    });

    group('Error Handling', () {
      test('should clear errors on successful operations', () async {
        // Arrange - set initial error state
        provider._signInError = 'Previous error';
        
        final mockResponse = MockAuthResponse();
        final mockUser = MockUser();
        when(mockUser.id).thenReturn('user123');
        when(mockResponse.user).thenReturn(mockUser);
        when(mockAuthRepository.signInWithEmail(any, any))
            .thenAnswer((_) async => mockResponse);
        when(mockUserRepository.getUserProfile('user123'))
            .thenAnswer((_) async => MockSocialUser());

        // Act
        await provider.signInWithEmail('test@example.com', 'password123');

        // Assert
        expect(provider.signInError, isNull);
      });

      test('should handle multiple concurrent operations', () async {
        // Arrange
        final completer1 = Completer<AuthResponse>();
        final completer2 = Completer<AuthResponse>();
        
        when(mockAuthRepository.signInWithEmail(any, any))
            .thenAnswer((_) => completer1.future);
        when(mockAuthRepository.signUpWithEmail(any, any, any))
            .thenAnswer((_) => completer2.future);

        // Act - start both operations
        final future1 = provider.signInWithEmail('test1@example.com', 'password');
        final future2 = provider.signUpWithEmail('test2@example.com', 'password', 'user');
        
        // Assert both are loading
        expect(provider.isSigningIn, isTrue);
        expect(provider.isSigningUp, isTrue);
        
        // Complete operations
        final mockResponse = MockAuthResponse();
        final mockUser = MockUser();
        when(mockUser.id).thenReturn('user123');
        when(mockResponse.user).thenReturn(mockUser);
        when(mockUserRepository.getUserProfile('user123'))
            .thenAnswer((_) async => MockSocialUser());
        
        completer1.complete(mockResponse);
        completer2.complete(mockResponse);
        
        await Future.wait([future1, future2]);
        
        // Assert final state
        expect(provider.isSigningIn, isFalse);
        expect(provider.isSigningUp, isFalse);
      });
    });
  });
}

// Extension to access private members for testing
extension EnhancedAuthProviderTestExtension on EnhancedAuthProvider {
  set _authRepository(AuthRepository repository) => 
      this._authRepository = repository;
  set _userRepository(UserRepository repository) => 
      this._userRepository = repository;
  set _currentUser(User? user) => this._currentUser = user;
  set _userProfile(SocialUser? profile) => this._userProfile = profile;
  set _isAuthenticated(bool authenticated) => this._isAuthenticated = authenticated;
  set _signInError(String? error) => this._signInError = error;
}
