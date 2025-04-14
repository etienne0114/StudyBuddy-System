// lib/ui/screens/materials/ai_assistant_dialog.dart

import 'package:flutter/material.dart';
import 'package:study_scheduler/data/models/study_material.dart';
import 'package:study_scheduler/data/models/ai_service.dart';
import 'package:study_scheduler/data/repositories/study_materials_repository.dart';
import 'dart:async';

class AIAssistantDialog extends StatefulWidget {
  final StudyMaterial? material;

  const AIAssistantDialog({
    Key? key,
    this.material,
  }) : super(key: key);

  @override
  State<AIAssistantDialog> createState() => _AIAssistantDialogState();
}

class _AIAssistantDialogState extends State<AIAssistantDialog> {
  final TextEditingController _questionController = TextEditingController();
  String _selectedAIService = 'Claude';
  bool _isProcessing = false;
  String _response = '';
  bool _showMaterialContext = true;
  
  // Create repository instance
  final StudyMaterialsRepository _repository = StudyMaterialsRepository();
  
  // Get all available AI services
  final List<AIService> _services = AIService.getAllServices();

  @override
  void initState() {
    super.initState();
    // Pre-fill question if material is provided
    if (widget.material != null) {
      _questionController.text = 'Help me understand ${widget.material!.title}';
    }
    
    // Try to get the user's most used service
    _loadPreferredService();
  }
  
  Future<void> _loadPreferredService() async {
    try {
      final preferredService = await _repository.getMostUsedAIService();
      if (preferredService != null && mounted) {
        setState(() {
          _selectedAIService = preferredService;
        });
      }
    } catch (e) {
      // No-op, keep default service
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _processQuestion() async {
    if (_questionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a question')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _response = '';
    });

    try {
      final service = AIService.getServiceByName(_selectedAIService);
      
      String materialContext = '';
      if (widget.material != null && _showMaterialContext) {
        materialContext = 
          'Title: ${widget.material!.title}\n'
          'Category: ${widget.material!.category}\n'
          'Description: ${widget.material!.description ?? 'No description provided'}\n';
      }

      final response = await _getAIResponse(service, materialContext);
      
      // Track usage if a material is being used
      if (widget.material != null) {
        await _repository.trackAIUsage(
          widget.material!.id, 
          _selectedAIService, 
          _questionController.text
        );
      } else {
        // Track general AI usage
        await _repository.trackAIUsage(
          null, 
          _selectedAIService, 
          _questionController.text
        );
      }
      
      if (mounted) {
        setState(() {
          _response = response;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _response = 'Error processing request: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<String> _getAIResponse(AIService service, String materialContext) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    
    // In a real implementation, this would call the actual AI service API
    final question = _questionController.text.trim();
    
    if (materialContext.isNotEmpty) {
      return 'Based on your material:\n\n$materialContext\n\n${service.getSimulatedResponse(question)}';
    } else {
      return service.getSimulatedResponse(question);
    }
  }

  // Simplified method to simulate opening an AI service
  void _launchAIService(AIService service) {
    // In a real app, we would use url_launcher to open the URL
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening ${service.name} at ${service.url}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 600,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology_alt, color: Colors.blueAccent, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'AI Learning Assistant',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.material != null) ...[
              Row(
                children: [
                  const Text(
                    'Include material context:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Switch(
                    value: _showMaterialContext,
                    onChanged: (value) {
                      setState(() {
                        _showMaterialContext = value;
                      });
                    },
                    activeColor: Colors.blueAccent,
                  ),
                ],
              ),
              if (_showMaterialContext) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.material!.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Category: ${widget.material!.category}',
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      if (widget.material!.description != null && widget.material!.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          widget.material!.description!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
            TextField(
              controller: _questionController,
              decoration: InputDecoration(
                hintText: 'Ask a question about your material...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.help_outline),
              ),
              maxLines: 3,
              minLines: 1,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _processQuestion(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                DropdownButton<String>(
                  value: _selectedAIService,
                  hint: const Text('Select AI Service'),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedAIService = value;
                      });
                    }
                  },
                  items: _services.map((service) {
                    return DropdownMenuItem<String>(
                      value: service.name,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.smart_toy,
                            color: service.color,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(service.name),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: 'Open $_selectedAIService',
                  child: IconButton(
                    icon: const Icon(Icons.open_in_new, size: 20),
                    onPressed: () {
                      final service = AIService.getServiceByName(_selectedAIService);
                      _launchAIService(service);
                    },
                  ),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _isProcessing ? null : _processQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Ask AI'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Flexible(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: _isProcessing
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'Consulting AI...',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: AIService.getServiceByName(_selectedAIService)
                                          .color
                                          .withAlpha(50),
                                      child: Text(
                                        _selectedAIService[0],
                                        style: TextStyle(
                                          color: AIService.getServiceByName(_selectedAIService)
                                              .color,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _response,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          height: 1.5,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Note: AI responses are simulated in this demo',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}