import '../providers/media_provider.dart';
import '../models/media_item.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';



class MediaCacheManager {
  static final Map<String, dynamic> _cache = {};
  static final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheExpiry = Duration(minutes: 5);

  static T? get<T>(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp == null || DateTime.now().difference(timestamp) > _cacheExpiry) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
      return null;
    }
    return _cache[key] as T?;
  }

  static void set(String key, dynamic value) {
    _cache[key] = value;
    _cacheTimestamps[key] = DateTime.now();
  }

  static void clear() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  static void remove(String key) {
    _cache.remove(key);
    _cacheTimestamps.remove(key);
  }
}

class OptimizedMediaProvider extends MediaProvider {
  final Map<String, List<dynamic>> _categoryCache = {};
  final Map<String, DateTime> _categoryTimestamps = {};
  static const Duration _categoryCacheExpiry = Duration(minutes: 3);

  @override
  Future<void> loadMedia({int page = 1, int limit = 20, String? category}) async {
    final cacheKey = category ?? 'all';
    final timestamp = _categoryTimestamps[cacheKey];
    
    if (page == 1 &&
        timestamp != null && 
        DateTime.now().difference(timestamp) < _categoryCacheExpiry &&
        _categoryCache[cacheKey] != null) {
      
      mediaItems = List<MediaItem>.from(_categoryCache[cacheKey]!);
      isLoading = false;
      error = null;
      notifyListeners();
      return;
    }

    await super.loadMedia(page: page, limit: limit, category: category);
    
    if (page == 1 && error == null) {
      _categoryCache[cacheKey] = List<MediaItem>.from(mediaItems);
      _categoryTimestamps[cacheKey] = DateTime.now();
    }
  }

  @override
  Future<void> refreshMedia() async {
    MediaCacheManager.clear();
    _categoryCache.clear();
    _categoryTimestamps.clear();
    await super.refreshMedia();
  }

  void clearCache() {
    MediaCacheManager.clear();
    _categoryCache.clear();
    _categoryTimestamps.clear();
  }
}
