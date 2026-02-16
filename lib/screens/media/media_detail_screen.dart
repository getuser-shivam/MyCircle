import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../models/media_item.dart';
import '../../providers/comment_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/enterprise/premium_components.dart';

class MediaDetailScreen extends StatefulWidget {
  final MediaItem media;

  const MediaDetailScreen({super.key, required this.media});

  @override
  State<MediaDetailScreen> createState() => _MediaDetailScreenState();
}

class _MediaDetailScreenState extends State<MediaDetailScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.media.type == MediaType.video && widget.media.videoUrl != null) {
      _initVideo();
    }
    // Fetch comments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommentProvider>().fetchComments(widget.media.id);
    });
  }

  void _initVideo() async {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.media.videoUrl!));
    await _videoController!.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      autoPlay: true,
      looping: true,
      aspectRatio: _videoController!.value.aspectRatio,
    );
    setState(() {});
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMediaInfo(),
                  const SizedBox(height: 24),
                  _buildInteractions(),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildCommentSection(),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildCommentInput(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: widget.media.type == MediaType.video && _chewieController != null
            ? Chewie(controller: _chewieController!)
            : Image.network(widget.media.url, fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildMediaInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.media.title,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(widget.media.description, style: TextStyle(color: Colors.grey[600], fontSize: 16)),
        const SizedBox(height: 24),
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundImage: NetworkImage(widget.media.userAvatar),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(widget.media.userName, 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (widget.media.isVerified)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(Icons.verified, color: Colors.blue, size: 16),
                        ),
                    ],
                  ),
                  const Text('Content Creator', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
            EnterpriseButton(
              text: 'Follow',
              onPressed: () {},
              isSecondary: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInteractions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _interactionItem(Icons.favorite_border_rounded, '${widget.media.likes}', 'Likes'),
        _interactionItem(Icons.chat_bubble_outline_rounded, '${widget.media.commentsCount}', 'Comments'),
        _interactionItem(Icons.share_outlined, 'Share', 'Export'),
        _interactionItem(Icons.bookmark_border_rounded, 'Save', 'Collection'),
      ],
    );
  }

  Widget _interactionItem(IconData icon, String value, String label) {
    return Column(
      children: [
        IconButton(
          onPressed: () {},
          icon: Icon(icon, size: 28),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildCommentSection() {
    return Consumer<CommentProvider>(
      builder: (context, provider, child) {
        final comments = provider.comments[widget.media.id] ?? [];
        if (provider.isLoading) return const Center(child: CircularProgressIndicator());

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Discussions (${comments.length})', 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...comments.map((comment) => _buildCommentItem(comment)).toList(),
          ],
        );
      },
    );
  }

  Widget _buildCommentItem(comment) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage(comment.userAvatar ?? 'https://i.pravatar.cc/100'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(comment.userName ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(comment.content),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text('2h ago', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    const SizedBox(width: 16),
                    const Text('Reply', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.favorite_border, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentInput() {
    return EnterpriseGlassCard(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 12, 
        bottom: MediaQuery.of(context).viewInsets.bottom + 20
      ),
      borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _commentController,
              decoration: const InputDecoration(
                hintText: 'Add a professional comment...',
                border: InputBorder.none,
              ),
            ),
          ),
          EnterpriseButton(
            text: 'Send',
            onPressed: () async {
              if (_commentController.text.isNotEmpty) {
                await context.read<CommentProvider>().postComment(
                  mediaId: widget.media.id,
                  content: _commentController.text,
                );
                _commentController.clear();
              }
            },
          ),
        ],
      ),
    );
  }
}
