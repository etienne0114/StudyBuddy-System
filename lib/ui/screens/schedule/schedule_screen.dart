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
import 'package:study_scheduler/ui/screens/schedule/ai_schedule_planner_screen.dart';

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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                // Custom App Bar with Gradient
                SliverAppBar(
                  expandedHeight: 120.0,
                  floating: false,
                  pinned: true,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                  title: const Text('Weekly Schedule'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.auto_awesome_rounded),
                      onPressed: _showAIPlanner,
                      tooltip: 'AI Planner',
                    ),
                    IconButton(
                      icon: const Icon(Icons.filter_list_rounded),
                      onPressed: _showScheduleFilterSheet,
                      tooltip: 'Filter Schedules',
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: _loadData,
                      tooltip: 'Refresh',
                    ),
                  ],
                ),

                // Calendar Section
                SliverToBoxAdapter(
                  child: Card(
                    margin: const EdgeInsets.all(16.0),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
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
                          selectedDecoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          markersMaxCount: 3,
                          outsideDaysVisible: false,
                        ),
                        headerStyle: const HeaderStyle(
                          titleCentered: true,
                          formatButtonShowsNext: false,
                          titleTextStyle: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Schedule Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.event_note_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat('EEEE, MMMM d').format(_selectedDay),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${_activities.length} Activities',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Activities List
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  sliver: _activities.isEmpty
                      ? SliverFillRemaining(
                          child: _buildEmptyState(),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final activity = _activities[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: InkWell(
                                  onTap: () => _navigateToEditActivity(activity),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 4,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: Color(activity.scheduleColorValue ?? AppColors.primary.value),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                activity.title,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${activity.formattedStartTime} - ${activity.formattedEndTime}',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit_rounded),
                                          onPressed: () => _navigateToEditActivity(activity),
                                          color: Colors.grey[600],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                            childCount: _activities.length,
                          ),
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddActivity,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy_rounded,
            size: 80,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'No Activities Scheduled',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add activities to your schedule for this day',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToAddActivity,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Activity'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
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
                    final Color scheduleColor = Color(schedule.color);
                        
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

  void _showAIPlanner() {
    if (_selectedScheduleId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a schedule first'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final selectedSchedule = _schedules.firstWhere(
      (schedule) => schedule.id == _selectedScheduleId,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AISchedulePlannerScreen(
          schedule: selectedSchedule,
        ),
      ),
    );
  }
}