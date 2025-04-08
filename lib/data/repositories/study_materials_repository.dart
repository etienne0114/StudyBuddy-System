// lib/data/repositories/study_materials_repository.dart

import 'package:study_scheduler/data/models/study_material.dart';
import 'package:study_scheduler/data/database/database_helper.dart';

class StudyMaterialsRepository {
  final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  
  // Get all study materials
  Future<List<StudyMaterial>> getMaterials() async {
    try {
      return await _databaseHelper.getStudyMaterials();
    } catch (e) {
      print('Error getting materials: $e');
      // Return empty list on error
      return [];
    }
  }
  
  // Get a specific study material by ID
  Future<StudyMaterial?> getMaterialById(int id) async {
    try {
      return await _databaseHelper.getStudyMaterial(id);
    } catch (e) {
      print('Error getting material by ID: $e');
      return null;
    }
  }
  
  // Add a new study material
  Future<int> addMaterial(StudyMaterial material) async {
    try {
      return await _databaseHelper.insertStudyMaterial(material);
    } catch (e) {
      print('Error adding material: $e');
      return -1;
    }
  }
  
  // Update an existing study material
  Future<int> updateMaterial(StudyMaterial material) async {
    try {
      return await _databaseHelper.updateStudyMaterial(material);
    } catch (e) {
      print('Error updating material: $e');
      return 0;
    }
  }
  
  // Delete a study material
  Future<int> deleteMaterial(int id) async {
    try {
      return await _databaseHelper.deleteStudyMaterial(id);
    } catch (e) {
      print('Error deleting material: $e');
      return 0;
    }
  }
  
  // Get study materials by category
  Future<List<StudyMaterial>> getMaterialsByCategory(String category) async {
    try {
      return await _databaseHelper.getStudyMaterialsByCategory(category);
    } catch (e) {
      print('Error getting materials by category: $e');
      return [];
    }
  }
  
  // Search for study materials
  Future<List<StudyMaterial>> searchMaterials(String query) async {
    try {
      return await _databaseHelper.searchStudyMaterials(query);
    } catch (e) {
      print('Error searching materials: $e');
      return [];
    }
  }
  
  // Track material usage - can be implemented in the future
  Future<void> trackMaterialUsage(int materialId) async {
    // Implementation will be added when needed
  }
  
  // Get recommended materials based on usage patterns - can be implemented in the future
  Future<List<StudyMaterial>> getRecommendedMaterials() async {
    // For now, just return the most recent materials
    try {
      final materials = await getMaterials();
      // Sort by most recent update
      materials.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      // Return top 5 or fewer
      return materials.take(5).toList();
    } catch (e) {
      print('Error getting recommended materials: $e');
      return [];
    }
  }
}