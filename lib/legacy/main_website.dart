import '../providers/auth_provider.dart';
import '../providers/media_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/website_main_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';



void main() {
  runApp(const MyCircleWebsiteApp());
}

class MyCircleWebsiteApp extends StatelessWidget {
  const MyCircleWebsiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MediaProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'MyCircle - Content Platform',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.purple,
              useMaterial3: true,
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF0F0F0F),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                backgroundColor: Color(0xFF1A1A1A),
                selectedItemColor: Colors.purple,
                unselectedItemColor: Colors.white70,
              ),
            ),
            home: const WebsiteMainWrapper(),
            routes: {
              '/home': (context) => const WebsiteMainWrapper(),
              '/upload': (context) => const WebsiteMainWrapper(),
              '/profile': (context) => const WebsiteMainWrapper(),
              '/discover': (context) => const WebsiteMainWrapper(),
              '/chat': (context) => const WebsiteMainWrapper(),
            },
          );
        },
      ),
    );
  }
}
