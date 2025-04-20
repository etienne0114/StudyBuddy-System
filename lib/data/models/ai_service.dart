// lib/data/models/ai_service.dart

import 'package:flutter/material.dart';

class AIService {
  static const String openai = 'openai';
  static const String claude = 'claude';

  static const List<String> availableServices = [openai, claude];

  static const Color openaiColor = Color(0xFF10A37F);
  static const Color claudeColor = Color(0xFF6B46C1);
  static const Color defaultColor = Color(0xFF6200EE);

  final String name;
  final String apiKey;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime updatedAt;

  AIService({
    required this.name,
    required this.apiKey,
    required this.isEnabled,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AIService.fromMap(Map<String, dynamic> map) {
    return AIService(
      name: map['service_name'] as String,
      apiKey: map['api_key'] as String,
      isEnabled: map['is_enabled'] == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'service_name': name,
      'api_key': apiKey,
      'is_enabled': isEnabled ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  AIService copyWith({
    String? name,
    String? apiKey,
    bool? isEnabled,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AIService(
      name: name ?? this.name,
      apiKey: apiKey ?? this.apiKey,
      isEnabled: isEnabled ?? this.isEnabled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static List<AIService> getAllServices() {
    return [
      const AIService(
        name: 'Claude',
        apiKey: 'claude-api-key',
        isEnabled: true,
        createdAt: DateTime(2024, 2, 29),
        updatedAt: DateTime(2024, 2, 29),
      ),
      const AIService(
        name: 'GPT-4',
        apiKey: 'gpt-4-api-key',
        isEnabled: true,
        createdAt: DateTime(2024, 2, 29),
        updatedAt: DateTime(2024, 2, 29),
      ),
      const AIService(
        name: 'Study Assistant',
        apiKey: 'study-assistant-api-key',
        isEnabled: true,
        createdAt: DateTime(2024, 2, 29),
        updatedAt: DateTime(2024, 2, 29),
      ),
      const AIService(
        name: 'Perplexity',
        apiKey: 'perplexity-api-key',
        isEnabled: true,
        createdAt: DateTime(2024, 2, 29),
        updatedAt: DateTime(2024, 2, 29),
      ),
      const AIService(
        name: 'DeepSeek',
        apiKey: 'deepseek-api-key',
        isEnabled: true,
        createdAt: DateTime(2024, 2, 29),
        updatedAt: DateTime(2024, 2, 29),
      ),
      const AIService(
        name: 'You',
        apiKey: 'you-api-key',
        isEnabled: true,
        createdAt: DateTime(2024, 2, 29),
        updatedAt: DateTime(2024, 2, 29),
      ),
    ];
  }

  static AIService getServiceByName(String name) {
    return getAllServices().firstWhere(
      (service) => service.name.toLowerCase() == name.toLowerCase(),
      orElse: () => getAllServices().first,
    );
  }

  bool hasCapability(String capability) {
    // Implementation of hasCapability method
    return false; // Placeholder return, actual implementation needed
  }

  String getSimulatedResponse(String query) {
    // This is a fallback method for when API calls fail or for testing
    switch (name.toLowerCase()) {
      case 'claude':
        return '''
I'm Claude, an AI assistant specialized in study planning and material analysis. Here's my response to your query:

$query

I can help you with:
- Creating personalized study plans
- Analyzing study materials
- Optimizing your schedule
- Answering questions about your studies
- Generating learning paths

Would you like me to help you with any of these tasks?
''';
      case 'gpt-4':
        return '''
I'm GPT-4, a powerful AI assistant for comprehensive study help. Here's my response to your query:

$query

I can assist you with:
- Generating study content
- Creating study plans
- Analyzing materials
- Generating practice quizzes
- Answering complex questions

How can I help you with your studies today?
''';
      case 'study assistant':
        return '''
I'm your Study Assistant, specialized in organizing and planning your studies. Here's my response to your query:

$query

I can help you with:
- Organizing study materials
- Creating study plans
- Tracking your progress
- Recommending study resources
- Managing your study schedule

What would you like me to help you with?
''';
      case 'perplexity':
        return '''
I'm Perplexity, focused on deep research and analysis. Here's my response to your query:

$query

I can assist you with:
- In-depth research
- Complex analysis
- Source verification
- Deep learning concepts
- Academic writing

How can I help with your research today?
''';
      case 'deepseek':
        return '''
I'm DeepSeek, specialized in technical and scientific studies. Here's my response to your query:

$query

I can help you with:
- Technical concepts
- Scientific research
- Code understanding
- Problem solving
- Mathematical analysis

What technical or scientific topic would you like to explore?
''';
      case 'you':
        return '''
I'm your personalized AI tutor. Here's my response to your query:

$query

I can help you with:
- Personalized learning paths
- Adaptive teaching methods
- Progress tracking
- Study recommendations
- Custom practice exercises

Let's work together to achieve your learning goals!
''';
      default:
        return 'I can help you with your studies. What would you like to know about: $query';
    }
  }
}