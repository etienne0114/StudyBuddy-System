// lib/data/database/database_helper_extension.dart

import 'package:sqflite/sqflite.dart';
import 'package:study_scheduler/data/models/study_material.dart';
import 'package:study_scheduler/data/database/database_helper.dart';

extension DatabaseHelperExtension on DatabaseHelper {
  // AI Usage Tracking - additional methods
  
  // Update database schema for AI integration (call during app initialization)
  Future<void> ensureAITablesExist() async {
    final Database db = await database;
    
    // Check if ai_usage_tracking table exists
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='ai_usage_tracking';"
    );
    
    if (tables.isEmpty) {
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
      await db.execute('CREATE INDEX idx_ai_usage_materialId ON ai_usage_tracking(materialId)');
      
      // Set database version to 3
      await db.execute('PRAGMA user_version = 3');
    }
  }

  // Track AI usage with a material
  Future<int> trackAIUsage(int? materialId, String aiService, String? queryText) async {
    await ensureAITablesExist();
    final Database db = await database;
    final now = DateTime.now().toIso8601String();
    
    return await db.insert('ai_usage_tracking', {
      'materialId': materialId,
      'aiService': aiService,
      'queryText': queryText,
      'usageDate': now,
    });
  }
  
  // Get most used AI services
  Future<List<Map<String, dynamic>>> getMostUsedAIServices() async {
    await ensureAITablesExist();
    final Database db = await database;
    
    try {
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT aiService, COUNT(*) as count
        FROM ai_usage_tracking
        GROUP BY aiService
        ORDER BY count DESC
        LIMIT 5
      ''');
      
      return maps;
    } catch (e) {
      // Return empty list if there's an error
      return [];
    }
  }
  
  // Get most accessed materials
  Future<List<StudyMaterial>> getMostAccessedMaterials() async {
    await ensureAITablesExist();
    final Database db = await database;
    
    try {
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT m.*, COUNT(t.id) as accessCount
        FROM study_materials m
        LEFT JOIN ai_usage_tracking t ON m.id = t.materialId
        WHERE t.materialId IS NOT NULL
        GROUP BY m.id
        ORDER BY accessCount DESC
        LIMIT 10
      ''');
      
      if (maps.isEmpty) {
        // If no AI usage yet, return recent materials
        return getRecentMaterials();
      }
      
      return List.generate(maps.length, (i) => StudyMaterial.fromMap(maps[i]));
    } catch (e) {
      // Return recent materials if there's an error
      return getRecentMaterials();
    }
  }
  
  // Get recent materials as a fallback
  Future<List<StudyMaterial>> getRecentMaterials() async {
    final Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'study_materials',
      orderBy: 'updatedAt DESC',
      limit: 5
    );
    return List.generate(maps.length, (i) => StudyMaterial.fromMap(maps[i]));
  }
  
  // Get AI service suggestions based on material category
  Future<List<String>> getRecommendedAIServicesForCategory(String category) async {
    await ensureAITablesExist();
    final Database db = await database;
    
    try {
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
      // Return default recommendations if there's an error
      return _getDefaultAIServicesForCategory(category);
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
    final Database db = await database;
    
    try {
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
      return 0;
    }
  }
  
  // Get user's most used AI service
  Future<String?> getMostUsedAIService() async {
    await ensureAITablesExist();
    final Database db = await database;
    
    try {
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
      return null;
    }
  }
  
  // Get materials similar to a given material
  Future<List<StudyMaterial>> getSimilarMaterials(int materialId) async {
    final Database db = await database;
    
    // First get the category of the current material
    final material = await getStudyMaterial(materialId);
    if (material == null) return [];
    
    // Get materials in the same category, excluding the current one
    final List<Map<String, dynamic>> maps = await db.query(
      'study_materials',
      where: 'id != ? AND category = ?',
      whereArgs: [materialId, material.category],
      limit: 5
    );
    
    return List.generate(maps.length, (i) => StudyMaterial.fromMap(maps[i]));
  }
}