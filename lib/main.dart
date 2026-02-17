import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Local imports
import 'exports.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables
  await dotenv.load(fileName: '.env');
  
  await Supabase.initialize(
    url: SupabaseOptions.url,
    anonKey: SupabaseOptions.anonKey,
  );
  final prefs = await SharedPreferences.getInstance();
  
  // Initialize providers
  final authProvider = AuthProvider();
  final themeProvider = ThemeProvider(prefs);
  final mediaProvider = MediaProvider();
  final notificationProvider = NotificationProvider();
  final socialProvider = SocialProvider();
  final commentProvider = CommentProvider();
  final subscriptionProvider = SubscriptionProvider();
  final antigravityProvider = AntigravityProvider();
  final desktopProvider = DesktopProvider();
  final streamProvider = StreamProvider();
  final streamChatProvider = StreamChatProvider();
  final streamCombinedProvider = StreamCombinedProvider();
  final aiChatProvider = AIChatProvider();
  final analyticsProvider = AnalyticsProvider();
  final recommendationProvider = RecommendationProvider();
  final discoveryProvider = DiscoveryProvider();

  // Initialize providers
  await authProvider.initialize();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => authProvider),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => themeProvider),
        ChangeNotifierProvider<MediaProvider>(create: (_) => mediaProvider),
        ChangeNotifierProvider<NotificationProvider>(create: (_) => notificationProvider),
        ChangeNotifierProvider<SocialProvider>(create: (_) => socialProvider),
        ChangeNotifierProvider<CommentProvider>(create: (_) => commentProvider),
        ChangeNotifierProvider<SubscriptionProvider>(create: (_) => subscriptionProvider),
        ChangeNotifierProvider<AntigravityProvider>(create: (_) => antigravityProvider),
        ChangeNotifierProvider<DesktopProvider>(create: (_) => desktopProvider),
        ChangeNotifierProvider<StreamProvider>(create: (_) => streamProvider),
        ChangeNotifierProvider<StreamChatProvider>(create: (_) => streamChatProvider),
        ChangeNotifierProvider<StreamCombinedProvider>(create: (_) => streamCombinedProvider),
        ChangeNotifierProvider<AIChatProvider>(create: (_) => aiChatProvider),
        ChangeNotifierProvider<AnalyticsProvider>(create: (_) => analyticsProvider),
        ChangeNotifierProvider<RecommendationProvider>(create: (_) => recommendationProvider),
        ChangeNotifierProvider<DiscoveryProvider>(create: (_) => discoveryProvider),
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
