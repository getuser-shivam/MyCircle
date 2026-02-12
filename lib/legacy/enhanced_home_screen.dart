import '../providers/media_provider.dart';
import '../widgets/optimized_media_grid.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';



class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _categories = [
    'For You',
    'Trending',
    'Popular',
    'New',
    'Following',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MyCircle',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notifications coming soon!')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.pushNamed(context, '/advanced-search');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 14,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: _categories.map((category) {
            return Tab(text: category);
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _categories.map((category) {
          return Consumer<MediaProvider>(
            builder: (context, mediaProvider, child) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mediaProvider.mediaItems.isEmpty) {
                  _loadCategoryMedia(category);
                }
              });

              return RefreshIndicator(
                onRefresh: () => _loadCategoryMedia(category, refresh: true),
                child: Column(
                  children: [
                    if (category == 'For You')
                      _buildTrendingBanner(),
                    Expanded(
                      child: OptimizedMediaGrid(),
                    ),
                  ],
                ),
              );
            },
          );
        }).toList(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/upload');
        },
        icon: const Icon(Icons.add),
        label: const Text('Upload'),
      ),
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
            Theme.of(context).primaryColor.withOpacity(0.8),
            Theme.of(context).primaryColor.withOpacity(0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🔥 Trending Now',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
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
          ElevatedButton(
            onPressed: () {
              _tabController.animateTo(1); // Switch to Trending tab
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            ),
            child: const Text('Explore'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadCategoryMedia(String category, {bool refresh = false}) async {
    try {
      final mediaProvider = context.read<MediaProvider>();
      
      switch (category) {
        case 'For You':
          if (refresh) {
            await mediaProvider.refreshMedia();
          } else {
            await mediaProvider.loadMedia();
          }
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
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading $category content: $e')),
        );
      }
    }
  }
}
