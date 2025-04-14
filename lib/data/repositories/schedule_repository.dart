// lib/data/repositories/schedule_repository.dart

import 'package:study_scheduler/data/database/database_helper.dart';
import 'package:study_scheduler/data/models/activity.dart';
import 'package:study_scheduler/data/models/schedule.dart';
import 'package:study_scheduler/services/notification_service.dart';

class ScheduleRepository {
  final DatabaseHelper dbHelper;
  final NotificationService notificationService;

  ScheduleRepository({
    required this.dbHelper, 
    required this.notificationService,
  });

  // Schedule operations
  Future<List<Schedule>> getAllSchedules() async {
    return await dbHelper.getSchedules();
  }

  Future<Schedule?> getScheduleById(int id) async {
    return await dbHelper.getSchedule(id);
  }

  Future<int> createSchedule(Schedule schedule) async {
    return await dbHelper.insertSchedule(schedule);
  }

  Future<int> updateSchedule(Schedule schedule) async {
    return await dbHelper.updateSchedule(schedule);
  }

  Future<bool> deleteSchedule(int id) async {
    // Get all activities for this schedule
    final activities = await dbHelper.getActivitiesByScheduleId(id);
    
    // Cancel notifications for activities
    for (final activity in activities) {
      if (activity.notifyBefore > 0 && activity.id != null) {
        await notificationService.cancelNotification(activity.id!);
      }
    }
    
    // Delete the schedule
    final result = await dbHelper.deleteSchedule(id);
    return result > 0;
  }

  // Activity operations
  Future<List<Activity>> getAllActivities() async {
    return await dbHelper.getActivities();
  }

  Future<List<Activity>> getActivitiesByScheduleId(int scheduleId) async {
    return await dbHelper.getActivitiesByScheduleId(scheduleId);
  }

  Future<List<Activity>> getUpcomingActivities() async {
    final today = DateTime.now().weekday;
    return await dbHelper.getUpcomingActivities(today);
  }

  Future<int> createActivity(Activity activity) async {
    final id = await dbHelper.insertActivity(activity);
    
    // Schedule notification if needed
    if (activity.notifyBefore > 0) {
      _scheduleActivityNotification(activity.copyWith(id: id));
    }
    
    return id;
  }

  Future<int> updateActivity(Activity activity) async {
    final result = await dbHelper.updateActivity(activity);
    
    // Cancel old notification and schedule new one if needed
    if (activity.id != null) {
      await notificationService.cancelNotification(activity.id!);
      
      if (activity.notifyBefore > 0) {
        _scheduleActivityNotification(activity);
      }
    }
    
    return result;
  }

  Future<int> deleteActivity(int id) async {
    // Cancel notification
    await notificationService.cancelNotification(id);
    
    return await dbHelper.deleteActivity(id);
  }

  Future<void> _scheduleActivityNotification(Activity activity) async {
    if (activity.id == null) return;
    
    // Only schedule for recurring activities or current day's activities
    if (activity.isRecurringFlag || activity.dayOfWeek == DateTime.now().weekday) {
      await notificationService.scheduleActivityNotification(activity);
    }
  }

  Future<void> rescheduleAllNotifications() async {
    // Cancel all existing notifications
    await notificationService.cancelAllNotifications();
    
    // Get all activities
    final activities = await dbHelper.getActivities();
    
    // Reschedule notifications for each activity
    for (final activity in activities) {
      if (activity.notifyBefore > 0 && activity.id != null) {
        _scheduleActivityNotification(activity);
      }
    }
  }
}