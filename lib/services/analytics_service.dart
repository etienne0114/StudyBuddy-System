import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A service for tracking user activities and app usage analytics
/// This is a stub implementation that would be replaced with a real analytics service
/// like Firebase Analytics in a production app
class AnalyticsService {
  // Singleton pattern
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();
  
  bool _isEnabled = false;
  bool _isInitialized = false;
  final Map<String, dynamic> _pendingEvents = {};
  
  /// Initialize the analytics service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Check if analytics is enabled in environment
      final analyticsEnabled = dotenv.env['ENABLE_ANALYTICS'] == 'true';
      
      // Check user preference
      final prefs = await SharedPreferences.getInstance();
      final userEnabled = prefs.getBool('analytics_enabled') ?? true;
      
      _isEnabled = analyticsEnabled && userEnabled;
      _isInitialized = true;
      
      // Send any pending events
      if (_isEnabled && _pendingEvents.isNotEmpty) {
        _sendPendingEvents();
      }
      
      if (kDebugMode) {
        print('Analytics service initialized. Enabled: $_isEnabled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing analytics service: $e');
      }
    }
  }
  
  /// Set whether analytics is enabled
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    
    // Save user preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('analytics_enabled', enabled);
    
    if (kDebugMode) {
      print('Analytics ${enabled ? 'enabled' : 'disabled'}');
    }
  }
  
  /// Track a screen view
  void trackScreenView(String screenName) {
    if (!_isInitialized) {
      _pendingEvents['screen_view_$screenName'] = {'name': screenName};
      return;
    }
    
    if (!_isEnabled) return;
    
    // This would be replaced with actual analytics tracking
    if (kDebugMode) {
      print('ANALYTICS: Screen View - $screenName');
    }
  }
  
  /// Track a user action
  void trackEvent(String eventName, {Map<String, dynamic>? parameters}) {
    if (!_isInitialized) {
      _pendingEvents[eventName] = parameters ?? {};
      return;
    }
    
    if (!_isEnabled) return;
    
    // This would be replaced with actual analytics tracking
    if (kDebugMode) {
      print('ANALYTICS: Event - $eventName');
      if (parameters != null) {
        print('  Parameters: $parameters');
      }
    }
  }
  
  /// Track user login
  void trackLogin(String method) {
    trackEvent('login', parameters: {'method': method});
  }
  
  /// Track user registration
  void trackRegistration(String method) {
    trackEvent('registration', parameters: {'method': method});
  }
  
  /// Track schedule creation
  void trackScheduleCreated(int scheduleId, String title) {
    trackEvent('schedule_created', parameters: {
      'schedule_id': scheduleId,
      'title': title,
    });
  }
  
  /// Track activity creation
  void trackActivityCreated(int activityId, int scheduleId, String title) {
    trackEvent('activity_created', parameters: {
      'activity_id': activityId,
      'schedule_id': scheduleId,
      'title': title,
    });
  }
  
  /// Track study material view
  void trackMaterialView(int materialId, String title, String type) {
    trackEvent('material_viewed', parameters: {
      'material_id': materialId,
      'title': title,
      'type': type,
    });
  }
  
  /// Track study material download
  void trackMaterialDownload(int materialId, String title, String type) {
    trackEvent('material_downloaded', parameters: {
      'material_id': materialId,
      'title': title,
      'type': type,
    });
  }
  
  /// Track search
  void trackSearch(String query, String category, int resultCount) {
    trackEvent('search', parameters: {
      'query': query,
      'category': category,
      'result_count': resultCount,
    });
  }
  
  /// Track app error
  void trackError(String errorType, String errorMessage, {StackTrace? stackTrace}) {
    trackEvent('app_error', parameters: {
      'error_type': errorType,
      'error_message': errorMessage,
      'stack_trace': stackTrace?.toString() ?? 'Not available',
    });
  }
  
  /// Track user feedback
  void trackFeedback(int rating, String? comment) {
    trackEvent('user_feedback', parameters: {
      'rating': rating,
      'comment': comment ?? 'No comment',
    });
  }
  
  /// Track notification received
  void trackNotificationReceived(int activityId, String title) {
    trackEvent('notification_received', parameters: {
      'activity_id': activityId,
      'title': title,
    });
  }
  
  /// Track notification action
  void trackNotificationAction(int activityId, String title, String action) {
    trackEvent('notification_action', parameters: {
      'activity_id': activityId,
      'title': title,
      'action': action,
    });
  }
  
  /// Send any pending events
  void _sendPendingEvents() {
    if (!_isEnabled || _pendingEvents.isEmpty) return;
    
    // Send each pending event
    _pendingEvents.forEach((eventName, parameters) {
      if (eventName.startsWith('screen_view_')) {
        trackScreenView(parameters['name']);
      } else {
        trackEvent(eventName, parameters: parameters);
      }
    });
    
    // Clear pending events
    _pendingEvents.clear();
  }
}