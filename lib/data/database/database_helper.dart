// lib/data/database/database_helper.dart

import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:study_scheduler/data/models/activity.dart';
import 'package:study_scheduler/data/models/schedule.dart';
import 'package:study_scheduler/data/models/study_material.dart';
import 'package:flutter/foundation.dart'; // Add this import for kDebugMode

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
      version: 3, // Increased version number for new features
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
    
    // Create AI usage tracking table
    await db.execute('''
      CREATE TABLE ai_usage_tracking(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        materialId INTEGER,
        aiService TEXT NOT NULL,
        queryText TEXT,
        usageDate TEXT NOT NULL,
        FOREIGN KEY (materialId) REFERENCES study_materials (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for faster queries
    await db.execute('CREATE INDEX idx_activities_scheduleId ON activities(scheduleId)');
    await db.execute('CREATE INDEX idx_activities_dayOfWeek ON activities(dayOfWeek)');
    await db.execute('CREATE INDEX idx_study_materials_category ON study_materials(category)');
    await db.execute('CREATE INDEX idx_ai_usage_materialId ON ai_usage_tracking(materialId)');
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
    
    if (oldVersion < 3) {
      // Add AI usage tracking table for upgrading from version 2 to 3
      await db.execute('''
        CREATE TABLE ai_usage_tracking(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          materialId INTEGER,
          aiService TEXT NOT NULL,
          queryText TEXT,
          usageDate TEXT NOT NULL,
          FOREIGN KEY (materialId) REFERENCES study_materials (id) ON DELETE CASCADE
        )
      ''');
      await db.execute('CREATE INDEX idx_ai_usage_materialId ON ai_usage_tracking(materialId)');
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
  
  // AI Usage Tracking operations
  Future<int> trackAIUsage(int? materialId, String aiService, String? queryText) async {
    final Database db = await database;
    final now = DateTime.now().toIso8601String();
    
    return await db.insert('ai_usage_tracking', {
      'materialId': materialId,
      'aiService': aiService,
      'queryText': queryText,
      'usageDate': now,
    });
  }
  
  Future<List<Map<String, dynamic>>> getMostUsedAIServices() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT aiService, COUNT(*) as count
      FROM ai_usage_tracking
      GROUP BY aiService
      ORDER BY count DESC
    ''');
    
    return maps;
  }
  
  Future<List<StudyMaterial>> getMostAccessedMaterials() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT m.*, COUNT(t.id) as accessCount
      FROM study_materials m
      LEFT JOIN ai_usage_tracking t ON m.id = t.materialId
      GROUP BY m.id
      ORDER BY accessCount DESC
      LIMIT 10
    ''');
    
    return List.generate(maps.length, (i) => StudyMaterial.fromMap(maps[i]));
  }
  
  
    Future<List<StudyMaterial>> getRecentMaterials() async {
    try {
      final Database db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'study_materials',
        orderBy: 'updatedAt DESC',
        limit: 1000,
      );
      return List.generate(maps.length, (i) => StudyMaterial.fromMap(maps[i]));
    } catch (e) {
      if (kDebugMode) {
        print('Error getting recent materials: $e');
      }
      return [];
    }
  }
  
  // Get AI service suggestions based on material category
  Future<List<String>> getRecommendedAIServicesForCategory(String category) async {
    try {
      final Database db = await database;
      
      final tablesExist = await _checkTableExists(db, 'ai_usage_tracking');
      if (!tablesExist) {
        return _getDefaultAIServicesForCategory(category);
      }
      
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT t.aiService, COUNT(*) as count
        FROM ai_usage_tracking t
        JOIN study_materials m ON t.materialId = m.id
        WHERE m.category = ?
        GROUP BY t.aiService
        ORDER BY count DESC
        LIMIT 3
      ''', [category]);
      
      if (maps.isEmpty) {
        // Default recommendations if no data
        return _getDefaultAIServicesForCategory(category);
      }
      
      return maps.map((map) => map['aiService'] as String).toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting recommended AI services for category: $e');
      }
      // Return default recommendations if there's an error
      return _getDefaultAIServicesForCategory(category);
    }
  }
  
  // Check if a table exists in the database
  Future<bool> _checkTableExists(Database db, String tableName) async {
    try {
      final result = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName';"
      );
      return result.isNotEmpty;
    } catch (e) {
      if (kDebugMode) {
        print('Error checking if table exists: $e');
      }
      return false;
    }
  }
  
  // Default AI service recommendations by category
  List<String> _getDefaultAIServicesForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'document':
        return ['Claude', 'Perplexity', 'ChatGPT'];
      case 'video':
        return ['ChatGPT', 'Claude', 'Perplexity'];
      case 'article':
        return ['Perplexity', 'Claude', 'DeepSeek'];
      case 'quiz':
        return ['ChatGPT', 'Claude', 'DeepSeek'];
      case 'practice':
        return ['GitHub Copilot', 'DeepSeek', 'ChatGPT'];
      case 'reference':
        return ['Perplexity', 'Claude', 'ChatGPT'];
      default:
        return ['Claude', 'ChatGPT', 'Perplexity'];
    }
  }
  
  // Get material view count
  Future<int> getMaterialViewCount(int materialId) async {
    try {
      final Database db = await database;
      
      final tablesExist = await _checkTableExists(db, 'ai_usage_tracking');
      if (!tablesExist) {
        return 0;
      }
      
      final List<Map<String, dynamic>> result = await db.rawQuery('''
        SELECT COUNT(*) as count
        FROM ai_usage_tracking
        WHERE materialId = ?
      ''', [materialId]);
      
      if (result.isNotEmpty) {
        return result.first['count'] as int;
      }
      return 0;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting material view count: $e');
      }
      return 0;
    }
  }
  
  // Get user's most used AI service
  Future<String?> getMostUsedAIService() async {
    try {
      final Database db = await database;
      
      final tablesExist = await _checkTableExists(db, 'ai_usage_tracking');
      if (!tablesExist) {
        return null;
      }
      
      final List<Map<String, dynamic>> result = await db.rawQuery('''
        SELECT aiService, COUNT(*) as count
        FROM ai_usage_tracking
        GROUP BY aiService
        ORDER BY count DESC
        LIMIT 1
      ''');
      
      if (result.isNotEmpty) {
        return result.first['aiService'] as String;
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting most used AI service: $e');
      }
      return null;
    }
  }

}