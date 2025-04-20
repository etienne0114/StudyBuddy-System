import 'package:flutter/material.dart';
import 'package:study_scheduler/data/models/activity.dart';
import 'package:study_scheduler/data/models/schedule.dart';
import 'package:study_scheduler/ui/dialogs/ai_assistant_dialog.dart';
import 'package:study_scheduler/utils/logger.dart';

class AddActivityScreen extends StatefulWidget {
  const AddActivityScreen({super.key});

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 1);
  int _selectedDayOfWeek = DateTime.now().weekday;
  bool _isRecurring = false;
  int _notifyBefore = 15; // Default 15 minutes
  Schedule? _selectedSchedule;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showAIAssistant() {
    showDialog(
      context: context,
      builder: (context) => const AIAssistantDialog(
        initialQuestion: 'Help me plan this activity.',
      ),
    );
  }

  Future<void> _selectTime(bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final activity = Activity(
        scheduleId: _selectedSchedule!.id!,
        title: _titleController.text,
        description: _descriptionController.text,
        dayOfWeek: _selectedDayOfWeek,
        startTime: _startTime.format(context),
        endTime: _endTime.format(context),
        notifyBefore: _notifyBefore,
        isRecurring: _isRecurring,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // TODO: Save activity to database
      Logger.info('Saving activity: ${activity.title}');

      Navigator.pop(context);
    } catch (e) {
      Logger.error('Error saving activity: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save activity')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Activity'),
        actions: [
          IconButton(
            icon: const Icon(Icons.assistant),
            onPressed: _showAIAssistant,
            tooltip: 'AI Assistant',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<Schedule>(
                value: _selectedSchedule,
                decoration: const InputDecoration(
                  labelText: 'Schedule',
                  border: OutlineInputBorder(),
                ),
                items: const [], // TODO: Add schedule items
                onChanged: (Schedule? value) {
                  setState(() => _selectedSchedule = value);
                },
                validator: (value) {
                  if (value == null) return 'Please select a schedule';
                  return null;
                },
              ),
              const SizedBox(height: 16.0),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
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
              DropdownButtonFormField<int>(
                value: _selectedDayOfWeek,
                decoration: const InputDecoration(
                  labelText: 'Day of Week',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (int i = 1; i <= 7; i++)
                    DropdownMenuItem(
                      value: i,
                      child: Text([
                        'Monday',
                        'Tuesday',
                        'Wednesday',
                        'Thursday',
                        'Friday',
                        'Saturday',
                        'Sunday'
                      ][i - 1]),
                    ),
                ],
                onChanged: (int? value) {
                  if (value != null) {
                    setState(() => _selectedDayOfWeek = value);
                  }
                },
              ),
              const SizedBox(height: 16.0),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Start Time'),
                      subtitle: Text(_startTime.format(context)),
                      onTap: () => _selectTime(true),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('End Time'),
                      subtitle: Text(_endTime.format(context)),
                      onTap: () => _selectTime(false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),
              DropdownButtonFormField<int>(
                value: _notifyBefore,
                decoration: const InputDecoration(
                  labelText: 'Notify Before',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem(value: 5, child: Text('5 minutes')),
                  const DropdownMenuItem(value: 10, child: Text('10 minutes')),
                  const DropdownMenuItem(value: 15, child: Text('15 minutes')),
                  const DropdownMenuItem(value: 30, child: Text('30 minutes')),
                  const DropdownMenuItem(value: 60, child: Text('1 hour')),
                ],
                onChanged: (int? value) {
                  if (value != null) {
                    setState(() => _notifyBefore = value);
                  }
                },
              ),
              const SizedBox(height: 16.0),
              SwitchListTile(
                title: const Text('Recurring Activity'),
                value: _isRecurring,
                onChanged: (bool value) {
                  setState(() => _isRecurring = value);
                },
              ),
              const SizedBox(height: 24.0),
              ElevatedButton(
                onPressed: _saveActivity,
                child: const Text('Save Activity'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 