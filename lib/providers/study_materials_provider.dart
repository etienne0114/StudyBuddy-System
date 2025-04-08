// lib/providers/study_materials_provider.dart

import 'package:flutter/foundation.dart';
import 'package:study_scheduler/data/models/study_material.dart';
import 'package:study_scheduler/data/repositories/study_materials_repository.dart';

class StudyMaterialsProvider with ChangeNotifier {
  final StudyMaterialsRepository _repository = StudyMaterialsRepository();
  
  List<StudyMaterial> _materials = [];
  List<StudyMaterial> _recommendedMaterials = [];
  String _selectedCategory = '';
  bool _isLoading = false;
  String _searchQuery = '';
  StudyMaterial? _selectedMaterial;
  
  // Getters
  List<StudyMaterial> get materials => _materials;
  List<StudyMaterial> get recommendedMaterials => _recommendedMaterials;
  String get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  StudyMaterial? get selectedMaterial => _selectedMaterial;
  List<String> get categories => [
    'Document',
    'Video',
    'Article',
    'Quiz',
    'Practice',
    'Reference',
  ];
  
  // Filtered materials based on search query
  List<StudyMaterial> get filteredMaterials {
    if (_searchQuery.isEmpty) {
      return _selectedCategory.isEmpty
          ? _materials
          : _materials.where((m) => m.category == _selectedCategory).toList();
    } else {
      final query = _searchQuery.toLowerCase();
      final filtered = _materials.where((m) =>
          m.title.toLowerCase().contains(query) ||
          (m.description?.toLowerCase().contains(query) ?? false));
          
      return _selectedCategory.isEmpty
          ? filtered.toList()
          : filtered.where((m) => m.category == _selectedCategory).toList();
    }
  }
  
  // Load all materials
  Future<void> loadMaterials() async {
    _setLoading(true);
    
    try {
      _materials = await _repository.getMaterials();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading materials: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Load recommended materials
  Future<void> loadRecommendedMaterials() async {
    _setLoading(true);
    
    try {
      _recommendedMaterials = await _repository.getRecommendedMaterials();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading recommended materials: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Load materials by category
  Future<void> loadMaterialsByCategory(String category) async {
    _selectedCategory = category;
    _setLoading(true);
    
    try {
      if (category.isEmpty) {
        await loadMaterials();
      } else {
        _materials = await _repository.getMaterialsByCategory(category);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading materials by category: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Search materials
  Future<void> searchMaterials(String query) async {
    _searchQuery = query;
    
    if (query.isEmpty) {
      await loadMaterials();
      return;
    }
    
    _setLoading(true);
    
    try {
      _materials = await _repository.searchMaterials(query);
      notifyListeners();
    } catch (e) {
      debugPrint('Error searching materials: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  // Add a new material
  Future<bool> addMaterial(StudyMaterial material) async {
    _setLoading(true);
    
    try {
      final id = await _repository.addMaterial(material);
      
      if (id > 0) {
        // Add the new material with its ID to the list
        final newMaterial = StudyMaterial(
          id: id,
          title: material.title,
          description: material.description,
          category: material.category,
          filePath: material.filePath,
          fileType: material.fileType,
          fileUrl: material.fileUrl,
          isOnline: material.isOnline,
          createdAt: material.createdAt,
          updatedAt: material.updatedAt,
        );
        
        _materials.add(newMaterial);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error adding material: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Update an existing material
  Future<bool> updateMaterial(StudyMaterial material) async {
    _setLoading(true);
    
    try {
      final result = await _repository.updateMaterial(material);
      
      if (result > 0) {
        // Update the material in the list
        final index = _materials.indexWhere((m) => m.id == material.id);
        if (index >= 0) {
          _materials[index] = material;
        }
        
        // Update selected material if it's the one being edited
        if (_selectedMaterial?.id == material.id) {
          _selectedMaterial = material;
        }
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error updating material: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Delete a material
  Future<bool> deleteMaterial(int id) async {
    _setLoading(true);
    
    try {
      final result = await _repository.deleteMaterial(id);
      
      if (result > 0) {
        // Remove the material from the list
        _materials.removeWhere((m) => m.id == id);
        
        // Clear selected material if it's the one being deleted
        if (_selectedMaterial?.id == id) {
          _selectedMaterial = null;
        }
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error deleting material: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }
  
  // Select a material
  void selectMaterial(StudyMaterial material) {
    _selectedMaterial = material;
    notifyListeners();
  }
  
  // Clear selected material
  void clearSelectedMaterial() {
    _selectedMaterial = null;
    notifyListeners();
  }
  
  // Clear selected category
  void clearSelectedCategory() {
    _selectedCategory = '';
    loadMaterials();
  }
  
  // Clear search query
  void clearSearchQuery() {
    _searchQuery = '';
    loadMaterials();
  }
  
  // Refresh all data
  Future<void> refreshAll() async {
    await loadMaterials();
    await loadRecommendedMaterials();
  }
  
  // Track usage of a material
  Future<void> trackUsage(int materialId) async {
    try {
      await _repository.trackMaterialUsage(materialId);
    } catch (e) {
      debugPrint('Error tracking material usage: $e');
    }
  }
  
  // Helper method to set loading state
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}