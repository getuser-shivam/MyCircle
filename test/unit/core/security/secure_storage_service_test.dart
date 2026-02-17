import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:my_circle/core/security/secure_storage_service.dart';

import 'secure_storage_service_test.mocks.dart';

@GenerateMocks([FlutterSecureStorage, Session])
void main() {
  group('SecureStorageService', () {
    late MockFlutterSecureStorage mockStorage;
    late MockSession mockSession;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      mockSession = MockSession();
    });

    group('storeSession', () {
      test('should store session successfully', () async {
        // Arrange
        const sessionJson = '{"access_token":"test_token"}';
        when(mockSession.toJson()).thenReturn(sessionJson);
        when(mockStorage.write(
          key: 'supabase_session',
          value: sessionJson,
        )).thenAnswer((_) async {});

        // Act
        await SecureStorageService.storeSession(mockSession);

        // Assert
        verify(mockStorage.write(
          key: 'supabase_session',
          value: sessionJson,
        )).called(1);
      });

      test('should throw exception when storage fails', () async {
        // Arrange
        when(mockStorage.write(
          key: anyNamed('key'),
          value: anyNamed('value'),
        )).thenThrow(Exception('Storage error'));

        // Act & Assert
        expect(
          () => SecureStorageService.storeSession(mockSession),
          throwsException,
        );
      });
    });

    group('retrieveSession', () {
      test('should return session when found', () async {
        // Arrange
        const sessionJson = '{"access_token":"test_token"}';
        when(mockStorage.read(key: 'supabase_session'))
            .thenAnswer((_) async => sessionJson);
        when(mockSession.fromJson(sessionJson)).thenReturn(mockSession);

        // Act
        final result = await SecureStorageService.retrieveSession();

        // Assert
        expect(result, isNotNull);
        verify(mockStorage.read(key: 'supabase_session')).called(1);
      });

      test('should return null when session not found', () async {
        // Arrange
        when(mockStorage.read(key: 'supabase_session'))
            .thenAnswer((_) async => null);

        // Act
        final result = await SecureStorageService.retrieveSession();

        // Assert
        expect(result, isNull);
        verify(mockStorage.read(key: 'supabase_session')).called(1);
      });

      test('should return null when session is corrupted', () async {
        // Arrange
        const corruptedJson = 'invalid json';
        when(mockStorage.read(key: 'supabase_session'))
            .thenAnswer((_) async => corruptedJson);
        when(mockStorage.fromJson(corruptedJson))
            .thenThrowFormatException('Invalid JSON');

        // Act
        final result = await SecureStorageService.retrieveSession();

        // Assert
        expect(result, isNull);
        verify(mockStorage.read(key: 'supabase_session')).called(1);
        verify(mockStorage.delete(key: 'supabase_session')).called(1);
      });
    });

    group('clearSession', () {
      test('should clear session successfully', () async {
        // Arrange
        when(mockStorage.delete(key: 'supabase_session'))
            .thenAnswer((_) async {});

        // Act
        await SecureStorageService.clearSession();

        // Assert
        verify(mockStorage.delete(key: 'supabase_session')).called(1);
      });

      test('should throw exception when deletion fails', () async {
        // Arrange
        when(mockStorage.delete(key: anyNamed('key')))
            .thenThrow(Exception('Deletion error'));

        // Act & Assert
        expect(
          () => SecureStorageService.clearSession(),
          throwsException,
        );
      });
    });

    group('token management', () {
      test('should store access token', () async {
        // Arrange
        const token = 'access_token_123';
        when(mockStorage.write(key: 'access_token', value: token))
            .thenAnswer((_) async {});

        // Act
        await SecureStorageService.storeAccessToken(token);

        // Assert
        verify(mockStorage.write(key: 'access_token', value: token)).called(1);
      });

      test('should retrieve access token', () async {
        // Arrange
        const token = 'access_token_123';
        when(mockStorage.read(key: 'access_token'))
            .thenAnswer((_) async => token);

        // Act
        final result = await SecureStorageService.getAccessToken();

        // Assert
        expect(result, equals(token));
      });

      test('should return null when access token not found', () async {
        // Arrange
        when(mockStorage.read(key: 'access_token'))
            .thenAnswer((_) async => null);

        // Act
        final result = await SecureStorageService.getAccessToken();

        // Assert
        expect(result, isNull);
      });

      test('should store refresh token', () async {
        // Arrange
        const token = 'refresh_token_123';
        when(mockStorage.write(key: 'refresh_token', value: token))
            .thenAnswer((_) async {});

        // Act
        await SecureStorageService.storeRefreshToken(token);

        // Assert
        verify(mockStorage.write(key: 'refresh_token', value: token)).called(1);
      });

      test('should retrieve refresh token', () async {
        // Arrange
        const token = 'refresh_token_123';
        when(mockStorage.read(key: 'refresh_token'))
            .thenAnswer((_) async => token);

        // Act
        final result = await SecureStorageService.getRefreshToken();

        // Assert
        expect(result, equals(token));
      });
    });

    group('user preferences', () {
      test('should store user preference', () async {
        // Arrange
        const key = 'theme';
        const value = 'dark';
        when(mockStorage.write(key: 'user_pref_theme', value: value))
            .thenAnswer((_) async {});

        // Act
        await SecureStorageService.storeUserPreference(key, value);

        // Assert
        verify(mockStorage.write(key: 'user_pref_theme', value: value)).called(1);
      });

      test('should retrieve user preference', () async {
        // Arrange
        const key = 'theme';
        const value = 'dark';
        when(mockStorage.read(key: 'user_pref_theme'))
            .thenAnswer((_) async => value);

        // Act
        final result = await SecureStorageService.getUserPreference(key);

        // Assert
        expect(result, equals(value));
      });
    });

    group('clearAllSecureData', () {
      test('should clear all secure data', () async {
        // Arrange
        when(mockStorage.deleteAll()).thenAnswer((_) async {});

        // Act
        await SecureStorageService.clearAllSecureData();

        // Assert
        verify(mockStorage.deleteAll()).called(1);
      });

      test('should throw exception when clearing fails', () async {
        // Arrange
        when(mockStorage.deleteAll()).thenThrow(Exception('Clear error'));

        // Act & Assert
        expect(
          () => SecureStorageService.clearAllSecureData(),
          throwsException,
        );
      });
    });

    group('isStorageAvailable', () {
      test('should return true when storage is available', () async {
        // Arrange
        when(mockStorage.read(key: 'test_key'))
            .thenAnswer((_) async => null);

        // Act
        final result = await SecureStorageService.isStorageAvailable();

        // Assert
        expect(result, isTrue);
      });

      test('should return false when storage is not available', () async {
        // Arrange
        when(mockStorage.read(key: 'test_key'))
            .thenThrow(Exception('Storage not available'));

        // Act
        final result = await SecureStorageService.isStorageAvailable();

        // Assert
        expect(result, isFalse);
      });
    });
  });
}
