import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Local imports
import 'exports.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'application/providers/dependency_injection.dart';
import 'core/features/feature_flags.dart';
import 'core/monitoring/performance_monitor.dart';
import 'core/security/logger_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Load environment variables
    await dotenv.load(fileName: '.env');
    
    // Initialize feature flags
    await FeatureFlags.initialize();
    
    // Initialize dependency injection
    await DependencyInjection.initialize();
    
    // Validate dependencies
    final diValid = await DependencyInjection.instance.validateDependencies();
    if (!diValid) {
      LoggerService.error('Dependency validation failed', tag: 'MAIN');
      return;
    }
    
    // Initialize Supabase
    await Supabase.initialize(
      url: SupabaseOptions.url,
      anonKey: SupabaseOptions.anonKey,
    );
    
    final prefs = await SharedPreferences.getInstance();
    
    // Initialize providers using dependency injection
    final di = DependencyInjection.instance;
    final authProvider = AuthProvider();
    final themeProvider = ThemeProvider(prefs);
    final mediaProvider = MediaProvider();
    final notificationProvider = NotificationProvider();
    final socialProvider = SocialProvider();
    final commentProvider = CommentProvider();
    final subscriptionProvider = SubscriptionProvider();
    final antigravityProvider = AntigravityProvider();
    final desktopProvider = DesktopProvider();
    final streamProvider = StreamProviderClean(
      getLiveStreamsUseCase: di.getLiveStreamsUseCase,
      streamRepository: di.streamRepositoryInterface,
    );
    final streamChatProvider = StreamChatProvider();
    final streamCombinedProvider = StreamCombinedProvider();
    final aiChatProvider = AIChatProvider();
    final analyticsProvider = AnalyticsProvider(
      getAnalyticsUseCase: di.getAnalyticsUseCase,
      analyticsRepository: di.analyticsRepositoryInterface,
    );
    final recommendationProvider = RecommendationProvider();
    final discoveryProvider = DiscoveryProvider();

    // Initialize providers
    await authProvider.initialize();
    
    LoggerService.info('Application initialized successfully', tag: 'MAIN');
    
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
          ChangeNotifierProvider<StreamProviderClean>(create: (_) => streamProvider),
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
  } catch (e, stackTrace) {
    LoggerService.critical('Failed to initialize application', tag: 'MAIN', error: e, stackTrace: stackTrace);
    
    // Show error UI
    runApp(ErrorApp(error: e, stackTrace: stackTrace));
  }
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
