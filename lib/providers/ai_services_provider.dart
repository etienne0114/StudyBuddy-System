// lib/data/providers/ai_services_provider.dart

import 'package:flutter/material.dart';
import 'package:study_scheduler/data/models/ai_service.dart';
import 'package:study_scheduler/data/models/study_material.dart';
import 'package:study_scheduler/data/repositories/study_materials_repository.dart';

class AIServicesProvider extends ChangeNotifier {
  final StudyMaterialsRepository _materialsRepository = StudyMaterialsRepository();
  
  final List<AIService> services = [
    AIService(
      name: 'Claude',
      iconPath: 'assets/icons/claude_icon.png',
      url: 'https://claude.ai',
      color: Colors.purple,
      description: 'Claude is an AI assistant created by Anthropic, designed to be helpful, harmless, and honest.',
      capabilities: [
        'Natural language understanding',
        'Long context window',
        'Nuanced reasoning',
        'Creative writing assistance',
        'Detailed explanations'
      ],
    ),
    AIService(
      name: 'ChatGPT',
      iconPath: 'assets/icons/chatgpt_icon.png',
      url: 'https://chat.openai.com',
      color: Colors.green,
      description: 'ChatGPT is an AI chatbot developed by OpenAI, based on the GPT language models.',
      capabilities: [
        'Conversational responses',
        'Code generation and debugging',
        'Language translation',
        'Content summarization',
        'Problem-solving assistance'
      ],
    ),
    AIService(
      name: 'GitHub Copilot',
      iconPath: 'assets/icons/copilot_icon.png',
      url: 'https://github.com/features/copilot',
      color: Colors.blue,
      description: 'GitHub Copilot is an AI pair programmer that offers autocomplete-style suggestions as you code.',
      capabilities: [
        'Code completion',
        'Function generation',
        'Documentation assistance',
        'Code explanations',
        'Test generation'
      ],
    ),
    AIService(
      name: 'DeepSeek',
      iconPath: 'assets/icons/deepseek_icon.png',
      url: 'https://deepseek.com',
      color: Colors.orange,
      description: 'DeepSeek is an AI assistant with strong capabilities in code and mathematical problem-solving.',
      capabilities: [
        'Advanced mathematical solutions',
        'Code generation',
        'Research assistance',
        'Technical explanations',
        'Academic writing support'
      ],
    ),
    AIService(
      name: 'Perplexity',
      iconPath: 'assets/icons/perplexity_icon.png',
      url: 'https://perplexity.ai',
      color: Colors.teal,
      description: 'Perplexity is an AI-powered search engine that provides answers with cited sources.',
      capabilities: [
        'Real-time information retrieval',
        'Citation of sources',
        'Follow-up questions',
        'Multidisciplinary knowledge',
        'Visual content understanding'
      ],
    ),
  ];

  AIService getServiceByName(String name) {
    return services.firstWhere(
      (service) => service.name == name,
      orElse: () => services.first,
    );
  }
  
  // Get recommended study materials based on learning patterns
  Future<List<StudyMaterial>> getRecommendedMaterials() async {
    // This would normally use advanced algorithms to recommend materials
    // For now, we'll just return all materials sorted by most recently updated
    try {
      final materials = await _materialsRepository.getMaterials();
      
      // Sort by recently updated
      materials.sort((a, b) => 
        DateTime.parse(b.updatedAt).compareTo(DateTime.parse(a.updatedAt))
      );
      
      return materials.take(5).toList();
    } catch (e) {
      print('Error getting recommended materials: $e');
      return [];
    }
  }
  
  // Track usage of study materials with AI for personalized recommendations
  Future<void> trackMaterialUsage(int materialId, String aiService) async {
    // In a real implementation, this would track usage patterns
    try {
      // Retrieve the material
      final material = await _materialsRepository.getMaterialById(materialId);
      
      if (material != null) {
        // Log the interaction for future recommendations
        print('Tracked usage of material: ${material.title} with AI service: $aiService');
        
        // Store tracking information in the database
        await _materialsRepository.trackAIUsage(materialId, aiService, null);
      }
    } catch (e) {
      print('Error tracking material usage: $e');
    }
  }
}