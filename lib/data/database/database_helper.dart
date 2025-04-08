import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:study_scheduler/data/models/activity.dart';
import 'package:study_scheduler/data/models/schedule.dart';
import 'package:study_scheduler/data/models/study_material.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static DatabaseHelper get instance => _instance;

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  DatabaseHelper._internal();

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'study_scheduler.db');
    return await openDatabase(
      path,
      version: 2, // Increased version number for migration
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create schedules table
    await db.execute('''
      CREATE TABLE schedules(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        color INTEGER,
        isActive INTEGER DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Create activities table
    await db.execute('''
      CREATE TABLE activities(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        scheduleId INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        location TEXT,
        dayOfWeek INTEGER NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        notifyBefore INTEGER DEFAULT 30,
        isRecurring INTEGER DEFAULT 1,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL,
        FOREIGN KEY (scheduleId) REFERENCES schedules (id) ON DELETE CASCADE
      )
    ''');

    // Create study materials table
    await db.execute('''
      CREATE TABLE study_materials(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        category TEXT NOT NULL,
        filePath TEXT,
        fileType TEXT,
        fileUrl TEXT,
        isOnline INTEGER DEFAULT 0,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      )
    ''');

    // Create indexes for faster queries
    await db.execute('CREATE INDEX idx_activities_scheduleId ON activities(scheduleId)');
    await db.execute('CREATE INDEX idx_activities_dayOfWeek ON activities(dayOfWeek)');
    await db.execute('CREATE INDEX idx_study_materials_category ON study_materials(category)');
  }

  // Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add study materials table for upgrading from version 1 to 2
      await db.execute('''
        CREATE TABLE study_materials(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT,
          category TEXT NOT NULL,
          filePath TEXT,
          fileType TEXT,
          fileUrl TEXT,
          isOnline INTEGER DEFAULT 0,
          createdAt TEXT NOT NULL,
          updatedAt TEXT NOT NULL
        )
      ''');
      await db.execute('CREATE INDEX idx_study_materials_category ON study_materials(category)');
    }
  }

  // Schedules operations
  Future<int> insertSchedule(Schedule schedule) async {
    final Database db = await database;
    return await db.insert('schedules', schedule.toMap());
  }

  Future<int> updateSchedule(Schedule schedule) async {
    final Database db = await database;
    return await db.update(
      'schedules',
      schedule.toMap(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  Future<int> deleteSchedule(int id) async {
    final Database db = await database;
    return await db.delete(
      'schedules',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Schedule>> getSchedules() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('schedules');
    return List.generate(maps.length, (i) => Schedule.fromMap(maps[i]));
  }

  Future<Schedule?> getSchedule(int id) async {
    final Database db = await database;
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

  // Activities operations
  Future<int> insertActivity(Activity activity) async {
    final Database db = await database;
    return await db.insert('activities', activity.toMap());
  }

  Future<int> updateActivity(Activity activity) async {
    final Database db = await database;
    return await db.update(
      'activities',
      activity.toMap(),
      where: 'id = ?',
      whereArgs: [activity.id],
    );
  }

  Future<int> deleteActivity(int id) async {
    final Database db = await database;
    return await db.delete(
      'activities',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Activity>> getActivities() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('activities');
    return List.generate(maps.length, (i) => Activity.fromMap(maps[i]));
  }

  Future<List<Activity>> getActivitiesByScheduleId(int scheduleId) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'activities',
      where: 'scheduleId = ?',
      whereArgs: [scheduleId],
    );
    return List.generate(maps.length, (i) => Activity.fromMap(maps[i]));
  }

  Future<List<Activity>> getActivitiesByDay(int dayOfWeek) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'activities',
      where: 'dayOfWeek = ?',
      whereArgs: [dayOfWeek],
    );
    return List.generate(maps.length, (i) => Activity.fromMap(maps[i]));
  }

  Future<Activity?> getActivity(int id) async {
    final Database db = await database;
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
  
  // Get upcoming activities for today and next days
  Future<List<Activity>> getUpcomingActivities(int dayOfWeek) async {
    final Database db = await database;
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

  // Study Materials operations
  Future<int> insertStudyMaterial(StudyMaterial material) async {
    final Database db = await database;
    return await db.insert('study_materials', material.toMap());
  }

  Future<int> updateStudyMaterial(StudyMaterial material) async {
    final Database db = await database;
    return await db.update(
      'study_materials',
      material.toMap(),
      where: 'id = ?',
      whereArgs: [material.id],
    );
  }

  Future<int> deleteStudyMaterial(int id) async {
    final Database db = await database;
    return await db.delete(
      'study_materials',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<StudyMaterial>> getStudyMaterials() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('study_materials');
    return List.generate(maps.length, (i) => StudyMaterial.fromMap(maps[i]));
  }

  Future<StudyMaterial?> getStudyMaterial(int id) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'study_materials',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return StudyMaterial.fromMap(maps.first);
    }
    return null;
  }
  
  Future<List<StudyMaterial>> getStudyMaterialsByCategory(String category) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'study_materials',
      where: 'category = ?',
      whereArgs: [category],
    );
    return List.generate(maps.length, (i) => StudyMaterial.fromMap(maps[i]));
  }
  
  Future<List<StudyMaterial>> searchStudyMaterials(String query) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'study_materials',
      where: 'title LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return List.generate(maps.length, (i) => StudyMaterial.fromMap(maps[i]));
  }
}