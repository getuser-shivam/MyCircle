import 'package:flutter/material.dart';

class AntigravityProvider extends ChangeNotifier {
  final List<String> availableModels = [
    "antigravity-v1",
    "Gemini 3 Pro (High)",
    "Gemini 3 Pro (Low)",
    "Gemini 3 Flash",
    "Claude Sonnet 4.5",
    "Claude Sonnet 4.5 (Thinking)",
    "Claude Opus 4.5 (Thinking)",
    "Claude Opus 4.6 (Thinking)",
    "GPT-OSS 120B (Medium)",
  ];

  String _selectedModel = "antigravity-v1";
  String get selectedModel => _selectedModel;

  void setModel(String model) {
    if (availableModels.contains(model)) {
      _selectedModel = model;
      notifyListeners();
    }
  }

  // Simulation of AI processing
  bool _isProcessing = false;
  bool get isProcessing => _isProcessing;

  Future<void> processQuery(String query) async {
    _isProcessing = true;
    notifyListeners();
    
    // Simulate thinking time
    await Future.delayed(const Duration(seconds: 2));
    
    _isProcessing = false;
    notifyListeners();
  }
}
