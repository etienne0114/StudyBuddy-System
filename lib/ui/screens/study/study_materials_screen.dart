import 'package:flutter/material.dart';
import 'package:study_scheduler/constants/app_colors.dart';
import 'package:study_scheduler/constants/app_styles.dart';
import 'package:study_scheduler/data/models/study_material.dart';
import 'package:study_scheduler/data/repositories/study_materials_repository.dart';
import 'package:study_scheduler/ui/screens/study/add_material_screen.dart';
import 'package:study_scheduler/ui/screens/study/ai_assistant_screen.dart';
import 'package:study_scheduler/utils/logger.dart';

class StudyMaterialsScreen extends StatefulWidget {
  const StudyMaterialsScreen({super.key});

  @override
  State<StudyMaterialsScreen> createState() => _StudyMaterialsScreenState();
}

class _StudyMaterialsScreenState extends State<StudyMaterialsScreen> {
  final _repository = StudyMaterialsRepository();
  List<StudyMaterial> _materials = [];
  StudyMaterial? _selectedMaterial;
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMaterials();
  }

  Future<void> _loadMaterials() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final materials = await _repository.getMaterials();
      setState(() {
        _materials = materials;
        _isLoading = false;
      });
    } catch (e) {
      Logger.error('Error loading materials: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading materials')),
        );
      }
    }
  }

  void _navigateToAddMaterial() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddMaterialScreen(),
      ),
    ).then((added) {
      if (added == true) {
        _loadMaterials();
      }
    });
  }

  void _navigateToEditMaterial(StudyMaterial material) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddMaterialScreen(),
      ),
    ).then((added) {
      if (added == true) {
        _loadMaterials();
      }
    });
  }

  void _showAIAssistant() {
    if (_selectedMaterial == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a material first'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIAssistantScreen(
          material: _selectedMaterial!,
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Search Materials'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Enter search terms...',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                });
                Navigator.pop(context);
              },
              child: const Text('Clear'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  List<StudyMaterial> get _filteredMaterials {
    if (_searchQuery.isEmpty) return _materials;
    return _materials.where((material) {
      return material.title.toLowerCase().contains(_searchQuery) ||
          (material.description?.toLowerCase().contains(_searchQuery) ?? false) ||
          material.category.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Materials'),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: _showAIAssistant,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _materials.isEmpty
              ? _buildEmptyState()
              : _buildMaterialsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddMaterial,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildMaterialsList() {
    final materials = _filteredMaterials;
    
    if (materials.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No materials found for "$_searchQuery"',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                });
              },
              child: const Text('Clear Search'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: materials.length,
      itemBuilder: (context, index) {
        final material = materials[index];
        final isSelected = _selectedMaterial?.id == material.id;
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          color: isSelected ? AppColors.primary.withOpacity(0.1) : null,
          child: ListTile(
            title: Text(material.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (material.description != null) ...[
                  Text(material.description!),
                  const SizedBox(height: 4),
                ],
                Row(
                  children: [
                    Chip(
                      label: Text(material.category),
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                    ),
                    if (material.filePath != null) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.file_present, size: 16),
                    ],
                    if (material.url != null) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.link, size: 16),
                    ],
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.auto_awesome),
                  onPressed: () {
                    setState(() {
                      _selectedMaterial = material;
                    });
                    _showAIAssistant();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _navigateToEditMaterial(material),
                ),
              ],
            ),
            onTap: () {
              setState(() {
                _selectedMaterial = material;
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return AppStyles.buildEmptyState(
      icon: Icons.book,
      message: 'No study materials yet',
      subMessage: 'Add your first study material to get started',
      actionButton: ElevatedButton.icon(
        onPressed: _navigateToAddMaterial,
        icon: const Icon(Icons.add),
        label: const Text('Add Material'),
        style: AppStyles.primaryButtonStyle,
      ),
    );
  }
} 