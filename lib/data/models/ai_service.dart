// lib/data/models/ai_service.dart

import 'package:flutter/material.dart';

class AIService {
  final String name;
  final String iconPath;
  final String url;
  final Color color;
  final String description;
  final List<String> capabilities;

  AIService({
    required this.name,
    required this.iconPath,
    required this.url,
    required this.color,
    required this.description,
    required this.capabilities,
  });

  // Helper method to generate a simulated response based on the service
  String getSimulatedResponse(String question) {
    final questionLower = question.toLowerCase();
    
    // Generic responses based on question content
    if (questionLower.contains('explain') || questionLower.contains('understand')) {
      return '''
Here's a simplified explanation:

${_getExplanation(questionLower)}

Would you like me to elaborate on any specific part?''';
    } else if (questionLower.contains('summarize') || questionLower.contains('summary')) {
      return '''
# Summary
${_getSummary(questionLower)}

Is there anything specific you'd like me to focus on?''';
    } else if (questionLower.contains('example') || questionLower.contains('practice')) {
      return '''
Here's an example to help you understand:

${_getExample(questionLower)}

Would you like to see another example?''';
    } else if (questionLower.contains('compare') || questionLower.contains('difference')) {
      return '''
## Comparison
${_getComparison(questionLower)}

These differences highlight why you might choose one over the other depending on your specific needs.''';
    } else if (questionLower.contains('quiz') || questionLower.contains('test')) {
      return '''
Here are some practice questions to test your understanding:

${_getQuizQuestions()}

Would you like me to provide the answers or would you prefer to try answering them first?''';
    } else {
      // Generic response
      return '''
Based on your question about "${_getTopicFromQuestion(questionLower)}", here's what I can tell you:

${_getGenericResponse(questionLower)}

Let me know if you'd like more specific information!''';
    }
  }

  // Helper methods to generate content based on question patterns
  String _getExplanation(String question) {
    final topic = _getTopicFromQuestion(question);
    return '''$topic refers to a concept that involves multiple interrelated components working together to achieve a specific outcome. At its core, it's about how different elements interact with each other.

The key principles include:
1. The foundational structure that supports the overall system
2. The processes that enable efficient operation
3. The optimization techniques that improve performance

Understanding these components will help you grasp the bigger picture and see how everything connects.''';
  }

  String _getSummary(String question) {
    final topic = _getTopicFromQuestion(question);
    return '''$topic can be summarized as a systematic approach to solving complex problems through a series of well-defined steps. It involves analyzing requirements, designing solutions, implementing those solutions, and then evaluating their effectiveness.

The main points to remember are:
- It follows a structured methodology
- It emphasizes both theoretical understanding and practical application
- It requires critical thinking and analytical skills
- It continues to evolve as new research emerges''';
  }

  String _getExample(String question) {
    final topic = _getTopicFromQuestion(question);
    return '''Let's look at a practical example of $topic:

**Scenario**: A student is trying to learn a new concept for an upcoming exam.

**Application**:
1. The student begins by reviewing the fundamental principles
2. They create visual diagrams to map relationships between key ideas
3. They solve practice problems, gradually increasing in difficulty
4. They explain the concept to a friend to test their understanding
5. They review areas where they struggled and repeat the process

This example demonstrates how the theoretical framework can be applied to achieve tangible results.''';
  }

  String _getComparison(String question) {
    final parts = question.split(' and ');
    final topicA = parts.length > 1 ? _cleanTopic(parts[0].split(' ').last) : "Approach A";
    final topicB = parts.length > 1 ? _cleanTopic(parts[1].split(' ').first) : "Approach B";
    
    return '''
| Aspect | $topicA | $topicB |
|--------|---------|---------|
| Foundational principle | Based on structural analysis | Based on functional analysis |
| Primary focus | Emphasizes theoretical framework | Emphasizes practical application |
| Learning curve | Steeper initial learning curve | More gradual learning progression |
| Best used for | Complex conceptual understanding | Immediate practical implementation |
| Supporting evidence | Strong theoretical research base | Extensive empirical validation |''';
  }

  String _getQuizQuestions() {
    return '''
1. What are the three main components of an effective learning strategy?

2. How does spaced repetition differ from massed practice, and which is more effective for long-term retention?

3. True or False: Active recall is less effective than passive review for deep understanding.

4. Explain how the concept of "desirable difficulty" contributes to more effective learning.

5. When studying complex material, which approach is generally more effective: focusing on one topic for an extended period or interleaving multiple related topics?''';
  }

  String _getGenericResponse(String question) {
    final topic = _getTopicFromQuestion(question);
    return '''
$topic is a fascinating area that combines theoretical concepts with practical applications. 

Key aspects to understand include:

1. The fundamental principles that form its foundation
2. How these principles interact in different contexts
3. Common applications and their impact
4. Current trends and future developments

Many learners find it helpful to approach this topic by first mastering the core concepts before moving on to more complex applications. Visual aids, practical exercises, and discussion with peers can significantly enhance your understanding.

If you're looking to deepen your knowledge, I recommend exploring some of the seminal works in this field, as well as recent research that shows how these concepts continue to evolve.''';
  }

  // Helper method to extract the topic from a question
  String _getTopicFromQuestion(String question) {
    // Remove common question starters
    final cleanQuestion = question
        .replaceAll(RegExp(r'(can you|could you|please|help me|explain|understand|what is|how does|tell me about)\s+', caseSensitive: false), '')
        .trim();
    
    // Get the first few words as the topic
    final words = cleanQuestion.split(' ');
    if (words.length <= 3) {
      return cleanQuestion;
    } else {
      return words.take(3).join(' ');
    }
  }
  
  String _cleanTopic(String topic) {
    return topic.replaceAll(RegExp(r'[?.,!]'), '').trim();
  }
  
  // Static methods to get service instances
  
  // Get all available AI services
  static List<AIService> getAllServices() {
    return [
      getClaudeService(),
      getChatGPTService(),
      getCopilotService(),
      getDeepSeekService(),
      getPerplexityService(),
    ];
  }
  
  // Get service by name
  static AIService getServiceByName(String name) {
    switch (name.toLowerCase()) {
      case 'claude':
        return getClaudeService();
      case 'chatgpt':
        return getChatGPTService();
      case 'github copilot':
      case 'copilot':
        return getCopilotService();
      case 'deepseek':
        return getDeepSeekService();
      case 'perplexity':
        return getPerplexityService();
      default:
        return getClaudeService(); // Default to Claude
    }
  }
  
  // Individual service instances
  
  static AIService getClaudeService() {
    return AIService(
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
    );
  }
  
  static AIService getChatGPTService() {
    return AIService(
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
    );
  }
  
  static AIService getCopilotService() {
    return AIService(
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
    );
  }
  
  static AIService getDeepSeekService() {
    return AIService(
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
    );
  }
  
  static AIService getPerplexityService() {
    return AIService(
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
    );
  }
}