import 'package:flutter/foundation.dart';
import 'auth_provider.dart';
import 'media_provider.dart';
import 'notification_provider.dart';
import 'social_provider.dart';
import 'theme_provider.dart';
import 'comment_provider.dart';
import 'social_graph_provider.dart';
import 'subscription_provider.dart';
import 'antigravity_provider.dart';
import '../models/media_item.dart';
import '../models/social_user.dart';

/// Combined provider that manages related state to reduce provider count
/// and optimize performance by minimizing unnecessary re-renders
class CombinedProvider extends ChangeNotifier {
  final AuthProvider authProvider;
  final MediaProvider mediaProvider;
  final NotificationProvider notificationProvider;
  final SocialProvider socialProvider;
  final ThemeProvider themeProvider;
  final CommentProvider commentProvider;
  final SocialGraphProvider socialGraphProvider;
  final SubscriptionProvider subscriptionProvider;
  final AntigravityProvider antigravityProvider;

  CombinedProvider({
    required this.authProvider,
    required this.mediaProvider,
    required this.notificationProvider,
    required this.socialProvider,
    required this.themeProvider,
    required this.commentProvider,
    required this.socialGraphProvider,
    required this.subscriptionProvider,
    required this.antigravityProvider,
  }) {
    // Listen to important changes and notify listeners
    authProvider.addListener(_onAuthStateChanged);
    mediaProvider.addListener(_onMediaChanged);
    notificationProvider.addListener(_onNotificationChanged);
  }

  @override
  void dispose() {
    authProvider.removeListener(_onAuthStateChanged);
    mediaProvider.removeListener(_onMediaChanged);
    notificationProvider.removeListener(_onNotificationChanged);
    super.dispose();
  }

  void _onAuthStateChanged() {
    notifyListeners();
  }

  void _onMediaChanged() {
    notifyListeners();
  }

  void _onNotificationChanged() {
    notifyListeners();
  }

  // Convenience getters for commonly used combinations
  bool get isLoading =>
      authProvider.isLoading ||
      mediaProvider.isLoading ||
      socialProvider.isLoading ||
      notificationProvider.isLoading;

  String? get currentError =>
      authProvider.error ??
      mediaProvider.error ??
      socialProvider.error ??
      notificationProvider.error;

  bool get hasUnreadNotifications => notificationProvider.hasUnreadNotifications;

  // User-related convenience methods
  Future<void> refreshUserData() async {
    if (authProvider.currentUser != null) {
      await Future.wait([
        mediaProvider.refreshMedia(),
        notificationProvider.refreshNotifications(),
        socialProvider.loadNearbyUsers(),
      ]);
    }
  }

  // Media-related convenience methods
  Future<void> loadUserMedia(String userId) async {
    await mediaProvider.loadUserMedia(userId);
  }

  Future<void> interactWithMedia(MediaItem media, {bool like = false}) async {
    if (like) {
      await mediaProvider.likeMedia(media.id);
      await notificationProvider.addNotification(
        'New like on your content!',
        'media_like',
      );
    }
  }

  // Social-related convenience methods
  Future<void> connectWithUser(SocialUser user) async {
    await socialGraphProvider.followUser(user.id);
    await notificationProvider.addNotification(
      'You have a new follower!',
      'new_follower',
    );
  }
}
