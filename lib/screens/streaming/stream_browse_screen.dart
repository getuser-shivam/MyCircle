import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import '../../models/stream_model.dart';
import '../../providers/stream_provider.dart';
import '../../widgets/feedback/error_widget.dart';
import '../../widgets/loading/shimmer_widget.dart';
import '../../widgets/streaming/stream_card_widget.dart';

class StreamBrowseScreen extends StatefulWidget {
  const StreamBrowseScreen({super.key});

  @override
  State<StreamBrowseScreen> createState() => _StreamBrowseScreenState();
}

class _StreamBrowseScreenState extends State<StreamBrowseScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  final List<String> _categories = [
    'Live Now',
    'Scheduled',
    'Trending',
    'Following',
    'Nearby',
    'Categories',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _scrollController.addListener(_onScroll);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStreams(_categories[0]);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreStreams();
    }
  }

  Future<void> _loadStreams(String category) async {
    try {
      final streamProvider = context.read<StreamProvider>();
      
      switch (category) {
        case 'Live Now':
          await streamProvider.loadLiveStreams();
          break;
        case 'Scheduled':
          await streamProvider.loadScheduledStreams();
          break;
        case 'Trending':
          await streamProvider.loadTrendingStreams();
          break;
        case 'Following':
          await streamProvider.loadFollowingStreams();
          break;
        case 'Nearby':
          await streamProvider.loadNearbyStreams();
          break;
        case 'Categories':
          await streamProvider.loadStreamsByCategory();
          break;
      }
    } catch (e) {
      _showErrorSnackBar('Error loading streams: $e');
    }
  }

  Future<void> _loadMoreStreams() async {
    try {
      await context.read<StreamProvider>().loadMoreStreams();
    } catch (e) {
      // Silent fail for pagination
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
            onPressed: () => _loadStreams(_categories[_tabController.index]),
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
              backgroundColor: Theme.of(context).colorScheme.surface,
              surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'Live Streams',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
              ),
              bottom: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.center,
                labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: Theme.of(context).textTheme.labelMedium,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: _categories.map((category) => Tab(text: category)).toList(),
                onTap: (index) => _loadStreams(_categories[index]),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _showSearchDialog,
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: _showFilterDialog,
                ),
              ],
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: _categories.map((category) {
            return Consumer<StreamProvider>(
                  builder: (context, streamProvider, child) {
                    final pagingController = category == _categories[_tabController.index]
                        ? streamProvider.liveStreamsPagingController
                        : streamProvider.scheduledStreamsPagingController;

                    if (streamProvider.error != null && pagingController.itemList == null) {
                      return AppErrorWidget(
                        error: streamProvider.error!,
                        onRetry: () => _loadStreams(category),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () => _loadStreams(category),
                      child: PagedGridView<int, LiveStream>(
                        pagingController: pagingController,
                        builderDelegate: PagedChildBuilderDelegate<LiveStream>(
                          itemBuilder: (context, stream, index) => StreamCard(
                            stream: stream,
                            onTap: () => _onStreamTap(stream),
                          ),
                          firstPageErrorIndicatorBuilder: (context) => AppErrorWidget(
                            error: pagingController.error.toString(),
                            onRetry: () => pagingController.refresh(),
                          ),
                          newPageErrorIndicatorBuilder: (context) => AppErrorWidget(
                            error: pagingController.error.toString(),
                            onRetry: () => pagingController.retryLastFailedRequest(),
                          ),
                          firstPageProgressIndicatorBuilder: (context) => _LoadingGrid(),
                          newPageProgressIndicatorBuilder: (context) => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          noItemsFoundIndicatorBuilder: (context) => EmptyStateWidget(
                            title: 'No streams found',
                            subtitle: 'Check back later for live content',
                            icon: Icons.live_tv_outlined,
                            action: ElevatedButton.icon(
                              onPressed: () => _loadStreams(category),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Refresh'),
                            ),
                          ),
                        ),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        padding: const EdgeInsets.all(16),
                      ),
                    );
                  },
                );
          }).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startStreaming,
        icon: const Icon(Icons.broadcast_on_personal),
        label: const Text('Go Live'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  List<LiveStream> _getStreamsForCategory(StreamProvider provider, String category) {
    switch (category) {
      case 'Live Now':
        return provider.liveStreams;
      case 'Scheduled':
        return provider.scheduledStreams;
      case 'Trending':
        return provider.trendingStreams;
      case 'Following':
        return provider.followingStreams;
      case 'Nearby':
        return provider.nearbyStreams;
      case 'Categories':
        return provider.streamsByCategory.values.expand((e) => e).toList();
      default:
        return provider.liveStreams;
    }
  }

  void _onStreamTap(LiveStream stream) {
    Navigator.pushNamed(
      context,
      '/streaming/player',
      arguments: {'stream': stream},
    );
  }

  void _startStreaming() {
    Navigator.pushNamed(context, '/streaming/setup');
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Streams'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Enter stream title or tags...',
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
          onSubmitted: (value) {
            Navigator.pop(context);
            if (value.isNotEmpty) {
              _searchStreams(value);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (_searchController.text.isNotEmpty) {
                _searchStreams(_searchController.text);
              }
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Streams'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Quality'),
              trailing: DropdownButton<String>(
                items: ['All', '720p', '1080p', '4K']
                    .map((quality) => DropdownMenuItem(value: quality, child: Text(quality)))
                    .toList(),
                onChanged: (value) {},
              ),
            ),
            ListTile(
              title: const Text('Category'),
              trailing: DropdownButton<String>(
                items: ['All', 'Gaming', 'Music', 'Art', 'Education', 'Sports']
                    .map((category) => DropdownMenuItem(value: category, child: Text(category)))
                    .toList(),
                onChanged: (value) {},
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Future<void> _searchStreams(String query) async {
    try {
      await context.read<StreamProvider>().searchStreams(query);
    } catch (e) {
      _showErrorSnackBar('Search failed: $e');
    }
  }
}

class _StreamGrid extends StatelessWidget {
  final List<LiveStream> streams;
  final bool isLoading;
  final VoidCallback onStreamTap;
  final VoidCallback onRefresh;

  const _StreamGrid({
    required this.streams,
    required this.isLoading,
    required this.onStreamTap,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index < streams.length) {
                  return _StreamCard(
                    stream: streams[index],
                    onTap: () => onStreamTap(streams[index]),
                  );
                }
                return null;
              },
              childCount: streams.length,
            ),
          ),
        ),
        if (isLoading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
      ],
    );
  }
}

class _StreamCard extends StatelessWidget {
  final LiveStream stream;
  final VoidCallback onTap;

  const _StreamCard({
    required this.stream,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  CachedNetworkImage(
                    imageUrl: stream.thumbnailUrl,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.error),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: stream.isLive ? Colors.red : Colors.orange,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (stream.isLive)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          const SizedBox(width: 4),
                          Text(
                            stream.isLive ? 'LIVE' : 'SCHEDULED',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.visibility, size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            _formatViewerCount(stream.viewerCount),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stream.title,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 10,
                          backgroundImage: CachedNetworkImageProvider(stream.streamerAvatar),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            stream.streamerName,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.category,
                          size: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          stream.category,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatViewerCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: 6,
        itemBuilder: (context, index) => const ShimmerWidget(
          height: double.infinity,
          width: double.infinity,
          borderRadius: 12,
        ),
      ),
    );
  }
}
