import 'package:flutter/material.dart' hide SizedBox;
import 'package:flutter/material.dart' as material show SizedBox;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:study_scheduler/constants/app_colors.dart';
import 'package:study_scheduler/constants/app_styles.dart';
import 'package:study_scheduler/data/models/activity.dart';
import 'package:study_scheduler/data/models/schedule.dart';
import 'package:study_scheduler/providers/schedule_provider.dart';
import 'package:study_scheduler/ui/screens/home/widgets/schedule_card.dart';
import 'package:study_scheduler/ui/screens/home/widgets/upcoming_activities.dart';
import 'package:study_scheduler/ui/screens/materials/materials_screen.dart';
import 'package:study_scheduler/ui/screens/profile/profile_screen.dart';
import 'package:study_scheduler/ui/screens/schedule/add_activity_screen.dart';
import 'package:study_scheduler/ui/screens/schedule/schedule_screen.dart';
class SizedBox extends material.SizedBox {
  const SizedBox({Key? key, double? width, double? height})
      : super(key: key, width: width, height: height);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late PageController _pageController;
  late String _currentDay;
  late String _currentDate;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    _setupCurrentDate();
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
      scheduleProvider.loadSchedules();
      scheduleProvider.loadTodayActivities();
      scheduleProvider.loadUpcomingActivities();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _setupCurrentDate() {
    final now = DateTime.now();
    _currentDay = DateFormat('EEEE').format(now);
    _currentDate = DateFormat('MMMM d, yyyy').format(now);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: [
          _buildHomeTab(),
          const ScheduleScreen(),
          const MaterialsScreen(),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Materials',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      floatingActionButton: _currentIndex <= 1 ? FloatingActionButton(
        onPressed: _navigateToAddActivity,
        child: const Icon(Icons.add),
      ) : null,
    );
  }

  Widget _buildHomeTab() {
    final scheduleProvider = Provider.of<ScheduleProvider>(context);
    final isLoading = scheduleProvider.isLoading;
    final List<Activity> todayActivities = scheduleProvider.todayActivities.cast<Activity>();
    final List<Schedule> schedules = scheduleProvider.schedules.cast<Schedule>();
    
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Study Scheduler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => scheduleProvider.refreshAll(),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => scheduleProvider.refreshAll(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderSection(),
                    const SizedBox(height: 24),
                    _buildTodayActivitiesSection(todayActivities),
                    const SizedBox(height: 24),
                    _buildSchedulesSection(schedules),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _currentDay,
          style: AppStyles.heading1,
        ),
        Text(
          _currentDate,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildTodayActivitiesSection(List<Activity> activities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Today's Activities",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        activities.isEmpty
            ? _buildEmptyActivitiesMessage()
            : UpcomingActivities(
                activities: activities,
                onActivityTap: _navigateToEditActivity,
              ),
      ],
    );
  }

  Widget _buildEmptyActivitiesMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(0.1 as int),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.event_available,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No activities scheduled for today',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _navigateToAddActivity,
            child: const Text('Add Activity'),
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulesSection(List<Schedule> schedules) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'My Schedules',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            TextButton(
              onPressed: () => _onTabTapped(1), // Navigate to schedule tab
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        schedules.isEmpty
            ? _buildEmptySchedulesMessage()
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: schedules.length > 3 ? 3 : schedules.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ScheduleCard(
                      schedule: schedules[index],
                      onTap: () {
                        // Select schedule and navigate to schedule tab
                        Provider.of<ScheduleProvider>(context, listen: false)
                            .selectSchedule(schedules[index]);
                        _onTabTapped(1);
                      },
                    ),
                  );
                },
              ),
      ],
    );
  }

  Widget _buildEmptySchedulesMessage() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(0.1 as int),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.calendar_today,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No schedules created yet',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              // Navigate to add schedule screen
              _onTabTapped(1);
            },
            child: const Text('Create Schedule'),
          ),
        ],
      ),
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onTabTapped(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _navigateToAddActivity() {
    final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
    final schedules = scheduleProvider.schedules;
    final selectedSchedule = scheduleProvider.selectedSchedule;
    
    // Check if there are any schedules
    if (schedules.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You need to create a schedule first'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    
    // Using "then" on the Future instead of "await" eliminates BuildContext usage across async gaps
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddActivityScreen(
          schedule: selectedSchedule ?? schedules.first,
        ),
      ),
    ).then((_) {
      if (!mounted) return;
      scheduleProvider.refreshAll();
    });
  }

  void _navigateToEditActivity(Activity activity) {
    final scheduleProvider = Provider.of<ScheduleProvider>(context, listen: false);
    final schedules = scheduleProvider.schedules;
    
    // Find the schedule that this activity belongs to
    final schedule = schedules.firstWhere(
      (s) => s.id == activity.scheduleId,
      orElse: () => schedules.first,
    );
    
    // Using "then" on the Future instead of "await" eliminates BuildContext usage across async gaps
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddActivityScreen(
          schedule: schedule,
          activity: activity,
        ),
      ),
    ).then((_) {
      if (!mounted) return;
      scheduleProvider.refreshAll();
    });
  }
}