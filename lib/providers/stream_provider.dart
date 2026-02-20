import 'package:flutter/foundation.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/stream_model.dart';
import '../../models/stream_viewer_model.dart';
import '../../services/stream_service.dart';
import '../core/security/logger_service.dart';

class StreamProvider extends ChangeNotifier {
  final StreamService _streamService = StreamService();
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Pagination Controllers
  final PagingController<int, LiveStream> _liveStreamsPagingController =
      PagingController(firstPageKey: 0);
  final PagingController<int, LiveStream> _scheduledStreamsPagingController =
      PagingController(firstPageKey: 0);
  final PagingController<int, LiveStream> _searchPagingController =
      PagingController(firstPageKey: 0);

  static const int _pageSize = 20;
  
  // Stream Lists (for non-paginated data)
  List<LiveStream> _trendingStreams = [];
  List<LiveStream> _followingStreams = [];
  List<LiveStream> _nearbyStreams = [];
  Map<String, List<LiveStream>> _streamsByCategory = {};
  List<LiveStream> _streamHistory = [];
  
  // Current Stream State
  LiveStream? _currentStream;
  List<StreamViewer> _currentViewers = [];
  StreamViewerStats? _streamStats;
  
  // State Management
  bool _isLoading = false;
  bool _isStreaming = false;
  String _searchQuery = '';
  String _selectedCategory = 'all';
  String? _error;
  
  // Cache Management
  final Map<String, List<LiveStream>> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  // Getters
  PagingController<int, LiveStream> get liveStreamsPagingController => 
      _searchQuery.isEmpty ? _liveStreamsPagingController : _searchPagingController;
  PagingController<int, LiveStream> get scheduledStreamsPagingController => 
      _scheduledStreamsPagingController;
  
  List<LiveStream> get liveStreams => _liveStreamsPagingController.itemList ?? [];
  List<LiveStream> get scheduledStreams => _scheduledStreamsPagingController.itemList ?? [];
  List<LiveStream> get searchResults => _searchPagingController.itemList ?? [];
  List<LiveStream> get trendingStreams => _trendingStreams;
  List<LiveStream> get followingStreams => _followingStreams;
  List<LiveStream> get nearbyStreams => _nearbyStreams;
  Map<String, List<LiveStream>> get streamsByCategory => _streamsByCategory;
  List<LiveStream> get streamHistory => _streamHistory;
  LiveStream? get currentStream => _currentStream;
  List<StreamViewer> get currentViewers => _currentViewers;
  StreamViewerStats? get streamStats => _streamStats;
  bool get isLoading => _isLoading;
  bool get isStreaming => _isStreaming;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String? get error => _error;

  StreamProvider() {
    _initializePaginationControllers();
    _loadInitialData();
  }

