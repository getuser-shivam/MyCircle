import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_circle/repositories/auth_repository.dart';
import 'package:my_circle/services/supabase_service.dart';

import 'auth_repository_test.mocks.dart';

@GenerateMocks([SupabaseService, SupabaseClient, AuthResponse, User, Session, AuthState])
void main() {
  group('AuthRepository', () {
    late AuthRepository repository;
    late MockSupabaseService mockSupabaseService;
    late MockSupabaseClient mockClient;

    setUp(() {
      mockSupabaseService = MockSupabaseService();
      mockClient = MockSupabaseClient();
      repository = AuthRepository(mockSupabaseService);
    });

    group('signInWithEmail', () {
      test('should sign in successfully with valid credentials', () async {
        // Arrange
        final mockResponse = MockAuthResponse();
        final mockUser = MockUser();
        when(mockUser.id).thenReturn('user123');
        when(mockResponse.user).thenReturn(mockUser);
        
        when(mockClient.auth.signInWithPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => mockResponse);

        // Act
        final result = await repository.signInWithEmail('test@example.com', 'password123');

        // Assert
        expect(result, isA<AuthResponse>());
        expect(result.user?.id, 'user123');
        verify(mockClient.auth.signInWithPassword(
          email: 'test@example.com',
          password: 'password123',
        )).called(1);
      });

      test('should throw exception when sign in fails', () async {
        // Arrange
        when(mockClient.auth.signInWithPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(Exception('Invalid credentials'));

        // Act & Assert
        expect(
          () => repository.signInWithEmail('test@example.com', 'wrongpassword'),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Failed to sign in'))),
        );
      });
    });

    group('signUpWithEmail', () {
      test('should sign up successfully and create user profile', () async {
        // Arrange
        final mockResponse = MockAuthResponse();
        final mockUser = MockUser();
        when(mockUser.id).thenReturn('user123');
        when(mockResponse.user).thenReturn(mockUser);
        
        when(mockClient.auth.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
          data: anyNamed('data'),
        )).thenAnswer((_) async => mockResponse);
        
        when(mockClient.from('users')).thenReturn(MockPostgrestBuilder());
        when(mockClient.from('users').insert(any)).thenAnswer((_) async {});

        // Act
        final result = await repository.signUpWithEmail('test@example.com', 'password123', 'testuser');

        // Assert
        expect(result, isA<AuthResponse>());
        expect(result.user?.id, 'user123');
        verify(mockClient.auth.signUp(
          email: 'test@example.com',
          password: 'password123',
          data: {'username': 'testuser'},
        )).called(1);
      });

      test('should throw exception when sign up fails', () async {
        // Arrange
        when(mockClient.auth.signUp(
          email: anyNamed('email'),
          password: anyNamed('password'),
          data: anyNamed('data'),
        )).thenThrow(Exception('Email already exists'));

        // Act & Assert
        expect(
          () => repository.signUpWithEmail('test@example.com', 'password123', 'testuser'),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Failed to sign up'))),
        );
      });
    });

    group('signInWithGoogle', () {
      test('should initiate Google sign in', () async {
        // Arrange
        when(mockClient.auth.signInWithOAuth(
          any,
          redirectTo: anyNamed('redirectTo'),
        )).thenAnswer((_) async => MockAuthResponse());

        // Act
        await repository.signInWithGoogle();

        // Assert
        verify(mockClient.auth.signInWithOAuth(
          Provider.google,
          redirectTo: 'io.supabase.flutter://signin-callback/',
        )).called(1);
      });

      test('should throw exception when Google sign in fails', () async {
        // Arrange
        when(mockClient.auth.signInWithOAuth(
          any,
          redirectTo: anyNamed('redirectTo'),
        )).thenThrow(Exception('Google sign in failed'));

        // Act & Assert
        expect(
          () => repository.signInWithGoogle(),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Failed to sign in with Google'))),
        );
      });
    });

    group('signOut', () {
      test('should sign out successfully', () async {
        // Arrange
        when(mockClient.auth.signOut()).thenAnswer((_) async {});

        // Act
        await repository.signOut();

        // Assert
        verify(mockClient.auth.signOut()).called(1);
      });

      test('should throw exception when sign out fails', () async {
        // Arrange
        when(mockClient.auth.signOut()).thenThrow(Exception('Sign out failed'));

        // Act & Assert
        expect(
          () => repository.signOut(),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Failed to sign out'))),
        );
      });
    });

    group('getCurrentUser', () {
      test('should return current user when authenticated', () async {
        // Arrange
        final mockUser = MockUser();
        when(mockUser.id).thenReturn('user123');
        when(mockClient.auth.currentUser).thenReturn(mockUser);

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result, isA<User>());
        expect(result?.id, 'user123');
      });

      test('should return null when not authenticated', () async {
        // Arrange
        when(mockClient.auth.currentUser).thenReturn(null);

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result, isNull);
      });

      test('should throw exception when getting current user fails', () async {
        // Arrange
        when(mockClient.auth.currentUser).thenThrow(Exception('Auth error'));

        // Act & Assert
        expect(
          () => repository.getCurrentUser(),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Failed to get current user'))),
        );
      });
    });

    group('isAuthenticated', () {
      test('should return true when user is authenticated', () async {
        // Arrange
        final mockUser = MockUser();
        when(mockUser.id).thenReturn('user123');
        when(mockClient.auth.currentUser).thenReturn(mockUser);

        // Act
        final result = await repository.isAuthenticated();

        // Assert
        expect(result, isTrue);
      });

      test('should return false when user is not authenticated', () async {
        // Arrange
        when(mockClient.auth.currentUser).thenReturn(null);

        // Act
        final result = await repository.isAuthenticated();

        // Assert
        expect(result, isFalse);
      });

      test('should return false when auth check fails', () async {
        // Arrange
        when(mockClient.auth.currentUser).thenThrow(Exception('Auth error'));

        // Act
        final result = await repository.isAuthenticated();

        // Assert
        expect(result, isFalse);
      });
    });

    group('resetPassword', () {
      test('should send password reset email successfully', () async {
        // Arrange
        when(mockClient.auth.resetPasswordForEmail(any)).thenAnswer((_) async {});

        // Act
        await repository.resetPassword('test@example.com');

        // Assert
        verify(mockClient.auth.resetPasswordForEmail('test@example.com')).called(1);
      });

      test('should throw exception when password reset fails', () async {
        // Arrange
        when(mockClient.auth.resetPasswordForEmail(any)).thenThrow(Exception('Email not found'));

        // Act & Assert
        expect(
          () => repository.resetPassword('invalid@example.com'),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Failed to reset password'))),
        );
      });
    });

    group('updatePassword', () {
      test('should update password successfully', () async {
        // Arrange
        when(mockClient.auth.updateUser(any)).thenAnswer((_) async => MockUser());

        // Act
        await repository.updatePassword('newpassword123');

        // Assert
        verify(mockClient.auth.updateUser(UserAttributes(password: 'newpassword123'))).called(1);
      });

      test('should throw exception when password update fails', () async {
        // Arrange
        when(mockClient.auth.updateUser(any)).thenThrow(Exception('Password too weak'));

        // Act & Assert
        expect(
          () => repository.updatePassword('weak'),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Failed to update password'))),
        );
      });
    });

    group('updateEmail', () {
      test('should update email successfully', () async {
        // Arrange
        when(mockClient.auth.updateUser(any)).thenAnswer((_) async => MockUser());

        // Act
        await repository.updateEmail('newemail@example.com');

        // Assert
        verify(mockClient.auth.updateUser(UserAttributes(email: 'newemail@example.com'))).called(1);
      });

      test('should throw exception when email update fails', () async {
        // Arrange
        when(mockClient.auth.updateUser(any)).thenThrow(Exception('Email already exists'));

        // Act & Assert
        expect(
          () => repository.updateEmail('existing@example.com'),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Failed to update email'))),
        );
      });
    });

    group('getSessionToken', () {
      test('should return session token when user is authenticated', () async {
        // Arrange
        final mockSession = MockSession();
        when(mockSession.accessToken).thenReturn('session_token_123');
        when(mockClient.auth.currentSession).thenReturn(mockSession);

        // Act
        final result = await repository.getSessionToken();

        // Assert
        expect(result, 'session_token_123');
      });

      test('should return null when no session exists', () async {
        // Arrange
        when(mockClient.auth.currentSession).thenReturn(null);

        // Act
        final result = await repository.getSessionToken();

        // Assert
        expect(result, isNull);
      });

      test('should throw exception when getting session token fails', () async {
        // Arrange
        when(mockClient.auth.currentSession).thenThrow(Exception('Session error'));

        // Act & Assert
        expect(
          () => repository.getSessionToken(),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Failed to get session token'))),
        );
      });
    });

    group('refreshSession', () {
      test('should refresh session successfully', () async {
        // Arrange
        when(mockClient.auth.refreshSession()).thenAnswer((_) async {});

        // Act
        await repository.refreshSession();

        // Assert
        verify(mockClient.auth.refreshSession()).called(1);
      });

      test('should throw exception when session refresh fails', () async {
        // Arrange
        when(mockClient.auth.refreshSession()).thenThrow(Exception('Refresh failed'));

        // Act & Assert
        expect(
          () => repository.refreshSession(),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message', contains('Failed to refresh session'))),
        );
      });
    });

    group('authStateChanges', () {
      test('should return auth state changes stream', () {
        // Arrange
        final mockStream = Stream<AuthState>.empty();
        when(mockClient.auth.onAuthStateChange).thenReturn(mockStream);

        // Act
        final result = repository.authStateChanges;

        // Assert
        expect(result, isA<Stream<AuthState>>());
        verify(mockClient.auth.onAuthStateChange).called(1);
      });
    });
  });
}

// Mock classes for testing
class MockPostgrestBuilder extends Mock {
  MockPostgrestBuilder insert(dynamic data);
  MockPostgrestBuilder update(dynamic data);
  MockPostgrestBuilder delete();
}
