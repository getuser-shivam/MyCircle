import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ai_chat.dart';

class AIChatRepository {
  final SupabaseClient _supabase;

  AIChatRepository(this._supabase);

  // Conversation operations
  Future<List<AIConversation>> getUserConversations(String userId) async {
    try {
      final data = await _supabase
          .from('ai_conversations')
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false);
      
      return data.map((item) => AIConversation.fromMap(item)).toList();
    } catch (e) {
      throw Exception('Failed to load conversations: $e');
    }
  }

  Future<AIConversation> createConversation({
    required String userId,
    required String title,
    required ConversationType type,
    required CompanionPersonality personality,
    String? companionId,
  }) async {
    try {
      final conversationData = {
        'user_id': userId,
        'companion_id': companionId,
        'title': title,
        'type': type.toString().split('.').last,
        'personality': personality.toString().split('.').last,
        'is_active': true,
        'message_count': 0,
      };

      final data = await _supabase
          .from('ai_conversations')
          .insert(conversationData)
          .select()
          .single();

      return AIConversation.fromMap(data);
    } catch (e) {
      throw Exception('Failed to create conversation: $e');
    }
  }

  Future<AIConversation> updateConversation(String conversationId, Map<String, dynamic> updates) async {
    try {
      final data = await _supabase
          .from('ai_conversations')
          .update(updates)
          .eq('id', conversationId)
          .select()
          .single();

      return AIConversation.fromMap(data);
    } catch (e) {
      throw Exception('Failed to update conversation: $e');
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      await _supabase
          .from('ai_conversations')
          .delete()
          .eq('id', conversationId);
    } catch (e) {
      throw Exception('Failed to delete conversation: $e');
    }
  }

  // Message operations
  Future<List<AIMessage>> getConversationMessages(String conversationId) async {
    try {
      final data = await _supabase
          .from('ai_messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false);
      
      return data.map((item) => AIMessage.fromMap(item)).toList();
    } catch (e) {
      throw Exception('Failed to load messages: $e');
    }
  }

  Future<AIMessage> createMessage({
    required String conversationId,
    required MessageRole role,
    required String content,
    Map<String, dynamic>? metadata,
    String? modelUsed,
  }) async {
    try {
      final messageData = {
        'conversation_id': conversationId,
        'role': role.toString().split('.').last,
        'content': content,
        'metadata': metadata,
        'is_read': false,
        'model_used': modelUsed,
      };

      final data = await _supabase
          .from('ai_messages')
          .insert(messageData)
          .select()
          .single();

      // Update conversation message count and last message timestamp
      await _supabase
          .from('ai_conversations')
          .update({
            'message_count': _supabase.rpc('increment', params: {'count': 1}),
            'last_message_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', conversationId);

      return AIMessage.fromMap(data);
    } catch (e) {
      throw Exception('Failed to create message: $e');
    }
  }

  Future<AIMessage> updateMessage(String messageId, Map<String, dynamic> updates) async {
    try {
      final data = await _supabase
          .from('ai_messages')
          .update(updates)
          .eq('id', messageId)
          .select()
          .single();

      return AIMessage.fromMap(data);
    } catch (e) {
      throw Exception('Failed to update message: $e');
    }
  }

  // Real-time subscriptions
  Stream<List<AIMessage>> getMessageStream(String conversationId) {
    return _supabase
        .from('ai_messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at')
        .map((data) => data.map((item) => AIMessage.fromMap(item)).toList());
  }

  Stream<List<AIConversation>> getConversationStream(String userId) {
    return _supabase
        .from('ai_conversations')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('updated_at', ascending: false)
        .map((data) => data.map((item) => AIConversation.fromMap(item)).toList());
  }
}

class AICompanionService {
  final SupabaseClient _supabase;

  AICompanionService(this._supabase);

  Future<List<AICompanion>> getAvailableCompanions() async {
    try {
      final data = await _supabase
          .from('ai_companions')
          .select()
          .eq('is_active', true)
          .order('usage_count', ascending: false);
      
      return data.map((item) => AICompanion.fromMap(item)).toList();
    } catch (e) {
      throw Exception('Failed to load companions: $e');
    }
  }

  Future<AICompanion> getCompanion(String companionId) async {
    try {
      final data = await _supabase
          .from('ai_companions')
          .select()
          .eq('id', companionId)
          .single();
      
      return AICompanion.fromMap(data);
    } catch (e) {
      throw Exception('Failed to load companion: $e');
    }
  }

  Future<void> incrementCompanionUsage(String companionId) async {
    try {
      await _supabase
          .from('ai_companions')
          .update({
            'usage_count': _supabase.rpc('increment', params: {'count': 1}),
          })
          .eq('id', companionId);
    } catch (e) {
      throw Exception('Failed to update companion usage: $e');
    }
  }

  // Predefined system prompts for different personalities
  String getSystemPrompt(CompanionPersonality personality) {
    switch (personality) {
      case CompanionPersonality.friendly:
        return '''You are a friendly AI companion for MyCircle. You are warm, casual, and encouraging. 
        You help users discover content, connect with others, and navigate the platform. 
        Use emojis occasionally and maintain a positive, approachable tone.''';
      
      case CompanionPersonality.professional:
        return '''You are a professional AI assistant for MyCircle. You are formal, knowledgeable, and efficient.
        You provide accurate information, help with platform features, and offer sophisticated recommendations.
        Maintain a professional tone and focus on practical solutions.''';
      
      case CompanionPersonality.witty:
        return '''You are a witty AI companion for MyCircle. You are humorous, clever, and entertaining.
        You make content discovery fun, engage with playful banter, and keep conversations lively.
        Use appropriate humor and clever wordplay while being helpful.''';
      
      case CompanionPersonality.supportive:
        return '''You are a supportive AI companion for MyCircle. You are empathetic, caring, and motivating.
        You encourage users, celebrate their achievements, and provide emotional support.
        Listen actively and respond with genuine care and encouragement.''';
      
      case CompanionPersonality.analytical:
        return '''You are an analytical AI assistant for MyCircle. You are logical, detailed, and insightful.
        You provide deep analysis, explain complex topics clearly, and help users understand patterns.
        Focus on data-driven insights and thorough explanations.''';
    }
  }
}

class AIRecommendationService {
  final SupabaseClient _supabase;

  AIRecommendationService(this._supabase);

  Future<List<AIRecommendation>> getRecommendations(String userId, {int limit = 20}) async {
    try {
      final data = await _supabase
          .from('ai_recommendations')
          .select()
          .eq('user_id', userId)
          .order('relevance_score', ascending: false)
          .limit(limit);
      
      return data.map((item) => AIRecommendation.fromMap(item)).toList();
    } catch (e) {
      throw Exception('Failed to load recommendations: $e');
    }
  }

  Future<AIRecommendation> createRecommendation({
    required String userId,
    required String conversationId,
    required String type,
    required String title,
    required String description,
    String? imageUrl,
    String? targetId,
    required Map<String, dynamic> data,
    required double relevanceScore,
  }) async {
    try {
      final recommendationData = {
        'user_id': userId,
        'conversation_id': conversationId,
        'type': type,
        'title': title,
        'description': description,
        'image_url': imageUrl,
        'target_id': targetId,
        'data': data,
        'relevance_score': relevanceScore,
        'is_viewed': false,
        'is_interacted': false,
      };

      final result = await _supabase
          .from('ai_recommendations')
          .insert(recommendationData)
          .select()
          .single();

      return AIRecommendation.fromMap(result);
    } catch (e) {
      throw Exception('Failed to create recommendation: $e');
    }
  }

  Future<void> markRecommendationViewed(String recommendationId) async {
    try {
      await _supabase
          .from('ai_recommendations')
          .update({'is_viewed': true})
          .eq('id', recommendationId);
    } catch (e) {
      throw Exception('Failed to mark recommendation as viewed: $e');
    }
  }

  Future<void> markRecommendationInteracted(String recommendationId) async {
    try {
      await _supabase
          .from('ai_recommendations')
          .update({'is_interacted': true})
          .eq('id', recommendationId);
    } catch (e) {
      throw Exception('Failed to mark recommendation as interacted: $e');
    }
  }

  Future<List<AIRecommendation>> getRecommendationsByType(String userId, String type) async {
    try {
      final data = await _supabase
          .from('ai_recommendations')
          .select()
          .eq('user_id', userId)
          .eq('type', type)
          .order('relevance_score', ascending: false)
          .limit(10);
      
      return data.map((item) => AIRecommendation.fromMap(item)).toList();
    } catch (e) {
      throw Exception('Failed to load recommendations by type: $e');
    }
  }
}
