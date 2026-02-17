import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../../models/stream_model.dart';
import '../../models/stream_chat_model.dart';
import '../../models/stream_viewer_model.dart';
import '../../providers/stream_provider.dart';
import '../../providers/stream_chat_provider.dart';
import '../../widgets/feedback/error_widget.dart';

class StreamPlayerScreen extends StatefulWidget {
  final LiveStream stream;

  const StreamPlayerScreen({
    super.key,
    required this.stream,
  });

  @override
  State<StreamPlayerScreen> createState() => _StreamPlayerScreenState();
}

class _StreamPlayerScreenState extends State<StreamPlayerScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late VideoPlayerController _videoController;
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  bool _showControls = true;
  bool _isFullscreen = false;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeVideoPlayer();
    _joinStream();
    
    // Auto-hide controls after 3 seconds
    _resetHideControlsTimer();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _videoController.dispose();
    _chatController.dispose();
    _chatScrollController.dispose();
    _hideControlsTimer?.cancel();
    _leaveStream();
    super.dispose();
  }

  void _initializeVideoPlayer() {
    _videoController = VideoPlayerController.network(widget.stream.streamUrl);
    _videoController.initialize().then((_) {
      setState(() {});
      _videoController.play();
    });
  }

  void _resetHideControlsTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _resetHideControlsTimer();
    }
  }

  Future<void> _joinStream() async {
    try {
      await context.read<StreamProvider>().joinStream(widget.stream.id);
      await context.read<StreamChatProvider>().connectToStreamChat(widget.stream.id);
    } catch (e) {
      _showErrorSnackBar('Failed to join stream: $e');
    }
  }

  Future<void> _leaveStream() async {
    try {
      await context.read<StreamProvider>().leaveStream();
      context.read<StreamChatProvider>().disconnect();
    } catch (e) {
      // Silent fail on leave
    }
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: OrientationBuilder(
        builder: (context, orientation) {
          if (orientation == Orientation.landscape) {
            return _buildLandscapeLayout();
          } else {
            return _buildPortraitLayout();
          }
        },
      ),
    );
  }

  Widget _buildPortraitLayout() {
    return Column(
      children: [
        // Video Player Section
        Expanded(
          flex: 3,
          child: _buildVideoPlayer(),
        ),
        // Stream Info and Tabs
        Expanded(
          flex: 2,
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                _buildStreamInfo(),
                _buildTabBar(),
                Expanded(
                  child: _buildTabBarView(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeLayout() {
    return Row(
      children: [
        // Video Player Section
        Expanded(
          flex: 3,
          child: _buildVideoPlayer(),
        ),
        // Chat and Viewers Sidebar
        Expanded(
          flex: 1,
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                _buildTabBar(),
                Expanded(
                  child: _buildTabBarView(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPlayer() {
    return GestureDetector(
      onTap: _toggleControls,
      child: Container(
        color: Colors.black,
        child: Stack(
          children: [
            Center(
              child: _videoController.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _videoController.value.aspectRatio,
                      child: VideoPlayer(_videoController),
                    )
                  : Container(
                      color: Colors.black,
                      child: const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
            ),
            if (_showControls) _buildVideoControls(),
            _buildStreamOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoControls() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withOpacity(0.7),
              Colors.transparent,
              Colors.transparent,
              Colors.black.withOpacity(0.7),
            ],
          ),
        ),
        child: Column(
          children: [
            // Top Controls
            SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                      color: Colors.white,
                    ),
                    onPressed: _toggleFullscreen,
                  ),
                ],
              ),
            ),
            const Spacer(),
            // Bottom Controls
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    _videoController.value.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: _togglePlayPause,
                ),
                Expanded(
                  child: VideoProgressIndicator(
                    _videoController,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Colors.red,
                      backgroundColor: Colors.white24,
                      bufferedColor: Colors.white54,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up, color: Colors.white),
                  onPressed: _toggleMute,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamOverlay() {
    return Positioned(
      top: 80,
      left: 16,
      right: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live Badge and Viewer Count
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 8,
                      height: 8,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Consumer<StreamProvider>(
                  builder: (context, provider, child) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.visibility, size: 14, color: Colors.white),
                        const SizedBox(width: 4),
                        Text(
                          _formatViewerCount(provider.currentStream?.viewerCount ?? widget.stream.viewerCount),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Stream Title
          Text(
            widget.stream.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  blurRadius: 4,
                  color: Colors.black,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Streamer Info
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: CachedNetworkImageProvider(widget.stream.streamerAvatar),
              ),
              const SizedBox(width: 8),
              Text(
                widget.stream.streamerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  shadows: [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreamInfo() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: CachedNetworkImageProvider(widget.stream.streamerAvatar),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.stream.streamerName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      widget.stream.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.favorite_border),
                onPressed: _toggleLike,
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _shareStream,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Chip(
                avatar: const Icon(Icons.category, size: 16),
                label: Text(widget.stream.category),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              ),
              const SizedBox(width: 8),
              if (widget.stream.tags.isNotEmpty)
                ...widget.stream.tags.take(2).map((tag) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Chip(
                    label: Text('#$tag'),
                    backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                  ),
                )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(icon: Icon(Icons.chat), text: 'Chat'),
        Tab(icon: Icon(Icons.people), text: 'Viewers'),
      ],
    );
  }

  Widget _buildTabBarView() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildChatTab(),
        _buildViewersTab(),
      ],
    );
  }

  Widget _buildChatTab() {
    return Column(
      children: [
        Expanded(
          child: Consumer<StreamChatProvider>(
            builder: (context, chatProvider, child) {
              if (chatProvider.messages.isEmpty) {
                return const Center(
                  child: Text('No messages yet. Be the first to say hi!'),
                );
              }

              return ListView.builder(
                controller: _chatScrollController,
                padding: const EdgeInsets.all(16),
                itemCount: chatProvider.messages.length,
                itemBuilder: (context, index) {
                  final message = chatProvider.messages[index];
                  return _ChatMessage(message: message);
                },
              );
            },
          ),
        ),
        _buildChatInput(),
      ],
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: () => _sendMessage(_chatController.text),
            icon: const Icon(Icons.send),
          ),
        ],
      ),
    );
  }

  Widget _buildViewersTab() {
    return Consumer<StreamProvider>(
      builder: (context, streamProvider, child) {
        final viewers = streamProvider.currentViewers;
        
        if (viewers.isEmpty) {
          return const Center(
            child: Text('No viewers yet'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: viewers.length,
          itemBuilder: (context, index) {
            final viewer = viewers[index];
            return _ViewerTile(viewer: viewer);
          },
        );
      },
    );
  }

  void _togglePlayPause() {
    setState(() {
      if (_videoController.value.isPlaying) {
        _videoController.pause();
      } else {
        _videoController.play();
      }
    });
  }

  void _toggleMute() {
    setState(() {
      _videoController.setVolume(_videoController.value.volume == 0 ? 1.0 : 0.0);
    });
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
  }

  void _toggleLike() {
    // Implement like functionality
  }

  void _shareStream() {
    // Implement share functionality
  }

  void _sendMessage(String message) {
    if (message.trim().isEmpty) return;
    
    context.read<StreamChatProvider>().sendMessage(message);
    _chatController.clear();
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

class _ChatMessage extends StatelessWidget {
  final StreamChatMessage message;

  const _ChatMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundImage: CachedNetworkImageProvider(message.userAvatar),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      message.userName,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: message.isFromStaff 
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                    ),
                    if (message.isModerator) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.verified,
                        size: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                    const SizedBox(width: 8),
                    Text(
                      _formatTimestamp(message.timestamp),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  message.content,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
}

class _ViewerTile extends StatelessWidget {
  final StreamViewer viewer;

  const _ViewerTile({required this.viewer});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: CachedNetworkImageProvider(viewer.userAvatar),
      ),
      title: Row(
        children: [
          Text(viewer.userName),
          if (viewer.isStaff) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.verified,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
          if (viewer.isVip) ...[
            const SizedBox(width: 4),
            Icon(
              Icons.star,
              size: 16,
              color: Colors.amber,
            ),
          ],
        ],
      ),
      subtitle: Text(
        'Watching for ${_formatWatchTime(viewer.watchTime)}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: viewer.isOnline
          ? Icon(
              Icons.circle,
              size: 8,
              color: Colors.green,
            )
          : Icon(
              Icons.circle,
              size: 8,
              color: Colors.grey,
            ),
    );
  }

  String _formatWatchTime(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}
