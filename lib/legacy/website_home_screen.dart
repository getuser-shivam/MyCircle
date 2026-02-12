import '../providers/media_provider.dart';
import '../widgets/content_card.dart';
import '../widgets/navigation_bar.dart';
import '../widgets/search_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';



class WebsiteHomeScreen extends StatefulWidget {
  const WebsiteHomeScreen({super.key});

  @override
  State<WebsiteHomeScreen> createState() => _WebsiteHomeScreenState();
}

class _WebsiteHomeScreenState extends State<WebsiteHomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  Future<void> _loadContent() async {
    await context.read<MediaProvider>().loadTrendingMedia();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchSection(),
          _buildFilterSection(),
          Expanded(
            child: _buildContentGrid(),
          ),
        ],
      ),
      bottomNavigationBar: const CustomNavigationBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1A1A1A),
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.play_arrow_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'MyCircle',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
        ),
        IconButton(
          onPressed: () {},
          icon: const Icon(Icons.account_circle_outlined, color: Colors.white),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(
          bottom: BorderSide(color: Color(0xFF2A2A2A), width: 1),
        ),
      ),
      child: CustomSearchBar(
        controller: _searchController,
        onSearch: (query) {
          context.read<MediaProvider>().searchMedia(query: query);
        },
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(
          bottom: BorderSide(color: Color(0xFF2A2A2A), width: 1),
        ),
      ),
      child: Row(
        children: [
          _buildFilterChip('All', true),
          const SizedBox(width: 8),
          _buildFilterChip('Trending', false),
          const SizedBox(width: 8),
          _buildFilterChip('New', false),
          const SizedBox(width: 8),
          _buildFilterChip('Popular', false),
          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.tune, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Theme.of(context).primaryColor : const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildContentGrid() {
    return Consumer<MediaProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        if (provider.mediaItems.isEmpty) {
          return const Center(
            child: Text(
              'No content found',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          );
        }

        return GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.7,
          ),
          itemCount: provider.mediaItems.length,
          itemBuilder: (context, index) {
            return ContentCard(
              mediaItem: provider.mediaItems[index],
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
