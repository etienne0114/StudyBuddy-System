// lib/ui/screens/schedule/schedule_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:study_scheduler/constants/app_colors.dart';
import 'package:study_scheduler/data/models/activity.dart';
import 'package:study_scheduler/data/models/schedule.dart';
import 'package:study_scheduler/data/repositories/schedule_repository.dart';
import 'package:study_scheduler/ui/screens/schedule/add_activity_screen.dart';
import 'package:study_scheduler/ui/screens/schedule/add_schedule_screen.dart';
import 'package:study_scheduler/ui/screens/home/widgets/upcoming_activities.dart';

class ScheduleDetailScreen extends StatefulWidget {
  final Schedule schedule;

  const ScheduleDetailScreen({
    Key? key,
    required this.schedule,
  }) : super(key: key);

  @override
  State<ScheduleDetailScreen> createState() => _ScheduleDetailScreenState();
}

class _ScheduleDetailScreenState extends State<ScheduleDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<Activity> _activities = [];
  List<int> _activitiesByDay = List.filled(7, 0); // Activity count for each day
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    
    // Default to current day
    final currentDayIndex = DateTime.now().weekday - 1; // 0-6 for Sunday-Saturday
    _tabController.index = currentDayIndex;
    
    _loadActivities();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final repository = Provider.of<ScheduleRepository>(context, listen: false);
      
      // Get activities for this schedule
      final activities = await repository.getActivitiesByScheduleId(widget.schedule.id!);
      
      // Count activities per day
      final activitiesByDay = List.filled(7, 0);
      for (final activity in activities) {
        final dayIndex = activity.dayOfWeek - 1; // Convert 1-7 to 0-6
        if (dayIndex >= 0 && dayIndex < 7) {
          activitiesByDay[dayIndex]++;
        }
      }
      
      setState(() {
        _activities = activities;
        _activitiesByDay = activitiesByDay;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading activities: $e');
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load activities: $e')),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final Color scheduleColor = Color(widget.schedule.color);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.schedule.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _navigateToEditSchedule,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          indicator: BoxDecoration(
            color: scheduleColor,
            borderRadius: BorderRadius.circular(8),
          ),
          tabs: [
            _buildDayTab('Mon', 0),
            _buildDayTab('Tue', 1),
            _buildDayTab('Wed', 2),
            _buildDayTab('Thu', 3),
            _buildDayTab('Fri', 4),
            _buildDayTab('Sat', 5),
            _buildDayTab('Sun', 6),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: List.generate(7, (index) => _buildDayView(index + 1)), // 1-7 for Monday-Sunday
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: scheduleColor,
        onPressed: () => _navigateToAddActivity(widget.schedule),
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildDayTab(String dayName, int dayIndex) {
    final activityCount = _activitiesByDay[dayIndex];
    
    return Tab(
      child: Row(
        children: [
          Text(dayName),
          if (activityCount > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$activityCount',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildDayView(int dayOfWeek) {
    // Filter activities for this day
    final dayActivities = _activities.where((a) => a.dayOfWeek == dayOfWeek).toList();
    
    // Sort by start time
    dayActivities.sort((a, b) => a.startTime.compareTo(b.startTime));
    
    if (dayActivities.isEmpty) {
      return _buildEmptyDayView(dayOfWeek);
    }
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getDayName(dayOfWeek),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${dayActivities.length} ${dayActivities.length == 1 ? 'Activity' : 'Activities'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Activities list
          Expanded(
            child: ListView.builder(
              itemCount: dayActivities.length,
              itemBuilder: (context, index) {
                final activity = dayActivities[index];
                
                // Add schedule info to the activity for display
                activity.scheduleTitle = widget.schedule.title;
                activity.scheduleColor = widget.schedule.color;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: _buildActivityCard(activity),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyDayView(int dayOfWeek) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No activities for ${_getDayName(dayOfWeek)}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add activities to your schedule',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToAddActivity(widget.schedule),
            icon: const Icon(Icons.add),
            label: const Text('Add Activity'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(widget.schedule.color),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActivityCard(Activity activity) {
    final Color scheduleColor = activity.scheduleColorValue ?? AppColors.primary;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _navigateToEditActivity(activity),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Time and duration
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: scheduleColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${activity.formattedStartTime} - ${activity.formattedEndTime}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: scheduleColor,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      activity.formattedDuration,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Activity title
              Text(
                activity.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              // Activity description (if any)
              if (activity.description != null && activity.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    activity.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              
              const SizedBox(height: 12),
              
              // Location and recurring status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Location (if any)
                  if (activity.location != null && activity.location!.isNotEmpty)
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              activity.location!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  
                  // Recurring indicator
                  if (activity.isRecurringFlag)
                    Row(
                      children: [
                        Icon(
                          Icons.repeat,
                          size: 16,
                          color: scheduleColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Weekly',
                          style: TextStyle(
                            fontSize: 12,
                            color: scheduleColor,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  String _getDayName(int dayOfWeek) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[dayOfWeek - 1]; // Convert 1-7 to 0-6 index
  }
  
  void _navigateToEditSchedule() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddScheduleScreen(
          schedule: widget.schedule,
        ),
      ),
    ).then((_) {
      // Refresh schedule and activities after editing
      _loadActivities();
    });
  }
  
  void _navigateToAddActivity(Schedule schedule) {
    // Get the current selected day
    final dayOfWeek = _tabController.index + 1; // Convert 0-6 to 1-7
    
    // Create a default time (current time rounded to nearest half hour)
    final now = TimeOfDay.now();
    final roundedMinute = (now.minute / 30).round() * 30;
    final startTime = TimeOfDay(
      hour: now.hour + (roundedMinute == 60 ? 1 : 0),
      minute: roundedMinute % 60,
    );
    final endTime = TimeOfDay(
      hour: (startTime.hour + 1) % 24,
      minute: startTime.minute,
    );
    
    // Create a template activity
    final newActivity = Activity(
      scheduleId: schedule.id!,
      title: '',
      dayOfWeek: dayOfWeek,
      startTime: '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}',
      endTime: '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}',
      notifyBefore: 30,
      isRecurring: 1,
      createdAt: DateTime.now().toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddActivityScreen(
          schedule: schedule,
          activity: newActivity,
        ),
      ),
    ).then((_) {
      // Refresh activities after adding new one
      _loadActivities();
    });
  }
  
  void _navigateToEditActivity(Activity activity) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddActivityScreen(
          schedule: widget.schedule,
          activity: activity,
        ),
      ),
    ).then((_) {
      // Refresh activities after editing
      _loadActivities();
    });
  }
}