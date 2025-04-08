// lib/ui/screens/materials/materials_screen.dart

import 'package:flutter/material.dart';
import 'package:study_scheduler/data/models/study_material.dart';
import 'package:study_scheduler/data/repositories/study_materials_repository.dart';
import 'package:study_scheduler/ui/screens/materials/material_detail_screen.dart';

class MaterialsScreen extends StatefulWidget {
  const MaterialsScreen({Key? key}) : super(key: key);

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  final StudyMaterialsRepository _repository = StudyMaterialsRepository();
  List<StudyMaterial> _materials = [];
  bool _isLoading = true;

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
      setState(() {
        _isLoading = false;
      });
      // Handle error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load materials: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Materials'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMaterials,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _materials.isEmpty
              ? const Center(child: Text('No materials found'))
              : ListView.builder(
                  itemCount: _materials.length,
                  itemBuilder: (context, index) {
                    final material = _materials[index];
                    return ListTile(
                      title: Text(material.title),
                      subtitle: Text(material.description ?? ''),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MaterialDetailScreen(material: material),
                          ),
                        );
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show dialog to add a new material or navigate to add screen
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}