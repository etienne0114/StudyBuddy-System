// lib/services/notification_service.dart

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:study_scheduler/data/models/activity.dart';
import 'package:study_scheduler/constants/app_constants.dart';
import 'package:study_scheduler/utils/logger.dart';

/// Simple placeholder service for notifications
/// This will allow your app to compile and run without the actual notification functionality
class NotificationService {
  // Singleton instance
  static final NotificationService _instance = NotificationService._internal();
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;
  
  factory NotificationService() {
    return _instance;
  }
  
  NotificationService._internal() {
    tz.initializeTimeZones();
  }
  
  /// Initialize notifications (placeholder)
  Future<bool> init() async {
    if (_isInitialized) return true;
    
    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      final iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
        onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) {
          _onDidReceiveLocalNotification(id, title, body, payload);
        },
      );
      
      final initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );
      
      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );
      
      // Create notification channel for Android
      final androidChannel = AndroidNotificationChannel(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        description: AppConstants.notificationChannelDescription,
        importance: Importance.high,
      );

      // Create the Android notification channel
      await _notifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
      
      _isInitialized = true;
      Logger.info('Notification service initialized successfully');
      return true;
    } catch (e) {
      Logger.error('Failed to initialize notifications: $e');
      return false;
    }
  }
  
  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap
    Logger.info('Notification tapped: ${response.payload}');
  }
  
  void _onDidReceiveLocalNotification(int id, String? title, String? body, String? payload) {
    // Handle iOS notification when app is in foreground
    Logger.info('Received local notification: $title');
  }
  
  /// Request notification permissions (placeholder)
  Future<bool> requestPermissions() async {
    try {
      // Request permissions for iOS
      final iOS = await _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (iOS != null) {
        await iOS.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
      
      // Request permissions for Android 13 and above
      final android = await _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        // For Android, we create the notification channel which implicitly requests permissions
        final androidChannel = AndroidNotificationChannel(
          AppConstants.notificationChannelId,
          AppConstants.notificationChannelName,
          description: AppConstants.notificationChannelDescription,
          importance: Importance.high,
        );
        await android.createNotificationChannel(androidChannel);
      }
      
      return true;
    } catch (e) {
      Logger.error('Failed to request notification permissions: $e');
      return false;
    }
  }
  
  /// Schedule a notification for an activity (placeholder)
  Future<void> scheduleActivityNotification(Activity activity) async {
    if (!_isInitialized) {
      Logger.error('Notification service not initialized');
      return;
    }
    
    if (activity.id == null || activity.notifyBefore <= 0) {
      return;
    }
    
    try {
      // Parse activity time
      final timeParts = activity.startTime.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      
      // Calculate next occurrence
      final now = DateTime.now();
      var scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );
      
      // Adjust day to next occurrence
      while (scheduledDate.weekday != activity.dayOfWeek || scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }
      
      // Subtract notification time
      final notificationTime = scheduledDate.subtract(Duration(minutes: activity.notifyBefore));
      
      if (notificationTime.isBefore(now)) {
        if (!activity.isRecurringFlag) {
          Logger.info('Skipping notification for past non-recurring activity: ${activity.title}');
          return;
        }
        // For recurring activities, schedule for next week
        scheduledDate = scheduledDate.add(const Duration(days: 7));
      }
      
      final androidDetails = AndroidNotificationDetails(
        AppConstants.notificationChannelId,
        AppConstants.notificationChannelName,
        channelDescription: AppConstants.notificationChannelDescription,
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: const BigTextStyleInformation(''),
        enableVibration: true,
        playSound: true,
        category: AndroidNotificationCategory.reminder,
      );
      
      final iosDetails = const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        badgeNumber: 1,
        categoryIdentifier: 'activity_reminder',
      );
      
      final details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      
      final String timeString = '${activity.startTime.substring(0, 5)}';
      final String notifyString = activity.notifyBefore >= 60
          ? '${activity.notifyBefore ~/ 60} hour(s)'
          : '${activity.notifyBefore} minutes';
      
      await _notifications.zonedSchedule(
        activity.id!,
        'Upcoming: ${activity.title}',
        'Your activity starts at $timeString (in $notifyString)',
        tz.TZDateTime.from(notificationTime, tz.local),
        details,
        androidAllowWhileIdle: true,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: activity.isRecurringFlag
            ? DateTimeComponents.dayOfWeekAndTime
            : null,
        payload: activity.id.toString(),
      );
      
      Logger.info('Scheduled notification for activity: ${activity.title} at $timeString');
    } catch (e) {
      Logger.error('Failed to schedule notification for activity ${activity.id}: $e');
    }
  }
  
  /// Cancel a specific notification (placeholder)
  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
      Logger.info('Cancelled notification: $id');
    } catch (e) {
      Logger.error('Failed to cancel notification $id: $e');
    }
  }
  
  /// Cancel all notifications (placeholder)
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      Logger.info('Cancelled all notifications');
    } catch (e) {
      Logger.error('Failed to cancel all notifications: $e');
    }
  }
  
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      Logger.error('Failed to get pending notifications: $e');
      return [];
    }
  }
}