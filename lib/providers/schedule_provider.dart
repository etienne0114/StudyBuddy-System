import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:study_scheduler/data/models/activity.dart';
import 'package:study_scheduler/data/models/schedule.dart';
import 'package:study_scheduler/data/repositories/schedule_repository.dart';

/// Provider class for schedule and activity state management
class ScheduleProvider extends ChangeNotifier {
  final ScheduleRepository _repository = ScheduleRepository();
  
  List<Schedule> _schedules = [];
  List<Activity> _activities = [];
  List<Activity> _todayActivities = [];
  List<Activity> _upcomingActivities = [];
  Schedule? _selectedSchedule;
  bool _isLoading = false;
  String? _error;
  int _currentDayOfWeek = DateTime.now().weekday;
  
  // Getters
  List<Schedule> get schedules => _schedules;
  List<Activity> get activities => _activities;
  List<Activity> get todayActivities => _todayActivities;
  List<Activity> get upcomingActivities => _upcomingActivities;
  Schedule? get selectedSchedule => _selectedSchedule;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentDayOfWeek => _currentDayOfWeek;
  
  /// Load all schedules
  Future<void> loadSchedules() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final schedules = await _repository.getAllSchedules();
      _schedules = schedules;
      
      if (_selectedSchedule != null) {
        // Update the selected schedule with the latest data
        _selectedSchedule = schedules.firstWhere(
          (s) => s.id == _selectedSchedule!.id,
          orElse: () => _selectedSchedule!,
        );
      }
    } catch (e) {
      _error = 'Failed to load schedules: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Load activities for today
  Future<void> loadTodayActivities() async {
    try {
      final activities = await _repository.getTodayActivities(_currentDayOfWeek);
      _todayActivities = activities;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load today\'s activities: $e';
      notifyListeners();
    }
  }
  
  /// Load upcoming activities
  Future<void> loadUpcomingActivities() async {
    try {
      final activities = await _repository.getUpcomingActivities();
      _upcomingActivities = activities;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load upcoming activities: $e';
      notifyListeners();
    }
  }
  
  /// Load activities for a specific schedule
  Future<void> loadActivitiesForSchedule(int scheduleId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final activities = await _repository.getActivitiesByScheduleId(scheduleId);
      _activities = activities;
    } catch (e) {
      _error = 'Failed to load activities: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Select a schedule
  void selectSchedule(Schedule schedule) {
    _selectedSchedule = schedule;
    loadActivitiesForSchedule(schedule.id!);
    notifyListeners();
  }
  
  /// Clear selected schedule
  void clearSelectedSchedule() {
    _selectedSchedule = null;
    _activities = [];
    notifyListeners();
  }
  
  /// Create a new schedule
  Future<bool> createSchedule(Schedule schedule) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final id = await _repository.createSchedule(schedule);
      
      // Get the created schedule with the ID
      final newSchedule = schedule.copyWith(id: id);
      
      _schedules.add(newSchedule);
      _selectedSchedule = newSchedule;
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to create schedule: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Update an existing schedule
  Future<bool> updateSchedule(Schedule schedule) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      await _repository.updateSchedule(schedule);
      
      // Update in the list
      final index = _schedules.indexWhere((s) => s.id == schedule.id);
      if (index != -1) {
        _schedules[index] = schedule;
      }
      
      // Update selected schedule if it's the same
      if (_selectedSchedule != null && _selectedSchedule!.id == schedule.id) {
        _selectedSchedule = schedule;
      }
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update schedule: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Delete a schedule
  Future<bool> deleteSchedule(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final success = await _repository.deleteSchedule(id);
      
      if (success) {
        // Remove from the list
        _schedules.removeWhere((s) => s.id == id);
        
        // Clear selected schedule if it's the same
        if (_selectedSchedule != null && _selectedSchedule!.id == id) {
          _selectedSchedule = null;
          _activities = [];
        }
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = 'Failed to delete schedule: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Create a new activity
  Future<bool> createActivity(Activity activity) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final id = await _repository.createActivity(activity);
      
      // Get the created activity with the ID
      final newActivity = activity.copyWith(id: id);
      
      // Add to the appropriate lists
      if (activity.dayOfWeek == _currentDayOfWeek) {
        _todayActivities.add(newActivity);
      }
      
      if (_selectedSchedule != null && activity.scheduleId == _selectedSchedule!.id) {
        _activities.add(newActivity);
      }
      
      // Reload upcoming activities
      await loadUpcomingActivities();
      
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to create activity: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Update an existing activity
  Future<bool> updateActivity(Activity activity) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final success = await _repository.updateActivity(activity);
      
      if (success) {
        // Update in the appropriate lists
        
        // Update in today activities
        final todayIndex = _todayActivities.indexWhere((a) => a.id == activity.id);
        if (todayIndex != -1) {
          if (activity.dayOfWeek == _currentDayOfWeek) {
            _todayActivities[todayIndex] = activity;
          } else {
            // Day changed, remove from today's list
            _todayActivities.removeAt(todayIndex);
          }
        } else if (activity.dayOfWeek == _currentDayOfWeek) {
          // Not in today's list but should be
          _todayActivities.add(activity);
        }
        
        // Update in activities list
        final index = _activities.indexWhere((a) => a.id == activity.id);
        if (index != -1) {
          if (activity.scheduleId == _selectedSchedule?.id) {
            _activities[index] = activity;
          } else {
            // Schedule changed, remove from this list
            _activities.removeAt(index);
          }
        } else if (activity.scheduleId == _selectedSchedule?.id) {
          // Not in list but should be
          _activities.add(activity);
        }
        
        // Reload upcoming activities
        await loadUpcomingActivities();
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = 'Failed to update activity: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Delete an activity
  Future<bool> deleteActivity(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      final success = await _repository.deleteActivity(id);
      
      if (success) {
        // Remove from all lists
        _todayActivities.removeWhere((a) => a.id == id);
        _activities.removeWhere((a) => a.id == id);
        _upcomingActivities.removeWhere((a) => a.id == id);
      }
      
      _isLoading = false;
      notifyListeners();
      return success;
    } catch (e) {
      _error = 'Failed to delete activity: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
  
  /// Refresh all data
  Future<void> refreshAll() async {
    await loadSchedules();
    await loadTodayActivities();
    await loadUpcomingActivities();
    
    if (_selectedSchedule != null) {
      await loadActivitiesForSchedule(_selectedSchedule!.id!);
    }
  }
  
  /// Set current day of week
  void setCurrentDayOfWeek(int dayOfWeek) {
    _currentDayOfWeek = dayOfWeek;
    loadTodayActivities();
    notifyListeners();
  }
  
  /// Reschedule all notifications
  Future<void> rescheduleAllNotifications() async {
    try {
      await _repository.rescheduleAllNotifications();
    } catch (e) {
      _error = 'Failed to reschedule notifications: $e';
      notifyListeners();
    }
  }
  
  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }
}