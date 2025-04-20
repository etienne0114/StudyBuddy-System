// lib/ui/screens/materials/compact_ai_assistant_dialog.dart

import 'package:flutter/material.dart';
import 'package:study_scheduler/data/models/study_material.dart';
import 'package:study_scheduler/services/ai_service.dart';
import 'package:study_scheduler/constants/app_colors.dart';

class CompactAIAssistantDialog extends StatefulWidget {
  final StudyMaterial? material;

  const CompactAIAssistantDialog({
    super.key,
    this.material,
  });

  @override
  State<CompactAIAssistantDialog> createState() => _CompactAIAssistantDialogState();
}

class _CompactAIAssistantDialogState extends State<CompactAIAssistantDialog> {
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIService _aiService = AIService();
  
  bool _isLoading = false;
  List<Message> _messages = [];
  String _selectedModel = 'Claude'; // Default AI model

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() {
    setState(() {
      _messages = [
        Message(
          content: widget.material != null
              ? 'Hello! I can help you understand "${widget.material!.title}". What would you like to know?'
              : 'Hello! I\'m your AI study assistant. How can I help you today?',
          isUser: false,
        ),
      ];
    });
  }

  Future<void> _sendMessage() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _messages.add(Message(content: question, isUser: true));
      _isLoading = true;
      _questionController.clear();
    });

    try {
      final response = await _aiService.getResponse(
        question: question,
        material: widget.material,
        model: _selectedModel,
      );

      if (mounted) {
        setState(() {
          _messages.add(Message(content: response, isUser: false));
          _isLoading = false;
        });

        // Scroll to bottom after adding new message
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _messages.add(Message(
            content: 'I apologize, but I encountered an error while processing your request. This could be due to:\n\n'
                    '1. Missing API configuration\n'
                    '2. Network connectivity issues\n'
                    '3. Service unavailability\n\n'
                    'Please try again in a moment or contact support if the issue persists.',
            isUser: false,
          ));
        });

        // Show a snackbar with more details in debug mode
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () {
                _questionController.text = question;
                _sendMessage();
              },
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(),
            const Divider(),
            _buildChatArea(),
            const Divider(),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.psychology_alt, color: AppColors.primary),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'AI Learning Assistant',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child: _buildModelSelector(),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildModelSelector() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: _selectedModel,
        isDense: true,
        icon: const Icon(Icons.arrow_drop_down, size: 20),
        items: const [
          DropdownMenuItem(
            value: 'Claude',
            child: Text('Claude', style: TextStyle(fontSize: 14)),
          ),
          DropdownMenuItem(
            value: 'GPT-4',
            child: Text('GPT-4', style: TextStyle(fontSize: 14)),
          ),
          DropdownMenuItem(
            value: 'Study Assistant',
            child: Text('Study Assistant', style: TextStyle(fontSize: 14)),
          ),
        ],
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedModel = newValue;
            });
          }
        },
      ),
    );
  }

  Widget _buildChatArea() {
    return Expanded(
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _messages.length + (_isLoading ? 1 : 0),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          if (index == _messages.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final message = _messages[index];
          return _MessageBubble(message: message);
        },
      ),
    );
  }

  Widget _buildInputArea() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _questionController,
            decoration: InputDecoration(
              hintText: 'Ask a question...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
            maxLines: null,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _sendMessage(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.send),
          onPressed: _sendMessage,
          color: AppColors.primary,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class Message {
  final String content;
  final bool isUser;

  Message({
    required this.content,
    required this.isUser,
  });
}

class _MessageBubble extends StatelessWidget {
  final Message message;

  const _MessageBubble({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: message.isUser ? 48 : 8,
          right: message.isUser ? 8 : 48,
          bottom: 8,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: message.isUser
              ? AppColors.primary
              : Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]
                  : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.content,
          style: TextStyle(
            color: message.isUser ? Colors.white : null,
          ),
        ),
      ),
    );
  }
}