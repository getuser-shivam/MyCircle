import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../providers/notification_provider.dart';
import '../../providers/theme_provider.dart';
import '../../screens/dashboard/enterprise_dashboard.dart';
import '../../screens/social/meet_me_screen.dart';
import '../../screens/home/ultimate_home_screen.dart';
import '../../screens/media/upload_screen.dart';
import '../../screens/user/profile_screen.dart';
import '../../providers/auth_provider.dart';
import '../common/connectivity_banner.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
  bool _isConnected = true;
  
  final List<Widget> _screens = [
    const UltimateHomeScreen(),
    const MeetMeScreen(),
    const UploadScreen(),
    const EnterpriseDashboard(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      setState(() {
        _isConnected = results.any((result) => result != ConnectivityResult.none);
      });
    });
  }

  Future<void> _checkConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    setState(() {
      _isConnected = results.any((result) => result != ConnectivityResult.none);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (!_isConnected)
            const ConnectivityBanner(),
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final isDark = themeProvider.isDarkMode;
          return Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              return Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                      width: 0.5,
                    ),
                  ),
                ),
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: NavigationBar(
                      selectedIndex: _currentIndex,
                      onDestinationSelected: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                      backgroundColor: isDark 
                          ? const Color(0xFF0F172A).withOpacity(0.7) 
                          : Colors.white.withOpacity(0.7),
                      indicatorColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      surfaceTintColor: Colors.transparent,
                      height: 70,
                      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                      destinations: [
                        NavigationDestination(
                          icon: Icon(Icons.dashboard_customize_outlined, 
                            color: _currentIndex == 0 ? Theme.of(context).colorScheme.primary : null),
                          selectedIcon: Icon(Icons.dashboard_customize_rounded, 
                            color: Theme.of(context).colorScheme.primary),
                          label: 'Discover',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.explore_outlined,
                            color: _currentIndex == 1 ? Theme.of(context).colorScheme.primary : null),
                          selectedIcon: Icon(Icons.explore_rounded,
                            color: Theme.of(context).colorScheme.primary),
                          label: 'Connect',
                        ),
                        NavigationDestination(
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context).colorScheme.primary,
                                  Theme.of(context).colorScheme.secondary,
                                ],
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.add, color: Colors.white, size: 24),
                          ),
                          label: 'Publish',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.analytics_outlined,
                            color: _currentIndex == 3 ? Theme.of(context).colorScheme.primary : null),
                          selectedIcon: Icon(Icons.analytics_rounded,
                            color: Theme.of(context).colorScheme.primary),
                          label: 'Insights',
                        ),
                        NavigationDestination(
                          icon: _buildProfileIcon(notificationProvider, false),
                          selectedIcon: _buildProfileIcon(notificationProvider, true),
                          label: 'Account',
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildProfileIcon(NotificationProvider provider, bool isSelected) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(
          isSelected ? Icons.person_rounded : Icons.person_outline_rounded,
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
        ),
        if (provider.unreadCount > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiary,
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '${provider.unreadCount}',
                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
