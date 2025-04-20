// lib/ui/screens/home/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_scheduler/constants/app_colors.dart';
import 'package:study_scheduler/data/models/activity.dart';
import 'package:study_scheduler/data/models/schedule.dart';
import 'package:study_scheduler/data/models/study_material.dart';
import 'package:study_scheduler/data/repositories/schedule_repository.dart';
import 'package:study_scheduler/data/repositories/study_materials_repository.dart';
import 'package:study_scheduler/ui/screens/materials/compact_ai_assistant_dialog.dart';
import 'package:study_scheduler/ui/screens/profile/profile_screen.dart';
import 'package:study_scheduler/ui/screens/schedule/add_activity_screen.dart';
import 'package:study_scheduler/ui/screens/schedule/add_schedule_screen.dart';
import 'package:study_scheduler/ui/screens/schedule/schedule_detail_screen.dart';
import 'package:study_scheduler/ui/screens/home/widgets/upcoming_activities.dart';
import 'package:study_scheduler/ui/screens/home/widgets/schedule_card.dart';
import 'package:study_scheduler/ui/screens/materials/materials_screen.dart';
import 'package:study_scheduler/ui/screens/materials/add_material_screen.dart';
import 'package:study_scheduler/ui/screens/materials/ai_study_recommendations_screen.dart';
import 'package:study_scheduler/ui/screens/materials/material_detail_screen.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isLoading = false;
  List<Activity> _upcomingActivities = [];
  List<Schedule> _allSchedules = [];
  List<Activity> _completedActivities = [];
  List<StudyMaterial> _recentMaterials = [];
  
  final StudyMaterialsRepository _materialsRepository = StudyMaterialsRepository();
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final repository = Provider.of<ScheduleRepository>(context, listen: false);
      
      // Load schedules
      final schedules = await repository.getAllSchedules();
      
      // Load today's upcoming activities
      final upcomingActivities = await repository.getUpcomingActivities();
      
      // Get completed activities (for demonstration, we'll simulate some completed activities)
      // In a real app, you would fetch this from a database with a status field
      final now = DateTime.now();
      final allActivities = await repository.getAllActivities();
      final completed = allActivities.where((activity) {
        // Consider activities with end time before current time as completed
        final timeParts = activity.endTime.split(':');
        final activityEndTime = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
        final activityEndDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          activityEndTime.hour,
          activityEndTime.minute,
        );
        
        return activityEndDateTime.isBefore(now) && activity.dayOfWeek == now.weekday;
      }).toList();
      
      // Load recent study materials
      final materials = await _materialsRepository.getMaterials();
      materials.sort((a, b) => 
        DateTime.parse(b.updatedAt).compareTo(DateTime.parse(a.updatedAt))
      );
      final recentMaterials = materials.take(5).toList();
      
      setState(() {
        _allSchedules = schedules;
        _upcomingActivities = upcomingActivities;
        _completedActivities = completed;
        _recentMaterials = recentMaterials;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error loading data: $e');
      }
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_rounded),
              label: 'Schedule',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_rounded),
              label: 'Materials',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }
  
  Widget? _buildFloatingActionButton() {
    if (_currentIndex == 0) {
      return FloatingActionButton(
        onPressed: () => _showAddActionSheet(),
        child: const Icon(Icons.add),
      );
    } else if (_currentIndex == 1) {
      return FloatingActionButton(
        onPressed: () => _navigateToAddSchedule(),
        child: const Icon(Icons.add),
      );
    } else if (_currentIndex == 2) {
      return FloatingActionButton(
        onPressed: () => _navigateToAddMaterial(),
        child: const Icon(Icons.add),
      );
    }
    return null;
  }
  
  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildScheduleTab();
      case 2:
        return _buildMaterialsTab();
      case 3:
        return _buildProfileTab();
      default:
        return _buildHomeTab();
    }
  }
  
  Widget _buildHomeTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final now = DateTime.now();
    final dateFormatter = DateFormat('EEEE, MMMM d');
    final timeFormatter = DateFormat('h:mm a');
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Custom App Bar with Gradient
          SliverAppBar(
            expandedHeight: 200.0,
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
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          'Welcome Back!',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          dateFormatter.format(now),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          timeFormatter.format(now),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Actions
                  _buildQuickActions(),
                  const SizedBox(height: 24),

                  // Upcoming Activities Section
                  _buildSectionHeader(
                    'Upcoming Activities',
                    'Today\'s schedule',
                    Icons.schedule_rounded,
                  ),
                  const SizedBox(height: 16),
                  _upcomingActivities.isEmpty
                      ? ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 100),
                          child: _buildEmptyState(
                            icon: Icons.event_available,
                            message: 'No upcoming activities',
                            subMessage: 'Enjoy your free time!',
                          ),
                        )
                      : SizedBox(
                          height: 180,
                          child: UpcomingActivities(
                            activities: _upcomingActivities,
                            onActivityTap: _navigateToActivityDetails,
                          ),
                        ),
                  const SizedBox(height: 24),

                  // My Schedules Section
                  _buildSectionHeader(
                    'My Schedules',
                    'Manage your time',
                    Icons.calendar_today_rounded,
                    action: TextButton(
                      onPressed: () {
                        setState(() {
                          _currentIndex = 1;
                        });
                      },
                      child: const Text('See All'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _allSchedules.isEmpty
                      ? ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 100),
                          child: _buildEmptyState(
                            icon: Icons.calendar_today,
                            message: 'No schedules yet',
                            subMessage: 'Create your first schedule to get started',
                          ),
                        )
                      : SizedBox(
                          height: 160,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _allSchedules.length > 3 ? 3 : _allSchedules.length,
                            itemBuilder: (context, index) {
                              final schedule = _allSchedules[index];
                              return Container(
                                width: 200,
                                margin: const EdgeInsets.only(right: 16),
                                child: ScheduleCard(
                                  schedule: schedule,
                                  onTap: () => _navigateToScheduleDetails(schedule),
                                ),
                              );
                            },
                          ),
                        ),
                  const SizedBox(height: 24),

                  // Study Materials Section
                  _buildSectionHeader(
                    'Recent Materials',
                    'Continue your studies',
                    Icons.book_rounded,
                    action: TextButton(
                      onPressed: () {
                        setState(() {
                          _currentIndex = 2;
                        });
                      },
                      child: const Text('See All'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _recentMaterials.isEmpty
                      ? ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 100),
                          child: _buildEmptyState(
                            icon: Icons.book,
                            message: 'No study materials yet',
                            subMessage: 'Add materials to start learning',
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            return GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: constraints.maxWidth > 600 ? 3 : 2,
                                childAspectRatio: 0.85,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: _recentMaterials.length > 4 ? 4 : _recentMaterials.length,
                              itemBuilder: (context, index) {
                                final material = _recentMaterials[index];
                                return _buildMaterialCard(material);
                              },
                            );
                          },
                        ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickActionButton(
            icon: Icons.add_task_rounded,
            label: 'Add Task',
            onTap: () => _navigateToAddActivity(),
          ),
          _buildQuickActionButton(
            icon: Icons.calendar_month_rounded,
            label: 'Schedule',
            onTap: () => _navigateToAddSchedule(),
          ),
          _buildQuickActionButton(
            icon: Icons.library_books_rounded,
            label: 'Material',
            onTap: () => _navigateToAddMaterial(),
          ),
          _buildQuickActionButton(
            icon: Icons.psychology_rounded,
            label: 'AI Help',
            onTap: () => _showAIAssistant(null),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSectionHeader(
    String title,
    String subtitle,
    IconData icon, {
    Widget? action,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
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
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        if (action != null) action,
      ],
    );
  }
  
  Widget _buildMaterialCard(StudyMaterial material) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MaterialDetailScreen(material: material),
          ),
        ).then((_) => _loadData()),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(material.category),
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.psychology_alt_rounded,
                      color: Colors.blue,
                      size: 20,
                    ),
                    onPressed: () => _showAIAssistant(material),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                material.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  material.category,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildScheduleTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return RefreshIndicator(
      onRefresh: _loadData,
      child: _allSchedules.isEmpty
          ? ListView(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: _buildEmptyState(
                    icon: Icons.calendar_today,
                    message: 'No schedules yet',
                    subMessage: 'Create your first schedule to get started',
                    actionButton: ElevatedButton.icon(
                      onPressed: _navigateToAddSchedule,
                      icon: const Icon(Icons.add),
                      label: const Text('Add Schedule'),
                    ),
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _allSchedules.length,
              itemBuilder: (context, index) {
                final schedule = _allSchedules[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: ScheduleCard(
                    schedule: schedule,
                    onTap: () => _navigateToScheduleDetails(schedule),
                  ),
                );
              },
            ),
    );
  }
  
  Widget _buildMaterialsTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // AI Learning Assistant Banner
          Container(
            margin: const EdgeInsets.all(16),
            height: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blueAccent.shade700, Colors.blueAccent.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AIStudyRecommendationsScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(50),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.psychology_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'AI Learning Assistant',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Get help with your studies using Claude, ChatGPT, Copilot, and other AI tools',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const AIStudyRecommendationsScreen(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.blueAccent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              child: const Text('Try It Now'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      const Icon(
                        Icons.smart_toy_outlined,
                        color: Colors.white,
                        size: 60,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          
          // Materials Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Study Materials',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MaterialsScreen(),
                          ),
                        ).then((_) => _loadData());
                      },
                      child: const Text('See All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _recentMaterials.isEmpty
                    ? _buildEmptyState(
                        icon: Icons.book,
                        message: 'Study Materials',
                        subMessage: 'Your study materials will appear here',
                        actionButton: ElevatedButton.icon(
                          onPressed: () => _navigateToAddMaterial(),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Material'),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _recentMaterials.length > 3 ? 3 : _recentMaterials.length,
                        itemBuilder: (context, index) {
                          final material = _recentMaterials[index];
                          return _buildMaterialListItem(material);
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProfileTab() {
    return const ProfileScreen();
  }
  
  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    String? subMessage,
    Widget? actionButton,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          if (subMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              subMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (actionButton != null) ...[
            const SizedBox(height: 24),
            actionButton,
          ],
        ],
      ),
    );
  }
  
  void _showAddActionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Create New Schedule'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToAddSchedule();
                },
              ),
              ListTile(
                leading: const Icon(Icons.event_note),
                title: const Text('Add New Activity'),
                onTap: () {
                  Navigator.pop(context);
                  if (_allSchedules.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please create a schedule first'),
                      ),
                    );
                  } else {
                    _navigateToAddActivity();
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.book),
                title: const Text('Add Study Material'),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToAddMaterial();
                },
              ),
              ListTile(
                leading: const Icon(Icons.psychology_alt),
                title: const Text('Ask AI Assistant'),
                onTap: () {
                  Navigator.pop(context);
                  _showAIAssistant(null);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  void _showNotificationSettings() {
    int reminderTime = 30; // Default: 30 minutes
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Notification Settings'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Set how long before an activity you\'d like to be notified:'),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: reminderTime,
                  decoration: const InputDecoration(
                    labelText: 'Reminder Time',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 5, child: Text('5 minutes before')),
                    DropdownMenuItem(value: 10, child: Text('10 minutes before')),
                    DropdownMenuItem(value: 15, child: Text('15 minutes before')),
                    DropdownMenuItem(value: 30, child: Text('30 minutes before')),
                    DropdownMenuItem(value: 60, child: Text('1 hour before')),
                    DropdownMenuItem(value: 120, child: Text('2 hours before')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        reminderTime = value;
                      });
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Save notification settings
                  _saveNotificationSettings(reminderTime);
                  Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  Future<void> _saveNotificationSettings(int reminderTime) async {
    try {
      final repository = Provider.of<ScheduleRepository>(context, listen: false);
      
      // In a real app, you'd save this to user preferences
      // and update all activities with the new reminder time
      
      // Here we'll just show a snackbar to confirm
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notifications will be sent $reminderTime minutes before activities'),
          ),
        );
      }
      
      // Reschedule all notifications with the new time
      await repository.rescheduleAllNotifications();
    } catch (e) {
      if (kDebugMode) {
        print('Error saving notification settings: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save notification settings: $e')),
        );
      }
    }
  }
  
  void _navigateToAddSchedule() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddScheduleScreen(),
      ),
    ).then((_) {
      _loadData();
    });
  }
  
  void _navigateToAddActivity() {
    // If there's at least one schedule, use the first one by default
    if (_allSchedules.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddActivityScreen(
            schedule: _allSchedules.first,
          ),
        ),
      ).then((_) {
        _loadData();
      });
    }
  }
  
  void _navigateToAddMaterial() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddMaterialScreen(),
      ),
    ).then((_) {
      _loadData();
    });
  }
  
  void _navigateToScheduleDetails(Schedule schedule) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduleDetailScreen(schedule: schedule),
      ),
    ).then((_) {
      _loadData();
    });
  }
  
  void _navigateToActivityDetails(Activity activity) {
    // Find the schedule for this activity
    final schedule = _allSchedules.firstWhere(
      (schedule) => schedule.id == activity.scheduleId,
      orElse: () => _allSchedules.first, // Fallback
    );
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddActivityScreen(
          schedule: schedule,
          activity: activity,
        ),
      ),
    ).then((_) {
      _loadData();
    });
  }
  
  void _showAIAssistant(StudyMaterial? material) {
  showDialog(
    context: context,
    builder: (context) => CompactAIAssistantDialog(material: material),
  );
}
  
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'document':
        return Icons.description;
      case 'video':
        return Icons.video_library;
      case 'article':
        return Icons.article;
      case 'quiz':
        return Icons.quiz;
      case 'practice':
        return Icons.school;
      case 'reference':
        return Icons.book;
      default:
        return Icons.folder;
    }
  }

  Widget _buildCompletedActivityCard(Activity activity) {
    final Color scheduleColor = activity.scheduleColorValue ?? AppColors.primary;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: scheduleColor,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Completed',
                    style: TextStyle(
                      fontSize: 12,
                      color: scheduleColor,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              activity.title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              '${activity.formattedStartTime} - ${activity.formattedEndTime}',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: scheduleColor.withAlpha(25),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                activity.scheduleTitle ?? 'Activity',
                style: TextStyle(
                  fontSize: 12,
                  color: scheduleColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMaterialListItem(StudyMaterial material) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MaterialDetailScreen(material: material),
          ),
        ).then((_) => _loadData()),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getCategoryIcon(material.category),
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      material.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (material.description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        material.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        material.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.psychology_alt_rounded,
                  color: Colors.blue,
                ),
                onPressed: () => _showAIAssistant(material),
                tooltip: 'AI Assistant',
              ),
            ],
          ),
        ),
      ),
    );
  }
}