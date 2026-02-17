import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:my_circle/core/security/auth_guard.dart';
import 'package:my_circle/core/security/secure_storage_service.dart';

import 'auth_flow_test.mocks.dart';

@GenerateMocks([SupabaseClient, AuthState])
void main() {
  group('Authentication Flow Integration Tests', () {
    late MockSupabaseClient mockSupabaseClient;
    late MockAuthState mockAuthState;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockAuthState = MockAuthState();
    });

    group('AuthGuard', () {
      test('should return false when no current user', () {
        // Arrange
        when(mockSupabaseClient.auth.currentUser).thenReturn(null);

        // Act
        final result = AuthGuard.isAuthenticated();

        // Assert
        expect(result, isFalse);
      });

      test('should return true when current user exists', () {
        // Arrange
        final mockUser = User(
          id: 'test-user-id',
          email: 'test@example.com',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: DateTime.now(),
          phone: '',
        );
        when(mockSupabaseClient.auth.currentUser).thenReturn(mockUser);

        // Act
        final result = AuthGuard.isAuthenticated();

        // Assert
        expect(result, isTrue);
      });

      test('should validate session expiry', () async {
        // Arrange
        final expiredSession = Session(
          accessToken: 'expired-token',
          tokenType: 'bearer',
          expiresIn: 0,
          expiresAt: DateTime.now().millisecondsSinceEpoch ~/ 1000 - 3600, // 1 hour ago
          refreshToken: 'refresh-token',
          user: null,
        );
        when(mockSupabaseClient.auth.currentSession).thenReturn(expiredSession);

        // Act
        final result = await AuthGuard.isSessionValid();

        // Assert
        expect(result, isFalse);
      });

      test('should validate valid session', () async {
        // Arrange
        final validSession = Session(
          accessToken: 'valid-token',
          tokenType: 'bearer',
          expiresIn: 3600,
          expiresAt: DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
          refreshToken: 'refresh-token',
          user: null,
        );
        when(mockSupabaseClient.auth.currentSession).thenReturn(validSession);

        // Act
        final result = await AuthGuard.isSessionValid();

        // Assert
        expect(result, isTrue);
      });

      test('should refresh session when needed', () async {
        // Arrange
        final sessionNeedingRefresh = Session(
          accessToken: 'old-token',
          tokenType: 'bearer',
          expiresIn: 1800, // 30 minutes
          expiresAt: DateTime.now().add(Duration(minutes: 30)).millisecondsSinceEpoch ~/ 1000,
          refreshToken: 'refresh-token',
          user: null,
        );
        final refreshedSession = Session(
          accessToken: 'new-token',
          tokenType: 'bearer',
          expiresIn: 3600,
          expiresAt: DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
          refreshToken: 'new-refresh-token',
          user: null,
        );

        when(mockSupabaseClient.auth.currentSession).thenReturn(sessionNeedingRefresh);
        when(mockSupabaseClient.auth.refreshSession())
            .thenAnswer((_) async => AuthResponse(session: refreshedSession, user: null));

        // Act
        final result = await AuthGuard.refreshSessionIfNeeded();

        // Assert
        expect(result, isTrue);
        verify(mockSupabaseClient.auth.refreshSession()).called(1);
      });

      test('should handle force logout', () async {
        // Arrange
        when(mockSupabaseClient.auth.signOut()).thenAnswer((_) async {});
        
        // Act
        await AuthGuard.forceLogout();

        // Assert
        verify(mockSupabaseClient.auth.signOut()).called(1);
      });

      test('should check resource ownership', () {
        // Arrange
        const currentUserId = 'user-123';
        final mockUser = User(
          id: currentUserId,
          email: 'test@example.com',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: DateTime.now(),
          phone: '',
        );
        when(mockSupabaseClient.auth.currentUser).thenReturn(mockUser);

        // Act & Assert
        expect(AuthGuard.isResourceOwner(currentUserId), isTrue);
        expect(AuthGuard.isResourceOwner('different-user'), isFalse);
      });
    });

    group('Secure Storage Integration', () {
      testWidgets('should store and retrieve session securely', (tester) async {
        // Arrange
        final testSession = Session(
          accessToken: 'test-access-token',
          tokenType: 'bearer',
          expiresIn: 3600,
          expiresAt: DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
          refreshToken: 'test-refresh-token',
          user: null,
        );

        // Act
        await SecureStorageService.storeSession(testSession);
        final retrievedSession = await SecureStorageService.retrieveSession();

        // Assert
        expect(retrievedSession, isNotNull);
        expect(retrievedSession!.accessToken, equals(testSession.accessToken));
        expect(retrievedSession.refreshToken, equals(testSession.refreshToken));
      });

      testWidgets('should handle corrupted session gracefully', (tester) async {
        // This test would require mocking the secure storage to return corrupted data
        // For now, we'll test the null case
        final result = await SecureStorageService.retrieveSession();
        expect(result, isNull);
      });

      testWidgets('should clear session on logout', (tester) async {
        // Arrange
        final testSession = Session(
          accessToken: 'test-access-token',
          tokenType: 'bearer',
          expiresIn: 3600,
          expiresAt: DateTime.now().add(Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
          refreshToken: 'test-refresh-token',
          user: null,
        );

        await SecureStorageService.storeSession(testSession);

        // Act
        await SecureStorageService.clearSession();
        final retrievedSession = await SecureStorageService.retrieveSession();

        // Assert
        expect(retrievedSession, isNull);
      });
    });

    group('Complete Authentication Flow', () {
      testWidgets('should handle login flow end-to-end', (tester) async {
        // This would be a more complex integration test
        // involving actual UI widgets and authentication screens
        
        // For now, we'll test the core logic
        expect(AuthGuard.isAuthenticated(), isFalse);
        
        // Simulate successful login
        final mockUser = User(
          id: 'test-user-id',
          email: 'test@example.com',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: DateTime.now(),
          phone: '',
        );
        when(mockSupabaseClient.auth.currentUser).thenReturn(mockUser);

        expect(AuthGuard.isAuthenticated(), isTrue);
      });

      testWidgets('should handle session timeout', (tester) async {
        // Arrange
        final expiredSession = Session(
          accessToken: 'expired-token',
          tokenType: 'bearer',
          expiresIn: 0,
          expiresAt: DateTime.now().millisecondsSinceEpoch ~/ 1000 - 3600,
          refreshToken: 'expired-refresh',
          user: null,
        );
        when(mockSupabaseClient.auth.currentSession).thenReturn(expiredSession);

        // Act
        final isValid = await AuthGuard.isSessionValid();

        // Assert
        expect(isValid, isFalse);
      });
    });

    group('Security Validation', () {
      test('should validate user permissions', () async {
        // Arrange
        final mockUser = User(
          id: 'test-user-id',
          email: 'test@example.com',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: DateTime.now(),
          phone: '',
        );
        when(mockSupabaseClient.auth.currentUser).thenReturn(mockUser);

        // Act
        final hasPermission = await AuthGuard.hasPermission('read_streams');

        // Assert
        expect(hasPermission, isTrue);
      });

      test('should deny permissions for unauthenticated user', () async {
        // Arrange
        when(mockSupabaseClient.auth.currentUser).thenReturn(null);

        // Act
        final hasPermission = await AuthGuard.hasPermission('read_streams');

        // Assert
        expect(hasPermission, isFalse);
      });
    });
  });
}
