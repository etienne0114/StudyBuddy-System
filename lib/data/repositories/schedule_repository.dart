import 'package:study_scheduler/data/database/database_helper.dart';
import 'package:study_scheduler/data/models/activity.dart';
import 'package:study_scheduler/data/models/schedule.dart';
import 'package:study_scheduler/services/notification_service.dart';
import 'package:study_scheduler/utils/logger.dart';

class ScheduleRepository {
  final DatabaseHelper _dbHelper;
  final NotificationService _notificationService;

  ScheduleRepository({
    required DatabaseHelper dbHelper,
    required NotificationService notificationService,
  })  : _dbHelper = dbHelper,
        _notificationService = notificationService;

  // Schedule operations
  Future<List<Schedule>> getAllSchedules() async {
    return await _dbHelper.getSchedules();
  }

  Future<Schedule?> getScheduleById(int id) async {
    return await _dbHelper.getSchedule(id);
  }

  Future<int> createSchedule(Schedule schedule) async {
    return await _dbHelper.insertSchedule(schedule);
  }

  Future<int> updateSchedule(Schedule schedule) async {
    return await _dbHelper.updateSchedule(schedule);
  }

  Future<bool> deleteSchedule(int id) async {
    try {
      final activities = await _dbHelper.getActivitiesByScheduleId(id);
      for (var activity in activities) {
        if (activity.id != null) {
          await _notificationService.cancelNotification(activity.id!);
        }
      }
      await _dbHelper.deleteSchedule(id);
      return true;
    } catch (e) {
      Logger.error('Error deleting schedule: $e');
      return false;
    }
  }

  // Activity operations
  Future<List<Activity>> getAllActivities() async {
    return await _dbHelper.getActivities();
  }

  Future<List<Activity>> getActivitiesByScheduleId(int scheduleId) async {
    return await _dbHelper.getActivitiesByScheduleId(scheduleId);
  }

  Future<List<Activity>> getTodayActivities(int dayOfWeek) async {
    return await _dbHelper.getUpcomingActivities(dayOfWeek);
  }

  Future<int> createActivity(Activity activity) async {
    try {
      final activityId = await _dbHelper.insertActivity(activity);
      final updatedActivity = activity.copyWith(id: activityId);
      await _notificationService.scheduleActivityNotification(updatedActivity);
      return activityId;
    } catch (e) {
      Logger.error('Error creating activity: $e');
      rethrow;
    }
  }

  Future<bool> updateActivity(Activity activity) async {
    try {
      if (activity.id == null) {
        throw Exception('Cannot update activity without ID');
      }
      await _dbHelper.updateActivity(activity);
      await _notificationService.cancelNotification(activity.id!);
      await _notificationService.scheduleActivityNotification(activity);
      return true;
    } catch (e) {
      Logger.error('Error updating activity: $e');
      return false;
    }
  }

  Future<bool> deleteActivity(int id) async {
    try {
      await _notificationService.cancelNotification(id);
      await _dbHelper.deleteActivity(id);
      return true;
    } catch (e) {
      Logger.error('Error deleting activity: $e');
      return false;
    }
  }

  Future<List<Activity>> getUpcomingActivities() async {
    final now = DateTime.now();
    final todayActivities = await getTodayActivities(now.weekday - 1);
    todayActivities.sort((a, b) => a.startTime.compareTo(b.startTime));
    final currentTime = DateTime.now().toString().substring(11, 16);
    final upcomingActivities = todayActivities.where((activity) {
      return activity.startTime.compareTo(currentTime) >= 0;
    }).toList();
    return upcomingActivities;
  }

  Future<void> rescheduleAllNotifications() async {
    try {
      final activities = await getAllActivities();
      await _notificationService.cancelAllNotifications();
      for (var activity in activities) {
        if (activity.id != null) {
          await _notificationService.scheduleActivityNotification(activity);
        }
      }
    } catch (e) {
      Logger.error('Error rescheduling notifications: $e');
    }
  }
}
