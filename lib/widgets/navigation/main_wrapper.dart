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

class _MainWrapperState extends State<MainWrapper> with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isConnected = true;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  
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
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _checkConnectivity();
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      setState(() {
        _isConnected = results.any((result) => result != ConnectivityResult.none);
      });
    });
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
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
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              child: _screens[_currentIndex],
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
                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                      width: 0.5,
                    ),
                  ),
                ),
                child: ClipRRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: NavigationBar(
                      selectedIndex: _currentIndex,
                      onDestinationSelected: _onDestinationSelected,
                      backgroundColor: isDark 
                          ? const Color(0xFF0F172A).withValues(alpha: 0.8) 
                          : Colors.white.withValues(alpha: 0.8),
                      indicatorColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                      surfaceTintColor: Colors.transparent,
                      height: 70,
                      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                      destinations: [
                        NavigationDestination(
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              _currentIndex == 0 ? Icons.dashboard_customize_rounded : Icons.dashboard_customize_outlined,
                              key: ValueKey(_currentIndex == 0),
                              color: _currentIndex == 0 ? Theme.of(context).colorScheme.primary : null,
                            ),
                          ),
                          label: 'Discover',
                        ),
                        NavigationDestination(
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              _currentIndex == 1 ? Icons.explore_rounded : Icons.explore_outlined,
                              key: ValueKey(_currentIndex == 1),
                              color: _currentIndex == 1 ? Theme.of(context).colorScheme.primary : null,
                            ),
                          ),
                          label: 'Connect',
                        ),
                        NavigationDestination(
                          icon: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
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
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Icon(
                                _currentIndex == 2 ? Icons.add : Icons.add,
                                key: ValueKey(_currentIndex == 2),
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                          label: 'Publish',
                        ),
                        NavigationDestination(
                          icon: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              _currentIndex == 3 ? Icons.analytics_rounded : Icons.analytics_outlined,
                              key: ValueKey(_currentIndex == 3),
                              color: _currentIndex == 3 ? Theme.of(context).colorScheme.primary : null,
                            ),
                          ),
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
      floatingActionButton: _currentIndex == 2 ? null : AnimatedBuilder(
        animation: _fabAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _fabAnimation.value,
            child: FloatingActionButton(
              onPressed: () => _onDestinationSelected(2),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              elevation: 8,
              child: const Icon(Icons.add),
            ),
          );
        },
      ),
    );
  }

  void _onDestinationSelected(int index) {
    if (index == _currentIndex) return;
    
    setState(() {
      _currentIndex = index;
    });
    
    // Animate FAB when switching away from upload screen
    if (index != 2 && _currentIndex != 2) {
      _fabAnimationController.forward(from: 0.0);
    } else if (index == 2) {
      _fabAnimationController.reverse();
    }
  }

  Widget _buildProfileIcon(NotificationProvider provider, bool isSelected) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            isSelected ? Icons.person_rounded : Icons.person_outline_rounded,
            key: ValueKey(isSelected),
            color: isSelected ? Theme.of(context).colorScheme.primary : null,
          ),
        ),
        if (provider.unreadCount > 0)
          Positioned(
            right: -6,
            top: -6,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Theme.of(context).colorScheme.tertiary, Theme.of(context).colorScheme.primary],
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.tertiary.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                '${provider.unreadCount}',
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
