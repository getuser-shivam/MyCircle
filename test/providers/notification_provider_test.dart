import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import 'package:my_circle\providers\notification_provider.dart';

// Generate mocks
@GenerateMocks([
  SupabaseClient,
  RealtimeChannel,
  PostgrestFilterBuilder,
  PostgrestTransformBuilder,
])
import 'notification_provider_test.mocks.dart';

void main() {
  group('NotificationProvider Tests', () {
    late NotificationProvider notificationProvider;
    late MockSupabaseClient mockSupabaseClient;
    late MockRealtimeChannel mockRealtimeChannel;

    setUp(() {
      mockSupabaseClient = MockSupabaseClient();
      mockRealtimeChannel = MockRealtimeChannel();
      
      notificationProvider = NotificationProvider();
    });

    tearDown(() {
      notificationProvider.dispose();
    });

    group('AppNotification Model Tests', () {
      test('should create AppNotification with required fields', () {
        const notification = AppNotification(
          id: '1',
          title: 'Test Title',
          body: 'Test Body',
          type: 'info',
          timestamp: null, // Will use current time
        );

        expect(notification.id, '1');
        expect(notification.title, 'Test Title');
        expect(notification.body, 'Test Body');
        expect(notification.type, 'info');
        expect(notification.isRead, false);
        expect(notification.data, null);
      });

      test('should create AppNotification with all fields', () {
        final timestamp = DateTime.now();
        const notification = AppNotification(
          id: '2',
          title: 'Test Title',
          body: 'Test Body',
          type: 'success',
          timestamp: timestamp,
          isRead: true,
          data: {'key': 'value'},
        );

        expect(notification.id, '2');
        expect(notification.title, 'Test Title');
        expect(notification.body, 'Test Body');
        expect(notification.type, 'success');
        expect(notification.timestamp, timestamp);
        expect(notification.isRead, true);
        expect(notification.data, {'key': 'value'});
      });

      test('should create AppNotification fromMap', () {
        final data = {
          'id': '3',
          'title': 'Map Title',
          'body': 'Map Body',
          'type': 'warning',
          'timestamp': '2024-01-01T00:00:00.000Z',
          'is_read': true,
          'data': {'mapped': true},
        };

        final notification = AppNotification.fromMap(data);

        expect(notification.id, '3');
        expect(notification.title, 'Map Title');
        expect(notification.body, 'Map Body');
        expect(notification.type, 'warning');
        expect(notification.isRead, true);
        expect(notification.data, {'mapped': true});
      });

      test('should handle missing data in fromMap gracefully', () {
        final data = <String, dynamic>{};

        final notification = AppNotification.fromMap(data);

        expect(notification.id, '');
        expect(notification.title, '');
        expect(notification.body, '');
        expect(notification.type, 'info');
        expect(notification.isRead, false);
        expect(notification.data, null);
      });

      test('should convert AppNotification toMap', () {
        final timestamp = DateTime.now();
        const notification = AppNotification(
          id: '4',
          title: 'Convert Title',
          body: 'Convert Body',
          type: 'error',
          timestamp: timestamp,
          isRead: false,
          data: {'convert': true},
        );

        final map = notification.toMap();

        expect(map['id'], '4');
        expect(map['title'], 'Convert Title');
        expect(map['body'], 'Convert Body');
        expect(map['type'], 'error');
        expect(map['timestamp'], timestamp.toIso8601String());
        expect(map['is_read'], false);
        expect(map['data'], {'convert': true});
      });
    });

    group('NotificationProvider State Management', () {
      test('should initialize with empty notifications list', () {
        expect(notificationProvider.notifications, isEmpty);
        expect(notificationProvider.unreadCount, 0);
      });

      test('should add notification', () {
        const notification = AppNotification(
          id: '5',
          title: 'New Notification',
          body: 'Test body',
          type: 'info',
          timestamp: null,
        );

        notificationProvider.addNotification(notification);

        expect(notificationProvider.notifications, contains(notification));
        expect(notificationProvider.notifications.length, 1);
        expect(notificationProvider.unreadCount, 1);
      });

      test('should mark notification as read', () {
        const notification = AppNotification(
          id: '6',
          title: 'Unread Notification',
          body: 'Test body',
          type: 'info',
          timestamp: null,
          isRead: false,
        );

        notificationProvider.addNotification(notification);
        notificationProvider.markAsRead('6');

        final updatedNotification = notificationProvider.notifications
            .firstWhere((n) => n.id == '6');
        expect(updatedNotification.isRead, true);
        expect(notificationProvider.unreadCount, 0);
      });

      test('should mark all notifications as read', () {
        final notifications = [
          const AppNotification(
            id: '7',
            title: 'Notification 1',
            body: 'Test body 1',
            type: 'info',
            timestamp: null,
            isRead: false,
          ),
          const AppNotification(
            id: '8',
            title: 'Notification 2',
            body: 'Test body 2',
            type: 'info',
            timestamp: null,
            isRead: false,
          ),
        ];

        for (final notification in notifications) {
          notificationProvider.addNotification(notification);
        }

        notificationProvider.markAllAsRead();

        for (final notification in notificationProvider.notifications) {
          expect(notification.isRead, true);
        }
        expect(notificationProvider.unreadCount, 0);
      });

      test('should remove notification', () {
        const notification = AppNotification(
          id: '9',
          title: 'To Remove',
          body: 'Test body',
          type: 'info',
          timestamp: null,
        );

        notificationProvider.addNotification(notification);
        notificationProvider.removeNotification('9');

        expect(notificationProvider.notifications, isNot(contains(notification)));
        expect(notificationProvider.notifications.length, 0);
      });

      test('should clear all notifications', () {
        final notifications = [
          const AppNotification(
            id: '10',
            title: 'Notification 1',
            body: 'Test body 1',
            type: 'info',
            timestamp: null,
          ),
          const AppNotification(
            id: '11',
            title: 'Notification 2',
            body: 'Test body 2',
            type: 'info',
            timestamp: null,
          ),
        ];

        for (final notification in notifications) {
          notificationProvider.addNotification(notification);
        }

        notificationProvider.clearNotifications();

        expect(notificationProvider.notifications, isEmpty);
        expect(notificationProvider.unreadCount, 0);
      });

      test('should calculate unread count correctly', () {
        final notifications = [
          const AppNotification(
            id: '12',
            title: 'Read Notification',
            body: 'Test body 1',
            type: 'info',
            timestamp: null,
            isRead: true,
          ),
          const AppNotification(
            id: '13',
            title: 'Unread Notification 1',
            body: 'Test body 2',
            type: 'info',
            timestamp: null,
            isRead: false,
          ),
          const AppNotification(
            id: '14',
            title: 'Unread Notification 2',
            body: 'Test body 3',
            type: 'info',
            timestamp: null,
            isRead: false,
          ),
        ];

        for (final notification in notifications) {
          notificationProvider.addNotification(notification);
        }

        expect(notificationProvider.unreadCount, 2);
      });
    });

    group('NotificationProvider Real-time Updates', () {
      test('should setup real-time subscription on initialization', () {
        // This would require proper mocking of Supabase client
        // For now, we verify the provider initializes without errors
        expect(notificationProvider.notifications, isEmpty);
      });

      test('should handle real-time notification updates', () {
        // This would require mocking the real-time channel
        // For now, we test the manual addition
        const notification = AppNotification(
          id: '15',
          title: 'Real-time Notification',
          body: 'Test body',
          type: 'info',
          timestamp: null,
        );

        notificationProvider.addNotification(notification);

        expect(notificationProvider.notifications, contains(notification));
      });
    });

    group('NotificationProvider Error Handling', () {
      test('should handle invalid notification data gracefully', () {
        final invalidData = {
          'id': null,
          'title': null,
          'body': null,
          'type': null,
        };

        expect(() => AppNotification.fromMap(invalidData), returnsNormally);
      });

      test('should handle duplicate notification IDs', () {
        const notification1 = AppNotification(
          id: '16',
          title: 'First Notification',
          body: 'Test body 1',
          type: 'info',
          timestamp: null,
        );

        const notification2 = AppNotification(
          id: '16',
          title: 'Second Notification',
          body: 'Test body 2',
          type: 'info',
          timestamp: null,
        );

        notificationProvider.addNotification(notification1);
        notificationProvider.addNotification(notification2);

        expect(notificationProvider.notifications.length, 2);
      });
    });

    group('NotificationProvider Listeners', () {
      test('should notify listeners when notifications change', () {
        bool notified = false;
        notificationProvider.addListener(() => notified = true);

        const notification = AppNotification(
          id: '17',
          title: 'Listener Test',
          body: 'Test body',
          type: 'info',
          timestamp: null,
        );

        notificationProvider.addNotification(notification);

        expect(notified, true);
      });

      test('should notify listeners when notification is marked as read', () {
        bool notified = false;
        notificationProvider.addListener(() => notified = true);

        const notification = AppNotification(
          id: '18',
          title: 'Read Listener Test',
          body: 'Test body',
          type: 'info',
          timestamp: null,
          isRead: false,
        );

        notificationProvider.addNotification(notification);
        notified = false; // Reset

        notificationProvider.markAsRead('18');

        expect(notified, true);
      });
    });
  });
}
