import '../providers/notification_provider.dart';
import '../providers/superior_media_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/superior_main_wrapper.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';



void main() {
  runApp(const SuperiorMyCircleApp());
}

class SuperiorMyCircleApp extends StatelessWidget {
  const SuperiorMyCircleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SuperiorMediaProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: Consumer2<ThemeProvider, NotificationProvider>(
        builder: (context, themeProvider, notificationProvider, child) {
          return MaterialApp(
            title: 'MyCircle - Superior to All Apps',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.lightTheme,
            darkTheme: themeProvider.darkTheme,
            themeMode: themeProvider.isDarkMode 
                ? ThemeMode.dark 
                : ThemeMode.light,
            home: const SuperiorMainWrapper(),
            routes: {
              '/home': (context) => const SuperiorMainWrapper(),
              '/superior-search': (context) => const AdvancedSearchScreen(),
              '/upload': (context) => const UploadScreen(),
              '/profile': (context) => const ProfileScreen(),
            },
            builder: (context, child) {
              return MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaleFactor: 1.0,
                ),
                child: Stack(
                  children: [
                    child!,
                    // Performance overlay for development
                    if (!const bool.fromEnvironment('dart.vm.product'))
                      Positioned(
                        top: 50,
                        left: 20,
                        child: Consumer<SuperiorMediaProvider>(
                          builder: (context, provider, child) {
                            return Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: provider.isQuantumMode 
                                      ? Colors.green 
                                      : Colors.orange,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.speed,
                                        color: provider.isQuantumMode 
                                            ? Colors.green 
                                            : Colors.orange,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Quantum Mode',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Performance: ${provider.performanceScore.toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                  if (provider.isNeuralProcessing) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          'AI Processing...',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
