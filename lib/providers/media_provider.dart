import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../models/media_item.dart';
import '../repositories/media_repository.dart';
import '../services/supabase_service.dart';
import '../core/errors/app_exceptions.dart';

class MediaProvider extends ChangeNotifier {
  final MediaRepository _repository;
  
  // State
  List<MediaItem> _mediaItems = [];
  List<MediaItem> _trendingMedia = [];
  List<MediaItem> _userMedia = [];
  List<String> _categories = [];
  
  // Loading states
  bool _isLoading = false;
  bool _isLoadingTrending = false;
  bool _isLoadingUser = false;
  bool _isSearching = false;
  
  // Pagination
  int _currentPage = 1;
  int _trendingPage = 1;
  int _userPage = 1;
  bool _hasMoreMedia = true;
  bool _hasMoreTrending = true;
  bool _hasMoreUser = true;
  
  // Error handling
  String? _error;
  String? _searchError;
  
  // Search state
  String _searchQuery = '';
  List<String> _selectedCategories = [];

  MediaProvider() : _repository = MediaRepository(SupabaseService.instance);

  // Getters
  List<MediaItem> get mediaItems => _mediaItems;
  List<MediaItem> get trendingMedia => _trendingMedia;
  List<MediaItem> get userMedia => _userMedia;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get isLoadingTrending => _isLoadingTrending;
  bool get isLoadingUser => _isLoadingUser;
  bool get isSearching => _isSearching;
  bool get hasMoreMedia => _hasMoreMedia;
  bool get hasMoreTrending => _hasMoreTrending;
  bool get hasMoreUser => _hasMoreUser;
  String? get error => _error;
  String? get searchError => _searchError;
  String get searchQuery => _searchQuery;
  List<String> get selectedCategories => _selectedCategories;

  Future<void> fetchMedia({int page = 1, int limit = 20}) async {
    try {
      _setLoading(true);
      _clearError();
      
      final media = await _repository.getMedia(
        page: page,
        limit: limit,
        categories: _selectedCategories,
      );
      
      if (page == 1) {
        _mediaItems = media;
      } else {
        _mediaItems.addAll(media);
      }
      
      _currentPage = page;
      _hasMoreMedia = media.length >= limit;
      notifyListeners();
    } on MediaException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Failed to fetch media');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchTrendingMedia({int page = 1, int limit = 20}) async {
    try {
      _setLoadingTrending(true);
      _clearError();
      
      final trending = await _repository.getTrendingMedia(
        page: page,
        limit: limit,
      );
      
      if (page == 1) {
        _trendingMedia = trending;
      } else {
        _trendingMedia.addAll(trending);
      }
      
      _trendingPage = page;
      _hasMoreTrending = trending.length >= limit;
      notifyListeners();
    } on MediaException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Failed to fetch trending media');
    } finally {
      _setLoadingTrending(false);
    }
  }

  Future<void> fetchUserMedia(String userId, {int page = 1, int limit = 20}) async {
    try {
      _setLoadingUser(true);
      _clearError();
      
      final media = await _repository.getUserMedia(
        userId: userId,
        page: page,
        limit: limit,
      );
      
      if (page == 1) {
        _userMedia = media;
      } else {
        _userMedia.addAll(media);
      }
      
      _userPage = page;
      _hasMoreUser = media.length >= limit;
      notifyListeners();
    } on MediaException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Failed to fetch user media');
    } finally {
      _setLoadingUser(false);
    }
  }

  Future<void> fetchCategories() async {
    try {
      _clearError();
      
      final categories = await _repository.getCategories();
      _categories = categories;
      notifyListeners();
    } on MediaException catch (e) {
      _setError(e.message);
    } catch (e) {
      _setError('Failed to fetch categories');
    }
  }

  Future<void> searchMedia(String query, {int page = 1, int limit = 20}) async {
    try {
      _setSearching(true);
      _clearSearchError();
      _searchQuery = query;
      
      final results = await _repository.searchMedia(
        query: query,
        page: page,
        limit: limit,
        categories: _selectedCategories,
      );
      
      if (page == 1) {
        _mediaItems = results;
      } else {
        _mediaItems.addAll(results);
      }
      
      _currentPage = page;
      _hasMoreMedia = results.length >= limit;
      notifyListeners();
    } on MediaException catch (e) {
      _setSearchError(e.message);
    } catch (e) {
      _setSearchError('Failed to search media');
    } finally {
      _setSearching(false);
    }
  }

  Future<void> refreshMedia() async {
    _currentPage = 1;
    _hasMoreMedia = true;
    await fetchMedia();
  }

  Future<void> refreshTrendingMedia() async {
    _trendingPage = 1;
    _hasMoreTrending = true;
    await fetchTrendingMedia();
  }

  Future<void> refreshUserMedia(String userId) async {
    _userPage = 1;
    _hasMoreUser = true;
    await fetchUserMedia(userId);
  }

  void toggleCategory(String category) {
    if (_selectedCategories.contains(category)) {
      _selectedCategories.remove(category);
    } else {
      _selectedCategories.add(category);
    }
    notifyListeners();
  }

  void clearCategories() {
    _selectedCategories.clear();
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    _clearSearchError();
    notifyListeners();
  }

  Future<void> loadMoreMedia() async {
    if (!_hasMoreMedia || _isLoading) return;
    await fetchMedia(page: _currentPage + 1);
  }

  Future<void> loadMoreTrendingMedia() async {
    if (!_hasMoreTrending || _isLoadingTrending) return;
    await fetchTrendingMedia(page: _trendingPage + 1);
  }

  Future<void> loadMoreUserMedia(String userId) async {
    if (!_hasMoreUser || _isLoadingUser) return;
    await fetchUserMedia(userId, page: _userPage + 1);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setLoadingTrending(bool loading) {
    _isLoadingTrending = loading;
    notifyListeners();
  }

  void _setLoadingUser(bool loading) {
    _isLoadingUser = loading;
    notifyListeners();
  }

  void _setSearching(bool searching) {
    _isSearching = searching;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void _setSearchError(String? error) {
    _searchError = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void _clearSearchError() {
    _searchError = null;
    notifyListeners();
  }
}
