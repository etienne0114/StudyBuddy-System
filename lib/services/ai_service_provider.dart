import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:study_scheduler/data/models/ai_service.dart';
import 'package:study_scheduler/data/models/study_material.dart';
import 'package:study_scheduler/utils/logger.dart';

class AIServiceProvider {
  static final AIServiceProvider _instance = AIServiceProvider._internal();
  static AIServiceProvider get instance => _instance;
  
  final Dio _dio = Dio();
  final Map<String, String> _apiKeys = {};
  bool _isInitialized = false;
  
  AIServiceProvider._internal();
  
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Load API keys from secure storage (implement this based on your storage solution)
      // For now, we'll use simulated keys for testing
      _apiKeys['claude'] = 'simulated_claude_key';
      _apiKeys['gpt-4'] = 'simulated_gpt4_key';
      _apiKeys['study assistant'] = 'simulated_study_assistant_key';
      _apiKeys['perplexity'] = 'simulated_perplexity_key';
      _apiKeys['deepseek'] = 'simulated_deepseek_key';
      _apiKeys['you'] = 'simulated_you_key';
      
      _isInitialized = true;
      Logger.info('AI Service Provider initialized successfully');
    } catch (e) {
      Logger.error('Error initializing AI Service Provider: $e');
      // Continue with simulated responses
    }
  }
  
  void setApiKey(String serviceName, String apiKey) {
    _apiKeys[serviceName.toLowerCase()] = apiKey;
  }
  
  Future<String> getResponse({
    required String query,
    required AIService service,
    StudyMaterial? material,
    Map<String, dynamic>? additionalContext,
  }) async {
    try {
      if (!service.isAvailable) {
        throw Exception('Service ${service.name} is not available');
      }
      
      final apiKey = _apiKeys[service.name.toLowerCase()];
      if (apiKey == null) {
        Logger.warning('API key not set for ${service.name}, using simulated response');
        return service.getSimulatedResponse(query);
      }
      
      final headers = _getHeaders(service.name, apiKey);
      final body = _buildRequestBody(service, query, material, additionalContext);
      
      final response = await _dio.post(
        service.apiEndpoint,
        options: Options(headers: headers),
        data: body,
      );
      
      return _parseResponse(service.name, response.data);
    } catch (e) {
      Logger.error('Error getting AI response: $e');
      // Return simulated response as fallback
      return service.getSimulatedResponse(query);
    }
  }
  
  Map<String, String> _getHeaders(String serviceName, String apiKey) {
    switch (serviceName.toLowerCase()) {
      case 'claude':
        return {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        };
      case 'gpt-4':
        return {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        };
      case 'study assistant':
        return {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        };
      case 'perplexity':
        return {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        };
      case 'deepseek':
        return {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        };
      case 'you':
        return {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        };
      default:
        return {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        };
    }
  }
  
  Map<String, dynamic> _buildRequestBody(
    AIService service,
    String query,
    StudyMaterial? material,
    Map<String, dynamic>? additionalContext,
  ) {
    final context = {
      if (material != null) ...{
        'material': {
          'title': material.title,
          'description': material.description,
          'category': material.category,
        },
      },
      if (additionalContext != null) ...additionalContext,
    };
    
    switch (service.name.toLowerCase()) {
      case 'claude':
        return {
          'model': service.settings['model'],
          'max_tokens': service.settings['max_tokens'],
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful study assistant. Use the provided context to help answer questions.',
            },
            {
              'role': 'user',
              'content': '''
Context: ${json.encode(context)}
Query: $query
''',
            },
          ],
        };
      case 'gpt-4':
        return {
          'model': service.settings['model'],
          'max_tokens': service.settings['max_tokens'],
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful study assistant. Use the provided context to help answer questions.',
            },
            {
              'role': 'user',
              'content': '''
Context: ${json.encode(context)}
Query: $query
''',
            },
          ],
        };
      case 'study assistant':
        return {
          'model': service.settings['model'],
          'max_tokens': service.settings['max_tokens'],
          'query': query,
          'context': context,
        };
      case 'perplexity':
        return {
          'model': service.settings['model'],
          'max_tokens': service.settings['max_tokens'],
          'query': query,
          'context': context,
        };
      case 'deepseek':
        return {
          'model': service.settings['model'],
          'max_tokens': service.settings['max_tokens'],
          'query': query,
          'context': context,
        };
      case 'you':
        return {
          'model': service.settings['model'],
          'max_tokens': service.settings['max_tokens'],
          'query': query,
          'context': context,
        };
      default:
        return {
          'query': query,
          'context': context,
        };
    }
  }
  
  String _parseResponse(String serviceName, dynamic data) {
    switch (serviceName.toLowerCase()) {
      case 'claude':
        return data['content'][0]['text'] as String;
      case 'gpt-4':
        return data['choices'][0]['message']['content'] as String;
      case 'study assistant':
        return data['response'] as String;
      case 'perplexity':
        return data['response'] as String;
      case 'deepseek':
        return data['response'] as String;
      case 'you':
        return data['response'] as String;
      default:
        return data['response'] as String? ?? 'No response received';
    }
  }
  
  Future<List<String>> getRecommendedServices(StudyMaterial material) async {
    try {
      final services = AIService.getAllServices();
      return services
          .where((service) => service.isAvailable)
          .where((service) => service.capabilities.contains('Material Analysis'))
          .map((service) => service.name)
          .toList();
    } catch (e) {
      Logger.error('Error getting recommended services: $e');
      return [];
    }
  }
  
  Future<Map<String, dynamic>> analyzeMaterial(StudyMaterial material) async {
    try {
      final service = AIService.getServiceByName('Claude');
      final response = await getResponse(
        query: '''
Analyze this study material and provide:
1. Key concepts
2. Difficulty level
3. Prerequisites
4. Recommended study approach
5. Estimated study time

Material: ${material.title}
Description: ${material.description}
Category: ${material.category}
''',
        service: service,
        material: material,
      );
      
      return {
        'analysis': response,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.error('Error analyzing material: $e');
      rethrow;
    }
  }
  
  Future<Map<String, dynamic>> generateStudyPlan(StudyMaterial material) async {
    try {
      final service = AIService.getServiceByName('Study Assistant');
      final response = await getResponse(
        query: '''
Generate a detailed study plan for this material:
1. Break down into manageable chunks
2. Suggested study schedule
3. Practice exercises
4. Review points
5. Assessment methods

Material: ${material.title}
Description: ${material.description}
Category: ${material.category}
''',
        service: service,
        material: material,
      );
      
      return {
        'plan': response,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      Logger.error('Error generating study plan: $e');
      rethrow;
    }
  }
} 