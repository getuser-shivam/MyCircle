enum StreamStatus {
  scheduled,
  live,
  ended,
  cancelled;

  String get displayName {
    switch (this) {
      case StreamStatus.scheduled:
        return 'Scheduled';
      case StreamStatus.live:
        return 'Live';
      case StreamStatus.ended:
        return 'Ended';
      case StreamStatus.cancelled:
        return 'Cancelled';
    }
  }
}

enum StreamQuality {
  low,
  medium,
  high,
  ultra;

  String get displayName {
    switch (this) {
      case StreamQuality.low:
        return '360p';
      case StreamQuality.medium:
        return '720p';
      case StreamQuality.high:
        return '1080p';
      case StreamQuality.ultra:
        return '4K';
    }
  }

  String get value {
    switch (this) {
      case StreamQuality.low:
        return 'low';
      case StreamQuality.medium:
        return 'medium';
      case StreamQuality.high:
        return 'high';
      case StreamQuality.ultra:
        return 'ultra';
    }
  }
}

class LiveStream {
  final String id;
  final String title;
  final String description;
  final String streamerId;
  final String streamerName;
  final String streamerAvatar;
  final bool isVerified;
  final String thumbnailUrl;
  final String streamUrl;
  final String streamKey;
  final StreamStatus status;
  final StreamQuality quality;
  final int viewerCount;
  final int maxViewers;
  final DateTime scheduledAt;
  final DateTime startedAt;
  final DateTime? endedAt;
  final List<String> tags;
  final String category;
  final bool isPrivate;
  final bool isRecorded;
  final double latitude;
  final double longitude;
  final String? locationName;
  final List<String> allowedViewerIds;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  LiveStream({
    required this.id,
    required this.title,
    required this.description,
    required this.streamerId,
    required this.streamerName,
    required this.streamerAvatar,
    this.isVerified = false,
    required this.thumbnailUrl,
    required this.streamUrl,
    required this.streamKey,
    required this.status,
    required this.quality,
    required this.viewerCount,
    required this.maxViewers,
    required this.scheduledAt,
    required this.startedAt,
    this.endedAt,
    required this.tags,
    required this.category,
    required this.isPrivate,
    required this.isRecorded,
    required this.latitude,
    required this.longitude,
    this.locationName,
    required this.allowedViewerIds,
    required this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LiveStream.fromMap(Map<String, dynamic> data) {
    return LiveStream(
      id: data['id']?.toString() ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      streamerId: data['streamer_id']?.toString() ?? '',
      streamerName: data['streamer_name'] ?? '',
      streamerAvatar: data['streamer_avatar'] ?? '',
      isVerified: (data['is_verified'] ?? data['verified'] ?? false) == true,
      thumbnailUrl: data['thumbnail_url'] ?? '',
      streamUrl: data['stream_url'] ?? '',
      streamKey: data['stream_key'] ?? '',
      status: _parseStatus(data['status']),
      quality: _parseQuality(data['quality']),
      viewerCount: data['viewer_count'] ?? 0,
      maxViewers: data['max_viewers'] ?? 1000,
      scheduledAt: DateTime.parse(data['scheduled_at'] ?? DateTime.now().toIso8601String()),
      startedAt: DateTime.parse(data['started_at'] ?? DateTime.now().toIso8601String()),
      endedAt: data['ended_at'] != null ? DateTime.parse(data['ended_at']) : null,
      tags: List<String>.from(data['tags'] ?? []),
      category: data['category'] ?? 'General',
      isPrivate: data['is_private'] ?? false,
      isRecorded: data['is_recorded'] ?? false,
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      locationName: data['location_name'],
      allowedViewerIds: List<String>.from(data['allowed_viewer_ids'] ?? []),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      createdAt: DateTime.parse(data['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(data['updated_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  factory LiveStream.fromJson(Map<String, dynamic> data) => LiveStream.fromMap(data);

  static StreamStatus _parseStatus(dynamic status) {
    final value = status?.toString().toLowerCase();
    if (value == 'scheduled') return StreamStatus.scheduled;
    if (value == 'live') return StreamStatus.live;
    if (value == 'ended') return StreamStatus.ended;
    if (value == 'cancelled') return StreamStatus.cancelled;
    return StreamStatus.scheduled;
  }

  static StreamQuality _parseQuality(dynamic quality) {
    final value = quality?.toString().toLowerCase();
    if (value == 'low') return StreamQuality.low;
    if (value == 'medium') return StreamQuality.medium;
    if (value == 'high') return StreamQuality.high;
    if (value == 'ultra') return StreamQuality.ultra;
    return StreamQuality.medium;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'streamer_id': streamerId,
      'streamer_name': streamerName,
      'streamer_avatar': streamerAvatar,
      'is_verified': isVerified,
      'thumbnail_url': thumbnailUrl,
      'stream_url': streamUrl,
      'stream_key': streamKey,
      'status': status.name,
      'quality': quality.value,
      'viewer_count': viewerCount,
      'max_viewers': maxViewers,
      'scheduled_at': scheduledAt.toIso8601String(),
      'started_at': startedAt.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'tags': tags,
      'category': category,
      'is_private': isPrivate,
      'is_recorded': isRecorded,
      'latitude': latitude,
      'longitude': longitude,
      'location_name': locationName,
      'allowed_viewer_ids': allowedViewerIds,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toJson() => toMap();

  LiveStream copyWith({
    String? id,
    String? title,
    String? description,
    String? streamerId,
    String? streamerName,
    String? streamerAvatar,
    bool? isVerified,
    String? thumbnailUrl,
    String? streamUrl,
    String? streamKey,
    StreamStatus? status,
    StreamQuality? quality,
    int? viewerCount,
    int? maxViewers,
    DateTime? scheduledAt,
    DateTime? startedAt,
    DateTime? endedAt,
    List<String>? tags,
    String? category,
    bool? isPrivate,
    bool? isRecorded,
    double? latitude,
    double? longitude,
    String? locationName,
    List<String>? allowedViewerIds,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LiveStream(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      streamerId: streamerId ?? this.streamerId,
      streamerName: streamerName ?? this.streamerName,
      streamerAvatar: streamerAvatar ?? this.streamerAvatar,
      isVerified: isVerified ?? this.isVerified,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      streamUrl: streamUrl ?? this.streamUrl,
      streamKey: streamKey ?? this.streamKey,
      status: status ?? this.status,
      quality: quality ?? this.quality,
      viewerCount: viewerCount ?? this.viewerCount,
      maxViewers: maxViewers ?? this.maxViewers,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      isPrivate: isPrivate ?? this.isPrivate,
      isRecorded: isRecorded ?? this.isRecorded,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      locationName: locationName ?? this.locationName,
      allowedViewerIds: allowedViewerIds ?? this.allowedViewerIds,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isLive => status == StreamStatus.live;
  bool get isScheduled => status == StreamStatus.scheduled;
  bool get isEnded => status == StreamStatus.ended;
  bool get isCancelled => status == StreamStatus.cancelled;
  bool get hasLocation => latitude != 0.0 && longitude != 0.0;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LiveStream && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'LiveStream(id: $id, title: $title, status: $status, viewerCount: $viewerCount)';
  }
}
