// lib/services/ai_assistant_service.dart

import 'package:flutter/material.dart';
import 'package:study_scheduler/data/models/study_material.dart';
import 'package:study_scheduler/data/repositories/study_materials_repository.dart';
import 'package:study_scheduler/utils/compact_ai_helper.dart';

/// Service to manage AI functionality throughout the app
class AIAssistantService extends ChangeNotifier {
  final StudyMaterialsRepository _materialsRepository;
  final CompactAIHelper _compactHelper = CompactAIHelper();
  
  // Track user preferences
  String _preferredAIService = 'Claude';
  bool _aiAssistantEnabled = true;
  
  // Getters
  String get preferredAIService => _preferredAIService;
  bool get aiAssistantEnabled => _aiAssistantEnabled;
  CompactAIHelper get compactHelper => _compactHelper;
  
  // Constructor with dependency injection
  AIAssistantService(this._materialsRepository) {
    _loadPreferences();
  }
  
  // Load user preferences
  Future<void> _loadPreferences() async {
    try {
      final preferredService = await _materialsRepository.getMostUsedAIService();
      if (preferredService != null) {
        _preferredAIService = preferredService;
        notifyListeners();
      }
    } catch (e) {
      // Fallback to default if there's an error
      debugPrint('Error loading AI preferences: $e');
    }
  }
  
  // Set preferred AI service
  Future<void> setPreferredAIService(String service) async {
    _preferredAIService = service;
    notifyListeners();
    
    // In a real implementation, save this to user preferences
  }
  
  // Enable/disable AI assistant
  void setAIAssistantEnabled(bool enabled) {
    _aiAssistantEnabled = enabled;
    notifyListeners();
    
    // In a real implementation, save this to user preferences
  }
  
  // Track AI usage
  Future<void> trackAIUsage(String? query, String aiService, {StudyMaterial? material}) async {
    try {
      await _materialsRepository.trackAIUsage(
        material?.id,
        aiService,
        query,
      );
    } catch (e) {
      debugPrint('Error tracking AI usage: $e');
    }
  }
  
  // Get recommended AI for a category
  Future<String> getRecommendedAIForCategory(String category) async {
    try {
      final recommendations = await _materialsRepository.getRecommendedAIServicesForCategory(category);
      if (recommendations.isNotEmpty) {
        return recommendations.first;
      }
    } catch (e) {
      debugPrint('Error getting recommended AI: $e');
    }
    
    return _preferredAIService; // Fallback to user's preferred service
  }
  
  // Generate AI response (simulated)
  String generateResponse(String query, String aiService) {
    // Real implementation would call the actual AI service
    // This is a simulated implementation
    
    if (query.toLowerCase().contains('plan') || 
        query.toLowerCase().contains('schedule')) {
      return '''
Here's a suggested daily plan:

**Morning Routine**
- 7:00 AM: Wake up and hydrate
- 7:15 AM: Quick exercise/stretching (15 min)
- 8:00 AM: Breakfast and preparation
- 8:30 AM: Review your day's goals

**Study Sessions**
- 9:00 AM - 10:30 AM: Focus session 1
- 10:30 AM - 10:45 AM: Short break
- 10:45 AM - 12:15 PM: Focus session 2
- 12:15 PM - 1:00 PM: Lunch break

**Afternoon**
- 1:00 PM - 2:30 PM: Focus session 3
- 2:30 PM - 2:45 PM: Short break
- 2:45 PM - 4:15 PM: Focus session 4
- 4:15 PM - 5:00 PM: Review and planning

**Evening**
- 5:00 PM - 6:00 PM: Exercise/personal time
- 6:00 PM - 7:00 PM: Dinner
- 7:00 PM - 9:00 PM: Relaxation or light review
- 9:00 PM: Wind down routine

Would you like me to help you customize this plan?
''';
    } else if (query.toLowerCase().contains('study') || 
               query.toLowerCase().contains('learn') ||
               query.toLowerCase().contains('understand')) {
      return '''
Here are some effective study techniques:

1. **Spaced Repetition**: Review material at increasing intervals

2. **Active Recall**: Test yourself rather than passively reviewing

3. **Pomodoro Technique**: 25 minutes of focused study followed by a 5-minute break

4. **Feynman Technique**:
   - Choose a concept
   - Explain it in simple terms
   - Identify gaps in your explanation
   - Review and simplify further

5. **Mind Mapping**: Create visual connections between related concepts

6. **Interleaving**: Mix up different subjects or problem types

Which of these techniques would you like to try?
''';
    } else {
      return '''
I'm here to help with your studies! I can assist with:

- Planning your study schedule
- Explaining difficult concepts
- Providing study techniques
- Helping you stay motivated
- Creating practice questions
- Summarizing material

What specific help do you need today?
''';
    }
  }
}