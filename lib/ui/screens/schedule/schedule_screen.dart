import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:study_scheduler/constants/app_colors.dart';
import 'package:study_scheduler/constants/app_styles.dart';
import 'package:study_scheduler/data/database/database_helper.dart';
import 'package:study_scheduler/data/models/activity.dart';
import 'package:study_scheduler/data/models/schedule.dart';
import 'package:study_scheduler/ui/screens/schedule/add_activity_screen.dart';
import 'package:study_scheduler/ui/screens/home/widgets/upcoming_activities.dart';
import 'package:intl/intl.dart';
import 'package:study_scheduler/utils/logger.dart';

// Extension to convert TimeOfDay to and from string format
extension TimeOfDayExtension on TimeOfDay {
  String toTimeString() {
    final hourString = hour.toString().padLeft(2, '0');
    final minuteString = minute.toString().padLeft(2, '0');
    return '$hourString:$minuteString';
  }
}

extension StringToTimeOfDay on String {
  TimeOfDay toTimeOfDay() {
    final parts = split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }
}

class ScheduleScreen extends StatefulWidget {
  final Schedule? selectedSchedule;

  const ScheduleScreen({
    Key? key,
    this.selectedSchedule,
  }) : super(key: key);

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  late CalendarFormat _calendarFormat;
  
  List<Schedule> _schedules = [];
  List<Activity> _activities = [];
  int? _selectedScheduleId;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
    _calendarFormat = CalendarFormat.week;
    
    if (widget.selectedSchedule != null) {
      _selectedScheduleId = widget.selectedSchedule!.id;
    }
    
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load all schedules
      final schedules = await _dbHelper.getSchedules();
      
      // If no specific schedule was selected, use the first one
      if (_selectedScheduleId == null && schedules.isNotEmpty) {
        _selectedScheduleId = schedules.first.id;
      }
      
      // Load activities for selected day
      final activities = await _loadActivitiesForSelectedDay();
      
      setState(() {
        _schedules = schedules;
        _activities = activities;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load schedule data')),
        );
      }
    }
  }

  Future<List<Activity>> _loadActivitiesForSelectedDay() async {
    // Get day of week (1-7, Monday-Sunday)
    final dayOfWeek = _selectedDay.weekday;
    
    // Load activities for the selected day
    if (_selectedScheduleId != null) {
      // Load activities for specific schedule
      final activities = await _dbHelper.getActivitiesByScheduleId(_selectedScheduleId!);
      
      // Filter by day of week
      return activities.where((activity) => activity.dayOfWeek == dayOfWeek).toList();
    } else {
      // Load all activities for this day
      return await _dbHelper.getUpcomingActivities(dayOfWeek);
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });
    
    // Reload activities for the new selected day
    _loadActivitiesForSelectedDay().then((activities) {
      setState(() {
        _activities = activities;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Schedule'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showScheduleFilterSheet,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCalendar(),
                _buildScheduleHeader(),
                Expanded(
                  child: _activities.isEmpty
                      ? _buildEmptyState()
                      : _buildActivitiesList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddActivity,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalendar() {
    return Card(
      margin: const EdgeInsets.all(8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        calendarFormat: _calendarFormat,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: _onDaySelected,
        onFormatChanged: (format) {
          setState(() {
            _calendarFormat = format;
          });
        },
        onPageChanged: (focusedDay) {
          _focusedDay = focusedDay;
        },
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          markersMaxCount: 3,
        ),
        headerStyle: const HeaderStyle(
          titleCentered: true,
          formatButtonShowsNext: false,
        ),
      ),
    );
  }

  Widget _buildScheduleHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            DateFormat('EEEE, MMMM d').format(_selectedDay),
            style: AppStyles.heading2,
          ),
          Text(
            '${_activities.length} Activities',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: UpcomingActivities(
        activities: _activities,
        onActivityTap: (activity) {
          _navigateToEditActivity(activity);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return AppStyles.buildEmptyState(
      icon: Icons.event_busy,
      message: 'No activities scheduled',
      subMessage: 'Add activities to your schedule for this day',
      actionButton: ElevatedButton.icon(
        onPressed: _navigateToAddActivity,
        icon: const Icon(Icons.add),
        label: const Text('Add Activity'),
        style: AppStyles.primaryButtonStyle,
      ),
    );
  }

  void _navigateToAddActivity() {
    // Check if there are any schedules
    if (_schedules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to create a schedule first'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    final now = TimeOfDay.now();
    final nextHour = TimeOfDay(
      hour: now.hour + 1 > 23 ? 23 : now.hour + 1,
      minute: now.minute,
    );
    
    // Create a new activity with default values
    final newActivity = Activity(
      title: '',
      dayOfWeek: _selectedDay.weekday,
      startTime: now.toTimeString(),
      endTime: nextHour.toTimeString(),
      scheduleId: _selectedScheduleId ?? _schedules.first.id!,
      description: '',
      notifyBefore: 30,
      isRecurring: 1,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddActivityScreen(
          activity: newActivity,
          schedule: _schedules.firstWhere((schedule) => schedule.id == newActivity.scheduleId),
        ),
      ),
    ).then((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  void _navigateToEditActivity(Activity activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddActivityScreen(
          activity: activity,
          schedule: _schedules.firstWhere((schedule) => schedule.id == activity.scheduleId),
        ),
      ),
    ).then((_) {
      if (mounted) {
        _loadData();
      }
    });
  }

  void _showScheduleFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter by Schedule',
                    style: AppStyles.heading3,
                  ),
                  const SizedBox(height: 16),
                  
                  // All schedules option
                  RadioListTile<int?>(
                    title: const Text('All Schedules'),
                    value: null,
                    groupValue: _selectedScheduleId,
                    onChanged: (value) {
                      setSheetState(() {
                        _selectedScheduleId = value;
                      });
                      
                      setState(() {
                        _selectedScheduleId = value;
                      });
                      
                      Navigator.pop(context);
                      _loadData();
                    },
                  ),
                  
                  // List of schedules
                  ..._schedules.map((schedule) {
                    final Color scheduleColor = schedule.color != null 
                        ? Color(schedule.color)
                        : Colors.grey;
                        
                    return RadioListTile<int?>(
                      title: Text(schedule.title),
                      subtitle: Text(
                        schedule.description ?? 'No description',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      value: schedule.id,
                      groupValue: _selectedScheduleId,
                      secondary: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: scheduleColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      onChanged: (value) {
                        setSheetState(() {
                          _selectedScheduleId = value;
                        });
                        
                        setState(() {
                          _selectedScheduleId = value;
                        });
                        
                        Navigator.pop(context);
                        _loadData();
                      },
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }
}