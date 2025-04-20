import 'package:flutter/material.dart';
import 'package:study_scheduler/data/models/study_material.dart';
import 'package:study_scheduler/data/repositories/study_materials_repository.dart';

class AIAssistantScreen extends StatefulWidget {
  final StudyMaterial material;

  const AIAssistantScreen({
    Key? key,
    required this.material,
  }) : super(key: key);

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final TextEditingController _queryController = TextEditingController();
  final StudyMaterialsRepository _repository = StudyMaterialsRepository();
  final ScrollController _scrollController = ScrollController();
  
  bool _isLoading = false;
  String _response = '';
  List<Map<String, String>> _chatHistory = [];

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _askAI() async {
    if (_queryController.text.trim().isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Track AI usage
      await _repository.trackAIUsage(
        widget.material.id,
        'Claude',
        _queryController.text.trim(),
      );

      // Add user query to chat history
      _chatHistory.add({
        'role': 'user',
        'content': _queryController.text.trim(),
      });

      // Simulate AI response (replace this with actual AI integration)
      String aiResponse = await _generateAIResponse(_queryController.text.trim());
      
      // Add AI response to chat history
      _chatHistory.add({
        'role': 'assistant',
        'content': aiResponse,
      });

      setState(() {
        _response = aiResponse;
        _queryController.clear();
      });

      // Scroll to bottom
      await Future.delayed(const Duration(milliseconds: 100));
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: \${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<String> _generateAIResponse(String query) async {
    // Simulate AI processing time
    await Future.delayed(const Duration(seconds: 1));

    // Create context about the material
    String materialContext = '''
    Material Title: ${widget.material.title}
    Category: ${widget.material.category}
    Description: ${widget.material.description ?? 'No description available'}
    ''';

    // Generate response based on query type
    if (query.toLowerCase().contains('summarize') || 
        query.toLowerCase().contains('summary')) {
      return 'Here\'s a summary of ${widget.material.title}:\n\n' +
             'This is a ${widget.material.category.toLowerCase()} about ${widget.material.title}. ' +
             'The main points include understanding key concepts and practical applications.';
    } else if (query.toLowerCase().contains('practice') || 
               query.toLowerCase().contains('question')) {
      return 'Here are some practice questions about ${widget.material.title}:\n\n' +
             '1. What are the key concepts covered in this material?\n' +
             '2. How would you apply these concepts in practice?\n' +
             '3. Can you explain the relationship between different topics?';
    } else if (query.toLowerCase().contains('study plan') || 
               query.toLowerCase().contains('schedule')) {
      return 'Here\'s a suggested study plan for ${widget.material.title}:\n\n' +
             '1. Review the basic concepts (30 minutes)\n' +
             '2. Work through examples (45 minutes)\n' +
             '3. Practice exercises (45 minutes)\n' +
             '4. Review and summarize (30 minutes)';
    } else {
      return 'I understand you\'re asking about ${widget.material.title}. ' +
             'Could you please be more specific about what you\'d like to know? ' +
             'I can help with:\n\n' +
             '• Summarizing the content\n' +
             '• Creating practice questions\n' +
             '• Making a study plan\n' +
             '• Explaining specific concepts';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Learning Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('AI Assistant Help'),
                  content: const SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('You can ask the AI assistant to:'),
                        SizedBox(height: 8),
                        Text('• Summarize the material'),
                        Text('• Generate practice questions'),
                        Text('• Create a study plan'),
                        Text('• Explain concepts'),
                        Text('• Provide learning tips'),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Material Context Card
          Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.material.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Category: ${widget.material.category}',
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                  if (widget.material.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.material.description!,
                      style: TextStyle(
                        color: Colors.grey[800],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Chat History
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              itemCount: _chatHistory.length,
              itemBuilder: (context, index) {
                final message = _chatHistory[index];
                final isUser = message['role'] == 'user';
                
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    child: Text(message['content']!),
                  ),
                );
              },
            ),
          ),
          
          // Quick Actions
          if (_chatHistory.isEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Wrap(
                spacing: 8.0,
                children: [
                  ActionChip(
                    label: const Text('Summarize'),
                    onPressed: () {
                      _queryController.text = 'Summarize this material';
                      _askAI();
                    },
                  ),
                  ActionChip(
                    label: const Text('Practice Questions'),
                    onPressed: () {
                      _queryController.text = 'Create practice questions';
                      _askAI();
                    },
                  ),
                  ActionChip(
                    label: const Text('Study Plan'),
                    onPressed: () {
                      _queryController.text = 'Create a study plan';
                      _askAI();
                    },
                  ),
                ],
              ),
            ),
          
          // Input Area
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    decoration: const InputDecoration(
                      hintText: 'Ask about this material...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _askAI(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  onPressed: _isLoading ? null : _askAI,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 