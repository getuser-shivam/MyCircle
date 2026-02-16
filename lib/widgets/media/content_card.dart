import 'dart:ui';
import '../../providers/media_provider.dart';
import '../../models/media_item.dart';
import 'package:flutter/material.dart';



class ContentCard extends StatefulWidget {
  final MediaItem mediaItem;
  final VoidCallback onTap;

  const ContentCard({
    super.key,
    required this.mediaItem,
    required this.onTap,
  });

  @override
  State<ContentCard> createState() => _ContentCardState();
}

class _ContentCardState extends State<ContentCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
    if (isHovered) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _isHovered 
                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2) 
                          : Colors.black.withValues(alpha: 0.1),
                      blurRadius: _isHovered ? 20 : 10,
                      offset: Offset(0, _isHovered ? 10 : 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      // Thumbnail with parallax-like effect
                      Positioned.fill(
                        child: AnimatedScale(
                          scale: _isHovered ? 1.1 : 1.0,
                          duration: const Duration(milliseconds: 500),
                          child: Container(
                            color: Theme.of(context).colorScheme.surface,
                            child: widget.mediaItem.thumbnailUrl != null
                                ? Image.network(
                                    widget.mediaItem.thumbnailUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
                                  )
                                : _buildPlaceholder(),
                          ),
                        ),
                      ),
                      
                      // Polished Gradient Overlay
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.2),
                                Colors.black.withValues(alpha: 0.8),
                              ],
                              stops: const [0.0, 0.4, 1.0],
                            ),
                          ),
                        ),
                      ),
                      
                      // Premium Badges
                      Positioned(
                        top: 12,
                        left: 12,
                        right: 12,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (widget.mediaItem.type != null)
                              _buildGlassBadge(
                                text: widget.mediaItem.type.toString().split('.').last.toUpperCase(),
                                icon: widget.mediaItem.type == MediaType.video ? Icons.play_arrow_rounded : Icons.gif_rounded,
                              ),
                            if (widget.mediaItem.duration != null)
                              _buildGlassBadge(text: widget.mediaItem.duration!),
                          ],
                        ),
                      ),
                      
                      // Title and stats with Micro-animations
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: AnimatedPadding(
                          duration: const Duration(milliseconds: 300),
                          padding: EdgeInsets.all(_isHovered ? 16 : 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.mediaItem.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _buildStatItem(Icons.visibility_rounded, _formatViews(widget.mediaItem.views)),
                                  const SizedBox(width: 12),
                                  _buildStatItem(Icons.favorite_rounded, _formatLikes(widget.mediaItem.likes)),
                                  const Spacer(),
                                  if (widget.mediaItem.isVerified)
                                    Icon(Icons.verified_rounded, color: Theme.of(context).colorScheme.primary, size: 16),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Hover Play Glow
                      if (_isHovered)
                        Positioned.fill(
                          child: Center(
                            child: AnimatedOpacity(
                              opacity: _isHovered ? 1.0 : 0.0,
                              duration: const Duration(milliseconds: 300),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                                      blurRadius: 15,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 32),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGlassBadge({required String text, IconData? icon}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.white, size: 14),
                const SizedBox(width: 4),
              ],
              Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.7), size: 14),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[700]!,
            Colors.grey[900]!,
          ],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.play_arrow_rounded,
          color: Colors.white54,
          size: 48,
        ),
      ),
    );
  }

  String _formatViews(int views) {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K';
    }
    return views.toString();
  }

  String _formatLikes(int likes) {
    if (likes >= 1000000) {
      return '${(likes / 1000000).toStringAsFixed(1)}M';
    } else if (likes >= 1000) {
      return '${(likes / 1000).toStringAsFixed(1)}K';
    }
    return likes.toString();
  }
}
