import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/auth_provider.dart';
import 'providers/media_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/social_provider.dart';
import 'providers/comment_provider.dart';
import 'providers/social_graph_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/antigravity_provider.dart';
import 'screens/premium/subscription_tier_screen.dart';
import 'screens/media/media_detail_screen.dart';
import 'screens/search/advanced_search_screen.dart';
import 'widgets/navigation/main_wrapper.dart';
import 'models/media_item.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: SupabaseOptions.url,
    anonKey: SupabaseOptions.anonKey,
  );
  final prefs = await SharedPreferences.getInstance();
  
  final authProvider = AuthProvider();
  await authProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(prefs)),
        ChangeNotifierProvider.value(value: authProvider),
        ChangeNotifierProvider(create: (_) => MediaProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => SocialProvider()),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider()),
        ChangeNotifierProvider(create: (_) => CommentProvider()),
        ChangeNotifierProvider(create: (_) => SocialGraphProvider()),
        ChangeNotifierProvider(create: (_) => AntigravityProvider()),
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
          title: 'MyCircle',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          routes: {
            '/': (context) => const MainWrapper(),
            '/subscriptions': (context) => const SubscriptionTierScreen(),
            '/advanced-search': (context) => const AdvancedSearchScreen(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/media') {
              final args = settings.arguments as Map<String, dynamic>;
              return MaterialPageRoute(
                builder: (context) => MediaDetailScreen(media: args['media']),
              );
            }
            return null;
          },
          initialRoute: '/',
        );
      },
    );
  }
}
