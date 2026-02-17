enum ConversationType {
  chat,
  recommendation,
  social_assist,
  content_discovery;

  String get displayName {
    switch (this) {
      case ConversationType.chat:
        return 'Chat';
      case ConversationType.recommendation:
        return 'Recommendations';
      case ConversationType.social_assist:
        return 'Social Assist';
      case ConversationType.content_discovery:
        return 'Discovery';
    }
  }
}

enum MessageRole {
  user,
  assistant,
  system;

  String get displayName {
    switch (this) {
      case MessageRole.user:
        return 'You';
      case MessageRole.assistant:
        return 'AI';
      case MessageRole.system:
        return 'System';
    }
  }
}

enum CompanionPersonality {
  friendly,
  professional,
  witty,
  supportive,
  analytical;

  String get displayName {
    switch (this) {
      case CompanionPersonality.friendly:
        return 'Friendly';
      case CompanionPersonality.professional:
        return 'Professional';
      case CompanionPersonality.witty:
        return 'Witty';
      case CompanionPersonality.supportive:
        return 'Supportive';
      case CompanionPersonality.analytical:
        return 'Analytical';
    }
  }

  String get description {
    switch (this) {
      case CompanionPersonality.friendly:
        return 'Warm, casual, and encouraging';
      case CompanionPersonality.professional:
        return 'Formal, knowledgeable, and efficient';
      case CompanionPersonality.witty:
        return 'Humorous, clever, and entertaining';
      case CompanionPersonality.supportive:
        return 'Empathetic, caring, and motivating';
      case CompanionPersonality.analytical:
        return 'Logical, detailed, and insightful';
    }
  }
}

class AIConversation {
  final String id;
  final String userId;
  final String? companionId;
  final String title;
  final ConversationType type;
  final CompanionPersonality personality;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastMessageAt;
  final int messageCount;

  AIConversation({
    required this.id,
    required this.userId,
    this.companionId,
    required this.title,
    required this.type,
    required this.personality,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.lastMessageAt,
    this.messageCount = 0,
  });

  factory AIConversation.fromMap(Map<String, dynamic> data) {
    return AIConversation(
      id: data['id']?.toString() ?? '',
      userId: data['user_id']?.toString() ?? '',
      companionId: data['companion_id']?.toString(),
      title: data['title'] ?? 'New Conversation',
      type: _parseConversationType(data['type']),
      personality: _parsePersonality(data['personality']),
      isActive: data['is_active'] ?? true,
      createdAt: DateTime.parse(data['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(data['updated_at'] ?? DateTime.now().toIso8601String()),
      lastMessageAt: data['last_message_at'] != null 
          ? DateTime.parse(data['last_message_at']) 
          : null,
      messageCount: data['message_count'] ?? 0,
    );
  }

  static ConversationType _parseConversationType(String? type) {
    if (type == null) return ConversationType.chat;
    switch (type.toLowerCase()) {
      case 'chat':
        return ConversationType.chat;
      case 'recommendation':
        return ConversationType.recommendation;
      case 'social_assist':
        return ConversationType.social_assist;
      case 'content_discovery':
        return ConversationType.content_discovery;
      default:
        return ConversationType.chat;
    }
  }

  static CompanionPersonality _parsePersonality(String? personality) {
    if (personality == null) return CompanionPersonality.friendly;
    switch (personality.toLowerCase()) {
      case 'friendly':
        return CompanionPersonality.friendly;
      case 'professional':
        return CompanionPersonality.professional;
      case 'witty':
        return CompanionPersonality.witty;
      case 'supportive':
        return CompanionPersonality.supportive;
      case 'analytical':
        return CompanionPersonality.analytical;
      default:
        return CompanionPersonality.friendly;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'companion_id': companionId,
      'title': title,
      'type': type.toString().split('.').last,
      'personality': personality.toString().split('.').last,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_message_at': lastMessageAt?.toIso8601String(),
      'message_count': messageCount,
    };
  }

  AIConversation copyWith({
    String? id,
    String? userId,
    String? companionId,
    String? title,
    ConversationType? type,
    CompanionPersonality? personality,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastMessageAt,
    int? messageCount,
  }) {
    return AIConversation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      companionId: companionId ?? this.companionId,
      title: title ?? this.title,
      type: type ?? this.type,
      personality: personality ?? this.personality,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      messageCount: messageCount ?? this.messageCount,
    );
  }
}

class AIMessage {
  final String id;
  final String conversationId;
  final MessageRole role;
  final String content;
  final Map<String, dynamic>? metadata;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? modelUsed;

  AIMessage({
    required this.id,
    required this.conversationId,
    required this.role,
    required this.content,
    this.metadata,
    this.isRead = false,
    required this.createdAt,
    this.processedAt,
    this.modelUsed,
  });

  factory AIMessage.fromMap(Map<String, dynamic> data) {
    return AIMessage(
      id: data['id']?.toString() ?? '',
      conversationId: data['conversation_id']?.toString() ?? '',
      role: _parseMessageRole(data['role']),
      content: data['content'] ?? '',
      metadata: data['metadata'] as Map<String, dynamic>?,
      isRead: data['is_read'] ?? false,
      createdAt: DateTime.parse(data['created_at'] ?? DateTime.now().toIso8601String()),
      processedAt: data['processed_at'] != null 
          ? DateTime.parse(data['processed_at']) 
          : null,
      modelUsed: data['model_used'],
    );
  }

