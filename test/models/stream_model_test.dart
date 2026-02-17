import 'package:flutter_test/flutter_test.dart';
import 'package:mycircle/models/stream_model.dart';

void main() {
  group('StreamStatus', () {
    test('should have correct string values', () {
      expect(StreamStatus.live.value, 'live');
      expect(StreamStatus.scheduled.value, 'scheduled');
      expect(StreamStatus.ended.value, 'ended');
      expect(StreamStatus.cancelled.value, 'cancelled');
    });

    test('should parse from string correctly', () {
      expect(StreamStatus.fromString('live'), StreamStatus.live);
      expect(StreamStatus.fromString('scheduled'), StreamStatus.scheduled);
      expect(StreamStatus.fromString('ended'), StreamStatus.ended);
      expect(StreamStatus.fromString('cancelled'), StreamStatus.cancelled);
      expect(StreamStatus.fromString('invalid'), StreamStatus.scheduled); // default
    });

    test('should have correct display names', () {
      expect(StreamStatus.live.displayName, 'Live');
      expect(StreamStatus.scheduled.displayName, 'Scheduled');
      expect(StreamStatus.ended.displayName, 'Ended');
      expect(StreamStatus.cancelled.displayName, 'Cancelled');
    });
  });

  group('StreamQuality', () {
    test('should have correct string values', () {
      expect(StreamQuality.low.value, '360p');
      expect(StreamQuality.medium.value, '720p');
      expect(StreamQuality.high.value, '1080p');
      expect(StreamQuality.ultra.value, '4K');
    });

    test('should parse from string correctly', () {
      expect(StreamQuality.fromString('360p'), StreamQuality.low);
      expect(StreamQuality.fromString('720p'), StreamQuality.medium);
      expect(StreamQuality.fromString('1080p'), StreamQuality.high);
      expect(StreamQuality.fromString('4K'), StreamQuality.ultra);
      expect(StreamQuality.fromString('invalid'), StreamQuality.medium); // default
    });

    test('should have correct display names', () {
      expect(StreamQuality.low.displayName, '360p');
      expect(StreamQuality.medium.displayName, '720p');
      expect(StreamQuality.high.displayName, '1080p');
      expect(StreamQuality.ultra.displayName, '4K');
    });
  });

  group('LiveStream', () {
    final now = DateTime.now();
    final later = now.add(const Duration(hours: 1));

    final sampleStream = LiveStream(
      id: 'stream_1',
      streamerId: 'user_1',
      title: 'Test Stream',
      description: 'Test Description',
      category: 'Gaming',
      tags: ['test', 'gaming'],
      thumbnailUrl: 'https://example.com/thumb.jpg',
      streamUrl: 'https://example.com/stream.m3u8',
      streamKey: 'key_123',
      status: StreamStatus.live,
      quality: StreamQuality.high,
      viewerCount: 100,
      maxViewers: 1000,
      isPrivate: false,
      isRecorded: true,
      isVerified: true,
      startedAt: now,
      scheduledAt: later,
      endedAt: null,
      streamerName: 'TestStreamer',
      streamerAvatar: 'https://example.com/avatar.jpg',
      latitude: 37.7749,
      longitude: -122.4194,
      locationName: 'San Francisco',
      createdAt: now,
      updatedAt: now,
    );

    test('should create LiveStream with all required fields', () {
      expect(sampleStream.id, 'stream_1');
      expect(sampleStream.streamerId, 'user_1');
      expect(sampleStream.title, 'Test Stream');
      expect(sampleStream.status, StreamStatus.live);
      expect(sampleStream.viewerCount, 100);
    });

    test('should convert to map correctly', () {
      final map = sampleStream.toMap();
      
      expect(map['id'], 'stream_1');
      expect(map['streamer_id'], 'user_1');
      expect(map['title'], 'Test Stream');
      expect(map['status'], 'live');
      expect(map['quality'], '1080p');
      expect(map['viewer_count'], 100);
    });

    test('should create from map correctly', () {
      final map = sampleStream.toMap();
      final streamFromMap = LiveStream.fromMap(map);
      
      expect(streamFromMap.id, sampleStream.id);
      expect(streamFromMap.streamerId, sampleStream.streamerId);
      expect(streamFromMap.title, sampleStream.title);
      expect(streamFromMap.status, sampleStream.status);
      expect(streamFromMap.quality, sampleStream.quality);
      expect(streamFromMap.viewerCount, sampleStream.viewerCount);
    });

    test('should handle null values in fromMap', () {
      final map = {
        'id': 'stream_2',
        'streamer_id': 'user_2',
        'title': 'Test Stream 2',
        'status': 'live',
        'quality': '720p',
        'viewer_count': 50,
        'started_at': now.toIso8601String(),
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
      };

      final stream = LiveStream.fromMap(map);
      expect(stream.id, 'stream_2');
      expect(stream.description, ''); // default empty string
      expect(stream.tags, []); // default empty list
      expect(stream.isPrivate, false); // default false
      expect(stream.isRecorded, true); // default true
    });

    test('copyWith should create new instance with updated values', () {
      final updatedStream = sampleStream.copyWith(
        title: 'Updated Title',
        viewerCount: 200,
        status: StreamStatus.ended,
      );

      expect(updatedStream.id, sampleStream.id); // unchanged
      expect(updatedStream.title, 'Updated Title'); // changed
      expect(updatedStream.viewerCount, 200); // changed
      expect(updatedStream.status, StreamStatus.ended); // changed
      expect(updatedStream.description, sampleStream.description); // unchanged
    });

    test('equality should work correctly', () {
      final stream1 = sampleStream;
      final stream2 = LiveStream.fromMap(sampleStream.toMap());
      final stream3 = sampleStream.copyWith(title: 'Different');

      expect(stream1, equals(stream2));
      expect(stream1, isNot(equals(stream3)));
    });

    test('toString should return meaningful representation', () {
      final stringRep = sampleStream.toString();
      expect(stringRep, contains('LiveStream'));
      expect(stringRep, contains('Test Stream'));
      expect(stringRep, contains('live'));
    });

    group('Computed Properties', () {
      test('isLive should return true for live streams', () {
        final liveStream = sampleStream.copyWith(status: StreamStatus.live);
        expect(liveStream.isLive, isTrue);
      });

      test('isLive should return false for non-live streams', () {
        final scheduledStream = sampleStream.copyWith(status: StreamStatus.scheduled);
        final endedStream = sampleStream.copyWith(status: StreamStatus.ended);
        
        expect(scheduledStream.isLive, isFalse);
        expect(endedStream.isLive, isFalse);
      });

      test('isScheduled should return true for scheduled streams', () {
        final scheduledStream = sampleStream.copyWith(status: StreamStatus.scheduled);
        expect(scheduledStream.isScheduled, isTrue);
      });

      test('isScheduled should return false for non-scheduled streams', () {
        final liveStream = sampleStream.copyWith(status: StreamStatus.live);
        expect(liveStream.isScheduled, isFalse);
      });

      test('isEnded should return true for ended streams', () {
        final endedStream = sampleStream.copyWith(status: StreamStatus.ended);
        expect(endedStream.isEnded, isTrue);
      });

      test('isCancelled should return true for cancelled streams', () {
        final cancelledStream = sampleStream.copyWith(status: StreamStatus.cancelled);
        expect(cancelledStream.isCancelled, isTrue);
      });

      test('duration should calculate correctly for live streams', () {
        final startTime = DateTime.now().subtract(const Duration(minutes: 30));
        final liveStream = sampleStream.copyWith(startedAt: startTime);
        
        final duration = liveStream.duration;
        expect(duration.inMinutes, greaterThanOrEqualTo(29));
        expect(duration.inMinutes, lessThanOrEqualTo(31));
      });

      test('duration should return zero for scheduled streams', () {
        final scheduledStream = sampleStream.copyWith(
          status: StreamStatus.scheduled,
          startedAt: null,
        );
        
        expect(scheduledStream.duration, Duration.zero);
      });

      test('isAtCapacity should return true when at max viewers', () {
        final fullStream = sampleStream.copyWith(
          viewerCount: 1000,
          maxViewers: 1000,
        );
        expect(fullStream.isAtCapacity, isTrue);
      });

      test('isAtCapacity should return false when not at capacity', () {
        final notFullStream = sampleStream.copyWith(
          viewerCount: 500,
          maxViewers: 1000,
        );
        expect(notFullStream.isAtCapacity, isFalse);
      });

      test('isAtCapacity should return false when no max viewers set', () {
        final unlimitedStream = sampleStream.copyWith(
          viewerCount: 5000,
          maxViewers: null,
        );
        expect(unlimitedStream.isAtCapacity, isFalse);
      });
    });

    group('Edge Cases', () {
      test('should handle empty tags list', () {
        final stream = sampleStream.copyWith(tags: []);
        expect(stream.tags, isEmpty);
      });

      test('should handle null optional fields', () {
        final stream = LiveStream(
          id: 'stream_edge',
          streamerId: 'user_edge',
          title: 'Edge Case Stream',
          status: StreamStatus.live,
          quality: StreamQuality.medium,
          viewerCount: 0,
          startedAt: now,
          createdAt: now,
          updatedAt: now,
        );
        
        expect(stream.description, isEmpty);
        expect(stream.tags, isEmpty);
        expect(stream.thumbnailUrl, isEmpty);
        expect(stream.streamUrl, isEmpty);
        expect(stream.endedAt, isNull);
        expect(stream.scheduledAt, isNull);
      });

      test('should handle very large viewer counts', () {
        final popularStream = sampleStream.copyWith(viewerCount: 1000000);
        expect(popularStream.viewerCount, 1000000);
      });

      test('should handle negative coordinates', () {
        final stream = sampleStream.copyWith(
          latitude: -37.7749,
          longitude: -122.4194,
        );
        expect(stream.latitude, -37.7749);
        expect(stream.longitude, -122.4194);
      });

      test('should handle zero viewer count', () {
        final emptyStream = sampleStream.copyWith(viewerCount: 0);
        expect(emptyStream.viewerCount, 0);
        expect(emptyStream.isAtCapacity, isFalse);
      });
    });

    group('Validation', () {
      test('should validate required fields', () {
        expect(() => LiveStream(
          id: '', // invalid empty id
          streamerId: 'user_1',
          title: 'Test',
          status: StreamStatus.live,
          quality: StreamQuality.medium,
          viewerCount: 0,
          startedAt: now,
          createdAt: now,
          updatedAt: now,
        ), throwsA(anything));

        expect(() => LiveStream(
          id: 'stream_1',
          streamerId: '', // invalid empty streamer_id
          title: 'Test',
          status: StreamStatus.live,
          quality: StreamQuality.medium,
          viewerCount: 0,
          startedAt: now,
          createdAt: now,
          updatedAt: now,
        ), throwsA(anything));
      });

      test('should handle invalid enum values in fromMap', () {
        final map = {
          'id': 'stream_invalid',
          'streamer_id': 'user_1',
          'title': 'Test',
          'status': 'invalid_status',
          'quality': 'invalid_quality',
          'viewer_count': 0,
          'started_at': now.toIso8601String(),
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        };

        final stream = LiveStream.fromMap(map);
        expect(stream.status, StreamStatus.scheduled); // default
        expect(stream.quality, StreamQuality.medium); // default
      });
    });
  });
}
