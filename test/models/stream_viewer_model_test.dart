import 'package:flutter_test/flutter_test.dart';
import 'package:mycircle/models/stream_viewer_model.dart';

void main() {
  group('ViewerRole', () {
    test('should have correct string values', () {
      expect(ViewerRole.viewer.value, 'viewer');
      expect(ViewerRole.moderator.value, 'moderator');
      expect(ViewerRole.vip.value, 'vip');
      expect(ViewerRole.staff.value, 'staff');
    });

    test('should parse from string correctly', () {
      expect(ViewerRole.fromString('viewer'), ViewerRole.viewer);
      expect(ViewerRole.fromString('moderator'), ViewerRole.moderator);
      expect(ViewerRole.fromString('vip'), ViewerRole.vip);
      expect(ViewerRole.fromString('staff'), ViewerRole.staff);
      expect(ViewerRole.fromString('invalid'), ViewerRole.viewer); // default
    });

    test('should have correct display names', () {
      expect(ViewerRole.viewer.displayName, 'Viewer');
      expect(ViewerRole.moderator.displayName, 'Moderator');
      expect(ViewerRole.vip.displayName, 'VIP');
      expect(ViewerRole.staff.displayName, 'Staff');
    });

    test('should have correct priority levels', () {
      expect(ViewerRole.staff.priority, 4);
      expect(ViewerRole.moderator.priority, 3);
      expect(ViewerRole.vip.priority, 2);
      expect(ViewerRole.viewer.priority, 1);
    });
  });

  group('StreamViewer', () {
    final now = DateTime.now();
    final joinTime = now.subtract(const Duration(minutes: 30));
    
    final sampleViewer = StreamViewer(
      id: 'viewer_1',
      streamId: 'stream_1',
      userId: 'user_1',
      userName: 'TestUser',
      userAvatar: 'https://example.com/avatar.jpg',
      role: ViewerRole.viewer,
      joinedAt: joinTime,
      lastSeen: now,
      watchTime: const Duration(minutes: 25),
      isOnline: true,
      isFollowing: false,
      isSubscriber: false,
      isStaff: false,
      isVip: false,
      isModerator: false,
      messagesSent: 5,
      reactionsSent: 12,
    );

    test('should create StreamViewer with all required fields', () {
      expect(sampleViewer.id, 'viewer_1');
      expect(sampleViewer.streamId, 'stream_1');
      expect(sampleViewer.userId, 'user_1');
      expect(sampleViewer.userName, 'TestUser');
      expect(sampleViewer.role, ViewerRole.viewer);
      expect(sampleViewer.isOnline, isTrue);
      expect(sampleViewer.watchTime, const Duration(minutes: 25));
    });

    test('should convert to map correctly', () {
      final map = sampleViewer.toMap();
      
      expect(map['id'], 'viewer_1');
      expect(map['stream_id'], 'stream_1');
      expect(map['user_id'], 'user_1');
      expect(map['user_name'], 'TestUser');
      expect(map['role'], 'viewer');
      expect(map['joined_at'], joinTime.toIso8601String());
      expect(map['last_seen'], now.toIso8601String());
      expect(map['watch_time'], const Duration(minutes: 25).inSeconds);
      expect(map['is_online'], true);
    });

    test('should create from map correctly', () {
      final map = sampleViewer.toMap();
      final viewerFromMap = StreamViewer.fromMap(map);
      
      expect(viewerFromMap.id, sampleViewer.id);
      expect(viewerFromMap.streamId, sampleViewer.streamId);
      expect(viewerFromMap.userId, sampleViewer.userId);
      expect(viewerFromMap.userName, sampleViewer.userName);
      expect(viewerFromMap.role, sampleViewer.role);
      expect(viewerFromMap.isOnline, sampleViewer.isOnline);
      expect(viewerFromMap.watchTime, sampleViewer.watchTime);
    });

    test('should handle null values in fromMap', () {
      final map = {
        'id': 'viewer_2',
        'stream_id': 'stream_2',
        'user_id': 'user_2',
        'user_name': 'User2',
        'role': 'viewer',
        'joined_at': joinTime.toIso8601String(),
        'last_seen': now.toIso8601String(),
        'watch_time': 600, // 10 minutes in seconds
        'is_online': true,
      };

      final viewer = StreamViewer.fromMap(map);
      expect(viewer.id, 'viewer_2');
      expect(viewer.userAvatar, ''); // default empty string
      expect(viewer.isFollowing, false); // default false
      expect(viewer.isSubscriber, false); // default false
      expect(viewer.messagesSent, 0); // default 0
    });

    test('copyWith should create new instance with updated values', () {
      final updatedViewer = sampleViewer.copyWith(
        role: ViewerRole.moderator,
        isOnline: false,
        messagesSent: 10,
      );

      expect(updatedViewer.id, sampleViewer.id); // unchanged
      expect(updatedViewer.role, ViewerRole.moderator); // changed
      expect(updatedViewer.isOnline, false); // changed
      expect(updatedViewer.messagesSent, 10); // changed
      expect(updatedViewer.userName, sampleViewer.userName); // unchanged
    });

    test('equality should work correctly', () {
      final viewer1 = sampleViewer;
      final viewer2 = StreamViewer.fromMap(sampleViewer.toMap());
      final viewer3 = sampleViewer.copyWith(userName: 'Different');

      expect(viewer1, equals(viewer2));
      expect(viewer1, isNot(equals(viewer3)));
    });

    group('Computed Properties', () {
      test('isLongTermViewer should return true for viewers watching > 1 hour', () {
        final longTermViewer = sampleViewer.copyWith(
          watchTime: const Duration(hours: 2),
        );
        expect(longTermViewer.isLongTermViewer, isTrue);
      });

      test('isLongTermViewer should return false for viewers watching < 1 hour', () {
        final shortTermViewer = sampleViewer.copyWith(
          watchTime: const Duration(minutes: 30),
        );
        expect(shortTermViewer.isLongTermViewer, isFalse);
      });

      test('isActive should return true for online viewers with recent activity', () {
        final activeViewer = sampleViewer.copyWith(
          lastSeen: DateTime.now().subtract(const Duration(minutes: 5)),
        );
        expect(activeViewer.isActive, isTrue);
      });

      test('isActive should return false for offline viewers', () {
        final inactiveViewer = sampleViewer.copyWith(
          isOnline: false,
        );
        expect(inactiveViewer.isActive, isFalse);
      });

      test('isActive should return false for online but idle viewers', () {
        final idleViewer = sampleViewer.copyWith(
          isOnline: true,
          lastSeen: DateTime.now().subtract(const Duration(minutes: 15)),
        );
        expect(idleViewer.isActive, isFalse);
      });

      test('engagementScore should calculate correctly', () {
        final engagedViewer = sampleViewer.copyWith(
          messagesSent: 10,
          reactionsSent: 20,
          watchTime: const Duration(minutes: 30),
        );
        
        // Score = (messages * 2) + (reactions * 1) + (watchTimeMinutes / 10)
        // = (10 * 2) + (20 * 1) + (30 / 10) = 20 + 20 + 3 = 43
        expect(engagedViewer.engagementScore, 43);
      });

      test('engagementScore should handle zero engagement', () {
        final unengagedViewer = sampleViewer.copyWith(
          messagesSent: 0,
          reactionsSent: 0,
          watchTime: Duration.zero,
        );
        expect(unengagedViewer.engagementScore, 0);
      });

      test('hasHighEngagement should return true for engaged viewers', () {
        final engagedViewer = sampleViewer.copyWith(
          messagesSent: 50,
          reactionsSent: 100,
        );
        expect(engagedViewer.hasHighEngagement, isTrue);
      });

      test('hasHighEngagement should return false for low engagement viewers', () {
        final unengagedViewer = sampleViewer.copyWith(
          messagesSent: 1,
          reactionsSent: 2,
        );
        expect(unengagedViewer.hasHighEngagement, isFalse);
      });
    });

    group('Helper Methods', () {
      test('updateLastSeen should update last seen time', () {
        final viewer = sampleViewer.copyWith(
          lastSeen: DateTime.now().subtract(const Duration(minutes: 10)),
        );
        final updatedViewer = viewer.updateLastSeen();
        
        expect(updatedViewer.lastSeen, isNot(viewer.lastSeen));
        expect(updatedViewer.lastSeen.difference(viewer.lastSeen).inSeconds, greaterThan(0));
      });

      test('incrementWatchTime should add time to watch duration', () {
        final viewer = sampleViewer.copyWith(
          watchTime: const Duration(minutes: 30),
        );
        final updatedViewer = viewer.incrementWatchTime(const Duration(minutes: 10));
        
        expect(updatedViewer.watchTime, const Duration(minutes: 40));
      });

      test('incrementMessagesSent should increase message count', () {
        final viewer = sampleViewer.copyWith(messagesSent: 5);
        final updatedViewer = viewer.incrementMessagesSent();
        
        expect(updatedViewer.messagesSent, 6);
      });

      test('incrementReactionsSent should increase reaction count', () {
        final viewer = sampleViewer.copyWith(reactionsSent: 12);
        final updatedViewer = viewer.incrementReactionsSent();
        
        expect(updatedViewer.reactionsSent, 13);
      });

      test('setOnlineStatus should update online status', () {
        final viewer = sampleViewer.copyWith(isOnline: false);
        final onlineViewer = viewer.setOnlineStatus(true);
        
        expect(onlineViewer.isOnline, isTrue);
        
        final offlineViewer = onlineViewer.setOnlineStatus(false);
        expect(offlineViewer.isOnline, isFalse);
      });

      test('promoteToRole should change viewer role', () {
        final viewer = sampleViewer.copyWith(role: ViewerRole.viewer);
        final modViewer = viewer.promoteToRole(ViewerRole.moderator);
        
        expect(modViewer.role, ViewerRole.moderator);
        expect(modViewer.isModerator, isTrue);
      });
    });

    group('Role-Based Properties', () {
      test('should correctly identify moderator role', () {
        final modViewer = sampleViewer.copyWith(role: ViewerRole.moderator);
        expect(modViewer.isModerator, isTrue);
        expect(modViewer.canModerate, isTrue);
      });

      test('should correctly identify VIP role', () {
        final vipViewer = sampleViewer.copyWith(role: ViewerRole.vip);
        expect(vipViewer.isVip, isTrue);
        expect(vipViewer.hasSpecialPrivileges, isTrue);
      });

      test('should correctly identify staff role', () {
        final staffViewer = sampleViewer.copyWith(role: ViewerRole.staff);
        expect(staffViewer.isStaff, isTrue);
        expect(staffViewer.canModerate, isTrue);
        expect(staffViewer.hasSpecialPrivileges, isTrue);
      });

      test('should correctly identify viewer role', () {
        final regularViewer = sampleViewer.copyWith(role: ViewerRole.viewer);
        expect(regularViewer.isModerator, isFalse);
        expect(regularViewer.isVip, isFalse);
        expect(regularViewer.isStaff, isFalse);
        expect(regularViewer.canModerate, isFalse);
        expect(regularViewer.hasSpecialPrivileges, isFalse);
      });
    });

    group('Edge Cases', () {
      test('should handle zero watch time', () {
        final viewer = sampleViewer.copyWith(watchTime: Duration.zero);
        expect(viewer.watchTime, Duration.zero);
        expect(viewer.isLongTermViewer, isFalse);
      });

      test('should handle very long watch time', () {
        final viewer = sampleViewer.copyWith(
          watchTime: const Duration(hours: 24),
        );
        expect(viewer.watchTime, const Duration(hours: 24));
        expect(viewer.isLongTermViewer, isTrue);
      });

      test('should handle very high engagement counts', () {
        final viewer = sampleViewer.copyWith(
          messagesSent: 10000,
          reactionsSent: 20000,
        );
        expect(viewer.messagesSent, 10000);
        expect(viewer.reactionsSent, 20000);
        expect(viewer.hasHighEngagement, isTrue);
      });

      test('should handle negative values in fromMap gracefully', () {
        final map = {
          'id': 'viewer_negative',
          'stream_id': 'stream_1',
          'user_id': 'user_1',
          'user_name': 'User',
          'role': 'viewer',
          'joined_at': joinTime.toIso8601String(),
          'last_seen': now.toIso8601String(),
          'watch_time': -100, // negative watch time
          'is_online': true,
          'messages_sent': -5, // negative messages
          'reactions_sent': -10, // negative reactions
        };

        final viewer = StreamViewer.fromMap(map);
        expect(viewer.watchTime, Duration.zero); // should be clamped to zero
        expect(viewer.messagesSent, 0); // should be clamped to zero
        expect(viewer.reactionsSent, 0); // should be clamped to zero
      });

      test('should handle future timestamps', () {
        final futureTime = DateTime.now().add(const Duration(hours: 1));
        final viewer = sampleViewer.copyWith(lastSeen: futureTime);
        expect(viewer.lastSeen.isAfter(DateTime.now()), isTrue);
        expect(viewer.isActive, isTrue); // future times are considered active
      });
    });

    group('Validation', () {
      test('should validate required fields', () {
        expect(() => StreamViewer(
          id: '', // invalid empty id
          streamId: 'stream_1',
          userId: 'user_1',
          userName: 'Test',
          role: ViewerRole.viewer,
          joinedAt: joinTime,
          lastSeen: now,
          watchTime: Duration.zero,
          isOnline: true,
        ), throwsA(anything));

        expect(() => StreamViewer(
          id: 'viewer_1',
          streamId: '', // invalid empty stream_id
          userId: 'user_1',
          userName: 'Test',
          role: ViewerRole.viewer,
          joinedAt: joinTime,
          lastSeen: now,
          watchTime: Duration.zero,
          isOnline: true,
        ), throwsA(anything));
      });

      test('should handle invalid role in fromMap', () {
        final map = {
          'id': 'viewer_invalid',
          'stream_id': 'stream_1',
          'user_id': 'user_1',
          'user_name': 'Test',
          'role': 'invalid_role',
          'joined_at': joinTime.toIso8601String(),
          'last_seen': now.toIso8601String(),
          'watch_time': 0,
          'is_online': true,
        };

        final viewer = StreamViewer.fromMap(map);
        expect(viewer.role, ViewerRole.viewer); // default
      });
    });
  });

  group('StreamViewerStats', () {
    final now = DateTime.now();
    
    final sampleStats = StreamViewerStats(
      id: 'stats_1',
      streamId: 'stream_1',
      totalViewers: 1000,
      currentViewers: 500,
      peakViewers: 1500,
      averageWatchTime: 25.5,
      newViewers: 200,
      returningViewers: 300,
      activeViewers: 400,
      vipCount: 50,
      moderatorCount: 10,
      staffCount: 5,
      totalMessages: 2000,
      totalReactions: 5000,
      engagementRate: 75.5,
      newViewerRate: 40.0,
      retentionRate: 60.0,
      viewersByCountry: {
        'US': 300,
        'UK': 100,
        'CA': 50,
      },
      viewersByDevice: {
        'mobile': 250,
        'desktop': 200,
        'tablet': 50,
      },
      createdAt: now,
      updatedAt: now,
    );

    test('should create StreamViewerStats with all required fields', () {
      expect(sampleStats.id, 'stats_1');
      expect(sampleStats.streamId, 'stream_1');
      expect(sampleStats.totalViewers, 1000);
      expect(sampleStats.currentViewers, 500);
      expect(sampleStats.peakViewers, 1500);
      expect(sampleStats.engagementRate, 75.5);
    });

    test('should convert to map correctly', () {
      final map = sampleStats.toMap();
      
      expect(map['id'], 'stats_1');
      expect(map['stream_id'], 'stream_1');
      expect(map['total_viewers'], 1000);
      expect(map['current_viewers'], 500);
      expect(map['peak_viewers'], 1500);
      expect(map['average_watch_time'], 25.5);
      expect(map['engagement_rate'], 75.5);
    });

    test('should create from map correctly', () {
      final map = sampleStats.toMap();
      final statsFromMap = StreamViewerStats.fromMap(map);
      
      expect(statsFromMap.id, sampleStats.id);
      expect(statsFromMap.streamId, sampleStats.streamId);
      expect(statsFromMap.totalViewers, sampleStats.totalViewers);
      expect(statsFromMap.currentViewers, sampleStats.currentViewers);
      expect(statsFromMap.engagementRate, sampleStats.engagementRate);
    });

    test('should handle null values in fromMap', () {
      final map = {
        'id': 'stats_2',
        'stream_id': 'stream_2',
        'total_viewers': 100,
        'current_viewers': 50,
        'peak_viewers': 150,
        'average_watch_time': 10.0,
        'engagement_rate': 50.0,
        'new_viewer_rate': 30.0,
        'retention_rate': 70.0,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final stats = StreamViewerStats.fromMap(map);
      expect(stats.id, 'stats_2');
      expect(stats.newViewers, 0); // default 0
      expect(stats.returningViewers, 0); // default 0
      expect(stats.viewersByCountry, {}); // default empty map
    });

    test('copyWith should create new instance with updated values', () {
      final updatedStats = sampleStats.copyWith(
        currentViewers: 600,
        engagementRate: 80.0,
        totalMessages: 2500,
      );

      expect(updatedStats.id, sampleStats.id); // unchanged
      expect(updatedStats.currentViewers, 600); // changed
      expect(updatedStats.engagementRate, 80.0); // changed
      expect(updatedStats.totalMessages, 2500); // changed
    });

    group('Computed Properties', () {
      test('viewerGrowthRate should calculate correctly', () {
        final stats = sampleStats.copyWith(
          totalViewers: 1000,
          currentViewers: 500,
        );
        // Growth rate = ((current - total) / total) * 100
        // = ((500 - 1000) / 1000) * 100 = -50%
        expect(stats.viewerGrowthRate, closeTo(-50.0, 0.1));
      });

      test('viewerRetentionRate should calculate correctly', () {
        final stats = sampleStats.copyWith(
          returningViewers: 300,
          totalViewers: 1000,
        );
        // Retention rate = (returning / total) * 100
        // = (300 / 1000) * 100 = 30%
        expect(stats.viewerRetentionRate, closeTo(30.0, 0.1));
      });

      test('messagesPerViewer should calculate correctly', () {
        final stats = sampleStats.copyWith(
          totalMessages: 2000,
          totalViewers: 1000,
        );
        expect(stats.messagesPerViewer, 2.0);
      });

      test('reactionsPerViewer should calculate correctly', () {
        final stats = sampleStats.copyWith(
          totalReactions: 5000,
          totalViewers: 1000,
        );
        expect(stats.reactionsPerViewer, 5.0);
      });

      test('topCountry should return country with most viewers', () {
        final stats = sampleStats.copyWith(
          viewersByCountry: {
            'US': 300,
            'UK': 100,
            'CA': 50,
          },
        );
        expect(stats.topCountry, 'US');
      });

      test('topCountry should return null for empty country data', () {
        final stats = sampleStats.copyWith(viewersByCountry: {});
        expect(stats.topCountry, isNull);
      });

      test('topDevice should return device with most viewers', () {
        final stats = sampleStats.copyWith(
          viewersByDevice: {
            'mobile': 250,
            'desktop': 200,
            'tablet': 50,
          },
        );
        expect(stats.topDevice, 'mobile');
      });
    });

    group('Edge Cases', () {
      test('should handle zero viewers', () {
        final stats = sampleStats.copyWith(
          totalViewers: 0,
          currentViewers: 0,
          peakViewers: 0,
        );
        expect(stats.totalViewers, 0);
        expect(stats.viewerGrowthRate, 0.0);
        expect(stats.messagesPerViewer, 0.0);
      });

      test('should handle very large numbers', () {
        final stats = sampleStats.copyWith(
          totalViewers: 1000000,
          currentViewers: 2000000,
          totalMessages: 5000000,
        );
        expect(stats.totalViewers, 1000000);
        expect(stats.viewerGrowthRate, 100.0);
      });

      test('should handle negative engagement rate', () {
        final stats = sampleStats.copyWith(engagementRate: -10.0);
        expect(stats.engagementRate, -10.0);
      });

      test('should handle engagement rate over 100%', () {
        final stats = sampleStats.copyWith(engagementRate: 150.0);
        expect(stats.engagementRate, 150.0);
      });
    });
  });
}
