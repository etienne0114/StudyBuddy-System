// lib/data/database/database_helper.dart

import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:study_scheduler/data/models/activity.dart';
import 'package:study_scheduler/data/models/schedule.dart';
import 'package:study_scheduler/data/models/study_material.dart';
import 'package:flutter/foundation.dart'; // Add this import for kDebugMode
import 'package:study_scheduler/utils/logger.dart';
import 'package:study_scheduler/constants/app_constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static DatabaseHelper get instance => _instance;

  static Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Add method to recreate database
  Future<void> recreateDatabase() async {
    String path = join(await getDatabasesPath(), 'study_scheduler.db');
    await deleteDatabase(path);
    _database = null;
    await database;
  }

  DatabaseHelper._internal();

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'study_scheduler.db');
    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createTables(db);
  }

  // Handle database upgrades with proper error handling
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    try {
      if (oldVersion < 2) {
        // Add study materials table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS study_materials (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            description TEXT,
            category TEXT NOT NULL,
            file_path TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');

        // Add AI usage tracking table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS ai_usage_tracking (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            service_name TEXT NOT NULL,
            query TEXT NOT NULL,
            response TEXT NOT NULL,
            tokens_used INTEGER NOT NULL,
            duration_ms INTEGER NOT NULL,
            success INTEGER NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        // Add AI service preferences table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS ai_service_preferences (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            service_name TEXT NOT NULL UNIQUE,
            is_enabled INTEGER NOT NULL,
            api_key TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      }

      if (oldVersion < 3) {
        // Add indexes for better performance
        await db.execute('CREATE INDEX IF NOT EXISTS idx_activities_schedule ON activities(schedule_id)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_activities_day ON activities(day_of_week)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_ai_usage_service ON ai_usage_tracking(service_name)');
      }
    } catch (e) {
      Logger.error('Error upgrading database: $e');
      rethrow;
    }
  }

  // Create all tables if they don't exist
  Future<void> _createTables(Database db) async {
    // Create schedules table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS schedules (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        color INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create activities table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS activities (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        schedule_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        day_of_week INTEGER NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT NOT NULL,
        notify_before INTEGER NOT NULL,
        is_recurring INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (schedule_id) REFERENCES schedules (id) ON DELETE CASCADE
      )
    ''');

    // Create study materials table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS study_materials (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        category TEXT NOT NULL,
        file_path TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create AI usage tracking table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ai_usage_tracking (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        service_name TEXT NOT NULL,
        query TEXT NOT NULL,
        response TEXT NOT NULL,
        tokens_used INTEGER NOT NULL,
        duration_ms INTEGER NOT NULL,
        success INTEGER NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Create AI service preferences table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ai_service_preferences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        service_name TEXT NOT NULL UNIQUE,
        is_enabled INTEGER NOT NULL,
        api_key TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // Create indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_activities_schedule ON activities(schedule_id)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_activities_day ON activities(day_of_week)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ai_usage_service ON ai_usage_tracking(service_name)');
  }

  Future<void> ensureAITablesExist() async {
    try {
      final db = await database;
      await _createTables(db);
    } catch (e) {
      Logger.error('Failed to ensure AI tables exist: $e');
      rethrow;
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
      where: 'schedule_id = ?',
      whereArgs: [scheduleId],
    );
    return List.generate(maps.length, (i) => Activity.fromMap(maps[i]));
  }

  Future<List<Activity>> getActivitiesByDay(int dayOfWeek) async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'activities',
      where: 'day_of_week = ?',
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
    final List<Map<String, dynamic>> maps = await db.query(
      'activities',
      where: 'day_of_week = ?',
      whereArgs: [dayOfWeek],
    );
    
    return List.generate(maps.length, (i) {
      Activity activity = Activity.fromMap(maps[i]);
      return activity;
    });
  }

  // Study Materials operations
  Future<int> insertStudyMaterial(StudyMaterial material) async {
    final db = await database;
    return await db.insert('study_materials', material.toMap());
  }

  Future<List<StudyMaterial>> getStudyMaterials() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('study_materials');
    return List.generate(maps.length, (i) => StudyMaterial.fromMap(maps[i]));
  }

  Future<StudyMaterial?> getStudyMaterial(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'study_materials',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return StudyMaterial.fromMap(maps.first);
  }

  Future<int> updateStudyMaterial(StudyMaterial material) async {
    final db = await database;
    return await db.update(
      'study_materials',
      material.toMap(),
      where: 'id = ?',
      whereArgs: [material.id],
    );
  }

  Future<int> deleteStudyMaterial(int id) async {
    final db = await database;
    return await db.delete(
      'study_materials',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<StudyMaterial>> getStudyMaterialsByCategory(String category) async {
    final db = await database;
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