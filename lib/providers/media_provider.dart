import '../models/media_item.dart';
import '../config/app_config.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

<<<<<<< HEAD
class MediaItem {
  final String id;
  final String title;
  final String url;
  final String thumbnailUrl;
  final String userName;
  final String userAvatar;
  final int views;
  final int likes;
  final int duration;
  final List<String> tags;
  final bool isVerified;
  final DateTime createdAt;
  final MediaType type;
  final String category;
  final bool isPrivate;
  final bool isApproved;
  final Map<String, dynamic> author;

  MediaItem({
    required this.id,
    required this.title,
    required this.url,
    required this.thumbnailUrl,
    required this.userName,
    required this.userAvatar,
    this.views = 0,
    this.likes = 0,
    this.duration = 0,
    this.tags = const [],
    this.isVerified = false,
    required this.createdAt,
    this.type = MediaType.gif,
    this.category = 'general',
    this.isPrivate = false,
    this.isApproved = false,
    this.author = const {},
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    final author = json['author'] ?? {};
    return MediaItem(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      url: json['fileUrl'] ?? json['url'] ?? '',
      thumbnailUrl: json['thumbnailUrl'] ?? '',
      userName: author['username'] ?? '',
      userAvatar: author['avatar'] ?? '',
      views: json['stats']?['views'] ?? json['views'] ?? 0,
      likes: json['stats']?['likes'] ?? json['likes'] ?? 0,
      duration: json['duration'] ?? 0,
      tags: List<String>.from(json['tags'] ?? []),
      isVerified: author['isVerified'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      type: _parseMediaType(json['type']),
      category: json['category'] ?? 'general',
      isPrivate: json['isPrivate'] ?? false,
      isApproved: json['isApproved'] ?? false,
      author: author,
    );
  }

  static MediaType _parseMediaType(String? type) {
    switch (type) {
      case 'video':
        return MediaType.video;
      case 'image':
        return MediaType.image;
      case 'gif':
      default:
        return MediaType.gif;
    }
  }
}

enum MediaType {
  gif,
  video,
  image,
}
=======

>>>>>>> a7119c3 (WIP: Final Reorganized State)

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

  PagingController<int, MediaItem> get pagingController => _pagingController;
  List<MediaItem> get trendingMedia => _trendingMedia;
  List<MediaItem> get searchResults => _searchResults;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  MediaProvider() {
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    _loadCategories();
    _loadTrendingMedia();
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      await _loadMediaFeed(page: pageKey, category: _selectedCategory);
    } catch (error) {
      _pagingController.error = error;
    }
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

  Future<void> searchMedia(String query) async {
    _searchQuery = query;
    _isLoading = true;
    notifyListeners();

    try {
      if (query.trim().isEmpty) {
        _searchResults.clear();
      } else {
        final uri = Uri.parse('$baseUrl/media/search').replace(queryParameters: {
          'q': query.trim(),
          'limit': '20',
        });

        final response = await http.get(uri);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['success']) {
            _searchResults = (data['data']['media'] as List)
                .map((item) => MediaItem.fromJson(item))
                .toList();
          }
        }
      }
    } catch (error) {
      debugPrint('Search media error: $error');
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
