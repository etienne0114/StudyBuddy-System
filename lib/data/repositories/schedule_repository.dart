// lib/data/repositories/schedule_repository.dart

import 'package:study_scheduler/data/database/database_helper.dart';
import 'package:study_scheduler/data/models/activity.dart';
import 'package:study_scheduler/data/models/schedule.dart';
import 'package:study_scheduler/services/notification_service.dart';
import 'package:study_scheduler/utils/logger.dart';

class ScheduleRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService();

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
      // Get all activities for this schedule
      final activities = await _dbHelper.getActivitiesByScheduleId(id);
      
      // Cancel notifications for all activities
      for (var activity in activities) {
        if (activity.id != null) {
          await _notificationService.cancelNotification(activity.id!);
        }
      }
      
      // Delete the schedule (should cascade delete activities due to foreign key)
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
      // Insert activity into database
      final activityId = await _dbHelper.insertActivity(activity);
      
      // Schedule notification for this activity
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
      // Make sure activity has an ID
      if (activity.id == null) {
        throw Exception('Cannot update activity without ID');
      }
      
      // Update activity in database
      await _dbHelper.updateActivity(activity);
      
      // Update notification
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
      // Cancel notification first
      await _notificationService.cancelNotification(id);
      
      // Delete activity from database
      await _dbHelper.deleteActivity(id);
      
      return true;
    } catch (e) {
      Logger.error('Error deleting activity: $e');
      return false;
    }
  }

  // Get upcoming activities across all schedules
  Future<List<Activity>> getUpcomingActivities() async {
    final now = DateTime.now();
    final todayActivities = await getTodayActivities(now.weekday - 1); // Convert to 0-based
    
    // Sort by start time
    todayActivities.sort((a, b) => a.startTime.compareTo(b.startTime));
    
    // Filter to only show upcoming activities
    final currentTime = DateTime.now().toString().substring(11, 16); // "HH:MM"
    
    final upcomingActivities = todayActivities.where((activity) {
      return activity.startTime.compareTo(currentTime) >= 0;
    }).toList();
    
    return upcomingActivities;
  }

  // Reschedule all notifications
  Future<void> rescheduleAllNotifications() async {
    try {
      // Get all activities
      final activities = await getAllActivities();
      
      // Cancel all existing notifications
      await _notificationService.cancelAllNotifications();
      
      // Schedule notifications for each activity
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