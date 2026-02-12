import 'package:flutter/material.dart';
import '../../models/social_user.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:math' as math;

class SwipeDeck extends StatefulWidget {
  final List<SocialUser> users;
  final Function(SocialUser, bool) onSwipe; // bool isLiked

  const SwipeDeck({
    super.key,
    required this.users,
    required this.onSwipe,
  });

  @override
  State<SwipeDeck> createState() => _SwipeDeckState();
}

class _SwipeDeckState extends State<SwipeDeck> with SingleTickerProviderStateMixin {
  late List<SocialUser> _deck;
  Offset _dragOffset = Offset.zero;
  late AnimationController _animationController;
  late Animation<Offset> _swipeAnimation;

  @override
  void initState() {
    super.initState();
    _deck = List.from(widget.users);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _swipeAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(_animationController);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    final threshold = MediaQuery.of(context).size.width * 0.3;
    if (_dragOffset.dx > threshold) {
      _swipe(true); // Right swipe
    } else if (_dragOffset.dx < -threshold) {
      _swipe(false); // Left swipe
    } else {
      _reset();
    }
  }

  void _swipe(bool isLiked) {
    final screenWidth = MediaQuery.of(context).size.width;
    _swipeAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset(isLiked ? screenWidth * 1.5 : -screenWidth * 1.5, _dragOffset.dy),
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));

    _animationController.forward().then((_) {
      if (_deck.isNotEmpty) {
        widget.onSwipe(_deck.first, isLiked);
        setState(() {
          _deck.removeAt(0);
          _dragOffset = Offset.zero;
          _animationController.reset();
        });
      }
    });
  }

  void _reset() {
    _swipeAnimation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.elasticOut));
    
    _animationController.forward().then((_) {
      setState(() {
        _dragOffset = Offset.zero;
        _animationController.reset();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_deck.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.explore_off_rounded, size: 80, color: Theme.of(context).colorScheme.primary.withOpacity(0.4)),
            const SizedBox(height: 16),
            Text('No more people nearby!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5))),
            const SizedBox(height: 8),
            Text('Check back later for new matches', style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3))),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Card stack area
        Expanded(
          child: Stack(
            children: _deck.asMap().entries.map((entry) {
              final index = entry.key;
              final user = entry.value;
              final isFront = index == 0;

              return Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: isFront
                      ? AnimatedBuilder(
                          animation: _animationController,
                          builder: (context, child) {
                            final offset = _animationController.isAnimating 
                                ? _swipeAnimation.value 
                                : _dragOffset;
                            final angle = (offset.dx / 400) * (math.pi / 12);

                            return Transform.translate(
                              offset: offset,
                              child: Transform.rotate(
                                angle: angle,
                                child: _buildCard(user, isFront: true),
                              ),
                            );
                          },
                        )
                      : _buildCard(user, isFront: false),
                ),
              );
            }).toList().reversed.toList(),
          ),
        ),
        // Action buttons Row
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24, left: 40, right: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // NOPE button
          _buildCircleButton(
            icon: Icons.close_rounded,
            color: Colors.redAccent,
            size: 60,
            onTap: () => _swipe(false),
          ),
          // SUPER LIKE button
          _buildCircleButton(
            icon: Icons.star_rounded,
            color: Colors.blueAccent,
            size: 48,
            onTap: () {
              if (_deck.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('⭐ Super Liked ${_deck.first.username}!'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.blueAccent,
                  ),
                );
                _swipe(true);
              }
            },
          ),
          // LIKE button
          _buildCircleButton(
            icon: Icons.favorite_rounded,
            color: Colors.greenAccent.shade400,
            size: 60,
            onTap: () => _swipe(true),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    required double size,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: color.withOpacity(0.4), width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.5),
      ),
    );
  }

  Widget _buildCard(SocialUser user, {required bool isFront}) {
    return GestureDetector(
      onPanUpdate: isFront ? _onPanUpdate : null,
      onPanEnd: isFront ? _onPanEnd : null,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: user.avatar,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => const Icon(Icons.person, size: 100),
              ),
              _buildCardOverlay(user),
              if (isFront && _dragOffset.dx != 0) _buildSwipeIndicator(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardOverlay(SocialUser user) {
    return Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.2),
              Colors.black.withOpacity(0.9),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${user.username}, ${user.age}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1,
                    ),
                  ),
                  if (user.isVerified) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.verified_rounded, color: Colors.blueAccent, size: 28),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: Colors.white70, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${user.locationSnippet} • ${user.distanceKm.toStringAsFixed(1)} km away',
                    style: const TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              if (user.bio != null) ...[
                const SizedBox(height: 12),
                Text(
                  user.bio!,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwipeIndicator() {
    final opacity = (_dragOffset.dx.abs() / 100).clamp(0.0, 1.0);
    final isRight = _dragOffset.dx > 0;

    return Positioned(
      top: 40,
      left: isRight ? 40 : null,
      right: isRight ? null : 40,
      child: Transform.rotate(
        angle: isRight ? -0.2 : 0.2,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: isRight ? Colors.greenAccent : Colors.redAccent,
              width: 4,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isRight ? 'LIKE' : 'NOPE',
            style: TextStyle(
              color: isRight ? Colors.greenAccent : Colors.redAccent,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }
}
