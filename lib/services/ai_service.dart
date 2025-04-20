import 'package:study_scheduler/data/models/study_material.dart';
import 'package:study_scheduler/utils/logger.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dio/dio.dart';
import 'package:study_scheduler/data/database/database_helper.dart';

class AIServiceException implements Exception {
  final String message;
  AIServiceException(this.message);
  
  @override
  String toString() => message;
}

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final Dio _dio = Dio();
  bool _isInitialized = false;
  String? _openAIKey;
  String? _anthropicKey;
  
  // API Endpoints
  static const String _openAIEndpoint = 'https://api.openai.com/v1/chat/completions';
  static const String _claudeEndpoint = 'https://api.anthropic.com/v1/messages';
  
  bool get isInitialized => _isInitialized;
  
  // Initialize the service with API keys
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await dotenv.load(fileName: ".env");
      _openAIKey = dotenv.env['OPENAI_API_KEY']?.trim();
      _anthropicKey = dotenv.env['ANTHROPIC_API_KEY']?.trim();
      
      if (_openAIKey == null || _anthropicKey == null) {
        throw AIServiceException('API keys not found. Please check your .env file.');
      }
      
      if (_openAIKey!.isEmpty || _anthropicKey!.isEmpty ||
          _openAIKey!.contains('your_') || _anthropicKey!.contains('your_')) {
        throw AIServiceException('Please replace the placeholder API keys with actual keys in your .env file.');
      }
      
      // Validate API keys with a test request
      await _validateAPIKeys();
      
      _isInitialized = true;
      Logger.info('AI Service initialized successfully');
    } catch (e) {
      _isInitialized = false;
      Logger.error('Failed to initialize AI service: $e');
      throw AIServiceException('Failed to initialize AI service. Please check your API keys.');
    }
  }

  Future<void> _validateAPIKeys() async {
    try {
      // Test OpenAI API
      final openAIResponse = await http.post(
        Uri.parse(_openAIEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAIKey',
        },
        body: jsonEncode({
          'model': 'gpt-4-turbo-preview',
          'messages': [{'role': 'user', 'content': 'test'}],
          'max_tokens': 1
        }),
      );

      if (openAIResponse.statusCode != 200) {
        throw AIServiceException('OpenAI API key validation failed. Please check your API key.');
      }

      // Test Claude API
      final claudeResponse = await http.post(
        Uri.parse(_claudeEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _anthropicKey!,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-3-opus-20240229',
          'max_tokens': 1,
          'messages': [
            {'role': 'user', 'content': 'test'},
          ],
        }),
      );

      if (claudeResponse.statusCode != 200) {
        throw AIServiceException('Claude API key validation failed. Please check your API key.');
      }
    } catch (e) {
      throw AIServiceException('API key validation failed. Please check your internet connection and API keys.');
    }
  }
  
  Future<String> getResponse({
    required String question,
    StudyMaterial? material,
    required String model,
  }) async {
    if (!_isInitialized) {
      try {
        await initialize();
      } catch (e) {
        return 'Configuration Error: Please ensure your API keys are properly set up in the .env file.';
      }
    }

    try {
      final response = switch (model.toLowerCase()) {
        'gpt-4' => await _getOpenAIResponse(question, material),
        'claude' => await _getClaudeResponse(question, material),
        'study assistant' => await _getStudyAssistantResponse(question, material),
        _ => await _getOpenAIResponse(question, material),
      };
      
      Logger.info('AI response generated successfully for model: $model');
      return response;
    } catch (e) {
      Logger.error('Error in AIService.getResponse: $e');
      if (e is AIServiceException) {
        return 'Error: ${e.message}';
      }
      return 'Sorry, I encountered an error. Please try again later.';
    }
  }

  Future<String> _getOpenAIResponse(String question, StudyMaterial? material) async {
    if (_openAIKey == null || _openAIKey!.isEmpty) {
      throw AIServiceException('OpenAI API key not configured');
    }

    try {
      final messages = _buildMessages(question, material);
      
      final response = await http.post(
        Uri.parse(_openAIEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAIKey',
        },
        body: jsonEncode({
          'model': 'gpt-4-turbo-preview',
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      } else {
        final error = jsonDecode(response.body);
        throw AIServiceException('OpenAI API error: ${error['error']['message'] ?? response.statusCode}');
      }
    } catch (e) {
      Logger.error('Error in _getOpenAIResponse: $e');
      rethrow;
    }
  }

  Future<String> _getClaudeResponse(String question, StudyMaterial? material) async {
    if (_anthropicKey == null || _anthropicKey!.isEmpty) {
      throw AIServiceException('Anthropic API key not configured');
    }

    try {
      final systemPrompt = _buildSystemPrompt(material);
      
      final response = await http.post(
        Uri.parse(_claudeEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _anthropicKey!,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-3-opus-20240229',
          'max_tokens': 1000,
          'messages': [
            {
              'role': 'system',
              'content': systemPrompt,
            },
            {
              'role': 'user',
              'content': question,
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['content'][0]['text'] as String;
      } else {
        final error = jsonDecode(response.body);
        throw AIServiceException('Claude API error: ${error['error']['message'] ?? response.statusCode}');
      }
    } catch (e) {
      Logger.error('Error in _getClaudeResponse: $e');
      rethrow;
    }
  }

  Future<String> _getStudyAssistantResponse(String question, StudyMaterial? material) async {
    // This is a fallback to OpenAI with study-specific prompting
    try {
      final messages = _buildMessages(question, material, isStudyFocused: true);
      
      final response = await http.post(
        Uri.parse(_openAIEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAIKey',
        },
        body: jsonEncode({
          'model': 'gpt-4-turbo-preview',
          'messages': messages,
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      } else {
        throw AIServiceException('API error: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('Error in _getStudyAssistantResponse: $e');
      rethrow;
    }
  }

  List<Map<String, String>> _buildMessages(
    String question,
    StudyMaterial? material, {
    bool isStudyFocused = false,
  }) {
    final messages = <Map<String, String>>[];
    
    // Add system message
    messages.add({
      'role': 'system',
      'content': _buildSystemPrompt(material, isStudyFocused: isStudyFocused),
    });

    // Add context if material is provided
    if (material != null) {
      messages.add({
        'role': 'system',
        'content': '''
Current study material:
Title: ${material.title}
Category: ${material.category}
Description: ${material.description ?? 'No description available'}
''',
      });
    }

    // Add user question
    messages.add({
      'role': 'user',
      'content': question,
    });

    return messages;
  }

  String _buildSystemPrompt(StudyMaterial? material, {bool isStudyFocused = false}) {
    if (isStudyFocused) {
      return '''
You are an expert study assistant with deep knowledge in education and learning methodologies.
Your goal is to help students understand their study materials, develop effective study strategies,
and achieve their learning objectives. Provide clear, concise, and practical advice.
${material != null ? 'Focus on helping with the current study material: ${material.title}' : ''}
''';
    }

    return '''
You are a helpful AI assistant specializing in education and learning.
Provide clear and concise responses to help users with their studies.
${material != null ? 'You are currently discussing: ${material.title}' : ''}
''';
  }

  // Method to analyze study material and provide insights
  Future<String> analyzeMaterial(StudyMaterial material) async {
    final prompt = '''
Please analyze this study material and provide insights:

Title: ${material.title}
Category: ${material.category}
Description: ${material.description ?? 'No description available'}

Provide:
1. Key concepts and topics
2. Estimated study time
3. Recommended study approach
4. Prerequisites if any
5. Practice suggestions
''';

    return await getResponse(
      question: prompt,
      material: material,
      model: 'gpt-4',
    );
  }

  // Method to generate a study plan
  Future<String> generateStudyPlan(StudyMaterial material, int daysAvailable) async {
    final prompt = '''
Create a detailed study plan for:

Title: ${material.title}
Category: ${material.category}
Description: ${material.description ?? 'No description available'}
Days Available: $daysAvailable

Include:
1. Daily breakdown of topics
2. Time allocation per topic
3. Review sessions
4. Practice exercises
5. Assessment points
''';

    return await getResponse(
      question: prompt,
      material: material,
      model: 'gpt-4',
    );
  }

  // Method to get practice questions
  Future<List<Map<String, String>>> getPracticeQuestions(
    StudyMaterial material,
    int numberOfQuestions,
  ) async {
    try {
      final prompt = '''
Generate practice questions for:

Title: ${material.title}
Category: ${material.category}
Description: ${material.description ?? 'No description available'}
Number of questions: $numberOfQuestions

Include a mix of:
1. Conceptual questions
2. Application-based questions
3. Analysis questions
''';

      final response = await http.post(
        Uri.parse(_openAIEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAIKey',
        },
        body: jsonEncode({
          'model': 'gpt-4-turbo-preview',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful AI tutor. Generate practice questions with answers based on the study material provided.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.7,
          'max_tokens': 2000,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        
        // Parse the content into questions and answers
        final List<Map<String, String>> questions = [];
        final lines = content.split('\n');
        String currentQuestion = '';
        String currentAnswer = '';
        
        for (final line in lines) {
          if (line.trim().isEmpty) continue;
          
          if (line.startsWith('Q') || line.startsWith('Question')) {
            // Save previous Q&A pair if exists
            if (currentQuestion.isNotEmpty && currentAnswer.isNotEmpty) {
              questions.add({
                'question': currentQuestion.trim(),
                'answer': currentAnswer.trim(),
              });
            }
            // Start new question
            currentQuestion = line.replaceFirst(RegExp(r'^Q[0-9]*:?\s*|Question [0-9]*:?\s*'), '');
            currentAnswer = '';
          } else if (line.startsWith('A') || line.startsWith('Answer')) {
            currentAnswer = line.replaceFirst(RegExp(r'^A[0-9]*:?\s*|Answer:?\s*'), '');
          } else if (currentAnswer.isNotEmpty) {
            currentAnswer += '\n$line';
          } else {
            currentQuestion += '\n$line';
          }
        }
        
        // Add the last Q&A pair
        if (currentQuestion.isNotEmpty && currentAnswer.isNotEmpty) {
          questions.add({
            'question': currentQuestion.trim(),
            'answer': currentAnswer.trim(),
          });
        }
        
        return questions;
      } else {
        throw AIServiceException('Failed to generate questions: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('Error in AIService.getPracticeQuestions: $e');
      rethrow;
    }
  }

  Future<void> _trackUsage({
    required String service,
    required String query,
    required String response,
    required int tokensUsed,
    required int durationMs,
    required bool success,
  }) async {
    try {
      final db = await _dbHelper.database;
      await db.insert('ai_usage_tracking', {
        'service_name': service,
        'query': query,
        'response': response,
        'tokens_used': tokensUsed,
        'duration_ms': durationMs,
        'success': success ? 1 : 0,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      Logger.error('Error tracking AI usage: $e');
    }
  }
}