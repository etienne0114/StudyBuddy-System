import 'package:flutter/material.dart';
import 'package:study_scheduler/data/models/activity.dart';
import 'package:study_scheduler/data/models/schedule.dart';
import 'package:study_scheduler/ui/dialogs/ai_assistant_dialog.dart';
import 'package:study_scheduler/utils/logger.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  Schedule? _selectedSchedule;
  final List<Activity> _activities = [];

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    try {
      // TODO: Implement schedule loading from database
      Logger.info('Loading schedules...');
    } catch (e) {
      Logger.error('Error loading schedules: $e');
    }
  }

  void _showAIAssistant() {
    showDialog(
      context: context,
      builder: (context) => const AIAssistantDialog(
        initialQuestion: 'Help me create a study schedule.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Scheduler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.assistant),
            onPressed: _showAIAssistant,
            tooltip: 'AI Assistant',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildScheduleSelector(),
          const Divider(),
          Expanded(
            child: _buildActivityList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add-activity'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildScheduleSelector() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: DropdownButton<Schedule>(
              value: _selectedSchedule,
              hint: const Text('Select a schedule'),
              isExpanded: true,
              items: const [], // TODO: Add schedule items
              onChanged: (Schedule? schedule) {
                setState(() {
                  _selectedSchedule = schedule;
                  _loadActivities();
                });
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _createNewSchedule,
            tooltip: 'Create new schedule',
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList() {
    if (_selectedSchedule == null) {
      return const Center(
        child: Text('Please select a schedule'),
      );
    }

    if (_activities.isEmpty) {
      return const Center(
        child: Text('No activities found'),
      );
    }

    return ListView.builder(
      itemCount: _activities.length,
      itemBuilder: (context, index) {
        final activity = _activities[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ListTile(
            title: Text(activity.title),
            subtitle: Text(activity.description ?? ''),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${activity.startTime} - ${activity.endTime}'),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editActivity(activity),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteActivity(activity),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _loadActivities() async {
    if (_selectedSchedule == null) return;
    try {
      // TODO: Implement activity loading from database
      Logger.info('Loading activities for schedule: ${_selectedSchedule!.id}');
    } catch (e) {
      Logger.error('Error loading activities: $e');
    }
  }

  void _createNewSchedule() {
    // TODO: Implement schedule creation
    Logger.info('Creating new schedule...');
  }

  void _editActivity(Activity activity) {
    // TODO: Implement activity editing
    Logger.info('Editing activity: ${activity.id}');
  }

  void _deleteActivity(Activity activity) {
    // TODO: Implement activity deletion
    Logger.info('Deleting activity: ${activity.id}');
  }
} 