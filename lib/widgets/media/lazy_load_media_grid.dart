import '../../providers/media_provider.dart';
import '../../models/media_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class LazyLoadMediaGrid extends StatelessWidget {
  const LazyLoadMediaGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaProvider = Provider.of<MediaProvider>(context);

    return PagedGridView<int, MediaItem>(
      pagingController: mediaProvider.pagingController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      builderDelegate: PagedChildBuilderDelegate<MediaItem>(
        itemBuilder: (context, item, index) => _MediaCard(media: item, index: index),
        firstPageProgressIndicatorBuilder: (_) => const _LoadingShimmer(),
        newPageProgressIndicatorBuilder: (_) => const Center(child: CircularProgressIndicator()),
        noItemsFoundIndicatorBuilder: (_) => const _EmptyState(),
      ),
    );
  }
}

class _MediaCard extends StatelessWidget {
  final MediaItem media;
  final int index;

  const _MediaCard({required this.media, required this.index});

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: 'media_${media.id}_$index',
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
        child: InkWell(
          onTap: () => Navigator.pushNamed(
            context,
            '/media',
            arguments: {'media': media},
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      media.thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: Colors.grey[200]),
                    ),
                    if (media.type == MediaType.video)
                      const Center(
                        child: CircleAvatar(
                          backgroundColor: Colors.black45,
                          child: Icon(Icons.play_arrow, color: Colors.white),
                        ),
                      ),
                    if (media.isVerified)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Icon(Icons.verified, color: Colors.blue[400], size: 20),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      media.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${media.userName}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.movie_filter_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No content found', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
