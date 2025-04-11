// lib/ui/screens/schedule/add_activity_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_scheduler/data/models/activity.dart';
import 'package:study_scheduler/data/models/schedule.dart';
import 'package:study_scheduler/data/repositories/schedule_repository.dart';
import 'package:study_scheduler/ui/widgets/custom_button.dart';
import 'package:study_scheduler/ui/widgets/custom_textfield.dart';

class AddActivityScreen extends StatefulWidget {
  final Schedule schedule;
  final Activity? activity; // Optional for editing existing activity

  const AddActivityScreen({
    Key? key,
    required this.schedule,
    this.activity,
  }) : super(key: key);

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late int _selectedDay;
  int _notifyBefore = 30; // Default 30 minutes
  bool _isRecurring = true;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize time values
    _startTime = TimeOfDay.now();
    _endTime = TimeOfDay(
      hour: _startTime.hour + 1,
      minute: _startTime.minute,
    );
    _selectedDay = DateTime.now().weekday; // 1-7 for Monday-Sunday
    
    // If editing existing activity, populate the form
    if (widget.activity != null) {
      _titleController.text = widget.activity!.title;
      _descriptionController.text = widget.activity!.description ?? '';
      _locationController.text = widget.activity!.location ?? '';
      _selectedDay = widget.activity!.dayOfWeek;
      _startTime = _stringToTimeOfDay(widget.activity!.startTime);
      _endTime = _stringToTimeOfDay(widget.activity!.endTime);
      _notifyBefore = widget.activity!.notifyBefore;
      _isRecurring = widget.activity!.isRecurringFlag;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  TimeOfDay _stringToTimeOfDay(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }

  String _timeOfDayToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectTime(BuildContext context, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStartTime ? _startTime : _endTime,
    );
    
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
          // If end time is now before start time, adjust it
          if (_endTime.hour < _startTime.hour || 
              (_endTime.hour == _startTime.hour && _endTime.minute < _startTime.minute)) {
            _endTime = TimeOfDay(
              hour: _startTime.hour + 1,
              minute: _startTime.minute,
            );
          }
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _saveActivity() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final activity = Activity(
        id: widget.activity?.id,
        scheduleId: widget.schedule.id!,
        title: _titleController.text,
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        location: _locationController.text.isEmpty ? null : _locationController.text,
        dayOfWeek: _selectedDay,
        startTime: _timeOfDayToString(_startTime),
        endTime: _timeOfDayToString(_endTime),
        notifyBefore: _notifyBefore,
        isRecurring: _isRecurring ? 1 : 0,
        createdAt: widget.activity?.createdAt ?? DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      final repository = Provider.of<ScheduleRepository>(context, listen: false);
      
      if (widget.activity == null) {
        await repository.createActivity(activity);
      } else {
        await repository.updateActivity(activity);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save activity: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.activity == null ? 'Add Activity' : 'Edit Activity'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomTextField(
                      controller: _titleController,
                      label: 'Title',
                      hint: 'Enter activity title',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _descriptionController,
                      label: 'Description',
                      hint: 'Enter activity description (optional)',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _locationController,
                      label: 'Location',
                      hint: 'Enter activity location (optional)',
                    ),
                    const SizedBox(height: 24),
                    Text('Day of Week', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    _buildDaySelector(),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Start Time', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => _selectTime(context, true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(_startTime.format(context)),
                                      const Icon(Icons.access_time),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('End Time', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => _selectTime(context, false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(_endTime.format(context)),
                                      const Icon(Icons.access_time),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text('Notification', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: _notifyBefore,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text('No notification')),
                        DropdownMenuItem(value: 5, child: Text('5 minutes before')),
                        DropdownMenuItem(value: 10, child: Text('10 minutes before')),
                        DropdownMenuItem(value: 15, child: Text('15 minutes before')),
                        DropdownMenuItem(value: 30, child: Text('30 minutes before')),
                        DropdownMenuItem(value: 60, child: Text('1 hour before')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _notifyBefore = value ?? 30;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Recurring Activity'),
                      subtitle: const Text('Repeat this activity every week'),
                      value: _isRecurring,
                      onChanged: (value) {
                        setState(() {
                          _isRecurring = value;
                        });
                      },
                    ),
                    const SizedBox(height: 32),
                    CustomButton(
                      text: widget.activity == null ? 'Add Activity' : 'Save Changes',
                      onPressed: _saveActivity,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildDaySelector() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        // Convert to 1-based index for dayOfWeek (1 = Monday, 7 = Sunday)
        final dayIndex = index + 1;
        return InkWell(
          onTap: () {
            setState(() {
              _selectedDay = dayIndex;
            });
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _selectedDay == dayIndex 
                  ? Theme.of(context).primaryColor 
                  : Colors.transparent,
              border: Border.all(
                color: Theme.of(context).primaryColor,
              ),
            ),
            child: Center(
              child: Text(
                days[index],
                style: TextStyle(
                  color: _selectedDay == dayIndex 
                      ? Colors.white 
                      : Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}