  static MessageRole _parseMessageRole(String? role) {
    if (role == null) return MessageRole.user;
    switch (role.toLowerCase()) {
      case 'user':
        return MessageRole.user;
      case 'assistant':
        return MessageRole.assistant;
      case 'system':
        return MessageRole.system;
      default:
        return MessageRole.user;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'role': role.toString().split('.').last,
      'content': content,
      'metadata': metadata,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
      'model_used': modelUsed,
    };
  }

  AIMessage copyWith({
    String? id,
    String? conversationId,
    MessageRole? role,
    String? content,
    Map<String, dynamic>? metadata,
    bool? isRead,
    DateTime? createdAt,
    DateTime? processedAt,
    String? modelUsed,
  }) {
    return AIMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      role: role ?? this.role,
      content: content ?? this.content,
      metadata: metadata ?? this.metadata,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
      modelUsed: modelUsed ?? this.modelUsed,
    );
  }
}

class AICompanion {
  final String id;
  final String name;
  final String avatar;
  final CompanionPersonality personality;
  final String description;
  final String systemPrompt;
  final List<String> capabilities;
  final bool isActive;
  final int usageCount;
  final DateTime createdAt;

  AICompanion({
    required this.id,
    required this.name,
    required this.avatar,
    required this.personality,
    required this.description,
    required this.systemPrompt,
    required this.capabilities,
    this.isActive = true,
    this.usageCount = 0,
    required this.createdAt,
  });

  factory AICompanion.fromMap(Map<String, dynamic> data) {
    return AICompanion(
      id: data['id']?.toString() ?? '',
      name: data['name'] ?? 'Companion',
      avatar: data['avatar'] ?? '',
      personality: AIConversation._parsePersonality(data['personality']),
      description: data['description'] ?? '',
      systemPrompt: data['system_prompt'] ?? '',
      capabilities: List<String>.from(data['capabilities'] ?? []),
      isActive: data['is_active'] ?? true,
      usageCount: data['usage_count'] ?? 0,
      createdAt: DateTime.parse(data['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar': avatar,
      'personality': personality.toString().split('.').last,
      'description': description,
      'system_prompt': systemPrompt,
      'capabilities': capabilities,
      'is_active': isActive,
      'usage_count': usageCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AICompanion copyWith({
    String? id,
    String? name,
    String? avatar,
    CompanionPersonality? personality,
    String? description,
    String? systemPrompt,
    List<String>? capabilities,
    bool? isActive,
    int? usageCount,
    DateTime? createdAt,
  }) {
    return AICompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      personality: personality ?? this.personality,
      description: description ?? this.description,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      capabilities: capabilities ?? this.capabilities,
      isActive: isActive ?? this.isActive,
      usageCount: usageCount ?? this.usageCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class AIRecommendation {
  final String id;
  final String userId;
  final String conversationId;
  final String type; // 'media', 'user', 'category', 'feature'
  final String title;
  final String description;
  final String? imageUrl;
  final String? targetId; // media_id, user_id, etc.
  final Map<String, dynamic> data;
  final double relevanceScore;
  final bool isViewed;
  final bool isInteracted;
  final DateTime createdAt;

  AIRecommendation({
    required this.id,
    required this.userId,
    required this.conversationId,
    required this.type,
    required this.title,
    required this.description,
    this.imageUrl,
    this.targetId,
    required this.data,
    required this.relevanceScore,
    this.isViewed = false,
    this.isInteracted = false,
    required this.createdAt,
  });

  factory AIRecommendation.fromMap(Map<String, dynamic> data) {
    return AIRecommendation(
      id: data['id']?.toString() ?? '',
      userId: data['user_id']?.toString() ?? '',
      conversationId: data['conversation_id']?.toString() ?? '',
      type: data['type'] ?? 'media',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['image_url'],
      targetId: data['target_id']?.toString(),
      data: data['data'] as Map<String, dynamic>? ?? {},
      relevanceScore: (data['relevance_score'] as num?)?.toDouble() ?? 0.0,
      isViewed: data['is_viewed'] ?? false,
      isInteracted: data['is_interacted'] ?? false,
      createdAt: DateTime.parse(data['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'conversation_id': conversationId,
      'type': type,
      'title': title,
      'description': description,
      'image_url': imageUrl,
      'target_id': targetId,
      'data': data,
      'relevance_score': relevanceScore,
      'is_viewed': isViewed,
      'is_interacted': isInteracted,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AIRecommendation copyWith({
    String? id,
    String? userId,
    String? conversationId,
    String? type,
    String? title,
    String? description,
    String? imageUrl,
    String? targetId,
    Map<String, dynamic>? data,
    double? relevanceScore,
    bool? isViewed,
    bool? isInteracted,
    DateTime? createdAt,
  }) {
    return AIRecommendation(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      conversationId: conversationId ?? this.conversationId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      targetId: targetId ?? this.targetId,
      data: data ?? this.data,
      relevanceScore: relevanceScore ?? this.relevanceScore,
      isViewed: isViewed ?? this.isViewed,
      isInteracted: isInteracted ?? this.isInteracted,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
