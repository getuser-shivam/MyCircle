import '../models/media_item.dart';
export '../models/media_item.dart';
import '../config/app_config.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';



class MediaProvider extends ChangeNotifier {
  final String baseUrl = AppConfig.baseUrl;
  final PagingController<int, MediaItem> _pagingController =
      PagingController(firstPageKey: 1);

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
  set mediaItems(List<MediaItem> value) {
    if (_searchQuery.isEmpty) {
      _trendingMedia = value;
    } else {
      _searchResults = value;
    }
    notifyListeners();
  }

  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  set error(String? value) {
    _error = value;
    notifyListeners();
  }

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
      _error = null;
      await _loadMediaFeed(page: pageKey, category: _selectedCategory);
    } catch (error) {
      _error = error.toString();
      _pagingController.error = error;
    }
  }

  Future<void> loadMedia({int page = 1, int limit = 20, String? category}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _loadMediaFeed(page: page, limit: limit, category: category ?? _selectedCategory);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreMedia({int page = 1, int limit = 20}) async {
    await _loadMediaFeed(page: page, limit: limit, category: _selectedCategory);
  }

  Future<void> _loadMediaFeed({
    int page = 1,
    int limit = 20,
    String? category,
    String? type,
    String? sort,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (category != null && category != 'all') 'category': category,
        if (type != null && type != 'all') 'type': type,
        if (sort != null) 'sort': sort,
      };

      final uri = Uri.parse('$baseUrl/media/feed').replace(queryParameters: queryParams);

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final mediaList = (data['data']['media'] as List)
              .map((item) => MediaItem.fromJson(item))
              .toList();

          if (page == 1) {
            if (_searchQuery.isEmpty) {
              _trendingMedia = mediaList;
            } else {
              _searchResults = mediaList;
            }
          } else {
            if (_searchQuery.isEmpty) {
              _trendingMedia.addAll(mediaList);
            } else {
              _searchResults.addAll(mediaList);
            }
          }

          final isLastPage = mediaList.length < limit;
          if (isLastPage) {
            _pagingController.appendLastPage(mediaList);
          } else {
            _pagingController.appendPage(mediaList, page + 1);
          }
        }
      } else {
        throw Exception('Failed to load media feed');
      }
    } catch (error) {
      debugPrint('Load media feed error: $error');
      _pagingController.error = error;
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
      await _loadMediaFeed(limit: 10, sort: 'trending');
      // For now, we'll use the same data as the feed
      // In a real app, you'd have a separate trending endpoint
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
      if (query.trim().isEmpty && (tags == null || tags.isEmpty)) {
        _searchResults.clear();
      } else {
        final queryParams = {
          'q': query.trim(),
          if (category != null && category != 'all') 'category': category,
          if (sortBy != null) 'sort': sortBy,
          if (tags != null && tags.isNotEmpty) 'tags': tags.join(','),
          'limit': '20',
        };

        final uri = Uri.parse('$baseUrl/media/search').replace(queryParameters: queryParams);

        final response = await http.get(uri);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success']) {
            _searchResults = (data['data']['media'] as List)
                .map((item) => MediaItem.fromJson(item))
                .toList();
          }
        } else {
          throw Exception('Failed to search media');
        }
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
    notifyListeners();
  }

  Future<void> refreshMedia() async {
    _pagingController.refresh();
    await _loadTrendingMedia();
  }

  Future<void> likeMedia(String mediaId, String? token) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/media/$mediaId/like'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          // Update local data if needed
          notifyListeners();
        }
      }
    } catch (error) {
      debugPrint('Like media error: $error');
    }
  }

  void shareMedia(MediaItem media) {
    // Implement share functionality
    debugPrint('Sharing media: ${media.title}');
  }

  Future<void> reportMedia(String mediaId, String reason, String? token) async {
    try {
      final headers = {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await http.post(
        Uri.parse('$baseUrl/media/$mediaId/report'),
        headers: headers,
        body: jsonEncode({
          'reason': reason,
          'description': '',
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Media reported successfully');
      }
    } catch (error) {
      debugPrint('Report media error: $error');
    }
  }

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}
