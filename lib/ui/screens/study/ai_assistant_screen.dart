import 'package:flutter/material.dart';
import 'package:study_scheduler/constants/app_colors.dart';
import 'package:study_scheduler/constants/app_styles.dart';
import 'package:study_scheduler/data/models/study_material.dart';
import 'package:study_scheduler/data/models/ai_service.dart';
import 'package:study_scheduler/services/ai_service_provider.dart';
import 'package:study_scheduler/utils/logger.dart';

class AIAssistantScreen extends StatefulWidget {
  final StudyMaterial material;

  const AIAssistantScreen({
    super.key,
    required this.material,
  });

  @override
  State<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends State<AIAssistantScreen> {
  final _aiProvider = AIServiceProvider.instance;
  final _queryController = TextEditingController();
  final _scrollController = ScrollController();
  
  String _selectedService = 'Claude';
  bool _isLoading = false;
  String _response = '';
  List<String> _recommendedServices = [];
  
  @override
  void initState() {
    super.initState();
    _loadRecommendedServices();
  }
  
  Future<void> _loadRecommendedServices() async {
    try {
      final services = await _aiProvider.getRecommendedServices(widget.material);
      setState(() {
        _recommendedServices = services;
        if (services.isNotEmpty) {
          _selectedService = services.first;
        }
      });
    } catch (e) {
      Logger.error('Error loading recommended services: $e');
    }
  }
  
  Future<void> _sendQuery() async {
    if (_queryController.text.trim().isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _response = '';
    });
    
    try {
      final service = AIService.getServiceByName(_selectedService);
      final response = await _aiProvider.getResponse(
        query: _queryController.text,
        service: service,
        material: widget.material,
      );
      
      setState(() {
        _response = response;
        _isLoading = false;
      });
      
      // Scroll to bottom to show response
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      Logger.error('Error getting AI response: $e');
      setState(() {
        _response = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _analyzeMaterial() async {
    setState(() {
      _isLoading = true;
      _response = '';
    });
    
    try {
      final result = await _aiProvider.analyzeMaterial(widget.material);
      setState(() {
        _response = result['analysis'];
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Error analyzing material: $e');
      setState(() {
        _response = 'Error analyzing material: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _generateStudyPlan() async {
    setState(() {
      _isLoading = true;
      _response = '';
    });
    
    try {
      final result = await _aiProvider.generateStudyPlan(widget.material);
      setState(() {
        _response = result['plan'];
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Error generating study plan: $e');
      setState(() {
        _response = 'Error generating study plan: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecommendedServices,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMaterialInfo(),
          _buildServiceSelector(),
          _buildQuickActions(),
          _buildQueryInput(),
          Expanded(
            child: _buildResponseArea(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMaterialInfo() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.material.title,
              style: AppStyles.heading2,
            ),
            if (widget.material.description != null) ...[
              const SizedBox(height: 8),
              Text(
                widget.material.description!,
                style: AppStyles.body1, // Replace with an existing style or define 'bodyText' in AppStyles
              ),
            ],
            const SizedBox(height: 8),
            Chip(
              label: Text(widget.material.category),
              backgroundColor: AppColors.primary.withOpacity(0.1),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildServiceSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: DropdownButton<String>(
        value: _selectedService,
        isExpanded: true,
        items: _recommendedServices.map((service) {
          final aiService = AIService.getServiceByName(service);
          return DropdownMenuItem(
            value: service,
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: aiService.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(service),
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
    );
  }
  
  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _analyzeMaterial,
            icon: const Icon(Icons.analytics),
            label: const Text('Analyze'),
            style: AppStyles.primaryButtonStyle,
          ),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _generateStudyPlan,
            icon: const Icon(Icons.calendar_today),
            label: const Text('Study Plan'),
            style: AppStyles.primaryButtonStyle,
          ),
        ],
      ),
    );
  }
  
  Widget _buildQueryInput() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _queryController,
              decoration: const InputDecoration(
                hintText: 'Ask a question about this material...',
                border: OutlineInputBorder(),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendQuery(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isLoading ? null : _sendQuery,
            icon: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResponseArea() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16.0),
      child: _response.isNotEmpty
          ? Text(
              _response,
              style: AppStyles.body1, // Replace with an existing style or define 'bodyText' in AppStyles
            )
          : Center(
              child: Text(
                'Ask a question or use one of the quick actions above',
                style: AppStyles.body1.copyWith(
                  color: Colors.grey,
                ),
              ),
            ),
    );
  }
  
  @override
  void dispose() {
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
} 