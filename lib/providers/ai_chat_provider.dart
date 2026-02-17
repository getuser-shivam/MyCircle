import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ai_chat.dart';
import '../services/ai_chat_service.dart';
import 'antigravity_provider.dart';

class AIChatProvider extends ChangeNotifier {
  final AIChatRepository _chatRepository;
  final AICompanionService _companionService;
  final AIRecommendationService _recommendationService;
  final AntigravityProvider _antigravityProvider;

  AIChatProvider(
    this._chatRepository,
    this._companionService,
    this._recommendationService,
    this._antigravityProvider,
  );

  // State
  List<AIConversation> _conversations = [];
  List<AIMessage> _currentMessages = [];
  List<AICompanion> _companions = [];
  List<AIRecommendation> _recommendations = [];
  
  AIConversation? _currentConversation;
  AICompanion? _selectedCompanion;
  CompanionPersonality _selectedPersonality = CompanionPersonality.friendly;
  
  bool _isLoading = false;
  bool _isSendingMessage = false;
  bool _isTyping = false;
  String? _error;

  // Getters
  List<AIConversation> get conversations => _conversations;
  List<AIMessage> get currentMessages => _currentMessages;
  List<AICompanion> get companions => _companions;
  List<AIRecommendation> get recommendations => _recommendations;
  
  AIConversation? get currentConversation => _currentConversation;
  AICompanion? get selectedCompanion => _selectedCompanion;
  CompanionPersonality get selectedPersonality => _selectedPersonality;
  
  bool get isLoading => _isLoading;
  bool get isSendingMessage => _isSendingMessage;
  bool get isTyping => _isTyping;
  String? get error => _error;

