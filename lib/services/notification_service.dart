import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:study_scheduler/data/models/activity.dart';
import 'package:study_scheduler/utils/date_utils.dart' as date_utils;
import 'package:study_scheduler/utils/logger.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Service for managing local notifications
class NotificationService {
  // Make this protected so it can be overridden in tests
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Singleton instance
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal() {
    tz_data.initializeTimeZones();
  }

  /// Initialize notifications
  Future<bool> init() async {
    try {
      // Android settings
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS settings
      const DarwinInitializationSettings darwinSettings =
          DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      // Initialize
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      );

      final bool? initialized = await flutterLocalNotificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationResponse,
      );

      // Request permissions
      await requestPermissions();

      return initialized ?? false;
    } catch (e) {
      Logger.error("Error initializing notifications: $e");
      return false;
    }
  }

  /// Handle notification responses (when user taps on notification)
  void _onNotificationResponse(NotificationResponse response) {
    Logger.info('Notification tapped: ${response.payload}');
    // This can be expanded to handle navigation, etc.
  }

  /// Request notification permissions
  Future<bool?> requestPermissions() async {
    try {
      // Request permissions for Android
      final androidImplementation =
          flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final bool? androidPermissionGranted =
          await androidImplementation?.requestPermission();

      // iOS permissions are already handled by DarwinInitializationSettings
      return androidPermissionGranted ?? true;
    } catch (e) {
      Logger.error("Error requesting permissions: $e");
      return false;
    }
  }

  /// Schedule a notification for an activity
  Future<void> scheduleActivityNotification(Activity activity) async {
    if (activity.id == null || activity.notifyBefore <= 0) {
      return;
    }

    try {
      // Cancel any existing notification with this ID
      await cancelNotification(activity.id!);

      // Get the next occurrence of this activity's day
      final DateTime nextOccurrence = date_utils.getNextOccurrence(activity.dayOfWeek);

      // Parse the activity start time
      final List<String> timeParts = activity.startTime.split(':');
      final int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);

      // Create a DateTime with the next occurrence date and activity start time
      final DateTime activityDateTime = DateTime(
        nextOccurrence.year,
        nextOccurrence.month,
        nextOccurrence.day,
        hour,
        minute,
      );

      // Calculate notification time (activity time - notify before minutes)
      final DateTime notificationTime = activityDateTime.subtract(
        Duration(minutes: activity.notifyBefore),
      );

      // Convert to TZ DateTime
      final tz.TZDateTime scheduledTime = tz.TZDateTime.from(
        notificationTime,
        tz.local,
      );

      // Create notification details
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'study_scheduler_channel',
        'Study Scheduler',
        channelDescription: 'Notifications for scheduled study activities',
        importance: Importance.max,
        priority: Priority.high,
      );

      const DarwinNotificationDetails darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      // Location text
      final String locationText = activity.location != null && activity.location!.isNotEmpty
          ? ' at ${activity.location}'
          : '';

      // Schedule the notification
      await flutterLocalNotificationsPlugin.zonedSchedule(
        activity.id!,
        'Upcoming: ${activity.title}',
        'Your activity starts in ${activity.notifyBefore} minutes$locationText',
        scheduledTime,
        notificationDetails,
        androidAllowWhileIdle: true, // ✅ REQUIRED argument
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: activity.isRecurring == 1
            ? DateTimeComponents.dayOfWeekAndTime
            : null,
        payload: 'activity_${activity.id}',
      );

      Logger.info('Scheduled notification for activity: ${activity.title}');
    } catch (e) {
      Logger.error('Error scheduling notification: $e');
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    try {
      await flutterLocalNotificationsPlugin.cancel(id);
      Logger.info('Cancelled notification: $id');
    } catch (e) {
      Logger.error('Error cancelling notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await flutterLocalNotificationsPlugin.cancelAll();
      Logger.info('Cancelled all notifications');
    } catch (e) {
      Logger.error('Error cancelling all notifications: $e');
    }
  }
}
