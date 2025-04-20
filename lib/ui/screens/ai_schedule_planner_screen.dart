import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_scheduler/data/models/activity.dart';
import 'package:study_scheduler/data/models/schedule.dart';
import 'package:study_scheduler/utils/logger.dart';

class AISchedulePlannerScreen extends StatefulWidget {
  const AISchedulePlannerScreen({super.key});

  @override
  State<AISchedulePlannerScreen> createState() => _AISchedulePlannerScreenState();
}

class _AISchedulePlannerScreenState extends State<AISchedulePlannerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _subjectsController = TextEditingController();
  final _hoursPerWeekController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  List<Activity>? _suggestedActivities;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _subjectsController.dispose();
    _hoursPerWeekController.dispose();
    super.dispose();
  }

  Future<void> _generateSchedule() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _suggestedActivities = null;
    });

    try {
      final aiManager = Provider.of<AIAssistantManager>(context, listen: false);
      final prompt = '''
Create a study schedule with the following parameters:
Title: ${_titleController.text}
Description: ${_descriptionController.text}
Subjects: ${_subjectsController.text}
Hours per week: ${_hoursPerWeekController.text}

Please suggest a balanced schedule that:
1. Distributes study time evenly across subjects
2. Includes breaks between sessions
3. Considers optimal study times
4. Allows for flexibility
''';

      final response = await aiManager.getResponse(prompt);
      // TODO: Parse AI response and create activities
      Logger.info('AI Response received: $response');

      setState(() {
        _isLoading = false;
        // TODO: Set _suggestedActivities based on AI response
      });
    } catch (e) {
      Logger.error('Error generating schedule: $e');
      setState(() {
        _isLoading = false;
        _error = 'Failed to generate schedule. Please try again.';
      });
    }
  }

  Future<void> _saveSchedule() async {
    if (_suggestedActivities == null || _suggestedActivities!.isEmpty) return;

    try {
      final schedule = Schedule(
        title: _titleController.text,
        description: _descriptionController.text,
        color: Colors.blue.value,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // TODO: Save schedule and activities to database
      Logger.info('Saving schedule: ${schedule.title}');

      Navigator.pop(context);
    } catch (e) {
      Logger.error('Error saving schedule: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save schedule')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Schedule Planner'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Schedule Title',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _subjectsController,
                decoration: const InputDecoration(
                  labelText: 'Subjects (comma-separated)',
                  border: OutlineInputBorder(),
                  hintText: 'Math, Physics, Chemistry',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter at least one subject';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _hoursPerWeekController,
                decoration: const InputDecoration(
                  labelText: 'Hours per Week',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter hours per week';
                  }
                  final hours = int.tryParse(value);
                  if (hours == null || hours <= 0 || hours > 168) {
                    return 'Please enter a valid number of hours (1-168)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _isLoading ? null : _generateSchedule,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Generate Schedule'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16.0),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              if (_suggestedActivities != null) ...[
                const SizedBox(height: 24.0),
                const Text(
                  'Suggested Schedule',
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16.0),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _suggestedActivities!.length,
                  itemBuilder: (context, index) {
                    final activity = _suggestedActivities![index];
                    return Card(
                      child: ListTile(
                        title: Text(activity.title),
                        subtitle: Text(
                            '${activity.startTime} - ${activity.endTime}\n${activity.description}'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24.0),
                ElevatedButton(
                  onPressed: _saveSchedule,
                  child: const Text('Save Schedule'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 