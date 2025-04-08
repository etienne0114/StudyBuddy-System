import 'dart:io';
import 'package:study_scheduler/api/api_client.dart';
import 'package:study_scheduler/data/models/study_material.dart';

class StudyMaterialsApi {
  final ApiClient _apiClient = ApiClient();
  
  // Get all study materials
  Future<List<StudyMaterial>> getAllMaterials({
    int page = 1,
    int limit = 20,
    String? searchQuery,
    String? type,
    List<String>? tags,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (searchQuery != null && searchQuery.isNotEmpty) 'q': searchQuery,
        if (type != null && type.isNotEmpty) 'type': type,
        if (tags != null && tags.isNotEmpty) 'tags': tags.join(','),
      };
      
      final response = await _apiClient.get('/study-materials', queryParameters: queryParams);
      
      if (response['data'] == null || response['data'] is! List) {
        return [];
      }
      
      return (response['data'] as List)
          .map((item) => StudyMaterial.fromJson(item))
          .toList();
    } catch (e) {
      print('Error fetching study materials: $e');
      rethrow;
    }
  }
  
  // Get study material details by ID
  Future<StudyMaterial> getMaterialById(int id) async {
    try {
      final response = await _apiClient.get('/study-materials/$id');
      return StudyMaterial.fromJson(response['data']);
    } catch (e) {
      print('Error fetching study material details: $e');
      rethrow;
    }
  }
  
  // Get study materials by category
  Future<List<StudyMaterial>> getMaterialsByCategory(String category, {
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        'category': category,
      };
      
      final response = await _apiClient.get(
        '/study-materials/category/$category',
        queryParameters: queryParams,
      );
      
      if (response['data'] == null || response['data'] is! List) {
        return [];
      }
      
      return (response['data'] as List)
          .map((item) => StudyMaterial.fromJson(item))
          .toList();
    } catch (e) {
      print('Error fetching study materials by category: $e');
      rethrow;
    }
  }
  
  // Search study materials
  Future<List<StudyMaterial>> searchMaterials(String query, {
    int page = 1,
    int limit = 20,
    List<String>? filters,
  }) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        'q': query,
        if (filters != null && filters.isNotEmpty) 'filters': filters.join(','),
      };
      
      final response = await _apiClient.get(
        '/study-materials/search',
        queryParameters: queryParams,
      );
      
      if (response['data'] == null || response['data'] is! List) {
        return [];
      }
      
      return (response['data'] as List)
          .map((item) => StudyMaterial.fromJson(item))
          .toList();
    } catch (e) {
      print('Error searching study materials: $e');
      rethrow;
    }
  }
  
  // Get recommended materials based on user's schedule and history
  Future<List<StudyMaterial>> getRecommendedMaterials({int limit = 10}) async {
    try {
      final response = await _apiClient.get(
        '/study-materials/recommended',
        queryParameters: {'limit': limit.toString()},
      );
      
      if (response['data'] == null || response['data'] is! List) {
        return [];
      }
      
      return (response['data'] as List)
          .map((item) => StudyMaterial.fromJson(item))
          .toList();
    } catch (e) {
      print('Error fetching recommended materials: $e');
      rethrow;
    }
  }
  
  // Upload a new study material (for teachers or admins)
  Future<StudyMaterial> uploadMaterial({
    required String title,
    required String description,
    required String type,
    required List<String> tags,
    File? file,
    File? thumbnail,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // First create the material metadata
      final materialData = {
        'title': title,
        'description': description,
        'type': type,
        'tags': tags,
        if (metadata != null) 'metadata': metadata,
      };
      
      final response = await _apiClient.post(
        '/study-materials',
        data: materialData,
      );
      
      final createdMaterial = StudyMaterial.fromJson(response['data']);
      
      // If there's a file to upload, attach it to the created material
      if (file != null) {
        await _apiClient.uploadFile(
          '/study-materials/${createdMaterial.id}/file',
          file,
          fieldName: 'materialFile',
        );
      }
      
      // If there's a thumbnail to upload, attach it
      if (thumbnail != null) {
        await _apiClient.uploadFile(
          '/study-materials/${createdMaterial.id}/thumbnail',
          thumbnail,
          fieldName: 'thumbnail',
        );
      }
      
      // Get the updated material with file URLs
      return await getMaterialById(createdMaterial.id);
    } catch (e) {
      print('Error uploading study material: $e');
      rethrow;
    }
  }
  
  // Track material usage
  Future<void> trackMaterialUsage(int materialId, String action) async {
    try {
      await _apiClient.post(
        '/study-materials/$materialId/track',
        data: {'action': action},
      );
    } catch (e) {
      print('Error tracking material usage: $e');
      // Don't rethrow - this is a non-critical operation
    }
  }
}