  // Initialization
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await Future.wait([
        _loadConversations(),
        _loadCompanions(),
        _loadRecommendations(),
      ]);
    } catch (e) {
      _error = e.toString();
      debugPrint('AIChatProvider initialization error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Conversation management
  Future<void> _loadConversations() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _conversations = await _chatRepository.getUserConversations(userId);
    
    // Subscribe to real-time updates
    _chatRepository.getConversationStream(userId).listen((updatedConversations) {
      _conversations = updatedConversations;
      notifyListeners();
    });
  }

  Future<void> createConversation({
    required String title,
    required ConversationType type,
    CompanionPersonality? personality,
    AICompanion? companion,
  }) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _error = 'User not authenticated';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final conversation = await _chatRepository.createConversation(
        userId: userId,
        title: title,
        type: type,
        personality: personality ?? _selectedPersonality,
        companionId: companion?.id,
      );

      _conversations.insert(0, conversation);
      await selectConversation(conversation.id);

      if (companion != null) {
        await incrementCompanionUsage(companion.id);
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Create conversation error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectConversation(String conversationId) async {
    if (_currentConversation?.id == conversationId) return;

    _isLoading = true;
    notifyListeners();

    try {
      _currentConversation = _conversations.firstWhere((c) => c.id == conversationId);
      await _loadMessages(conversationId);
    } catch (e) {
      _error = 'Conversation not found';
      debugPrint('Select conversation error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _chatRepository.deleteConversation(conversationId);
      _conversations.removeWhere((c) => c.id == conversationId);
      
      if (_currentConversation?.id == conversationId) {
        _currentConversation = null;
        _currentMessages = [];
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Delete conversation error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Message management
  Future<void> _loadMessages(String conversationId) async {
    _currentMessages = await _chatRepository.getConversationMessages(conversationId);
    
    // Subscribe to real-time message updates
    _chatRepository.getMessageStream(conversationId).listen((updatedMessages) {
      _currentMessages = updatedMessages;
      notifyListeners();
    });
  }

  Future<void> sendMessage(String content) async {
    if (_currentConversation == null || content.trim().isEmpty) return;

    _isSendingMessage = true;
    _error = null;
    notifyListeners();

    try {
      // Create user message
      final userMessage = await _chatRepository.createMessage(
        conversationId: _currentConversation!.id,
        role: MessageRole.user,
        content: content.trim(),
      );

      // Simulate AI typing
      _isTyping = true;
      notifyListeners();
      
      // Get AI response using AntigravityProvider
      final systemPrompt = _companionService.getSystemPrompt(_currentConversation!.personality);
      final fullPrompt = '$systemPrompt\n\nUser: $content';
      
      await _antigravityProvider.processQuery(fullPrompt);
      
      // Generate AI response (simplified - in production would use actual AI model)
      final aiResponse = await _generateAIResponse(content, _currentConversation!.personality);
      
      _isTyping = false;
      
      // Create AI message
      final aiMessage = await _chatRepository.createMessage(
        conversationId: _currentConversation!.id,
        role: MessageRole.assistant,
        content: aiResponse,
        modelUsed: _antigravityProvider.selectedModel,
      );

      // Generate recommendations based on conversation
      await _generateContextualRecommendations(content, aiResponse);

    } catch (e) {
      _error = e.toString();
      debugPrint('Send message error: $e');
    } finally {
      _isSendingMessage = false;
      _isTyping = false;
      notifyListeners();
    }
  }

  Future<String> _generateAIResponse(String userMessage, CompanionPersonality personality) async {
    // Simulate AI response generation
    await Future.delayed(const Duration(seconds: 1));
    
    switch (personality) {
      case CompanionPersonality.friendly:
        return "Hey! That's really interesting! 😊 I'd love to help you explore that. Have you checked out the trending content in the app? There might be something perfect for you!";
      
      case CompanionPersonality.professional:
        return "I understand your inquiry. Based on your request, I recommend exploring the relevant sections of the platform. The analytics suggest several options that align with your preferences.";
      
      case CompanionPersonality.witty:
        return "Ah, a curious mind! Excellent taste, I must say. Let me whip up some suggestions that'll knock your socks off! 🎭 Prepare for content magic!";
      
      case CompanionPersonality.supportive:
        return "I really appreciate you sharing that with me. You're taking a great step by exploring this. I'm here to support you, and I believe we'll find something wonderful that resonates with you.";
      
      case CompanionPersonality.analytical:
        return "Analyzing your request... Based on the data patterns and your historical preferences, the optimal content strategy would involve exploring categories with high engagement correlation to your query.";
    }
  }

  Future<void> _generateContextualRecommendations(String userMessage, String aiResponse) async {
    if (_currentConversation == null) return;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    try {
      // Generate contextual recommendations based on conversation
      final recommendations = _extractRecommendations(userMessage, aiResponse);
      
      for (final rec in recommendations) {
        await _recommendationService.createRecommendation(
          userId: userId,
          conversationId: _currentConversation!.id,
          type: rec['type'],
          title: rec['title'],
          description: rec['description'],
          imageUrl: rec['image_url'],
          targetId: rec['target_id'],
          data: rec['data'] ?? {},
          relevanceScore: rec['relevance_score'] ?? 0.8,
        );
      }
    } catch (e) {
      debugPrint('Generate recommendations error: $e');
    }
  }

  List<Map<String, dynamic>> _extractRecommendations(String userMessage, String aiResponse) {
    // Simplified recommendation extraction
    // In production, this would use NLP to extract relevant content recommendations
    return [
      {
        'type': 'media',
        'title': 'Trending Content',
        'description': 'Popular content matching your interests',
        'relevance_score': 0.9,
        'data': {'source': 'conversation_analysis'},
      },
      {
        'type': 'user',
        'title': 'Similar Users',
        'description': 'Connect with like-minded people',
        'relevance_score': 0.7,
        'data': {'source': 'social_graph'},
      },
    ];
  }

  // Companion management
  Future<void> _loadCompanions() async {
    _companions = await _companionService.getAvailableCompanions();
  }

  void selectCompanion(AICompanion? companion) {
    _selectedCompanion = companion;
    if (companion != null) {
      _selectedPersonality = companion.personality;
    }
    notifyListeners();
  }

  void setPersonality(CompanionPersonality personality) {
    _selectedPersonality = personality;
    notifyListeners();
  }

  Future<void> incrementCompanionUsage(String companionId) async {
    try {
      await _companionService.incrementCompanionUsage(companionId);
      
      // Update local companion usage count
      final index = _companions.indexWhere((c) => c.id == companionId);
      if (index != -1) {
        final companion = _companions[index];
        _companions[index] = companion.copyWith(usageCount: companion.usageCount + 1);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Increment companion usage error: $e');
    }
  }

  // Recommendation management
  Future<void> _loadRecommendations() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    _recommendations = await _recommendationService.getRecommendations(userId);
  }

  Future<void> markRecommendationViewed(String recommendationId) async {
    try {
      await _recommendationService.markRecommendationViewed(recommendationId);
      
      // Update local state
      final index = _recommendations.indexWhere((r) => r.id == recommendationId);
      if (index != -1) {
        _recommendations[index] = _recommendations[index].copyWith(isViewed: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Mark recommendation viewed error: $e');
    }
  }

  Future<void> markRecommendationInteracted(String recommendationId) async {
    try {
      await _recommendationService.markRecommendationInteracted(recommendationId);
      
      // Update local state
      final index = _recommendations.indexWhere((r) => r.id == recommendationId);
      if (index != -1) {
        _recommendations[index] = _recommendations[index].copyWith(isInteracted: true);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Mark recommendation interacted error: $e');
    }
  }

  // Utility methods
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void refresh() {
    initialize();
  }

  @override
  void dispose() {
    // Cleanup streams and resources
    super.dispose();
  }
}
