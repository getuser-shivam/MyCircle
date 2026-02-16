import '../../providers/media_provider.dart';
import '../../widgets/media/media_card.dart';
import '../../widgets/media/media_player.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';



class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<String> _searchHistory = [];
  List<String> _trendingSearches = [
    'trending',
    'viral',
    'hot',
    'new',
    'popular',
    'best',
    'top',
    'amazing',
  ];

  @override
  void initState() {
    super.initState();
    _searchFocusNode.requestFocus();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(),
            Expanded(
              child: Consumer<MediaProvider>(
                builder: (context, mediaProvider, child) {
                  if (mediaProvider.searchQuery.isEmpty) {
                    return _buildSearchSuggestions();
                  } else {
                    return _buildSearchResults(mediaProvider);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              // Clear search and go back
              _searchController.clear();
              context.read<MediaProvider>().searchMedia(query: '');
            },
            icon: const Icon(Icons.arrow_back),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  hintText: 'Search content, users, tags...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            context.read<MediaProvider>().searchMedia(query: '');
                          },
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (value) {
                  _performSearch(value);
                },
                onChanged: (value) {
                  setState(() {});
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              // Filter options
              _showFilterDialog();
            },
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSuggestions() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_searchHistory.isNotEmpty) ...[
            _buildSectionHeader('Recent Searches'),
            const SizedBox(height: 12),
            _buildSearchHistory(),
            const SizedBox(height: 24),
          ],
          _buildSectionHeader('Trending Searches'),
          const SizedBox(height: 12),
          _buildTrendingSearches(),
          const SizedBox(height: 24),
          _buildSectionHeader('Browse Categories'),
          const SizedBox(height: 12),
          _buildCategories(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildSearchHistory() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _searchHistory.map((term) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history,
                size: 16,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              Text(
                term,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _searchHistory.remove(term);
                  });
                },
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrendingSearches() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _trendingSearches.map((term) {
        return GestureDetector(
          onTap: () {
            _searchController.text = term;
            _performSearch(term);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.trending_up,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  term,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategories() {
    return Consumer<MediaProvider>(
      builder: (context, mediaProvider, child) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemCount: mediaProvider.categories.length,
          itemBuilder: (context, index) {
            final category = mediaProvider.categories[index];
            return GestureDetector(
              onTap: () {
                _searchController.text = category;
                _performSearch(category);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Center(
                  child: Text(
                    category,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchResults(MediaProvider mediaProvider) {
    if (mediaProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (mediaProvider.searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found for "${mediaProvider.searchQuery}"',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try different keywords or browse categories',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.8,
      ),
      itemCount: mediaProvider.searchResults.length,
      itemBuilder: (context, index) {
        final media = mediaProvider.searchResults[index];
        return MediaCard(
          media: media,
          onTap: () => _openMediaPlayer(context, media),
        );
      },
    );
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) return;

    // Add to search history
    if (!_searchHistory.contains(query)) {
      setState(() {
        _searchHistory.insert(0, query);
        if (_searchHistory.length > 10) {
          _searchHistory.removeLast();
        }
      });
    }

    context.read<MediaProvider>().searchMedia(query.trim());
  }

  void _openMediaPlayer(BuildContext context, dynamic media) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MediaPlayer(media: media),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Filters'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Content Type'),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: () {
                // Show content type options
              },
            ),
            ListTile(
              title: const Text('Duration'),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: () {
                // Show duration options
              },
            ),
            ListTile(
              title: const Text('Upload Date'),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: () {
                // Show upload date options
              },
            ),
            ListTile(
              title: const Text('Sort By'),
              trailing: const Icon(Icons.arrow_drop_down),
              onTap: () {
                // Show sort options
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Apply filters
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }
}
