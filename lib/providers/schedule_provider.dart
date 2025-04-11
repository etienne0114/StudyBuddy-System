import 'package:flutter/foundation.dart';
import 'package:study_scheduler/data/database/database_helper.dart';
import 'package:study_scheduler/data/models/activity.dart';
import 'package:study_scheduler/data/models/schedule.dart';
import 'package:study_scheduler/data/repositories/schedule_repository.dart';
import 'package:study_scheduler/services/notification_service.dart';

/// Provider class for schedule and activity state management
class ScheduleProvider extends ChangeNotifier {
  final ScheduleRepository _repository;

  ScheduleProvider({
    required DatabaseHelper dbHelper,
    required NotificationService notificationService,
  }) : _repository = ScheduleRepository(
          dbHelper: dbHelper,
          notificationService: notificationService,
        );

  List<Schedule> _schedules = [];
  List<Activity> _activities = [];
  List<Activity> _todayActivities = [];
  List<Activity> _upcomingActivities = [];
  Schedule? _selectedSchedule;
  bool _isLoading = false;
  String? _error;
  int _currentDayOfWeek = DateTime.now().weekday;

  List<Schedule> get schedules => _schedules;
  List<Activity> get activities => _activities;
  List<Activity> get todayActivities => _todayActivities;
  List<Activity> get upcomingActivities => _upcomingActivities;
  Schedule? get selectedSchedule => _selectedSchedule;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentDayOfWeek => _currentDayOfWeek;

  Future<void> loadSchedules() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final schedules = await _repository.getAllSchedules();
      _schedules = schedules;

      if (_selectedSchedule != null) {
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

  void selectSchedule(Schedule schedule) {
    _selectedSchedule = schedule;
    loadActivitiesForSchedule(schedule.id!);
    notifyListeners();
  }

  void clearSelectedSchedule() {
    _selectedSchedule = null;
    _activities = [];
    notifyListeners();
  }

  Future<bool> createSchedule(Schedule schedule) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final id = await _repository.createSchedule(schedule);
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

  Future<bool> updateSchedule(Schedule schedule) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _repository.updateSchedule(schedule);

      final index = _schedules.indexWhere((s) => s.id == schedule.id);
      if (index != -1) {
        _schedules[index] = schedule;
      }

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

  Future<bool> deleteSchedule(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _repository.deleteSchedule(id);

      if (success) {
        _schedules.removeWhere((s) => s.id == id);

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

  Future<bool> createActivity(Activity activity) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final id = await _repository.createActivity(activity);
      final newActivity = activity.copyWith(id: id);

      if (activity.dayOfWeek == _currentDayOfWeek) {
        _todayActivities.add(newActivity);
      }

      if (_selectedSchedule != null && activity.scheduleId == _selectedSchedule!.id) {
        _activities.add(newActivity);
      }

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

  Future<bool> updateActivity(Activity activity) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _repository.updateActivity(activity);

      if (success) {
        final todayIndex = _todayActivities.indexWhere((a) => a.id == activity.id);
        if (todayIndex != -1) {
          if (activity.dayOfWeek == _currentDayOfWeek) {
            _todayActivities[todayIndex] = activity;
          } else {
            _todayActivities.removeAt(todayIndex);
          }
        } else if (activity.dayOfWeek == _currentDayOfWeek) {
          _todayActivities.add(activity);
        }

        final index = _activities.indexWhere((a) => a.id == activity.id);
        if (index != -1) {
          if (activity.scheduleId == _selectedSchedule?.id) {
            _activities[index] = activity;
          } else {
            _activities.removeAt(index);
          }
        } else if (activity.scheduleId == _selectedSchedule?.id) {
          _activities.add(activity);
        }

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

  Future<bool> deleteActivity(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _repository.deleteActivity(id);

      if (success) {
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

  Future<void> refreshAll() async {
    await loadSchedules();
    await loadTodayActivities();
    await loadUpcomingActivities();

    if (_selectedSchedule != null) {
      await loadActivitiesForSchedule(_selectedSchedule!.id!);
    }
  }

  void setCurrentDayOfWeek(int dayOfWeek) {
    _currentDayOfWeek = dayOfWeek;
    loadTodayActivities();
    notifyListeners();
  }

  Future<void> rescheduleAllNotifications() async {
    try {
      await _repository.rescheduleAllNotifications();
    } catch (e) {
      _error = 'Failed to reschedule notifications: $e';
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
