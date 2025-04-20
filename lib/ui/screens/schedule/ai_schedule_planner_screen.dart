import 'package:flutter/material.dart';
import 'package:study_scheduler/constants/app_colors.dart';
import 'package:study_scheduler/constants/app_styles.dart';
import 'package:study_scheduler/data/models/schedule.dart';
import 'package:study_scheduler/data/models/study_material.dart';
import 'package:study_scheduler/data/repositories/study_materials_repository.dart';
import 'package:study_scheduler/services/ai_service.dart';
import 'package:study_scheduler/utils/logger.dart';

class AISchedulePlannerScreen extends StatefulWidget {
  final Schedule schedule;

  const AISchedulePlannerScreen({
    super.key,
    required this.schedule,
  });

  @override
  State<AISchedulePlannerScreen> createState() => _AISchedulePlannerScreenState();
}

class _AISchedulePlannerScreenState extends State<AISchedulePlannerScreen> {
  final _aiService = AIService();
  final _materialsRepository = StudyMaterialsRepository();
  
  bool _isLoading = false;
  String _response = '';
  final List<StudyMaterial> _selectedMaterials = [];
  List<StudyMaterial> _availableMaterials = [];
  
  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }
  
  Future<void> _loadMaterials() async {
    try {
      final materials = await _materialsRepository.getMaterials();
      setState(() {
        _availableMaterials = materials;
      });
    } catch (e) {
      Logger.error('Error loading materials: $e');
    }
  }
  
  Future<void> _generateSchedule() async {
    if (_selectedMaterials.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one study material')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
      _response = '';
    });
    
    try {
      final response = await _aiService.getResponse(
        question: '''
Generate an optimal study schedule for the following materials:
${_selectedMaterials.map((m) => '- ${m.title} (${m.category})').join('\n')}

Consider:
1. Material difficulty and prerequisites
2. Optimal study time distribution
3. Breaks and rest periods
4. Review sessions
5. Practice exercises

Format the response as a weekly schedule with specific time slots.
''',
        model: 'study assistant',
      );
      
      setState(() {
        _response = response;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Error generating schedule: $e');
      setState(() {
        _response = 'Error generating schedule: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _optimizeSchedule() async {
    setState(() {
      _isLoading = true;
      _response = '';
    });
    
    try {
      final response = await _aiService.getResponse(
        question: '''
Optimize this study schedule considering:
1. Peak cognitive performance times
2. Material difficulty progression
3. Spaced repetition principles
4. Energy levels throughout the day
5. Balance between different subjects

Current schedule:
${widget.schedule.title}
${widget.schedule.description ?? ''}

Selected materials:
${_selectedMaterials.map((m) => '- ${m.title} (${m.category})').join('\n')}
''',
        model: 'claude',
      );
      
      setState(() {
        _response = response;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Error optimizing schedule: $e');
      setState(() {
        _response = 'Error optimizing schedule: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Schedule Planner'),
      ),
      body: Column(
        children: [
          _buildMaterialSelector(),
          _buildActions(),
          Expanded(
            child: _buildResponseArea(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMaterialSelector() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Study Materials',
              style: AppStyles.heading3,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableMaterials.map((material) {
                final isSelected = _selectedMaterials.contains(material);
                return FilterChip(
                  label: Text(material.title),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedMaterials.add(material);
                      } else {
                        _selectedMaterials.remove(material);
                      }
                    });
                  },
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  selectedColor: AppColors.primary.withOpacity(0.3),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildActions() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _generateSchedule,
            icon: const Icon(Icons.calendar_today),
            label: const Text('Generate Schedule'),
            style: AppStyles.primaryButtonStyle,
          ),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _optimizeSchedule,
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Optimize'),
            style: AppStyles.primaryButtonStyle,
          ),
        ],
      ),
    );
  }
  
  Widget _buildResponseArea() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _response.isNotEmpty
              ? Text(
                  _response,
                  style: TextStyle(
                    color: AppColors.primary, // Replace 'primary' with the appropriate color from AppColors
                  ),
                )
              : Center(
                  child: Text(
                    'Select materials and use one of the actions above to generate or optimize your schedule',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
    );
  }
} 