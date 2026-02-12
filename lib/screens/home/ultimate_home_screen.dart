import '../../providers/media_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/media/lazy_load_media_grid.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';



class UltimateHomeScreen extends StatefulWidget {
  const UltimateHomeScreen({super.key});

  @override
  State<UltimateHomeScreen> createState() => _UltimateHomeScreenState();
}

class _UltimateHomeScreenState extends State<UltimateHomeScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _showFab = true;

  final List<String> _categories = [
    'For You',
    'Trending',
    'Popular',
    'New',
    'Following',
    'Premium',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _scrollController.addListener(_onScroll);
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCategoryData(_categories[0]);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final shouldShowFab = _scrollController.offset < 100;
    if (_showFab != shouldShowFab) {
      setState(() {
        _showFab = shouldShowFab;
      });
    }
  }

  Future<void> _loadCategoryData(String category) async {
    try {
      final mediaProvider = context.read<MediaProvider>();
      
      switch (category) {
        case 'For You':
          await mediaProvider.loadMedia();
          break;
        case 'Trending':
          await mediaProvider.loadMedia(category: 'trending');
          break;
        case 'Popular':
          await mediaProvider.loadMedia(category: 'popular');
          break;
        case 'New':
          await mediaProvider.loadMedia(category: 'new');
          break;
        case 'Following':
          await mediaProvider.loadMedia(category: 'following');
          break;
        case 'Premium':
          await mediaProvider.loadMedia(category: 'premium');
          break;
      }
    } catch (e) {
      _showErrorSnackBar('Error loading $category content: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () => _loadCategoryData(_categories[_tabController.index]),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        controller: _scrollController,
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'MyCircle',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColor.withOpacity(0.8),
                        Theme.of(context).primaryColor.withOpacity(0.4),
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 20,
                        right: 20,
                        child: Consumer<NotificationProvider>(
                          builder: (context, notificationProvider, child) {
                            return Stack(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.notifications, color: Colors.white),
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/notifications');
                                  },
                                ),
                                if (notificationProvider.unreadCount > 0)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        notificationProvider.unreadCount > 99 
                                            ? '99+' 
                                            : '${notificationProvider.unreadCount}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: () {
                    Navigator.pushNamed(context, '/advanced-search');
                  },
                ),
                Consumer<NotificationProvider>(
                  builder: (context, notificationProvider, child) {
                    return IconButton(
                      icon: Icon(
                        notificationProvider.isOnline 
                            ? Icons.cloud_done 
                            : Icons.cloud_off,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        // Show connectivity status
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              notificationProvider.isOnline 
                                  ? 'Connected to internet' 
                                  : 'No internet connection',
                            ),
                            backgroundColor: notificationProvider.isOnline 
                                ? Colors.green 
                                : Colors.orange,
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.center,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                onTap: (index) {
                  _loadCategoryData(_categories[index]);
                },
                tabs: _categories.map((category) {
                  return Tab(
                    text: category,
                    icon: Icon(_getCategoryIcon(category)),
                  );
                }).toList(),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: _categories.map((category) {
            return RefreshIndicator(
              onRefresh: () => _loadCategoryData(category),
              child: Column(
                children: [
                  if (category == 'For You')
                    _buildTrendingBanner(),
                  if (category == 'Premium')
                    _buildPremiumBanner(),
                  Expanded(
                    child: LazyLoadMediaGrid(),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      floatingActionButton: AnimatedScale(
        scale: _showFab ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 200),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.pushNamed(context, '/upload');
          },
          icon: const Icon(Icons.add),
          label: const Text('Upload'),
          backgroundColor: Theme.of(context).primaryColor,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildTrendingBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.orange[400]!,
            Colors.red[400]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange[400]!.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_fire_department,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                '🔥 Trending Now',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Check out what\'s hot today',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  _tabController.animateTo(1); // Switch to Trending tab
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.orange[600],
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
                child: const Text('Explore'),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/advanced-search');
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                ),
                child: const Text('Search'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber[400]!,
            Colors.yellow[600]!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.diamond,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                '💎 Premium Content',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Exclusive content for premium members',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              // Navigate to premium upgrade
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Premium upgrade coming soon!')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.amber[800],
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
            child: const Text('Upgrade to Premium'),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'For You':
        return Icons.home;
      case 'Trending':
        return Icons.local_fire_department;
      case 'Popular':
        return Icons.favorite;
      case 'New':
        return Icons.new_releases;
      case 'Following':
        return Icons.people;
      case 'Premium':
        return Icons.diamond;
      default:
        return Icons.category;
    }
  }
}
