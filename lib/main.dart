import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Local imports
import 'exports.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: SupabaseOptions.url,
    anonKey: SupabaseOptions.anonKey,
  );
  final prefs = await SharedPreferences.getInstance();
  final themeProvider = ThemeProvider(prefs);
  
  final authProvider = AuthProvider();
  await authProvider.initialize();

  final mediaProvider = MediaProvider();
  final notificationProvider = NotificationProvider();
  final socialProvider = SocialProvider();
  final commentProvider = CommentProvider();
  final socialGraphProvider = SocialGraphProvider();
  final subscriptionProvider = SubscriptionProvider();
  final antigravityProvider = AntigravityProvider();

  final combinedProvider = CombinedProvider(
    authProvider: authProvider,
    mediaProvider: mediaProvider,
    notificationProvider: notificationProvider,
    socialProvider: socialProvider,
    themeProvider: themeProvider,
    commentProvider: commentProvider,
    socialGraphProvider: socialGraphProvider,
    subscriptionProvider: subscriptionProvider,
    antigravityProvider: antigravityProvider,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: themeProvider),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider.value(value: mediaProvider),
        ChangeNotifierProvider.value(value: notificationProvider),
        ChangeNotifierProvider.value(value: socialProvider),
        ChangeNotifierProvider.value(value: commentProvider),
        ChangeNotifierProvider.value(value: socialGraphProvider),
        ChangeNotifierProvider.value(value: subscriptionProvider),
        ChangeNotifierProvider.value(value: antigravityProvider),
        ChangeNotifierProvider.value(value: combinedProvider),
      ],
      child: const MyCircleApp(),
    ),
  );
}

class MyCircleApp extends StatelessWidget {
  const MyCircleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: AppConstants.enableDebugBanner,
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          routes: {
            AppConstants.homeRoute: (context) => const MainWrapper(),
            AppConstants.subscriptionsRoute: (context) => const SubscriptionTierScreen(),
            AppConstants.searchRoute: (context) => const AdvancedSearchScreen(),
            AppConstants.uploadRoute: (context) => const UploadScreen(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == AppConstants.mediaDetailRoute) {
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (context) => MediaDetailScreen(media: args['media']),
              );
            }
            return null;
          },
          initialRoute: AppConstants.homeRoute,
        );
      },
    );
  }
}
