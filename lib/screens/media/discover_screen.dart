import '../../providers/media_provider.dart';
import '../../widgets/media/content_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';



class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _categories = [
    'Trending',
    'Popular',
    'New',
    'Hot',
    'Top Rated',
    'Featured',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _loadTrendingContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTrendingContent() async {
    await context.read<MediaProvider>().loadMedia();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        title: const Text(
          'Discover',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          indicatorColor: Theme.of(context).primaryColor,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.normal,
          ),
          tabs: _categories.map((category) {
            return Tab(
              text: category,
            );
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _categories.map((category) {
          return _buildCategoryContent(category);
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryContent(String category) {
    return Consumer<MediaProvider>(
      builder: (context, provider, child) {
        // Filter content based on category
        final filteredContent = provider.mediaItems.where((item) {
          switch (category) {
            case 'Trending':
              return item.views > 10000;
            case 'Popular':
              return item.likes > 1000;
            case 'New':
              return DateTime.now().difference(item.createdAt).inDays <= 7;
            case 'Hot':
              return item.views > 5000 && item.likes > 500;
            case 'Top Rated':
              return item.likes > 2000;
            case 'Featured':
              return item.isPremium;
            default:
              return true;
          }
        }).toList();

        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (filteredContent.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.category_outlined,
                  color: Colors.white.withOpacity(0.5),
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'No content in $category',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: filteredContent.length,
          itemBuilder: (context, index) {
            return ContentCard(
              mediaItem: filteredContent[index],
              onTap: () {
                // Navigate to content detail
              },
            );
          },
        );
      },
    );
  }
}
