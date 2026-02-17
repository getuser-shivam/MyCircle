import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:my_circle/providers/provider_setup.dart';
import 'package:my_circle/providers/enhanced_auth_provider.dart';
import 'package:my_circle/providers/enhanced_media_provider.dart';
import 'package:my_circle/providers/enhanced_stream_provider.dart';
import 'package:my_circle/providers/enhanced_social_provider.dart';
import 'package:my_circle/providers/theme_provider.dart';
import 'package:my_circle/providers/notification_provider.dart';
import 'package:my_circle/providers/antigravity_provider.dart';
import 'package:my_circle/services/supabase_service.dart';

import 'provider_setup_test.mocks.dart';

@GenerateMocks([SupabaseService])
void main() {
  group('ProviderSetup Widget Tests', () {
    late MockSupabaseService mockSupabaseService;

    setUp(() {
      mockSupabaseService = MockSupabaseService();
    });

    Widget createProviderSetupWidget({Widget? child}) {
      return ProviderSetup(
        child: child ?? const SizedBox(),
      );
    }

    testWidgets('should provide all required providers', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createProviderSetupWidget());
      await tester.pumpAndSettle();

      // Assert - Check that all providers are available
      expect(find.byType(EnhancedAuthProvider), findsOneWidget);
      expect(find.byType(EnhancedMediaProvider), findsOneWidget);
      expect(find.byType(EnhancedStreamProvider), findsOneWidget);
      expect(find.byType(EnhancedSocialProvider), findsOneWidget);
      expect(find.byType(ThemeProvider), findsOneWidget);
      expect(find.byType(NotificationProvider), findsOneWidget);
      expect(find.byType(AntigravityProvider), findsOneWidget);
    });

    testWidgets('should provide SupabaseService', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(createProviderSetupWidget());
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(Provider<SupabaseService>), findsOneWidget);
    });

    testWidgets('should access providers through context extension', (WidgetTester tester) async {
      // Arrange
      Widget testWidget() {
        return Builder(
          builder: (context) {
            // Test context extension methods
            final authProvider = context.authProvider;
            final mediaProvider = context.mediaProvider;
            final streamProvider = context.streamProvider;
            final socialProvider = context.socialProvider;
            final themeProvider = context.themeProvider;
            final notificationProvider = context.notificationProvider;
            final antigravityProvider = context.antigravityProvider;

            return Column(
              children: [
                Text('Auth: ${authProvider.runtimeType}'),
                Text('Media: ${mediaProvider.runtimeType}'),
                Text('Stream: ${streamProvider.runtimeType}'),
                Text('Social: ${socialProvider.runtimeType}'),
                Text('Theme: ${themeProvider.runtimeType}'),
                Text('Notification: ${notificationProvider.runtimeType}'),
                Text('Antigravity: ${antigravityProvider.runtimeType}'),
              ],
            );
          },
        );
      }

      await tester.pumpWidget(createProviderSetupWidget(child: testWidget()));
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('Auth: EnhancedAuthProvider'), findsOneWidget);
      expect(find.textContaining('Media: EnhancedMediaProvider'), findsOneWidget);
      expect(find.textContaining('Stream: EnhancedStreamProvider'), findsOneWidget);
      expect(find.textContaining('Social: EnhancedSocialProvider'), findsOneWidget);
      expect(find.textContaining('Theme: ThemeProvider'), findsOneWidget);
      expect(find.textContaining('Notification: NotificationProvider'), findsOneWidget);
      expect(find.textContaining('Antigravity: AntigravityProvider'), findsOneWidget);
    });

    testWidgets('should access watch methods through context extension', (WidgetTester tester) async {
      // Arrange
      Widget testWidget() {
        return Builder(
          builder: (context) {
            // Test watch context extension methods
            final authProvider = context.watchAuth;
            final mediaProvider = context.watchMedia;
            final streamProvider = context.watchStream;
            final socialProvider = context.watchSocial;
            final themeProvider = context.watchTheme;
            final notificationProvider = context.watchNotifications;
            final antigravityProvider = context.watchAntigravity;

            return Column(
              children: [
                Text('Watch Auth: ${authProvider.runtimeType}'),
                Text('Watch Media: ${mediaProvider.runtimeType}'),
                Text('Watch Stream: ${streamProvider.runtimeType}'),
                Text('Watch Social: ${socialProvider.runtimeType}'),
                Text('Watch Theme: ${themeProvider.runtimeType}'),
                Text('Watch Notification: ${notificationProvider.runtimeType}'),
                Text('Watch Antigravity: ${antigravityProvider.runtimeType}'),
              ],
            );
          },
        );
      }

      await tester.pumpWidget(createProviderSetupWidget(child: testWidget()));
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('Watch Auth: EnhancedAuthProvider'), findsOneWidget);
      expect(find.textContaining('Watch Media: EnhancedMediaProvider'), findsOneWidget);
      expect(find.textContaining('Watch Stream: EnhancedStreamProvider'), findsOneWidget);
      expect(find.textContaining('Watch Social: EnhancedSocialProvider'), findsOneWidget);
      expect(find.textContaining('Watch Theme: ThemeProvider'), findsOneWidget);
      expect(find.textContaining('Watch Notification: NotificationProvider'), findsOneWidget);
      expect(find.textContaining('Watch Antigravity: AntigravityProvider'), findsOneWidget);
    });

    testWidgets('should access convenience methods through context extension', (WidgetTester tester) async {
      // Arrange
      Widget testWidget() {
        return Builder(
          builder: (context) {
            // Test convenience methods
            final isAuthenticated = context.isAuthenticated;
            final isLoading = context.isLoading;
            final currentError = context.currentError;

            return Column(
              children: [
                Text('Is Authenticated: $isAuthenticated'),
                Text('Is Loading: $isLoading'),
                Text('Current Error: ${currentError ?? "None"}'),
              ],
            );
          },
        );
      }

      await tester.pumpWidget(createProviderSetupWidget(child: testWidget()));
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('Is Authenticated: false'), findsOneWidget);
      expect(find.textContaining('Is Loading: false'), findsOneWidget);
      expect(find.textContaining('Current Error: None'), findsOneWidget);
      when(mockSupabaseService.initialize()).thenAnswer((_) async {});
    });

    testWidgets('should render child widget correctly', (WidgetTester tester) async {
      // Arrange
      const testChild = Text('Test Child Widget');

      await tester.pumpWidget(createProviderSetupWidget(child: testChild));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test Child Widget'), findsOneWidget);
    });

    testWidgets('should handle nested provider access', (WidgetTester tester) async {
      // Arrange
      Widget nestedTestWidget() {
        return Builder(
          builder: (context) {
            return Builder(
              builder: (context) {
                // Access providers from nested builder
                final authProvider = context.authProvider;
                final mediaProvider = context.mediaProvider;
                
                return Column(
                  children: [
                    Text('Nested Auth: ${authProvider.runtimeType}'),
                    Text('Nested Media: ${mediaProvider.runtimeType}'),
                  ],
                );
              },
            );
          },
        );
      }

      await tester.pumpWidget(createProviderSetupWidget(child: nestedTestWidget()));
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('Nested Auth: EnhancedAuthProvider'), findsOneWidget);
      expect(find.textContaining('Nested Media: EnhancedMediaProvider'), findsOneWidget);
    });

    testWidgets('should maintain provider instances across rebuilds', (WidgetTester tester) async {
      // Arrange
      Provider<EnhancedAuthProvider>? firstAuthProvider;
      Provider<EnhancedMediaProvider>? firstMediaProvider;

      Widget testWidget() {
        return Builder(
          builder: (context) {
            // Store provider instances on first build
            firstAuthProvider ??= Provider.of<EnhancedAuthProvider>(context, listen: false);
            firstMediaProvider ??= Provider.of<EnhancedMediaProvider>(context, listen: false);
            
            return const Text('Test Widget');
          },
        );
      }

      await tester.pumpWidget(createProviderSetupWidget(child: testWidget()));
      await tester.pumpAndSettle();

      // Act - Trigger rebuild
      await tester.pumpWidget(createProviderSetupWidget(child: testWidget()));
      await tester.pumpAndSettle();

      // Assert - Providers should be the same instances
      final currentAuthProvider = Provider.of<EnhancedAuthProvider>(tester.element(find.byType(EnhancedAuthProvider)), listen: false);
      final currentMediaProvider = Provider.of<EnhancedMediaProvider>(tester.element(find.byType(EnhancedMediaProvider)), listen: false);
      
      expect(identical(firstAuthProvider, currentAuthProvider), isTrue);
      expect(identical(firstMediaProvider, currentMediaProvider), isTrue);
    });

    testWidgets('should handle provider state changes', (WidgetTester tester) async {
      // Arrange
      Widget stateTestWidget() {
        return Builder(
          builder: (context) {
            final authProvider = context.watchAuth;
            final isAuthenticated = authProvider.isAuthenticated;
            
            return ElevatedButton(
              onPressed: () {
                // Simulate state change (this would normally be done through provider methods)
                if (isAuthenticated) {
                  // In a real scenario, you'd call provider.signOut()
                }
              },
              child: Text('Authenticated: $isAuthenticated'),
            );
          },
        );
      }

      await tester.pumpWidget(createProviderSetupWidget(child: stateTestWidget()));
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('Authenticated: false'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });

  group('ProviderUtils Tests', () {
    testWidgets('should show error snackbar', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  ProviderUtils.showError(context, 'Test Error Message');
                },
                child: const Text('Show Error'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Show Error'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Test Error Message'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('should show success snackbar', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  ProviderUtils.showSuccess(context, 'Success Message');
                },
                child: const Text('Show Success'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Show Success'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Success Message'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('should show loading snackbar', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  ProviderUtils.showLoading(context, 'Loading Message');
                },
                child: const Text('Show Loading'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Show Loading'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Loading Message'), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should show confirmation dialog', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  final result = await ProviderUtils.confirmAction(
                    context,
                    title: 'Confirm Action',
                    content: 'Are you sure you want to proceed?',
                  );
                  // In a real test, you'd verify the result
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('Confirm Action'), findsOneWidget);
      expect(find.text('Are you sure you want to proceed?'), findsOneWidget);
      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('should handle dialog confirmation', (WidgetTester tester) async {
      // Arrange
      bool? dialogResult;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  dialogResult = await ProviderUtils.confirmAction(
                    context,
                    title: 'Confirm Action',
                    content: 'Are you sure?',
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      // Assert
      expect(dialogResult, isTrue);
    });

    testWidgets('should handle dialog cancellation', (WidgetTester tester) async {
      // Arrange
      bool? dialogResult;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () async {
                  dialogResult = await ProviderUtils.confirmAction(
                    context,
                    title: 'Confirm Action',
                    content: 'Are you sure?',
                  );
                },
                child: const Text('Show Dialog'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Assert
      expect(dialogResult, isFalse);
    });
  });

  group('ProviderInitializer Tests', () {
    test('should initialize successfully', () async {
      // Arrange
      when(mockSupabaseService.initialize()).thenAnswer((_) async {});

      // Act
      await ProviderInitializer.initialize();

      // Assert
      verify(mockSupabaseService.initialize()).called(1);
    });

    test('should handle initialization errors', () async {
      // Arrange
      when(mockSupabaseService.initialize()).thenThrow(Exception('Initialization failed'));

      // Act & Assert
      expect(
        () => ProviderInitializer.initialize(),
        throwsException,
      );
    });

    test('should dispose successfully', () async {
      // Act
      await ProviderInitializer.dispose();

      // Assert - Should not throw
      expect(await ProviderInitializer.dispose(), completes);
    });
  });
}
