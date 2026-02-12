import '../providers/auth_provider.dart';
import '../providers/media_provider.dart';
import '../providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/advanced_search_screen.dart';
import 'screens/enhanced_home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/upload_screen.dart';
import 'widgets/connectivity_banner.dart';
import 'widgets/main_wrapper.dart';



void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => MediaProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'MyCircle',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.isDarkMode 
                ? ThemeMode.dark 
                : ThemeMode.light,
            home: const MainWrapper(),
            routes: {
              '/home': (context) => const EnhancedHomeScreen(),
              '/advanced-search': (context) => const AdvancedSearchScreen(),
              '/upload': (context) => const UploadScreen(),
              '/profile': (context) => const ProfileScreen(),
            },
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaleFactor: 1.0, // Prevent text scaling issues
                ),
                child: child!,
              );
            },
          );
        },
      ),
    );
  }
}
