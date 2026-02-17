import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:provider/provider.dart';
import 'package:mycircle/screens/streaming/stream_browse_screen.dart';
import 'package:mycircle/providers/stream_provider.dart';
import 'package:mycircle/models/stream_model.dart';

import 'stream_browse_screen_test.mocks.dart';

@GenerateMocks([StreamProvider])
void main() {
  group('StreamBrowseScreen', () {
    late MockStreamProvider mockStreamProvider;

    setUp(() {
      mockStreamProvider = MockStreamProvider();
    });

    final sampleStreams = [
      LiveStream(
        id: 'stream_1',
        streamerId: 'user_1',
        title: 'Gaming Stream 1',
        status: StreamStatus.live,
        quality: StreamQuality.high,
        viewerCount: 1000,
        startedAt: DateTime.now(),
        streamerName: 'Gamer1',
        category: 'Gaming',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      LiveStream(
        id: 'stream_2',
        streamerId: 'user_2',
        title: 'Music Stream 1',
        status: StreamStatus.live,
        quality: StreamQuality.medium,
        viewerCount: 500,
        startedAt: DateTime.now(),
        streamerName: 'Musician1',
        category: 'Music',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    testWidgets('should display app bar with correct title', (WidgetTester tester) async {
      when(mockStreamProvider.isLoading).thenReturn(false);
      when(mockStreamProvider.error).thenReturn(null);
      when(mockStreamProvider.liveStreams).thenReturn(sampleStreams);
      when(mockStreamProvider.trendingStreams).thenReturn(sampleStreams);

      await tester.pumpWidget(
        ChangeNotifierProvider<StreamProvider>(
          create: (_) => mockStreamProvider,
          child: MaterialApp(
            home: StreamBrowseScreen(),
          ),
        ),
      );

      expect(find.text('Live Streams'), findsOneWidget);
    });

    testWidgets('should display tabs correctly', (WidgetTester tester) async {
      when(mockStreamProvider.isLoading).thenReturn(false);
      when(mockStreamProvider.error).thenReturn(null);
      when(mockStreamProvider.liveStreams).thenReturn(sampleStreams);
      when(mockStreamProvider.trendingStreams).thenReturn(sampleStreams);

      await tester.pumpWidget(
        ChangeNotifierProvider<StreamProvider>(
          create: (_) => mockStreamProvider,
          child: MaterialApp(
            home: StreamBrowseScreen(),
          ),
        ),
      );

      expect(find.text('Live Now'), findsOneWidget);
      expect(find.text('Scheduled'), findsOneWidget);
      expect(find.text('Trending'), findsOneWidget);
      expect(find.text('Following'), findsOneWidget);
      expect(find.text('Nearby'), findsOneWidget);
      expect(find.text('Categories'), findsOneWidget);
    });

    testWidgets('should display search icon', (WidgetTester tester) async {
      when(mockStreamProvider.isLoading).thenReturn(false);
      when(mockStreamProvider.error).thenReturn(null);
      when(mockStreamProvider.liveStreams).thenReturn(sampleStreams);

      await tester.pumpWidget(
        ChangeNotifierProvider<StreamProvider>(
          create: (_) => mockStreamProvider,
          child: MaterialApp(
            home: StreamBrowseScreen(),
          ),
        ),
      );

      expect(find.byIcon(Icons.search), findsOneWidget);
    });

    testWidgets('should display filter icon', (WidgetTester tester) async {
      when(mockStreamProvider.isLoading).thenReturn(false);
      when(mockStreamProvider.error).thenReturn(null);
      when(mockStreamProvider.liveStreams).thenReturn(sampleStreams);

      await tester.pumpWidget(
        ChangeNotifierProvider<StreamProvider>(
          create: (_) => mockStreamProvider,
          child: MaterialApp(
            home: StreamBrowseScreen(),
          ),
        ),
      );

      expect(find.byIcon(Icons.filter_list), findsOneWidget);
    });

    testWidgets('should display floating action button', (WidgetTester tester) async {
      when(mockStreamProvider.isLoading).thenReturn(false);
      when(mockStreamProvider.error).thenReturn(null);
      when(mockStreamProvider.liveStreams).thenReturn(sampleStreams);

      await tester.pumpWidget(
        ChangeNotifierProvider<StreamProvider>(
          create: (_) => mockStreamProvider,
          child: MaterialApp(
            home: StreamBrowseScreen(),
          ),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.text('Go Live'), findsOneWidget);
    });

    testWidgets('should display streams in grid', (WidgetTester tester) async {
      when(mockStreamProvider.isLoading).thenReturn(false);
      when(mockStreamProvider.error).thenReturn(null);
      when(mockStreamProvider.liveStreams).thenReturn(sampleStreams);

      await tester.pumpWidget(
        ChangeNotifierProvider<StreamProvider>(
          create: (_) => mockStreamProvider,
          child: MaterialApp(
            home: StreamBrowseScreen(),
          ),
        ),
      );

      // Should find stream cards
      expect(find.text('Gaming Stream 1'), findsOneWidget);
      expect(find.text('Music Stream 1'), findsOneWidget);
      expect(find.text('Gamer1'), findsOneWidget);
      expect(find.text('Musician1'), findsOneWidget);
    });

    testWidgets('should display loading indicator', (WidgetTester tester) async {
      when(mockStreamProvider.isLoading).thenReturn(true);
      when(mockStreamProvider.error).thenReturn(null);
      when(mockStreamProvider.liveStreams).thenReturn([]);

      await tester.pumpWidget(
        ChangeNotifierProvider<StreamProvider>(
          create: (_) => mockStreamProvider,
          child: MaterialApp(
            home: StreamBrowseScreen(),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should display error state', (WidgetTester tester) async {
      when(mockStreamProvider.isLoading).thenReturn(false);
      when(mockStreamProvider.error).thenReturn('Network error');
      when(mockStreamProvider.liveStreams).thenReturn([]);

      await tester.pumpWidget(
        ChangeNotifierProvider<StreamProvider>(
          create: (_) => mockStreamProvider,
          child: MaterialApp(
            home: StreamBrowseScreen(),
          ),
        ),
      );

      expect(find.text('Network error'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('should display empty state', (WidgetTester tester) async {
      when(mockStreamProvider.isLoading).thenReturn(false);
      when(mockStreamProvider.error).thenReturn(null);
      when(mockStreamProvider.liveStreams).thenReturn([]);

      await tester.pumpWidget(
        ChangeNotifierProvider<StreamProvider>(
          create: (_) => mockStreamProvider,
          child: MaterialApp(
            home: StreamBrowseScreen(),
          ),
        ),
      );

      expect(find.text('No streams found'), findsOneWidget);
      expect(find.text('Check back later for live content'), findsOneWidget);
    });

    testWidgets('should handle tab switching', (WidgetTester tester) async {
      when(mockStreamProvider.isLoading).thenReturn(false);
      when(mockStreamProvider.error).thenReturn(null);
      when(mockStreamProvider.liveStreams).thenReturn(sampleStreams);
      when(mockStreamProvider.scheduledStreams).thenReturn([]);

      await tester.pumpWidget(
        ChangeNotifierProvider<StreamProvider>(
          create: (_) => mockStreamProvider,
          child: MaterialApp(
            home: StreamBrowseScreen(),
          ),
        ),
      );

      // Initially on Live Now tab
      expect(find.text('Gaming Stream 1'), findsOneWidget);

      // Switch to Scheduled tab
      await tester.tap(find.text('Scheduled'));
      await tester.pumpAndSettle();

      // Should show empty state for scheduled streams
      expect(find.text('No streams found'), findsOneWidget);
    });

    testWidgets('should handle search tap', (WidgetTester tester) async {
      when(mockStreamProvider.isLoading).thenReturn(false);
      when(mockStreamProvider.error).thenReturn(null);
      when(mockStreamProvider.liveStreams).thenReturn(sampleStreams);

      await tester.pumpWidget(
        ChangeNotifierProvider<StreamProvider>(
          create: (_) => mockStreamProvider,
          child: MaterialApp(
            home: StreamBrowseScreen(),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.search));
      await tester.pumpAndSettle();

      // Should open search dialog or navigate to search
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('should handle filter tap', (WidgetTester tester) async {
      when(mockStreamProvider.isLoading).thenReturn(false);
      when(mockStreamProvider.error).thenReturn(null);
      when(mockStreamProvider.liveStreams).thenReturn(sampleStreams);

      await tester.pumpWidget(
        ChangeNotifierProvider<StreamProvider>(
          create: (_) => mockStreamProvider,
          child: MaterialApp(
            home: StreamBrowseScreen(),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.filter_list));
      await tester.pumpAndSettle();

      // Should open filter dialog
      expect(find.byType(Checkbox), findsWidgets);
    });

    testWidgets('should handle FAB tap', (WidgetTester tester) async {
      when(mockStreamProvider.isLoading).thenReturn(false);
      when(mockStreamProvider.error).thenReturn(null);
      when(mockStreamProvider.liveStreams).thenReturn(sampleStreams);

      await tester.pumpWidget(
        ChangeNotifierProvider<StreamProvider>(
          create: (_) => mockStreamProvider,
          child: MaterialApp(
            home: StreamBrowseScreen(),
          ),
        ),
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Should navigate to stream setup screen
      // This would depend on the actual navigation implementation
    });

    testWidgets('should handle stream card tap', (WidgetTester tester) async {
      when(mockStreamProvider.isLoading).thenReturn(false);
      when(mockStreamProvider.error).thenReturn(null);
      when(mockStreamProvider.liveStreams).thenReturn(sampleStreams);

      await tester.pumpWidget(
        ChangeNotifierProvider<StreamProvider>(
          create: (_) => mockStreamProvider,
          child: MaterialApp(
            home: StreamBrowseScreen(),
          ),
        ),
      );

      await tester.tap(find.text('Gaming Stream 1'));
      await tester.pumpAndSettle();

      // Should navigate to stream player screen
      verify(mockStreamProvider.loadStreamById('stream_1')).called(1);
    });

    testWidgets('should handle pull to refresh', (WidgetTester tester) async {
      when(mockStreamProvider.isLoading).thenReturn(false);
      when(mockStreamProvider.error).thenReturn(null);
      when(mockStreamProvider.liveStreams).thenReturn(sampleStreams);
      when(mockStreamProvider.refreshAll()).thenAnswer((_) async {});

      await tester.pumpWidget(
        ChangeNotifierProvider<StreamProvider>(
          create: (_) => mockStreamProvider,
          child: MaterialApp(
            home: StreamBrowseScreen(),
          ),
        ),
      );

      // Pull down to refresh
      await tester.fling(
        find.byType(RefreshIndicator),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      verify(mockStreamProvider.refreshAll()).called(1);
    });

    testWidgets('should handle retry on error', (WidgetTester tester) async {
      when(mockStreamProvider.isLoading).thenReturn(false);
      when(mockStreamProvider.error).thenReturn('Network error');
      when(mockStreamProvider.liveStreams).thenReturn([]);
      when(mockStreamProvider.refreshAll()).thenAnswer((_) async {});

      await tester.pumpWidget(
        ChangeNotifierProvider<StreamProvider>(
          create: (_) => mockStreamProvider,
          child: MaterialApp(
            home: StreamBrowseScreen(),
          ),
        ),
      );

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      verify(mockStreamProvider.refreshAll()).called(1);
    });

    testWidgets('should display trending streams', (WidgetTester tester) async {
      when(mockStreamProvider.isLoading).thenReturn(false);
      when(mockStreamProvider.error).thenReturn(null);
      when(mockStreamProvider.trendingStreams).thenReturn(sampleStreams);

      await tester.pumpWidget(
        ChangeNotifierProvider<StreamProvider>(
          create: (_) => mockStreamProvider,
          child: MaterialApp(
            home: StreamBrowseScreen(),
          ),
        ),
      );

      // Switch to trending tab
      await tester.tap(find.text('Trending'));
      await tester.pumpAndSettle();

      expect(find.text('Gaming Stream 1'), findsOneWidget);
      expect(find.text('Music Stream 1'), findsOneWidget);
    });

    testWidgets('should handle empty trending streams', (WidgetTester tester) async {
      when(mockStreamProvider.isLoading).thenReturn(false);
      when(mockStreamProvider.error).thenReturn(null);
      when(mockStreamProvider.trendingStreams).thenReturn([]);

      await tester.pumpWidget(
        ChangeNotifierProvider<StreamProvider>(
          create: (_) => mockStreamProvider,
          child: MaterialApp(
            home: StreamBrowseScreen(),
          ),
        ),
      );

      // Switch to trending tab
      await tester.tap(find.text('Trending'));
      await tester.pumpAndSettle();

      expect(find.text('No streams found'), findsOneWidget);
    });

    testWidgets('should handle following streams', (WidgetTester tester) async {
      when(mockStreamProvider.isLoading).thenReturn(false);
      when(mockStreamProvider.error).thenReturn(null);
      when(mockStreamProvider.followingStreams).thenReturn(sampleStreams);

      await tester.pumpWidget(
        ChangeNotifierProvider<StreamProvider>(
          create: (_) => mockStreamProvider,
          child: MaterialApp(
            home: StreamBrowseScreen(),
          ),
        ),
      );

      // Switch to following tab
      await tester.tap(find.text('Following'));
      await tester.pumpAndSettle();

      expect(find.text('Gaming Stream 1'), findsOneWidget);
    });

    testWidgets('should handle nearby streams', (WidgetTester tester) async {
      when(mockStreamProvider.isLoading).thenReturn(false);
      when(mockStreamProvider.error).thenReturn(null);
      when(mockStreamProvider.nearbyStreams).thenReturn(sampleStreams);

      await tester.pumpWidget(
        ChangeNotifierProvider<StreamProvider>(
          create: (_) => mockStreamProvider,
          child: MaterialApp(
            home: StreamBrowseScreen(),
          ),
        ),
      );

      // Switch to nearby tab
      await tester.tap(find.text('Nearby'));
      await tester.pumpAndSettle();

      expect(find.text('Gaming Stream 1'), findsOneWidget);
    });

    testWidgets('should handle category streams', (WidgetTester tester) async {
      final categoryStreams = {'Gaming': sampleStreams};
      
      when(mockStreamProvider.isLoading).thenReturn(false);
      when(mockStreamProvider.error).thenReturn(null);
      when(mockStreamProvider.streamsByCategory).thenReturn(categoryStreams);

      await tester.pumpWidget(
        ChangeNotifierProvider<StreamProvider>(
          create: (_) => mockStreamProvider,
          child: MaterialApp(
            home: StreamBrowseScreen(),
          ),
        ),
      );

      // Switch to categories tab
      await tester.tap(find.text('Categories'));
      await tester.pumpAndSettle();

      expect(find.text('Gaming'), findsOneWidget);
    });

    testWidgets('should handle infinite scroll', (WidgetTester tester) async {
      when(mockStreamProvider.isLoading).thenReturn(false);
      when(mockStreamProvider.error).thenReturn(null);
      when(mockStreamProvider.liveStreams).thenReturn(sampleStreams);
      when(mockStreamProvider.liveStreamsPagingController).thenReturn(
        // Mock paging controller
        null, // This would need proper mocking
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<StreamProvider>(
          create: (_) => mockStreamProvider,
          child: MaterialApp(
            home: StreamBrowseScreen(),
          ),
        ),
      );

      // Scroll to bottom to trigger load more
      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, -500),
        1000,
      );
      await tester.pumpAndSettle();

      // Should attempt to load more streams
      // This would depend on the actual pagination implementation
    });

    testWidgets('should handle orientation change', (WidgetTester tester) async {
      when(mockStreamProvider.isLoading).thenReturn(false);
      when(mockStreamProvider.error).thenReturn(null);
      when(mockStreamProvider.liveStreams).thenReturn(sampleStreams);

      await tester.pumpWidget(
        ChangeNotifierProvider<StreamProvider>(
          create: (_) => mockStreamProvider,
          child: MaterialApp(
            home: StreamBrowseScreen(),
          ),
        ),
      );

      // Change to landscape
      await tester.binding.setSurfaceSize(const Size(800, 400));
      await tester.pump();

      // Should adapt layout
      expect(find.byType(StreamBrowseScreen), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Change back to portrait
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pump();

      expect(find.byType(StreamBrowseScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle large number of streams', (WidgetTester tester) async {
      final manyStreams = List.generate(50, (index) => LiveStream(
        id: 'stream_$index',
        streamerId: 'user_$index',
        title: 'Stream $index',
        status: StreamStatus.live,
        quality: StreamQuality.medium,
        viewerCount: 100 + index,
        startedAt: DateTime.now(),
        streamerName: 'Streamer $index',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      when(mockStreamProvider.isLoading).thenReturn(false);
      when(mockStreamProvider.error).thenReturn(null);
      when(mockStreamProvider.liveStreams).thenReturn(manyStreams);

      await tester.pumpWidget(
        ChangeNotifierProvider<StreamProvider>(
          create: (_) => mockStreamProvider,
          child: MaterialApp(
            home: StreamBrowseScreen(),
          ),
        ),
      );

      // Should display multiple streams
      expect(find.text('Stream 0'), findsOneWidget);
      expect(find.text('Stream 1'), findsOneWidget);
      expect(find.text('Stream 49'), findsOneWidget);
    });

    testWidgets('should handle stream with special characters', (WidgetTester tester) async {
      final specialStream = LiveStream(
        id: 'special_stream',
        streamerId: 'user_special',
        title: 'Stream 🎮 with @special #characters',
        status: StreamStatus.live,
        quality: StreamQuality.high,
        viewerCount: 1000,
        startedAt: DateTime.now(),
        streamerName: 'Special Gamer 🎯',
        category: 'Gaming',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockStreamProvider.isLoading).thenReturn(false);
      when(mockStreamProvider.error).thenReturn(null);
      when(mockStreamProvider.liveStreams).thenReturn([specialStream]);

      await tester.pumpWidget(
        ChangeNotifierProvider<StreamProvider>(
          create: (_) => mockStreamProvider,
          child: MaterialApp(
            home: StreamBrowseScreen(),
          ),
        ),
      );

      expect(find.textContaining('Stream 🎮'), findsOneWidget);
      expect(find.textContaining('Special Gamer 🎯'), findsOneWidget);
    });

    testWidgets('should handle very long stream titles', (WidgetTester tester) async {
      final longTitleStream = LiveStream(
        id: 'long_title_stream',
        streamerId: 'user_long',
        title: 'This is a very long stream title that should be truncated properly and not break the layout of the stream card in the grid view',
        status: StreamStatus.live,
        quality: StreamQuality.medium,
        viewerCount: 500,
        startedAt: DateTime.now(),
        streamerName: 'LongTitleStreamer',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(mockStreamProvider.isLoading).thenReturn(false);
      when(mockStreamProvider.error).thenReturn(null);
      when(mockStreamProvider.liveStreams).thenReturn([longTitleStream]);

      await tester.pumpWidget(
        ChangeNotifierProvider<StreamProvider>(
          create: (_) => mockStreamProvider,
          child: MaterialApp(
            home: StreamBrowseScreen(),
          ),
        ),
      );

      // Should not overflow
      expect(tester.takeException(), isNull);
      expect(find.byType(StreamBrowseScreen), findsOneWidget);
    });

    testWidgets('should handle provider state changes', (WidgetTester tester) async {
      when(mockStreamProvider.isLoading).thenReturn(true);
      when(mockStreamProvider.error).thenReturn(null);
      when(mockStreamProvider.liveStreams).thenReturn([]);

      await tester.pumpWidget(
        ChangeNotifierProvider<StreamProvider>(
          create: (_) => mockStreamProvider,
          child: MaterialApp(
            home: StreamBrowseScreen(),
          ),
        ),
      );

      // Initially loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Simulate data loaded
      when(mockStreamProvider.isLoading).thenReturn(false);
      when(mockStreamProvider.liveStreams).thenReturn(sampleStreams);
      
      // Notify listeners
      mockStreamProvider.notifyListeners();
      await tester.pump();

      // Should show streams
      expect(find.text('Gaming Stream 1'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });

  group('StreamBrowseScreen Edge Cases', () {
    testWidgets('should handle null provider gracefully', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StreamBrowseScreen(),
        ),
      );

      // Should not crash
      expect(find.byType(StreamBrowseScreen), findsOneWidget);
    });

    testWidgets('should handle empty provider data', (WidgetTester tester) async {
      final emptyProvider = StreamProvider();

      await tester.pumpWidget(
        ChangeNotifierProvider<StreamProvider>(
          create: (_) => emptyProvider,
          child: MaterialApp(
            home: StreamBrowseScreen(),
          ),
        ),
      );

      // Should show empty state
      expect(find.text('No streams found'), findsOneWidget);
    });

    testWidgets('should handle network errors gracefully', (WidgetTester tester) async {
      final mockStreamProvider = MockStreamProvider();
      
      when(mockStreamProvider.isLoading).thenReturn(false);
      when(mockStreamProvider.error).thenReturn('Network connection failed');
      when(mockStreamProvider.liveStreams).thenReturn([]);

      await tester.pumpWidget(
        ChangeNotifierProvider<StreamProvider>(
          create: (_) => mockStreamProvider,
          child: MaterialApp(
            home: StreamBrowseScreen(),
          ),
        ),
      );

      expect(find.text('Network connection failed'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('should handle rapid tab switching', (WidgetTester tester) async {
      final mockStreamProvider = MockStreamProvider();
      
      when(mockStreamProvider.isLoading).thenReturn(false);
      when(mockStreamProvider.error).thenReturn(null);
      when(mockStreamProvider.liveStreams).thenReturn([]);
      when(mockStreamProvider.scheduledStreams).thenReturn([]);
      when(mockStreamProvider.trendingStreams).thenReturn([]);
      when(mockStreamProvider.followingStreams).thenReturn([]);
      when(mockStreamProvider.nearbyStreams).thenReturn([]);
      when(mockStreamProvider.streamsByCategory).thenReturn({});

      await tester.pumpWidget(
        ChangeNotifierProvider<StreamProvider>(
          create: (_) => mockStreamProvider,
          child: MaterialApp(
            home: StreamBrowseScreen(),
          ),
        ),
      );

      // Rapidly switch between tabs
      await tester.tap(find.text('Scheduled'));
      await tester.pump();
      
      await tester.tap(find.text('Trending'));
      await tester.pump();
      
      await tester.tap(find.text('Following'));
      await tester.pump();
      
      await tester.tap(find.text('Live Now'));
      await tester.pump();

      // Should not crash
      expect(find.byType(StreamBrowseScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
