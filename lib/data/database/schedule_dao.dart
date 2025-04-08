import 'package:sqflite/sqflite.dart';
import 'package:study_scheduler/data/database/database_helper.dart';
import 'package:study_scheduler/data/models/schedule.dart';

/// Data Access Object for Schedule operations
class ScheduleDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  
  /// Insert a new schedule
  Future<int> insert(Schedule schedule) async {
    final Database db = await _dbHelper.database;
    return await db.insert('schedules', schedule.toMap());
  }
  
  /// Update an existing schedule
  Future<int> update(Schedule schedule) async {
    final Database db = await _dbHelper.database;
    return await db.update(
      'schedules',
      schedule.toMap(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }
  
  /// Delete a schedule by ID
  Future<int> delete(int id) async {
    final Database db = await _dbHelper.database;
    // Foreign key constraint will delete associated activities
    return await db.delete(
      'schedules',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  /// Get all schedules
  Future<List<Schedule>> getAll() async {
    final Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('schedules');
    return List.generate(maps.length, (i) => Schedule.fromMap(maps[i]));
  }
  
  /// Get active schedules
  Future<List<Schedule>> getActiveSchedules() async {
    final Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'schedules',
      where: 'isActive = ?',
      whereArgs: [1],
    );
    return List.generate(maps.length, (i) => Schedule.fromMap(maps[i]));
  }
  
  /// Get schedule by ID
  Future<Schedule?> getById(int id) async {
    final Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'schedules',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return Schedule.fromMap(maps.first);
    }
    return null;
  }
  
  /// Toggle schedule active status
  Future<int> toggleActiveStatus(int id, bool isActive) async {
    final Database db = await _dbHelper.database;
    return await db.update(
      'schedules',
      {'isActive': isActive ? 1 : 0, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  /// Get schedules with activity counts
  Future<List<Map<String, dynamic>>> getSchedulesWithActivityCounts() async {
    final Database db = await _dbHelper.database;
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT s.*, COUNT(a.id) as activityCount
      FROM schedules s
      LEFT JOIN activities a ON s.id = a.scheduleId
      GROUP BY s.id
      ORDER BY s.isActive DESC, s.title ASC
    ''');
    
    return results.map((map) {
      final schedule = Schedule.fromMap(map);
      return {
        'schedule': schedule,
        'activityCount': map['activityCount'] as int,
      };
    }).toList();
  }
  
  /// Check if a schedule with the same title already exists
  Future<bool> titleExists(String title, {int? excludeId}) async {
    final Database db = await _dbHelper.database;
    
    String whereClause = 'title = ?';
    List<dynamic> whereArgs = [title];
    
    if (excludeId != null) {
      whereClause += ' AND id != ?';
      whereArgs.add(excludeId);
    }
    
    final count = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(*) FROM schedules WHERE $whereClause',
        whereArgs,
      ),
    );
    
    return (count ?? 0) > 0;
  }
  
  /// Get schedule with its activities
  Future<Map<String, dynamic>?> getScheduleWithActivities(int id) async {
    final Database db = await _dbHelper.database;
    
    // Get the schedule
    final List<Map<String, dynamic>> scheduleMaps = await db.query(
      'schedules',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (scheduleMaps.isEmpty) {
      return null;
    }
    
    final schedule = Schedule.fromMap(scheduleMaps.first);
    
    // Get the activities for this schedule
    final List<Map<String, dynamic>> activityMaps = await db.query(
      'activities',
      where: 'scheduleId = ?',
      whereArgs: [id],
      orderBy: 'dayOfWeek ASC, startTime ASC',
    );
    
    final activities = activityMaps.map((map) => map).toList();
    
    return {
      'schedule': schedule,
      'activities': activities,
    };
  }
  
  /// Update schedule color
  Future<int> updateColor(int id, int color) async {
    final Database db = await _dbHelper.database;
    return await db.update(
      'schedules',
      {'color': color, 'updatedAt': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}