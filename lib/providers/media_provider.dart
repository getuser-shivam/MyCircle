import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/media_item.dart';
import '../repositories/media_repository.dart';
import '../services/supabase_service.dart';
import 'package:flutter/foundation.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class MediaProvider extends ChangeNotifier {
  final MediaRepository _mediaRepository;
  
  // Separate controllers for different feeds to avoid collisions
  final PagingController<int, MediaItem> _latestPagingController =
      PagingController(firstPageKey: 0);
  final PagingController<int, MediaItem> _trendingPagingController =
      PagingController(firstPageKey: 0);
  final PagingController<int, MediaItem> _searchPagingController =
      PagingController(firstPageKey: 0);

  static const int _pageSize = 20;

  // State
  List<MediaItem> _trendingMedia = [];
  List<String> _categories = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'all';
  String? _error;

  MediaProvider() : _mediaRepository = MediaRepository(SupabaseService.instance);

  // Getters
  List<MediaItem> get trendingMedia => _trendingMedia;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String? get error => _error;
  PagingController<int, MediaItem> get pagingController => 
      _searchQuery.isEmpty ? _latestPagingController : _searchPagingController;
  PagingController<int, MediaItem> get trendingPagingController => _trendingPagingController;

  Future<void> loadTrendingMedia() async {
    try {
      _setLoading(true);
      _clearError();
      
      final media = await _mediaRepository.fetchMedia(
        limit: _pageSize,
        category: _selectedCategory == 'all' ? null : _selectedCategory,
      );
      
      _trendingMedia = media;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load trending media: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadCategories() async {
    try {
      _setLoading(true);
      _clearError();
      
      final categories = await _mediaRepository.getCategories();
      _categories = ['all', ...categories];
      notifyListeners();
    } catch (e) {
      _setError('Failed to load categories: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> searchMedia(String query) async {
    try {
      _setLoading(true);
      _clearError();
      _searchQuery = query;
      
      if (query.isEmpty) {
        _searchPagingController.itemList.clear();
        notifyListeners();
        return;
      }
      
      final media = await _mediaRepository.fetchMedia(
        limit: _pageSize,
        query: query,
      );
      
      _searchPagingController.itemList.clear();
      _searchPagingController.appendPage(media);
      notifyListeners();
    } catch (e) {
      _setError('Failed to search media: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMoreMedia() async {
    try {
      _setLoading(true);
      _clearError();
      
      final controller = _searchQuery.isEmpty ? _latestPagingController : _searchPagingController;
      
      if (!controller.canLoadNextPage) return;
      
      final nextPageKey = controller.nextPageKey + 1;
      final media = await _mediaRepository.fetchMedia(
        limit: _pageSize,
        offset: nextPageKey * _pageSize,
        category: _selectedCategory == 'all' ? null : _selectedCategory,
        query: _searchQuery.isEmpty ? null : _searchQuery,
      );
      
      controller.appendPage(media);
      notifyListeners();
    } catch (e) {
      _setError('Failed to load more media: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshMedia() async {
    try {
      _setLoading(true);
      _clearError();
      
      if (_searchQuery.isEmpty) {
        await loadTrendingMedia();
      } else {
        await searchMedia(_searchQuery);
      }
    } catch (e) {
      _setError('Failed to refresh media: $e');
    } finally {
      _setLoading(false);
    }
  }

  void setCategory(String category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      _trendingMedia.clear();
      _latestPagingController.refresh();
      notifyListeners();
      loadTrendingMedia();
    }
  }

  void clearSearch() {
    _searchQuery = '';
    _searchPagingController.itemList.clear();
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }
}
