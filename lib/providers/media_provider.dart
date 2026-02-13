import '../models/media_item.dart';
export '../models/media_item.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class MediaProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final PagingController<int, MediaItem> _pagingController =
      PagingController(firstPageKey: 0);

  static const int _pageSize = 20;
  DocumentSnapshot? _lastDocument;

  List<MediaItem> _trendingMedia = [];
  List<MediaItem> _searchResults = [];
  List<String> _categories = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'all';
  String? _error;

  PagingController<int, MediaItem> get pagingController => _pagingController;
  List<MediaItem> get trendingMedia => _trendingMedia;
  List<MediaItem> get searchResults => _searchResults;
  List<MediaItem> get mediaItems => _searchQuery.isEmpty ? _trendingMedia : _searchResults;

  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String? get error => _error;

  MediaProvider() {
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    _loadCategories();
    _loadTrendingMedia();
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newItems = await _getMediaFromFirestore(
        limit: _pageSize,
        category: _selectedCategory,
        startAfter: pageKey == 0 ? null : _lastDocument,
      );

      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        _pagingController.appendPage(newItems, pageKey + 1);
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  Future<List<MediaItem>> _getMediaFromFirestore({
    required int limit,
    String? category,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _firestore.collection('media').orderBy('createdAt', descending: true);

    if (category != null && category != 'all') {
      query = query.where('category', isEqualTo: category);
    }

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final querySnapshot = await query.limit(limit).get();
    
    if (querySnapshot.docs.isNotEmpty) {
      _lastDocument = querySnapshot.docs.last;
      return querySnapshot.docs.map((doc) => MediaItem.fromFirestore(doc)).toList();
    }
    return [];
  }

  Future<void> loadMoreMedia({int page = 1, int limit = 20}) async {
    // Pagination handled by PagingController
    // This method is kept for compatibility with LazyLoadMediaGrid
    if (!_isLoading) {
       // Ideally we would trigger loading next page here if manual control is needed
    }
  }

  Future<void> _loadCategories() async {
    _categories = [
      'all',
      'trending',
      'popular',
      'new',
      'hot',
      'top_rated',
      'most_viewed',
    ];
    notifyListeners();
  }

  Future<void> _loadTrendingMedia() async {
    _isLoading = true;
    notifyListeners();

    try {
      final snapshot = await _firestore
          .collection('media')
          .orderBy('likesCount', descending: true)
          .limit(10)
          .get();
      
      _trendingMedia = snapshot.docs.map((doc) => MediaItem.fromFirestore(doc)).toList();
    } catch (error) {
      debugPrint('Load trending media error: $error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchMedia({
    required String query,
    String? category,
    String? sortBy,
    List<String>? tags,
  }) async {
    _searchQuery = query;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (query.trim().isEmpty) {
        _searchResults.clear();
      } else {
        // Simple search by title (Note: Firestore doesn't support full-text search natively)
        // For production, use Algolia or similar. Here we implement a basic prefix search.
        final snapshot = await _firestore
            .collection('media')
            .where('title', isGreaterThanOrEqualTo: query)
            .where('title', isLessThan: '${query}z')
            .limit(20)
            .get();

        _searchResults = snapshot.docs.map((doc) => MediaItem.fromFirestore(doc)).toList();
      }
    } catch (error) {
      debugPrint('Search media error: $error');
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectCategory(String category) {
    _selectedCategory = category;
    _pagingController.refresh();
    _lastDocument = null; // Reset cursor
    notifyListeners();
  }

  Future<void> refreshMedia() async {
    _lastDocument = null;
    _pagingController.refresh();
    await _loadTrendingMedia();
  }

  Future<void> loadMedia({int page = 1, int limit = 20, String? category}) async {
    // Legacy support for manual pagination calls
    if (page == 1) {
      _pagingController.refresh();
    }
  }
}
