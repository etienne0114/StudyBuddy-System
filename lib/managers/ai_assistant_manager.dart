// lib/managers/ai_assistant_manager.dart
// This is a singleton manager to handle all AI operations seamlessly

import 'package:flutter/material.dart';
import 'package:study_scheduler/data/models/study_material.dart';
import 'package:study_scheduler/data/models/ai_service.dart' as ai_model;
import 'package:study_scheduler/data/repositories/study_materials_repository.dart';
import 'package:study_scheduler/services/ai_service.dart';
import 'package:study_scheduler/utils/logger.dart';

enum AIAssistantState {
  idle,
  loading,
  error,
  success
}

class AIAssistantManager extends ChangeNotifier {
  // Singleton instance
  static final AIAssistantManager _instance = AIAssistantManager._internal();
  factory AIAssistantManager() => _instance;
  
  // Dependencies
  final StudyMaterialsRepository _repository = StudyMaterialsRepository();
  final AIService _aiService = AIService();
  
  // State management
  AIAssistantState _state = AIAssistantState.idle;
  AIAssistantState get state => _state;
  
  String _errorMessage = '';
  String get errorMessage => _errorMessage;
  
  String _lastResponse = '';
  String get lastResponse => _lastResponse;
  
  String _preferredService = 'Claude';
  String get preferredService => _preferredService;
  
  bool get isReady => _state == AIAssistantState.idle;
  bool get isProcessing => _state == AIAssistantState.loading;
  bool get hasError => _state == AIAssistantState.error;
  
  // Private constructor
  AIAssistantManager._internal();
  
  // Initialize manager
  Future<void> initialize() async {
    if (_state == AIAssistantState.loading) return;
    
    try {
      _setLoading();
      
      // Initialize AI service first
      await _aiService.initialize();
      
      // Create AI tables if they don't exist
      await _repository.ensureAITablesExist();
      
      // Load user preferences
      final preferred = await _repository.getMostUsedAIService();
      if (preferred != null) {
        _preferredService = preferred;
      }
      
      _state = AIAssistantState.idle;
      notifyListeners();
    } catch (e) {
      Logger.error('AI Assistant initialization failed: $e');
      _setError('Failed to initialize AI Assistant. Please check your API keys.');
    }
  }
  
  // Get AI response with error handling and state management
  Future<String> getResponse(String query, {String? service}) async {
    if (_state == AIAssistantState.loading) {
      return 'Please wait for the current request to complete.';
    }
    
    _setLoading();
    try {
      final response = await _aiService.getResponse(query, service: service);
      _setSuccess(response);
      return response;
    } catch (e) {
      Logger.error('Failed to get AI response: $e');
      _setError('Failed to get AI response. Please try again.');
      return _errorMessage;
    }
  }
  
  // Track AI usage without failing
  Future<void> _trackUsage(int? materialId, String aiService, String? query) async {
    try {
      await _repository.trackAIUsage(materialId, aiService, query);
    } catch (e) {
      // Log but don't fail
      Logger.error('Failed to track AI usage: $e');
    }
  }
  
  // Update preferred service
  Future<void> setPreferredService(String service) async {
    if (_preferredService != service) {
      _preferredService = service;
      notifyListeners();
    }
  }
  
  // Reset error state
  void resetError() {
    if (_state == AIAssistantState.error) {
      _state = AIAssistantState.idle;
      _errorMessage = '';
    }
  }
  
  // Private helper to update state
  void _setLoading() {
    _state = AIAssistantState.loading;
    _errorMessage = '';
    notifyListeners();
  }
  
  // Private helper to set error state
  void _setError(String message) {
    _state = AIAssistantState.error;
    _errorMessage = message;
    notifyListeners();
  }
  
  // Private helper to set success state
  void _setSuccess(String response) {
    _state = AIAssistantState.idle;
    _lastResponse = response;
    _errorMessage = '';
    notifyListeners();
  }
  
  // Get recommended AI service for material
  Future<String> getRecommendedService(StudyMaterial material) async {
    try {
      final recommendations = await _repository.getRecommendedAIServicesForCategory(material.category);
      return recommendations.isNotEmpty ? recommendations.first : _preferredService;
    } catch (e) {
      Logger.error('Failed to get recommended AI service: $e');
      return _preferredService;
    }
  }
  
  // Analyze material with AI
  Future<String> analyzeMaterial(StudyMaterial material) async {
    if (_state == AIAssistantState.loading) {
      return 'Please wait for the current request to complete.';
    }
    
    _setLoading();
    try {
      final service = await getRecommendedService(material);
      final response = await _aiService.analyzeMaterial(material);
      
      await _trackUsage(material.id, service, 'analyze_material');
      
      _setSuccess(response);
      return response;
    } catch (e) {
      Logger.error('Failed to analyze material: $e');
      _setError('Failed to analyze material. Please try again later.');
      return _errorMessage;
    }
  }
  
  // Get AI service color
  Color getServiceColor(String service) {
    switch (service.toLowerCase()) {
      case 'openai':
        return ai_model.AIService.openaiColor;
      case 'claude':
        return ai_model.AIService.claudeColor;
      default:
        return ai_model.AIService.defaultColor;
    }
  }

  // Get available service names
  List<String> getAvailableServiceNames() {
    return ai_model.AIService.availableServices;
  }
}