// lib/managers/ai_assistant_manager.dart
// This is a singleton manager to handle all AI operations seamlessly

import 'package:flutter/material.dart';
import 'package:study_scheduler/data/models/study_material.dart';
import 'package:study_scheduler/data/models/ai_service.dart';
import 'package:study_scheduler/data/repositories/study_materials_repository.dart';
import 'package:flutter/foundation.dart';

class AIAssistantManager {
  // Singleton instance
  static final AIAssistantManager _instance = AIAssistantManager._internal();
  static AIAssistantManager get instance => _instance;
  
  // Private constructor
  AIAssistantManager._internal();
  
  // Repository reference
  final StudyMaterialsRepository _repository = StudyMaterialsRepository();
  
  // User's preferred AI service
  String _preferredService = 'Claude';
  String get preferredService => _preferredService;
  
  // Initialize manager
  Future<void> initialize() async {
    try {
      // Create AI tables if they don't exist
      await _repository.ensureAITablesExist();
      
      // Load user preferences
      final preferred = await _repository.getMostUsedAIService();
      if (preferred != null) {
        _preferredService = preferred;
      }
    } catch (e) {
      // Handle errors silently
      if (kDebugMode) {
        print('AI Assistant initialization issue (handled silently): $e');
      }
    }
  }
  
  // Track AI usage without failing
  Future<void> trackUsage(String aiService, String? query, {StudyMaterial? material}) async {
    try {
      await _repository.trackAIUsage(material?.id, aiService, query);
    } catch (e) {
      // Silently handle errors
      if (kDebugMode) {
        print('AI usage tracking issue (handled silently): $e');
      }
    }
  }
  
  // Get response from AI (simulated)
  Future<String> getAIResponse(String query, String aiService, {StudyMaterial? material}) async {
    try {
      // Track usage first
      await trackUsage(aiService, query, material: material);
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Get the AI service instance
      final service = AIService.getServiceByName(aiService);
      
      // Return simulated response
      return service.getSimulatedResponse(query);
    } catch (e) {
      // Return a generic response if there's an error
      if (kDebugMode) {
        print('AI response generation issue (handled silently): $e');
      }
      return "I can help you plan your day, understand study materials, or answer questions about your studies. What would you like help with?";
    }
  }
  
  // Get AI service color
  Color getServiceColor(String serviceName) {
    final service = AIService.getServiceByName(serviceName);
    return service.color;
  }

  // Get available service names
  List<String> getAvailableServiceNames() {
    return AIService.getAllServices().map((service) => service.name).toList();
  }
}