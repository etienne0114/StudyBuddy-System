// lib/ui/dialogs/ai_assistant_dialog.dart
// This is the main AI assistant dialog

import 'package:flutter/material.dart';
import 'package:study_scheduler/data/models/study_material.dart';
import 'package:study_scheduler/managers/ai_assistant_manager.dart';

class AIAssistantDialog extends StatefulWidget {
  final StudyMaterial? material;
  final String? initialQuestion;
  
  const AIAssistantDialog({
    Key? key,
    this.material,
    this.initialQuestion,
  }) : super(key: key);
  
  /// Show the AI assistant dialog
  static Future<void> show(BuildContext context, {
    StudyMaterial? material,
    String? initialQuestion,
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AIAssistantDialog(
        material: material,
        initialQuestion: initialQuestion,
      ),
    );
  }

  @override
  State<AIAssistantDialog> createState() => _AIAssistantDialogState();
}

class _AIAssistantDialogState extends State<AIAssistantDialog> {
  final TextEditingController _questionController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final AIAssistantManager _manager = AIAssistantManager.instance;
  
  String _selectedService = '';
  bool _isProcessing = false;
  String _response = '';
  bool _showMaterialContext = true;
  
  // Available services
  late List<String> _services;
  
  @override
  void initState() {
    super.initState();
    _initializeAssistant();
  }
  
  Future<void> _initializeAssistant() async {
    // Get preferred service
    _selectedService = _manager.preferredService;
    
    // Get available services
    _services = _manager.getAvailableServiceNames();
    
    // Set initial question if provided
    if (widget.initialQuestion != null) {
      _questionController.text = widget.initialQuestion!;
    } else if (widget.material != null) {
      _questionController.text = 'Help me understand ${widget.material!.title}';
    }
    
    // Focus the text field if empty
    if (_questionController.text.isEmpty) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _focusNode.requestFocus();
        }
      });
    } else {
      // Auto-process if question is pre-filled
      _processQuestion();
    }
  }
  
  @override
  void dispose() {
    _questionController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  
  Future<void> _processQuestion() async {
    // Don't process empty questions
    final question = _questionController.text.trim();
    if (question.isEmpty) return;
    
    // Update state to show processing
    setState(() {
      _isProcessing = true;
      _response = '';
    });
    
    try {
      // Get response from AI
      final response = await _manager.getAIResponse(
        question, 
        _selectedService,
        material: widget.material,
      );
      
      // Update UI with response
      if (mounted) {
        setState(() {
          _response = response;
          _isProcessing = false;
        });
      }
    } catch (e) {
      // Handle error and show a generic response
      if (mounted) {
        setState(() {
          _response = "I'm here to help with your studies! What would you like assistance with?";
          _isProcessing = false;
        });
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
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 500,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            if (widget.material != null && _showMaterialContext)
              _buildMaterialContext(),
            _buildInputSection(),
            _buildControlBar(),
            _buildResponseArea(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.withAlpha(30),
            child: const Icon(Icons.psychology_alt, color: Colors.blue),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'AI Learning Assistant',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMaterialContext() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Study Material Context:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Switch(
                value: _showMaterialContext,
                onChanged: (value) {
                  setState(() {
                    _showMaterialContext = value;
                  });
                },
                activeColor: Colors.blue,
              ),
            ],
          ),
          if (_showMaterialContext) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.material!.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Category: ${widget.material!.category}',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                    ),
                  ),
                  if (widget.material!.description != null && 
                     widget.material!.description!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.material!.description!,
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 13,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildInputSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.help_outline, color: Colors.grey),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _questionController,
                focusNode: _focusNode,
                decoration: const InputDecoration(
                  hintText: 'Ask a question...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                maxLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _processQuestion(),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildControlBar() {
    final serviceColor = _manager.getServiceColor(_selectedService);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: serviceColor.withAlpha(30),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedService,
                borderRadius: BorderRadius.circular(12),
                icon: Icon(Icons.arrow_drop_down, color: serviceColor),
                items: _services.map((service) {
                  final color = _manager.getServiceColor(service);
                  return DropdownMenuItem<String>(
                    value: service,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.smart_toy,
                          size: 16,
                          color: color,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          service,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedService = value;
                    });
                  }
                },
              ),
            ),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: _isProcessing ? null : _processQuestion,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Ask AI'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResponseArea() {
    return Flexible(
      child: Container(
        margin: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: _isProcessing
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _response.isEmpty
                ? const Center(
                    child: Text(
                      'Ask a question to get AI assistance',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _response,
                      style: const TextStyle(
                        height: 1.5,
                      ),
                    ),
                  ),
      ),
    );
  }
  
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Powered by ',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          Text(
            _selectedService,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _manager.getServiceColor(_selectedService),
            ),
          ),
        ],
      ),
    );
  }
}