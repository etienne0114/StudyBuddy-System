// lib/data/models/ai_service.dart

import 'package:flutter/material.dart';

class AIService {
  final String name;
  final String description;
  final Color color;
  final List<String> capabilities;
  final bool isAvailable;
  final String apiEndpoint;
  final Map<String, dynamic> settings;

  const AIService({
    required this.name,
    required this.description,
    required this.color,
    required this.capabilities,
    required this.isAvailable,
    required this.apiEndpoint,
    required this.settings,
  });

  static List<AIService> getAllServices() {
    return [
      AIService(
        name: 'Claude',
        description: 'Advanced AI assistant for study planning and material analysis',
        color: Colors.purple,
        capabilities: [
          'Study Planning',
          'Material Analysis',
          'Question Answering',
          'Schedule Optimization',
          'Learning Path Generation'
        ],
        isAvailable: true,
        apiEndpoint: 'https://api.anthropic.com/v1/messages',
        settings: {
          'model': 'claude-3-opus-20240229',
          'max_tokens': 4000,
        },
      ),
      AIService(
        name: 'GPT-4',
        description: 'Powerful language model for comprehensive study assistance',
        color: Colors.green,
        capabilities: [
          'Content Generation',
          'Study Planning',
          'Material Analysis',
          'Quiz Generation'
        ],
        isAvailable: true,
        apiEndpoint: 'https://api.openai.com/v1/chat/completions',
        settings: {
          'model': 'gpt-4-turbo-preview',
          'max_tokens': 4000,
        },
      ),
      AIService(
        name: 'Study Assistant',
        description: 'Specialized AI for study material organization and planning',
        color: Colors.blue,
        capabilities: [
          'Material Organization',
          'Study Planning',
          'Progress Tracking',
          'Recommendation Engine'
        ],
        isAvailable: true,
        apiEndpoint: 'https://api.study-assistant.com/v1',
        settings: {
          'model': 'study-assistant-v2',
          'max_tokens': 2000,
        },
      ),
      AIService(
        name: 'Perplexity',
        description: 'Research-focused AI for deep learning and analysis',
        color: Colors.orange,
        capabilities: [
          'Research',
          'Deep Learning',
          'Content Analysis',
          'Source Verification'
        ],
        isAvailable: true,
        apiEndpoint: 'https://api.perplexity.ai/v1',
        settings: {
          'model': 'perplexity-pro',
          'max_tokens': 3000,
        },
      ),
      AIService(
        name: 'DeepSeek',
        description: 'Advanced AI for technical and scientific study materials',
        color: Colors.indigo,
        capabilities: [
          'Technical Analysis',
          'Scientific Research',
          'Code Understanding',
          'Problem Solving'
        ],
        isAvailable: true,
        apiEndpoint: 'https://api.deepseek.com/v1',
        settings: {
          'model': 'deepseek-coder',
          'max_tokens': 4000,
        },
      ),
      AIService(
        name: 'You',
        description: 'Personalized AI tutor for adaptive learning',
        color: Colors.teal,
        capabilities: [
          'Personalized Learning',
          'Adaptive Teaching',
          'Progress Tracking',
          'Study Recommendations'
        ],
        isAvailable: true,
        apiEndpoint: 'https://api.you.com/v1',
        settings: {
          'model': 'you-tutor-v1',
          'max_tokens': 3000,
        },
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
    return capabilities.contains(capability);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'color': color.value,
      'capabilities': capabilities,
      'isAvailable': isAvailable,
      'apiEndpoint': apiEndpoint,
      'settings': settings,
    };
  }

  factory AIService.fromMap(Map<String, dynamic> map) {
    return AIService(
      name: map['name'] as String,
      description: map['description'] as String,
      color: Color(map['color'] as int),
      capabilities: List<String>.from(map['capabilities'] as List),
      isAvailable: map['isAvailable'] as bool,
      apiEndpoint: map['apiEndpoint'] as String,
      settings: Map<String, dynamic>.from(map['settings'] as Map),
    );
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