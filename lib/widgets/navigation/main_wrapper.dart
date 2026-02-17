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
import '../common/animations.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isConnected = true;
  late AnimationController _fabAnimationController;
  late AnimationController _navAnimationController;
  late Animation<double> _fabAnimation;
  late Animation<Offset> _navSlideAnimation;
  
  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.home_rounded,
      activeIcon: Icons.home_rounded,
      label: 'Home',
      screen: const UltimateHomeScreen(),
    ),
    NavigationItem(
      icon: Icons.explore_rounded,
      activeIcon: Icons.explore_rounded,
      label: 'Discover',
      screen: const MeetMeScreen(),
    ),
    NavigationItem(
      icon: Icons.add_circle_outline_rounded,
      activeIcon: Icons.add_circle_rounded,
      label: 'Create',
      screen: const UploadScreen(),
      isCenter: true,
    ),
    NavigationItem(
      icon: Icons.analytics_rounded,
      activeIcon: Icons.analytics_rounded,
      label: 'Analytics',
      screen: const EnterpriseDashboard(),
    ),
    NavigationItem(
      icon: Icons.person_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
      screen: const ProfileScreen(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: AnimationConstants.medium,
      vsync: this,
    );
    _navAnimationController = AnimationController(
      duration: AnimationConstants.medium,
      vsync: this,
    );
    
    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));

    _navSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _navAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _navAnimationController.forward();
    _fabAnimationController.forward();
    
    _checkConnectivity();
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    _navAnimationController.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    setState(() {
      _isConnected = result != ConnectivityResult.none;
    });

    Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        _isConnected = result != ConnectivityResult.none;
      });
    });
  }

  void _onItemTapped(int index) {
    if (index == 2) { // Create button
      _showCreateMenu();
      return;
    }
    
    setState(() {
      _currentIndex = index;
    });
    
    // Add haptic feedback
    HapticFeedback.lightImpact();
  }

  void _showCreateMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateMenuBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: AnimationConstants.medium,
        transitionBuilder: (child, animation) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        },
        child: _navigationItems[_currentIndex].screen,
      ),
      
      // Connectivity banner
      if (!_isConnected)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AnimatedSlideIn.fromTop(
            child: ConnectivityBanner(
              isConnected: _isConnected,
              onRetry: _checkConnectivity,
            ),
          ),
        ),

      // Modern bottom navigation
      bottomNavigationBar: SlideTransition(
        position: _navSlideAnimation,
        child: _buildModernBottomNav(),
      ),
    );
  }

  Widget _buildModernBottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _navigationItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isActive = _currentIndex == index;
                
                if (item.isCenter) {
                  return _buildCenterButton();
                }
                
                return _buildNavigationItem(item, isActive, index);
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationItem(NavigationItem item, bool isActive, int index) {
    return Expanded(
      child: BounceAnimation(
        onTap: () => _onItemTapped(index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: AnimationConstants.fast,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isActive 
                      ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  isActive ? item.activeIcon : item.icon,
                  color: isActive 
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  size: 24,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedFadeIn(
                duration: AnimationConstants.fast,
                child: Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive 
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterButton() {
    return BounceAnimation(
      onTap: () => _onItemTapped(2),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Widget screen;
  final bool isCenter;

  const NavigationItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.screen,
    this.isCenter = false,
  });
}

class CreateMenuBottomSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Create Content',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Create options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _buildCreateOption(
                  context,
                  icon: Icons.video_call_rounded,
                  title: 'Go Live',
                  subtitle: 'Start a live stream',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to live streaming setup
                  },
                ),
                _buildCreateOption(
                  context,
                  icon: Icons.upload_file_rounded,
                  title: 'Upload Video',
                  subtitle: 'Share your content',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to upload screen
                  },
                ),
                _buildCreateOption(
                  context,
                  icon: Icons.photo_camera_rounded,
                  title: 'Create Story',
                  subtitle: 'Share moments',
                  onTap: () {
                    Navigator.pop(context);
                    // Navigate to story creation
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildCreateOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return BounceAnimation(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}
    
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
