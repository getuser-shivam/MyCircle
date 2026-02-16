import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/social_provider.dart';
import '../../models/social_user.dart';
import '../../widgets/social/user_card.dart';
import '../../widgets/social/swipe_deck.dart';
import '../../widgets/social/filter_bottom_sheet.dart';
import './social_profile_screen.dart';

enum DiscoveryMode { grid, swipe }

class MeetMeScreen extends StatefulWidget {
  const MeetMeScreen({super.key});

  @override
  State<MeetMeScreen> createState() => _MeetMeScreenState();
}

class _MeetMeScreenState extends State<MeetMeScreen> {
  DiscoveryMode _mode = DiscoveryMode.grid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SocialProvider>().loadNearbyUsers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _mode == DiscoveryMode.grid ? _buildGridView() : _buildSwipeView(),
      floatingActionButton: _mode == DiscoveryMode.grid 
        ? FloatingActionButton(
            onPressed: () {},
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.flash_on_rounded, color: Colors.white),
          )
        : null,
    );
  }

  Widget _buildGridView() {
    return CustomScrollView(
      slivers: [
        _buildAppBar(),
        _buildLiveNowSection(),
        _buildSectionHeader('Nearby People'),
        _buildUserGrid(),
      ],
    );
  }

  Widget _buildSwipeView() {
    return Column(
      children: [
        _buildSimplifiedAppBar(),
        Expanded(
          child: Consumer<SocialProvider>(
            builder: (context, provider, child) {
              return SwipeDeck(
                users: provider.nearbyUsers,
                onSwipe: (user, isLiked) {
                  debugPrint('Swiped ${user.username}: ${isLiked ? 'Liked' : 'Nope'}');
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSimplifiedAppBar() {
    return Container(
      padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Discover',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          _buildModeToggle(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      floating: true,
      pinned: true,
      expandedHeight: 120,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Theme.of(context).colorScheme.background.withValues(alpha: 0.8),
              padding: const EdgeInsets.only(top: 60, left: 20, right: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Meet Me',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Find someone new today',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _buildModeToggle(),
                      const SizedBox(width: 12),
                      _buildFilterButton(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleItem(Icons.grid_view_rounded, DiscoveryMode.grid),
          _buildToggleItem(Icons.style_rounded, DiscoveryMode.swipe),
        ],
      ),
    );
  }

  Widget _buildToggleItem(IconData icon, DiscoveryMode mode) {
    final isActive = _mode == mode;
    return GestureDetector(
      onTap: () => setState(() => _mode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Theme.of(context).colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isActive ? Colors.white : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildFilterButton() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(Icons.tune_rounded, color: Theme.of(context).colorScheme.primary),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => FilterBottomSheet(
              onApply: (minAge, maxAge, gender, maxDistance) {
                debugPrint('Filters: Age $minAge-$maxAge, Gender: $gender, Distance: $maxDistance km');
                // TODO: Apply filters to SocialProvider
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLiveNowSection() {
    return SliverToBoxAdapter(
      child: Container(
        height: 100,
        margin: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              child: Text(
                'LIVE NOW',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.redAccent,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Expanded(
              child: Consumer<SocialProvider>(
                builder: (context, provider, child) {
                  final liveUsers = provider.nearbyUsers.where((u) => u.status == UserStatus.live).toList();
                  if (liveUsers.isEmpty) return const SizedBox.shrink();
                  
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    itemCount: liveUsers.length,
                    itemBuilder: (context, index) {
                      final user = liveUsers[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        width: 60,
                        child: Column(
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.redAccent, width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 25,
                                backgroundImage: NetworkImage(user.avatar),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.username,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('See All'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserGrid() {
    return Consumer<SocialProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.75,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final user = provider.nearbyUsers[index];
                return UserCard(
                  user: user,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SocialProfileScreen(user: user),
                      ),
                    );
                  },
                );
              },
              childCount: provider.nearbyUsers.length,
            ),
          ),
        );
      },
    );
  }
}
