// lib/data/database/activity_dao.dart

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:study_scheduler/data/database/database_helper.dart';
import 'package:study_scheduler/data/models/activity.dart';
import 'package:study_scheduler/utils/date_utils.dart' as date_utils;

/// Data Access Object for Activity operations
class ActivityDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  /// Insert a new activity
  Future<int> insert(Activity activity) async {
    final Database db = await _dbHelper.database;
    return await db.insert('activities', activity.toMap());
  }
  
  /// Update an existing activity
  Future<int> update(Activity activity) async {
    final Database db = await _dbHelper.database;
    return await db.update(
      'activities',
      activity.toMap(),
      where: 'id = ?',
      whereArgs: [activity.id],
    );
  }
  
  /// Delete an activity by ID
  Future<int> delete(int id) async {
    final Database db = await _dbHelper.database;
    return await db.delete(
      'activities',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  /// Get all activities
  Future<List<Activity>> getAll() async {
    final Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('activities');
    return List.generate(maps.length, (i) => Activity.fromMap(maps[i]));
  }
  
  /// Get activity by ID
  Future<Activity?> getById(int id) async {
    final Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'activities',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return Activity.fromMap(maps.first);
    }
    return null;
  }
  
  /// Get activities by schedule ID
  Future<List<Activity>> getByScheduleId(int scheduleId) async {
    final Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'activities',
      where: 'scheduleId = ?',
      whereArgs: [scheduleId],
    );
    return List.generate(maps.length, (i) => Activity.fromMap(maps[i]));
  }
  
  /// Get activities by day of week
  Future<List<Activity>> getByDayOfWeek(int dayOfWeek) async {
    final Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'activities',
      where: 'dayOfWeek = ?',
      whereArgs: [dayOfWeek],
    );
    return List.generate(maps.length, (i) => Activity.fromMap(maps[i]));
  }
  
  /// Get activities for a specific day with schedule info
  Future<List<Activity>> getActivitiesForDay(int dayOfWeek) async {
    final Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT a.*, s.title as scheduleTitle, s.color as scheduleColor
      FROM activities a
      JOIN schedules s ON a.scheduleId = s.id
      WHERE a.dayOfWeek = ? AND s.isActive = 1
      ORDER BY a.startTime ASC
    ''', [dayOfWeek]);
    
    return List.generate(maps.length, (i) {
      Activity activity = Activity.fromMap(maps[i]);
      activity.scheduleTitle = maps[i]['scheduleTitle'] as String;
      activity.scheduleColor = maps[i]['scheduleColor'] as int;
      return activity;
    });
  }
  
  /// Get upcoming activities for today
  Future<List<Activity>> getUpcomingActivities() async {
    final now = DateTime.now();
    final currentDayOfWeek = now.weekday - 1; // Convert to 0-based (0 = Monday)
    final currentTimeString = date_utils.timeOfDayToString(TimeOfDay.now());
    
    final Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT a.*, s.title as scheduleTitle, s.color as scheduleColor
      FROM activities a
      JOIN schedules s ON a.scheduleId = s.id
      WHERE a.dayOfWeek = ? AND s.isActive = 1
      ORDER BY a.startTime ASC
    ''', [currentDayOfWeek]);
    
    final activities = List.generate(maps.length, (i) {
      Activity activity = Activity.fromMap(maps[i]);
      activity.scheduleTitle = maps[i]['scheduleTitle'] as String;
      activity.scheduleColor = maps[i]['scheduleColor'] as int;
      return activity;
    });
    
    // Filter for upcoming activities (start time >= current time)
    return activities.where((activity) {
      return activity.startTime.compareTo(currentTimeString) >= 0;
    }).toList();
  }
  
  /// Get active (ongoing) activities for right now
  Future<List<Activity>> getActiveActivities() async {
    final now = DateTime.now();
    final currentDayOfWeek = now.weekday - 1; // Convert to 0-based (0 = Monday)
    final currentTimeString = date_utils.timeOfDayToString(TimeOfDay.now());
    
    final Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT a.*, s.title as scheduleTitle, s.color as scheduleColor
      FROM activities a
      JOIN schedules s ON a.scheduleId = s.id
      WHERE a.dayOfWeek = ? AND s.isActive = 1
      ORDER BY a.startTime ASC
    ''', [currentDayOfWeek]);
    
    final activities = List.generate(maps.length, (i) {
      Activity activity = Activity.fromMap(maps[i]);
      activity.scheduleTitle = maps[i]['scheduleTitle'] as String;
      activity.scheduleColor = maps[i]['scheduleColor'] as int;
      return activity;
    });
    
    // Filter for active activities (current time is between start and end)
    return activities.where((activity) {
      return activity.startTime.compareTo(currentTimeString) <= 0 && 
             activity.endTime.compareTo(currentTimeString) >= 0;
    }).toList();
  }
  
  /// Get past activities for today
  Future<List<Activity>> getPastActivitiesToday() async {
    final now = DateTime.now();
    final currentDayOfWeek = now.weekday - 1; // Convert to 0-based (0 = Monday)
    final currentTimeString = date_utils.timeOfDayToString(TimeOfDay.now());
    
    final Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT a.*, s.title as scheduleTitle, s.color as scheduleColor
      FROM activities a
      JOIN schedules s ON a.scheduleId = s.id
      WHERE a.dayOfWeek = ? AND s.isActive = 1
      ORDER BY a.startTime ASC
    ''', [currentDayOfWeek]);
    
    final activities = List.generate(maps.length, (i) {
      Activity activity = Activity.fromMap(maps[i]);
      activity.scheduleTitle = maps[i]['scheduleTitle'] as String;
      activity.scheduleColor = maps[i]['scheduleColor'] as int;
      return activity;
    });
    
    // Filter for past activities (end time < current time)
    return activities.where((activity) {
      return activity.endTime.compareTo(currentTimeString) < 0;
    }).toList();
  }
  
  /// Delete all activities for a specific schedule
  Future<int> deleteAllForSchedule(int scheduleId) async {
    final Database db = await _dbHelper.database;
    return await db.delete(
      'activities',
      where: 'scheduleId = ?',
      whereArgs: [scheduleId],
    );
  }
  
  /// Check if an activity exists at the same time on the same day
  Future<bool> hasConflict(Activity activity) async {
    final Database db = await _dbHelper.database;
    
    // Skip checking the activity itself when updating
    String whereClause = 'dayOfWeek = ? AND id != ? AND ((startTime <= ? AND endTime >= ?) OR (startTime >= ? AND startTime <= ?))';
    List<dynamic> whereArgs = [
      activity.dayOfWeek,
      activity.id ?? -1, // Use -1 for new activities
      activity.endTime,
      activity.startTime,
      activity.startTime,
      activity.endTime,
    ];
    
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM activities WHERE $whereClause',
        whereArgs,
      ),
    );
    
    return (count ?? 0) > 0;
  }
}