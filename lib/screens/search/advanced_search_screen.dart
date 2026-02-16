import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import '../../providers/media_provider.dart';
import '../../models/media_item.dart';
import '../../widgets/enterprise/premium_components.dart';

class AdvancedSearchScreen extends StatefulWidget {
  const AdvancedSearchScreen({super.key});

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enterprise Search'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchHeader(),
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: EnterpriseGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.search_rounded, color: Colors.grey),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search for high-quality media...',
                  border: InputBorder.none,
                ),
                onSubmitted: (value) => _performSearch(),
              ),
            ),
            IconButton(
              onPressed: _performSearch,
              icon: const Icon(Icons.arrow_forward_ios_rounded, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    final mediaProvider = Provider.of<MediaProvider>(context);

    if (mediaProvider.searchQuery.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_rounded, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Enter a query to search', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return PagedListView<int, MediaItem>(
      pagingController: mediaProvider.pagingController,
      padding: const EdgeInsets.all(20),
      builderDelegate: PagedChildBuilderDelegate<MediaItem>(
        itemBuilder: (context, item, index) => _SearchResultTile(media: item),
        noItemsFoundIndicatorBuilder: (_) => const Center(
          child: Text('No results found for your search.'),
        ),
      ),
    );
  }

  void _performSearch() {
    context.read<MediaProvider>().searchMedia(_searchController.text);
  }
}

class _SearchResultTile extends StatelessWidget {
  final MediaItem media;
  const _SearchResultTile({required this.media});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.bottom(16),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            media.thumbnailUrl,
            width: 60,
            height: 60,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], width: 60, height: 60),
          ),
        ),
        title: Text(media.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('@${media.userName} • ${media.category}'),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: () => Navigator.pushNamed(
          context,
          '/media',
          arguments: {'media': media},
        ),
      ),
    );
  }
}
