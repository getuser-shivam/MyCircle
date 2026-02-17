import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/media_item.dart';
import '../services/media_service.dart';
import 'package:flutter/foundation.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class MediaProvider extends ChangeNotifier {
  final MediaService _mediaService = MediaService();
  
  // Separate controllers for different feeds to avoid collisions
  final PagingController<int, MediaItem> _latestPagingController =
      PagingController(firstPageKey: 0);
  final PagingController<int, MediaItem> _trendingPagingController =
      PagingController(firstPageKey: 0);
  final PagingController<int, MediaItem> _searchPagingController =
      PagingController(firstPageKey: 0);

  static const int _pageSize = 20;

  List<MediaItem> _trendingMedia = [];
  List<String> _categories = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'all';
  String? _error;

  PagingController<int, MediaItem> get pagingController => _searchQuery.isEmpty ? _latestPagingController : _searchPagingController;
  PagingController<int, MediaItem> get trendingPagingController => _trendingPagingController;
  
  List<MediaItem> get trendingMedia => _trendingMedia;
  List<String> get categories => _categories;
  List<MediaItem> get searchResults => _searchPagingController.itemList ?? [];
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String? get error => _error;

  MediaProvider() {
    _latestPagingController.addPageRequestListener((pageKey) {
      _fetchPage(_latestPagingController, pageKey, category: _selectedCategory);
    });
    
    _searchPagingController.addPageRequestListener((pageKey) {
      _fetchPage(_searchPagingController, pageKey, query: _searchQuery);
    });

    _loadCategories();
    _loadTrendingMedia();
  }

  Future<void> _fetchPage(PagingController<int, MediaItem> controller, int pageKey, {String? category, String? query}) async {
    try {
      final newItems = await _mediaService.fetchMedia(
        limit: _pageSize,
        category: category,
        query: query,
        offset: pageKey,
      );

      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        controller.appendLastPage(newItems);
      } else {
        controller.appendPage(newItems, pageKey + newItems.length);
      }
    } catch (error) {
      controller.error = error;
    }
  }

  Future<void> _loadCategories() async {
    _categories = await _mediaService.fetchCategories();
    notifyListeners();
  }

  Future<void> _loadTrendingMedia() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _trendingMedia = await _mediaService.fetchTrendingMedia();
    } catch (e) {
      _error = e.toString();
      debugPrint('Load trending media error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void searchMedia(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    _searchPagingController.refresh();
    notifyListeners();
  }

  void selectCategory(String category) {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    _latestPagingController.refresh();
    notifyListeners();
  }

  Future<void> refreshMedia() async {
    _latestPagingController.refresh();
    _searchPagingController.refresh();
    await _loadTrendingMedia();
  }

  @override
  void dispose() {
    _latestPagingController.dispose();
    _trendingPagingController.dispose();
    _searchPagingController.dispose();
    super.dispose();
  }
}

