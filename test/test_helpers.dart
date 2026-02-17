import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mycircle/models/stream_model.dart';
import 'package:mycircle/models/stream_chat_model.dart';
import 'package:mycircle/models/stream_viewer_model.dart';

/// Test helpers for streaming feature tests
class StreamingTestHelpers {
  /// Creates a sample live stream for testing
  static LiveStream createSampleStream({
    String id = 'stream_1',
    String streamerId = 'user_1',
    String title = 'Test Stream',
    StreamStatus status = StreamStatus.live,
    StreamQuality quality = StreamQuality.high,
    int viewerCount = 1000,
    String category = 'Gaming',
    List<String> tags = const ['gaming', 'test'],
    bool isVerified = true,
    bool isPrivate = false,
    bool isRecorded = true,
  }) {
    final now = DateTime.now();
    return LiveStream(
      id: id,
      streamerId: streamerId,
      title: title,
      description: 'Test stream description',
      category: category,
      tags: tags,
      thumbnailUrl: 'https://example.com/thumb.jpg',
      streamUrl: 'https://example.com/stream.m3u8',
      status: status,
      quality: quality,
      viewerCount: viewerCount,
      maxViewers: 5000,
      isPrivate: isPrivate,
      isRecorded: isRecorded,
      isVerified: isVerified,
      startedAt: status == StreamStatus.live ? now : null,
      scheduledAt: status == StreamStatus.scheduled ? now.add(const Duration(hours: 1)) : null,
      endedAt: status == StreamStatus.ended ? now.subtract(const Duration(hours: 1)) : null,
      streamerName: 'TestStreamer',
      streamerAvatar: 'https://example.com/avatar.jpg',
      latitude: 37.7749,
      longitude: -122.4194,
      locationName: 'San Francisco',
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Creates a sample stream chat message for testing
  static StreamChatMessage createSampleMessage({
    String id = 'message_1',
    String streamId = 'stream_1',
    String userId = 'user_1',
    String userName = 'TestUser',
    String content = 'Hello stream!',
    List<String> reactions = const ['heart'],
    bool isPinned = false,
    bool isDeleted = false,
    bool isFromStaff = false,
    bool isModerator = false,
  }) {
    return StreamChatMessage(
      id: id,
      streamId: streamId,
      userId: userId,
      userName: userName,
      userAvatar: 'https://example.com/avatar.jpg',
      content: content,
      timestamp: DateTime.now(),
      reactions: reactions,
      isPinned: isPinned,
      isDeleted: isDeleted,
      isFromStaff: isFromStaff,
      isModerator: isModerator,
    );
  }

  /// Creates a sample stream viewer for testing
  static StreamViewer createSampleViewer({
    String id = 'viewer_1',
    String streamId = 'stream_1',
    String userId = 'user_1',
    String userName = 'TestUser',
    ViewerRole role = ViewerRole.viewer,
    bool isOnline = true,
    bool isFollowing = false,
    bool isSubscriber = false,
    int messagesSent = 5,
    int reactionsSent = 12,
  }) {
    final now = DateTime.now();
    return StreamViewer(
      id: id,
      streamId: streamId,
      userId: userId,
      userName: userName,
      userAvatar: 'https://example.com/avatar.jpg',
      role: role,
      joinedAt: now.subtract(const Duration(minutes: 30)),
      lastSeen: now,
      watchTime: const Duration(minutes: 25),
      isOnline: isOnline,
      isFollowing: isFollowing,
      isSubscriber: isSubscriber,
      isStaff: role == ViewerRole.staff,
      isVip: role == ViewerRole.vip,
      isModerator: role == ViewerRole.moderator,
      messagesSent: messagesSent,
      reactionsSent: reactionsSent,
    );
  }

  /// Creates a list of sample streams for testing
  static List<LiveStream> createSampleStreams({int count = 5}) {
    return List.generate(count, (index) => createSampleStream(
      id: 'stream_$index',
      streamerId: 'user_$index',
      title: 'Test Stream $index',
      viewerCount: 1000 + (index * 100),
      category: ['Gaming', 'Music', 'Art', 'Education', 'Sports'][index % 5],
    ));
  }

  /// Creates a list of sample messages for testing
  static List<StreamChatMessage> createSampleMessages({int count = 5}) {
    return List.generate(count, (index) => createSampleMessage(
      id: 'message_$index',
      userId: 'user_$index',
      userName: 'User$index',
      content: 'Message $index',
      timestamp: DateTime.now().subtract(Duration(minutes: index)),
    ));
  }

  /// Creates a Material app wrapper for widget testing
  static Widget createMaterialApp(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  /// Creates a Material app wrapper with provider
  static Widget createMaterialAppWithProvider<T extends ChangeNotifier>(
    Widget child,
    T provider,
  ) {
    return ChangeNotifierProvider<T>(
      create: (_) => provider,
      child: MaterialApp(
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  /// Waits for all animations and async operations to complete
  static Future<void> waitForAnimations(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(seconds: 5));
  }

  /// Finds a widget by its text content, case-insensitive
  static Finder findTextIgnoreCase(String text) {
    return find.byWidgetPredicate((widget) {
      if (widget is Text) {
        final data = widget.data;
        if (data is String) {
          return data.toLowerCase().contains(text.toLowerCase());
        }
      }
      return false;
    });
  }

  /// Finds an icon by its type
  static Finder findIcon(IconData iconData) {
    return find.byWidgetPredicate((widget) {
      if (widget is Icon) {
        return widget.icon == iconData;
      }
      return false;
    });
  }

  /// Simulates a user scrolling to the bottom of a scrollable widget
  static Future<void> scrollToBottom(WidgetTester tester, Finder finder) {
    return tester.fling(
      finder,
      const Offset(0, -1000),
      1000,
    );
  }

  /// Simulates a user scrolling to the top of a scrollable widget
  static Future<void> scrollToTop(WidgetTester tester, Finder finder) {
    return tester.fling(
      finder,
      const Offset(0, 1000),
      1000,
    );
  }

  /// Enters text into a text field and dismisses keyboard
  static Future<void> enterText(WidgetTester tester, Finder finder, String text) async {
    await tester.tap(finder);
    await tester.pump();
    await tester.enterText(finder, text);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
  }

  /// Taps a widget and waits for navigation
  static Future<void> tapAndWait(WidgetTester tester, Finder finder) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Verifies that a mock was called exactly once
  static void verifyCalledOnce<T extends Mock>(T mock) {
    verify(mock).called(1);
  }

  /// Verifies that a mock was never called
  static void verifyNeverCalled<T extends Mock>(T mock) {
    verifyNever(mock);
  }

  /// Creates a testable widget with common setup
  static Widget createTestableWidget({
    required Widget child,
    ThemeData? theme,
    List<NavigatorObserver>? observers,
  }) {
    return MaterialApp(
      theme: theme,
      home: child,
      navigatorObservers: observers ?? [],
    );
  }

  /// Generates test data for performance testing
  static List<LiveStream> generateLargeDataset({int count = 1000}) {
    return List.generate(count, (index) => createSampleStream(
      id: 'stream_$index',
      streamerId: 'user_$index',
      title: 'Performance Test Stream $index',
      viewerCount: 100 + (index % 1000),
      category: ['Gaming', 'Music', 'Art', 'Education', 'Sports'][index % 5],
      tags: ['test', 'performance', 'category${index % 5}'],
    ));
  }

  /// Creates a mock response for API testing
  static Map<String, dynamic> createMockStreamResponse(LiveStream stream) {
    return {
      'id': stream.id,
      'streamer_id': stream.streamerId,
      'title': stream.title,
      'description': stream.description,
      'category': stream.category,
      'tags': stream.tags,
      'thumbnail_url': stream.thumbnailUrl,
      'stream_url': stream.streamUrl,
      'status': stream.status.value,
      'quality': stream.quality.value,
      'viewer_count': stream.viewerCount,
      'max_viewers': stream.maxViewers,
      'is_private': stream.isPrivate,
      'is_recorded': stream.isRecorded,
      'is_verified': stream.isVerified,
      'started_at': stream.startedAt?.toIso8601String(),
      'scheduled_at': stream.scheduledAt?.toIso8601String(),
      'ended_at': stream.endedAt?.toIso8601String(),
      'streamer_name': stream.streamerName,
      'streamer_avatar': stream.streamerAvatar,
      'latitude': stream.latitude,
      'longitude': stream.longitude,
      'location_name': stream.locationName,
      'created_at': stream.createdAt.toIso8601String(),
      'updated_at': stream.updatedAt.toIso8601String(),
    };
  }

  /// Benchmarks widget performance
  static Future<void> benchmarkWidget(
    WidgetTester tester,
    Widget widget,
    int iterations, {
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final stopwatch = Stopwatch()..start();

    for (int i = 0; i < iterations; i++) {
      await tester.pumpWidget(createMaterialApp(widget));
      await tester.pump();
    }

    stopwatch.stop();
    print('Widget benchmark: ${iterations} iterations in ${stopwatch.elapsedMilliseconds}ms');
    print('Average: ${stopwatch.elapsedMilliseconds / iterations}ms per iteration');
  }

  /// Tests widget accessibility
  static Future<void> testAccessibility(WidgetTester tester, Widget widget) async {
    await tester.pumpWidget(createMaterialApp(widget));
    await tester.pump();

    // Check for semantic labels
    final semantics = tester.binding.pipelineOwner.semanticsOwner;
    if (semantics != null) {
      final nodes = semantics.rootNodesWithSemantics;
      for (final node in nodes) {
        if (node.label.isEmpty && node.actions.isNotEmpty) {
          print('Warning: Interactive widget without semantic label: $node');
        }
      }
    }
  }

  /// Creates test scenarios for different stream states
  static Map<String, LiveStream> createStreamStateScenarios() {
    final now = DateTime.now();
    return {
      'live': createSampleStream(status: StreamStatus.live, startedAt: now),
      'scheduled': createSampleStream(
        status: StreamStatus.scheduled,
        scheduledAt: now.add(const Duration(hours: 2)),
      ),
      'ended': createSampleStream(
        status: StreamStatus.ended,
        startedAt: now.subtract(const Duration(hours: 2)),
        endedAt: now.subtract(const Duration(hours: 1)),
      ),
      'cancelled': createSampleStream(status: StreamStatus.cancelled),
      'private': createSampleStream(isPrivate: true),
      'unverified': createSampleStream(isVerified: false),
      'empty': createSampleStream(viewerCount: 0),
      'popular': createSampleStream(viewerCount: 50000),
    };
  }
}

/// Custom test matcher for streaming-related assertions
class StreamingMatchers {
  /// Matches a stream with specific status
  static Matcher hasStatus(StreamStatus status) {
    return predicate((LiveStream stream) => stream.status == status);
  }

  /// Matches a stream with specific category
  static Matcher hasCategory(String category) {
    return predicate((LiveStream stream) => stream.category == category);
  }

  /// Matches a stream with minimum viewer count
  static Matcher hasMinViewers(int minViewers) {
    return predicate((LiveStream stream) => stream.viewerCount >= minViewers);
  }

  /// Matches a message with specific content
  static Matcher hasContent(String content) {
    return predicate((StreamChatMessage message) => message.content.contains(content));
  }

  /// Matches a viewer with specific role
  static Matcher hasRole(ViewerRole role) {
    return predicate((StreamViewer viewer) => viewer.role == role);
  }

  /// Matches a list containing streams with specific status
  static Matcher containsStreamsWithStatus(StreamStatus status) {
    return predicate((List<LiveStream> streams) {
      return streams.any((stream) => stream.status == status);
    });
  }

  /// Matches a list sorted by viewer count (descending)
  static Matcher isSortedByViewers() {
    return predicate((List<LiveStream> streams) {
      for (int i = 0; i < streams.length - 1; i++) {
        if (streams[i].viewerCount < streams[i + 1].viewerCount) {
          return false;
        }
      }
      return true;
    });
  }
}

/// Test configuration for streaming tests
class StreamingTestConfig {
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration animationTimeout = Duration(seconds: 5);
  static const Duration networkTimeout = Duration(seconds: 10);
  
  static const int defaultStreamCount = 10;
  static const int defaultMessageCount = 20;
  static const int maxRetryAttempts = 3;
  
  static const String testStreamId = 'test_stream_1';
  static const String testUserId = 'test_user_1';
  static const String testUserName = 'TestUser';
}

/// Custom test exceptions for streaming tests
class StreamingTestException implements Exception {
  final String message;
  final dynamic originalError;
  
  const StreamingTestException(this.message, [this.originalError]);
  
  @override
  String toString() => 'StreamingTestException: $message${originalError != null ? ' (Original: $originalError)' : ''}';
}