  void _initializePaginationControllers() {
    _liveStreamsPagingController.addPageRequestListener((pageKey) {
      _fetchLiveStreamsPage(_liveStreamsPagingController, pageKey);
    });
    
    _scheduledStreamsPagingController.addPageRequestListener((pageKey) {
      _fetchScheduledStreamsPage(_scheduledStreamsPagingController, pageKey);
    });

    _searchPagingController.addPageRequestListener((pageKey) {
      _fetchSearchPage(_searchPagingController, pageKey, _searchQuery);
    });
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadTrendingStreams(),
      _loadStreamsByCategory(),
    ]);
  }

  // Pagination Methods
  Future<void> _fetchLiveStreamsPage(
    PagingController<int, LiveStream> controller, 
    int pageKey
  ) async {
    try {
      final newStreams = await _getStreamsFromCacheOrService(
        cacheKey: 'live_streams_$pageKey',
        fetchFunction: () => _streamService.getLiveStreams(
          limit: _pageSize,
          page: (pageKey ~/ _pageSize) + 1,
        ),
      );

      final isLastPage = newStreams.length < _pageSize;
      if (isLastPage) {
        controller.appendLastPage(newStreams);
      } else {
        controller.appendPage(newStreams, pageKey + _pageSize);
      }
    } catch (error) {
      LoggerService.error('Fetch live streams error: $error', tag: 'STREAM');
      controller.error = error;
      _setError('Failed to load live streams: $error');
    }
  }

  Future<void> _fetchScheduledStreamsPage(
    PagingController<int, LiveStream> controller, 
    int pageKey
  ) async {
    try {
      final newStreams = await _getStreamsFromCacheOrService(
        cacheKey: 'scheduled_streams_$pageKey',
        fetchFunction: () => _streamService.getScheduledStreams(
          limit: _pageSize,
          page: (pageKey ~/ _pageSize) + 1,
        ),
      );

      final isLastPage = newStreams.length < _pageSize;
      if (isLastPage) {
        controller.appendLastPage(newStreams);
      } else {
        controller.appendPage(newStreams, pageKey + _pageSize);
      }
    } catch (error) {
      LoggerService.error('Fetch scheduled streams error: $error', tag: 'STREAM');
      controller.error = error;
      _setError('Failed to load scheduled streams: $error');
    }
  }

  Future<void> _fetchSearchPage(
    PagingController<int, LiveStream> controller, 
    int pageKey, 
    String query
  ) async {
    try {
      final newStreams = await _getStreamsFromCacheOrService(
        cacheKey: 'search_${query}_$pageKey',
        fetchFunction: () => _streamService.searchStreams(query),
      );

      final isLastPage = newStreams.length < _pageSize;
      if (isLastPage) {
        controller.appendLastPage(newStreams);
      } else {
        controller.appendPage(newStreams, pageKey + _pageSize);
      }
    } catch (error) {
      LoggerService.error('Search streams error: $error', tag: 'STREAM');
      controller.error = error;
      _setError('Failed to search streams: $error');
    }
  }

  // Cache Management
  Future<List<LiveStream>> _getStreamsFromCacheOrService({
    required String cacheKey,
    required Future<List<LiveStream>> Function() fetchFunction,
  }) async {
    // Check cache first
    if (_cache.containsKey(cacheKey)) {
      final timestamp = _cacheTimestamps[cacheKey];
      if (timestamp != null && 
          DateTime.now().difference(timestamp) < _cacheExpiry) {
        return _cache[cacheKey]!;
      }
    }

    // Fetch from service
    final streams = await fetchFunction();
    
    // Update cache
    _cache[cacheKey] = streams;
    _cacheTimestamps[cacheKey] = DateTime.now();
    
    return streams;
  }

  void _clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  void _clearExpiredCache() {
    final now = DateTime.now();
    _cacheTimestamps.removeWhere((key, timestamp) {
      if (now.difference(timestamp) > _cacheExpiry) {
        _cache.remove(key);
        return true;
      }
      return false;
    });
  }

  // Load Methods
  Future<void> _loadTrendingStreams() async {
    _setLoading(true);
    _clearError();

    try {
      final streams = await _getStreamsFromCacheOrService(
        cacheKey: 'trending_streams',
        fetchFunction: () => _streamService.getTrendingStreams(),
      );
      _trendingStreams = streams;
      notifyListeners();
    } catch (e) {
      LoggerService.error('Load trending streams error: $e', tag: 'STREAM');
      _setError('Failed to load trending streams: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadFollowingStreams({bool refresh = false}) async {
    if (!refresh && _followingStreams.isNotEmpty) return;

    _setLoading(true);
    _clearError();

    try {
      final streams = await _getStreamsFromCacheOrService(
        cacheKey: 'following_streams',
        fetchFunction: () => _streamService.getFollowingStreams(),
      );
      _followingStreams = streams;
      notifyListeners();
    } catch (e) {
      LoggerService.error('Load following streams error: $e', tag: 'STREAM');
      _setError('Failed to load following streams: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadNearbyStreams({bool refresh = false}) async {
    if (!refresh && _nearbyStreams.isNotEmpty) return;

    _setLoading(true);
    _clearError();

    try {
      // Default to San Francisco coordinates for demo
      final streams = await _getStreamsFromCacheOrService(
        cacheKey: 'nearby_streams',
        fetchFunction: () => _streamService.getNearbyStreams(37.7749, -122.4194, 50),
      );
      _nearbyStreams = streams;
      notifyListeners();
    } catch (e) {
      LoggerService.error('Load nearby streams error: $e', tag: 'STREAM');
      _setError('Failed to load nearby streams: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadStreamsByCategory() async {
    _setLoading(true);
    _clearError();

    try {
      final categories = ['Gaming', 'Music', 'Art', 'Education', 'Sports'];
      
      for (final category in categories) {
        final streams = await _getStreamsFromCacheOrService(
          cacheKey: 'category_$category',
          fetchFunction: () => _streamService.getStreamsByCategory(category),
        );
        _streamsByCategory[category] = streams;
      }
      
      notifyListeners();
    } catch (e) {
      LoggerService.error('Load streams by category error: $e', tag: 'STREAM');
      _setError('Failed to load streams by category: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Stream CRUD Operations
  Future<void> loadStreamById(String streamId) async {
    _setLoading(true);
    _clearError();

    try {
      final stream = await _getStreamsFromCacheOrService(
        cacheKey: 'stream_$streamId',
        fetchFunction: () => _streamService.getStreamById(streamId).then((s) => [s!]),
      );
      _currentStream = stream.isNotEmpty ? stream.first : null;
      notifyListeners();
    } catch (e) {
      LoggerService.error('Load stream by ID error: $e', tag: 'STREAM');
      _setError('Failed to load stream: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<LiveStream> createStream(Map<String, dynamic> streamData) async {
    _setLoading(true);
    _clearError();

    try {
      final stream = await _streamService.createStream(streamData);
      _currentStream = stream;
      
      if (stream.status == StreamStatus.live) {
        _isStreaming = true;
      }
      
      // Clear relevant caches
      _clearCache();
      
      // Refresh pagination controllers
      _liveStreamsPagingController.refresh();
      _scheduledStreamsPagingController.refresh();
      
      notifyListeners();
      return stream;
    } catch (e) {
      LoggerService.error('Create stream error: $e', tag: 'STREAM');
      _setError('Failed to create stream: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> startStream(String streamId) async {
    _setLoading(true);
    _clearError();

    try {
      await _streamService.startStream(streamId);
      _isStreaming = true;
      
      if (_currentStream?.id == streamId) {
        _currentStream = _currentStream!.copyWith(
          status: StreamStatus.live,
          startedAt: DateTime.now(),
        );
      }
      
      // Clear and refresh caches
      _clearCache();
      _liveStreamsPagingController.refresh();
      _scheduledStreamsPagingController.refresh();
      
      notifyListeners();
    } catch (e) {
      LoggerService.error('Start stream error: $e', tag: 'STREAM');
      _setError('Failed to start stream: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> endStream(String streamId) async {
    _setLoading(true);
    _clearError();

    try {
      await _streamService.endStream(streamId);
      _isStreaming = false;
      
      if (_currentStream?.id == streamId) {
        _currentStream = _currentStream!.copyWith(
          status: StreamStatus.ended,
          endedAt: DateTime.now(),
        );
      }
      
      // Clear and refresh caches
      _clearCache();
      _liveStreamsPagingController.refresh();
      _scheduledStreamsPagingController.refresh();
      
      notifyListeners();
    } catch (e) {
      LoggerService.error('End stream error: $e', tag: 'STREAM');
      _setError('Failed to end stream: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Stream Interaction Methods
  Future<void> joinStream(String streamId) async {
    try {
      await _streamService.joinStream(streamId);
      await loadStreamById(streamId);
      await loadStreamViewers(streamId);
    } catch (e) {
      LoggerService.error('Join stream error: $e', tag: 'STREAM');
      _setError('Failed to join stream: $e');
    }
  }

  Future<void> leaveStream() async {
    try {
      if (_currentStream?.id != null) {
        await _streamService.leaveStream(_currentStream!.id);
      }
      _currentStream = null;
      _currentViewers.clear();
      _streamStats = null;
      notifyListeners();
    } catch (e) {
      LoggerService.error('Leave stream error: $e', tag: 'STREAM');
      _setError('Failed to leave stream: $e');
    }
  }

  Future<void> loadStreamViewers(String streamId) async {
    try {
      final viewers = await _streamService.getStreamViewers(streamId);
      _currentViewers = viewers;
      notifyListeners();
    } catch (e) {
      debugPrint('Load stream viewers error: $e');
      _setError('Failed to load stream viewers: $e');
    }
  }

  Future<void> loadStreamAnalytics() async {
    if (_currentStream?.id == null) return;

    try {
      final stats = await _streamService.getStreamStats(_currentStream!.id);
      _streamStats = stats;
      notifyListeners();
    } catch (e) {
      debugPrint('Load stream analytics error: $e');
      _setError('Failed to load stream analytics: $e');
    }
  }

  Future<void> loadStreamHistory({bool refresh = false}) async {
    if (!refresh && _streamHistory.isNotEmpty) return;

    try {
      final history = await _getStreamsFromCacheOrService(
        cacheKey: 'stream_history',
        fetchFunction: () => _streamService.getUserStreamHistory(),
      );
      _streamHistory = history;
      notifyListeners();
    } catch (e) {
      debugPrint('Load stream history error: $e');
      _setError('Failed to load stream history: $e');
    }
  }

  // Search and Filter Methods
  void searchStreams(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    _searchPagingController.refresh();
    notifyListeners();
  }

  void selectCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    _liveStreamsPagingController.refresh();
    notifyListeners();
  }

  // Real-time Updates
  Future<void> sendReaction(String streamId, String reactionType) async {
    try {
      await _streamService.sendReaction(streamId, reactionType);
      
      // Update local stream data
      if (_currentStream?.id == streamId) {
        // This would typically be handled by real-time subscriptions
        await loadStreamById(streamId);
      }
    } catch (e) {
      debugPrint('Send reaction error: $e');
      _setError('Failed to send reaction: $e');
    }
  }

  Future<void> updateStream(String streamId, Map<String, dynamic> data) async {
    _setLoading(true);
    _clearError();

    try {
      final updatedStream = await _streamService.updateStream(streamId, data);
      
      if (_currentStream?.id == streamId) {
        _currentStream = updatedStream;
      }
      
      // Update in cached lists
      _updateStreamInLists(updatedStream);
      
      // Clear relevant caches
      _clearCache();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Update stream error: $e');
      _setError('Failed to update stream: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Refresh Methods
  Future<void> refreshAll() async {
    _clearCache();
    await Future.wait([
      _loadTrendingStreams(),
      _loadStreamsByCategory(),
    ]);
    
    _liveStreamsPagingController.refresh();
    _scheduledStreamsPagingController.refresh();
    _searchPagingController.refresh();
  }

  Future<void> refreshLiveStreams() async {
    _clearCache();
    _liveStreamsPagingController.refresh();
  }

  Future<void> refreshScheduledStreams() async {
    _clearCache();
    _scheduledStreamsPagingController.refresh();
  }

  // Private Helper Methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void _updateStreamInLists(LiveStream updatedStream) {
    // Update in trending streams
    final trendingIndex = _trendingStreams.indexWhere((s) => s.id == updatedStream.id);
    if (trendingIndex != -1) {
      _trendingStreams[trendingIndex] = updatedStream;
    }

    // Update in following streams
    final followingIndex = _followingStreams.indexWhere((s) => s.id == updatedStream.id);
    if (followingIndex != -1) {
      _followingStreams[followingIndex] = updatedStream;
    }

    // Update in nearby streams
    final nearbyIndex = _nearbyStreams.indexWhere((s) => s.id == updatedStream.id);
    if (nearbyIndex != -1) {
      _nearbyStreams[nearbyIndex] = updatedStream;
    }

    // Update in category streams
    _streamsByCategory.forEach((category, streams) {
      final categoryIndex = streams.indexWhere((s) => s.id == updatedStream.id);
      if (categoryIndex != -1) {
        streams[categoryIndex] = updatedStream;
      }
    });
  }

  // Cleanup
  void clearAll() {
    _clearCache();
    _trendingStreams.clear();
    _followingStreams.clear();
    _nearbyStreams.clear();
    _streamsByCategory.clear();
    _streamHistory.clear();
    _currentStream = null;
    _currentViewers.clear();
    _streamStats = null;
    _isStreaming = false;
    _searchQuery = '';
    _selectedCategory = 'all';
    _error = null;
    
    // Reset pagination controllers
    _liveStreamsPagingController.refresh();
    _scheduledStreamsPagingController.refresh();
    _searchPagingController.refresh();
    
    notifyListeners();
  }

  @override
  void dispose() {
    _liveStreamsPagingController.dispose();
    _scheduledStreamsPagingController.dispose();
    _searchPagingController.dispose();
    super.dispose();
  }
}
