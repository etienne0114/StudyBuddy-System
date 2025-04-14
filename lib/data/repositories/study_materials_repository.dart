// lib/data/repositories/study_materials_repository.dart

import 'package:study_scheduler/data/models/study_material.dart';
import 'package:study_scheduler/data/database/database_helper.dart';
import 'package:study_scheduler/data/database/database_helper_extension.dart';

class StudyMaterialsRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;

  // Get all study materials
  Future<List<StudyMaterial>> getMaterials() async {
    return await _databaseHelper.getStudyMaterials();
  }

  // Get study material by ID
  Future<StudyMaterial?> getMaterialById(int id) async {
    return await _databaseHelper.getStudyMaterial(id);
  }

  // Get study materials by category
  Future<List<StudyMaterial>> getMaterialsByCategory(String category) async {
    return await _databaseHelper.getStudyMaterialsByCategory(category);
  }

  // Search study materials
  Future<List<StudyMaterial>> searchMaterials(String query) async {
    return await _databaseHelper.searchStudyMaterials(query);
  }

  // Add new study material
  Future<int> addMaterial(StudyMaterial material) async {
    return await _databaseHelper.insertStudyMaterial(material);
  }

  // Update existing study material
  Future<int> updateMaterial(StudyMaterial material) async {
    return await _databaseHelper.updateStudyMaterial(material);
  }

  // Delete study material
  Future<int> deleteMaterial(int id) async {
    return await _databaseHelper.deleteStudyMaterial(id);
  }
  
  // Get recommended materials (most recent for now)
  Future<List<StudyMaterial>> getRecommendedMaterials() async {
    return await _databaseHelper.getRecentMaterials();
  }
  
  // Track AI usage with a material
  Future<int> trackAIUsage(int? materialId, String aiService, String? query) async {
    return await _databaseHelper.trackAIUsage(materialId, aiService, query);
  }
  
  // Get most used AI services
  Future<List<Map<String, dynamic>>> getMostUsedAIServices() async {
    return await _databaseHelper.getMostUsedAIServices();
  }
  
  // Get materials most frequently accessed with AI
  Future<List<StudyMaterial>> getMostAccessedMaterials() async {
    return await _databaseHelper.getMostAccessedMaterials();
  }
  
  // Get recommended AI services based on material category
  Future<List<String>> getRecommendedAIServicesForCategory(String category) async {
    return await _databaseHelper.getRecommendedAIServicesForCategory(category);
  }
  
  // Get material view count
  Future<int> getMaterialViewCount(int materialId) async {
    return await _databaseHelper.getMaterialViewCount(materialId);
  }
  
  // Get user's most used AI service
  Future<String?> getMostUsedAIService() async {
    return await _databaseHelper.getMostUsedAIService();
  }
  
  // Get materials similar to a given material
  Future<List<StudyMaterial>> getSimilarMaterials(int materialId) async {
    return await _databaseHelper.getSimilarMaterials(materialId);
  }
  
  // Ensure AI tables exist (call during app initialization)
  Future<void> ensureAITablesExist() async {
    await _databaseHelper.ensureAITablesExist();
  }
  
  // Get AI learning summary stats
  Future<Map<String, dynamic>> getAILearningSummary() async {
    final db = await _databaseHelper.database;
    
    try {
      // Total AI sessions
      final sessionCountResult = await db.rawQuery('SELECT COUNT(*) as count FROM ai_usage_tracking');
      final sessionCount = sessionCountResult.first['count'] as int? ?? 0;
      
      // Unique materials accessed with AI
      final uniqueMaterialsResult = await db.rawQuery(
        'SELECT COUNT(DISTINCT materialId) as count FROM ai_usage_tracking WHERE materialId IS NOT NULL'
      );
      final uniqueMaterialsCount = uniqueMaterialsResult.first['count'] as int? ?? 0;
      
      // Most active day
      final dayResult = await db.rawQuery('''
        SELECT substr(usageDate, 1, 10) as day, COUNT(*) as count 
        FROM ai_usage_tracking 
        GROUP BY day 
        ORDER BY count DESC 
        LIMIT 1
      ''');
      final mostActiveDay = dayResult.isNotEmpty ? dayResult.first['day'] as String : null;
      
      // Most studied category
      final categoryResult = await db.rawQuery('''
        SELECT m.category, COUNT(*) as count 
        FROM ai_usage_tracking t
        JOIN study_materials m ON t.materialId = m.id
        GROUP BY m.category
        ORDER BY count DESC
        LIMIT 1
      ''');
      final mostStudiedCategory = categoryResult.isNotEmpty ? categoryResult.first['category'] as String : null;
      
      return {
        'totalSessions': sessionCount,
        'uniqueMaterialsAccessed': uniqueMaterialsCount,
        'mostActiveDay': mostActiveDay,
        'mostStudiedCategory': mostStudiedCategory,
      };
    } catch (e) {
      return {
        'totalSessions': 0,
        'uniqueMaterialsAccessed': 0,
        'mostActiveDay': null,
        'mostStudiedCategory': null,
      };
    }
  }
  
  // Get user's learning streak (consecutive days using AI assistant)
  Future<int> getLearningStreak() async {
    final db = await _databaseHelper.database;
    
    try {
      // Get all days with AI usage, ordered by date
      final daysResult = await db.rawQuery('''
        SELECT DISTINCT substr(usageDate, 1, 10) as day
        FROM ai_usage_tracking
        ORDER BY day DESC
      ''');
      
      if (daysResult.isEmpty) return 0;
      
      final days = daysResult.map((res) => res['day'] as String).toList();
      final today = DateTime.now().toIso8601String().substring(0, 10);
      
      // Check if user studied today
      int streak = 0;
      if (days.contains(today) || days.first == DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10)) {
        streak = 1;
        
        // Calculate streak by checking consecutive days
        DateTime currentDate = days.first == today 
            ? DateTime.now() 
            : DateTime.parse(days.first);
        
        for (int i = 1; i < days.length; i++) {
          final expectedPreviousDay = currentDate.subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
          if (days[i] == expectedPreviousDay) {
            streak++;
            currentDate = currentDate.subtract(const Duration(days: 1));
          } else {
            break;
          }
        }
      }
      
      return streak;
    } catch (e) {
      return 0;
    }
  }
}