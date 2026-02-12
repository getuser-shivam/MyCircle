import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class Notification {
  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;

  Notification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.data,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? json['message'] ?? '',
      body: json['body'] ?? json['message'] ?? '',
      type: json['type'] ?? 'info',
      timestamp: DateTime.parse(json['createdAt'] ?? json['timestamp'] ?? DateTime.now().toIso8601String()),
      isRead: json['read'] ?? json['isRead'] ?? false,
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'data': data,
    };
  }
}

class NotificationProvider extends ChangeNotifier {
  List<Notification> _notifications = [];
  bool _isOnline = true;
  int _unreadCount = 0;
  bool _isLoading = false;

  List<Notification> get notifications => _notifications;
  bool get isOnline => _isOnline;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  NotificationProvider() {
    fetchNotifications();
    _checkConnectivity();
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      _isOnline = result != ConnectivityResult.none;
      notifyListeners();
    });
  }

  Future<void> fetchNotifications({String? token}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/notifications'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success']) {
          final List<dynamic> notificationsJson = data['data']['notifications'];
          _notifications = notificationsJson
              .map((json) => Notification.fromJson(json))
              .toList();
          _unreadCount = data['data']['unreadCount'];
        }
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadNotifications() async {
    // Keep local storage as a fallback or cache
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = prefs.getStringList('notifications') ?? [];
      
      if (_notifications.isEmpty) {
        _notifications = notificationsJson
            .map((json) => Notification.fromJson(Map<String, dynamic>.from(
                  jsonDecode(json) as Map
                )))
            .toList();
        _updateUnreadCount();
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    }
  }

  Future<void> _saveNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notificationsJson = _notifications
          .map((notification) => jsonEncode(notification.toJson()))
          .toList();
      
      await prefs.setStringList('notifications', notificationsJson.cast<String>());
    } catch (e) {
      debugPrint('Error saving notifications: $e');
    }
  }

  Future<void> _checkConnectivity() async {
    try {
      final result = await Connectivity().checkConnectivity();
      _isOnline = result != ConnectivityResult.none;
      notifyListeners();
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
    }
  }

  void addNotification({
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? data,
  }) {
    final notification = Notification(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      body: body,
      type: type,
      timestamp: DateTime.now(),
      data: data,
    );

    _notifications.insert(0, notification);
    _updateUnreadCount();
    _saveNotifications();
    notifyListeners();

    // Show in-app notification
    _showInAppNotification(notification);
  }

  Future<void> markAsRead(String notificationId, {String? token}) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      try {
        final response = await http.put(
          Uri.parse('${AppConfig.baseUrl}/notifications/$notificationId/read'),
          headers: {
            'Content-Type': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          _notifications[index] = Notification(
            id: _notifications[index].id,
            title: _notifications[index].title,
            body: _notifications[index].body,
            type: _notifications[index].type,
            timestamp: _notifications[index].timestamp,
            isRead: true,
            data: _notifications[index].data,
          );
          
          _updateUnreadCount();
          _saveNotifications();
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Error marking as read: $e');
      }
    }
  }

  Future<void> markAllAsRead({String? token}) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/notifications/read-all'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        _notifications = _notifications.map((notification) => Notification(
          id: notification.id,
          title: notification.title,
          body: notification.body,
          type: notification.type,
          timestamp: notification.timestamp,
          isRead: true,
          data: notification.data,
        )).toList();
        
        _unreadCount = 0;
        _saveNotifications();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking all as read: $e');
    }
  }

  void clearNotifications() {
    _notifications.clear();
    _unreadCount = 0;
    _saveNotifications();
    notifyListeners();
  }

  void deleteNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
    _updateUnreadCount();
    _saveNotifications();
    notifyListeners();
  }

  void _updateUnreadCount() {
    _unreadCount = _notifications.where((n) => !n.isRead).length;
  }

  void _showInAppNotification(Notification notification) {
    // This would integrate with a snackbar or custom notification widget
    debugPrint('New notification: ${notification.title} - ${notification.body}');
  }

  // Simulate receiving real-time notifications
  void simulateRealtimeNotification() {
    final notifications = [
      {
        'title': 'New Like!',
        'body': 'Someone liked your content',
        'type': 'like',
      },
      {
        'title': 'New Follower!',
        'body': 'Someone started following you',
        'type': 'follow',
      },
      {
        'title': 'Trending Content!',
        'body': 'Your content is trending',
        'type': 'trending',
      },
      {
        'title': 'New Comment',
        'body': 'Someone commented on your content',
        'type': 'comment',
      },
    ];

    final randomNotification = notifications[
        DateTime.now().millisecondsSinceEpoch % notifications.length];

    addNotification(
      title: randomNotification['title']!,
      body: randomNotification['body']!,
      type: randomNotification['type']!,
    );
  }
}
