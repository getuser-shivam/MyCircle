import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../widgets/media/lazy_load_media_grid.dart';
import '../../providers/media_provider.dart';
import '../../widgets/common/content_guard.dart';
import '../../widgets/home/trending_banner.dart';
import '../../widgets/home/category_tabs.dart';
import '../../widgets/feedback/error_widget.dart';



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
      body: RefreshIndicator(
        onRefresh: () => _loadCategoryData(_categories[_tabController.index]),
        child: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Consumer<MediaProvider>(
                      builder: (context, mediaProvider, child) {
                        return TrendingBanner(
                          trendingItems: mediaProvider.trendingMedia,
                          onTap: (media) {
                            Navigator.pushNamed(
                              context,
                              '/media',
                              arguments: {'media': media},
                            );
                          },
                        );
                      },
                    ),
                    CategoryTabs(
                      categories: _categories,
                      selectedCategory: _categories[_tabController.index],
                      onCategorySelected: _onCategorySelected,
                      tabController: _tabController,
                    ),
                  ],
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: _categories.map((category) {
              return Consumer<MediaProvider>(
                builder: (context, mediaProvider, child) {
                  if (mediaProvider.error != null) {
                    return AppErrorWidget(
                      error: mediaProvider.error!,
                      onRetry: () => _loadCategoryData(category),
                    );
                  }

                  if (mediaProvider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  return const LazyLoadMediaGrid();
                },
              );
            }).toList(),
          ),
        ),
      ),
      floatingActionButton: _showFab
          ? FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, '/upload');
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  void _onCategorySelected(String category) {
    final index = _categories.indexOf(category);
    if (index != -1) {
      _tabController.animateTo(index);
      _loadCategoryData(category);
    }
  }
}
