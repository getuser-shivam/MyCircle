import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/media_provider.dart';

class AISearchSuggestions extends StatefulWidget {
  final TextEditingController controller;
  final Function(String) onSuggestionSelected;

  const AISearchSuggestions({
    super.key,
    required this.controller,
    required this.onSuggestionSelected,
  });

  @override
  State<AISearchSuggestions> createState() => _AISearchSuggestionsState();
}

class _AISearchSuggestionsState extends State<AISearchSuggestions>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  List<String> _suggestions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    widget.controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onSearchChanged);
    _animationController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = widget.controller.text.trim();
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
      });
      _animationController.reverse();
      return;
    }

    if (query.length >= 2) {
      _generateSuggestions(query);
    }
  }

  Future<void> _generateSuggestions(String query) async {
    setState(() {
      _isLoading = true;
    });

    // Simulate AI processing delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Generate smart suggestions based on query
    final suggestions = _getSmartSuggestions(query);

    setState(() {
      _suggestions = suggestions;
      _isLoading = false;
    });

    if (_suggestions.isNotEmpty) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  List<String> _getSmartSuggestions(String query) {
    // Smart suggestion algorithm
    final suggestions = <String>[];

    // Add exact match with different variations
    suggestions.add(query);

    // Add popular search variations
    if (query.toLowerCase().contains('cat')) {
      suggestions.addAll(['funny cats', 'cute cats', 'cat videos', 'cat memes']);
    } else if (query.toLowerCase().contains('dog')) {
      suggestions.addAll(['funny dogs', 'cute dogs', 'dog videos', 'puppy memes']);
    } else if (query.toLowerCase().contains('funny')) {
      suggestions.addAll(['funny videos', 'funny memes', 'funny animals', 'funny fails']);
    } else if (query.toLowerCase().contains('music')) {
      suggestions.addAll(['music videos', 'electronic music', 'hip hop', 'pop music']);
    }

    // Add trending topics
    suggestions.addAll([
      'trending',
      'viral',
      'popular',
      'new',
      'hot',
      'best of week',
    ]);

    // Remove duplicates and limit to 6 suggestions
    return suggestions.toSet().take(6).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_suggestions.isEmpty && !_isLoading) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              constraints: const BoxConstraints(maxHeight: 300),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: _isLoading ? _buildLoadingState() : _buildSuggestionsList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'AI is thinking...',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return ListView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      itemCount: _suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = _suggestions[index];
        final isExactMatch = suggestion == widget.controller.text.trim();

        return InkWell(
          onTap: () => _selectSuggestion(suggestion),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: index < _suggestions.length - 1
                  ? Border(
                      bottom: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    )
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  isExactMatch ? Icons.search : Icons.smart_toy_outlined,
                  size: 20,
                  color: isExactMatch
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    suggestion,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isExactMatch ? FontWeight.w600 : FontWeight.w400,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                if (!isExactMatch)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'AI',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _selectSuggestion(String suggestion) {
    widget.controller.text = suggestion;
    widget.onSuggestionSelected(suggestion);

    // Animate out
    _animationController.reverse().then((_) {
      setState(() {
        _suggestions = [];
      });
    });
  }
}
