import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:study_scheduler/constants/app_colors.dart';
import 'package:study_scheduler/constants/app_styles.dart';
import 'package:study_scheduler/data/models/study_material.dart';
import 'package:study_scheduler/data/repositories/study_materials_repository.dart';
import 'package:study_scheduler/utils/logger.dart';
import 'package:url_launcher/url_launcher.dart';

class AddMaterialScreen extends StatefulWidget {
  const AddMaterialScreen({Key? key}) : super(key: key);

  @override
  State<AddMaterialScreen> createState() => _AddMaterialScreenState();
}

class _AddMaterialScreenState extends State<AddMaterialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _urlController = TextEditingController();
  final _repository = StudyMaterialsRepository();
  
  String _selectedCategory = 'Document';
  String? _selectedFilePath;
  bool _isLoading = false;
  
  final List<String> _categories = [
    'Document',
    'Video',
    'Article',
    'Quiz',
    'Practice',
    'Reference',
    'Other'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'mp4', 'mp3'],
      );

      if (result != null) {
        setState(() {
          _selectedFilePath = result.files.single.path;
        });
      }
    } catch (e) {
      Logger.error('Error picking file: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error selecting file')),
        );
      }
    }
  }

  Future<void> _validateUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        setState(() {
          _selectedFilePath = null; // Clear local file selection
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid URL')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid URL format')),
        );
      }
    }
  }

  Future<void> _saveMaterial() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFilePath == null && _urlController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a file or URL')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final material = StudyMaterial(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        filePath: _selectedFilePath,
        url: _urlController.text.trim(),
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );

      await _repository.addMaterial(material);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      Logger.error('Error saving material: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving material')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Study Material'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveMaterial,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCategory = value;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Add Resource',
              style: AppStyles.heading3,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Local File',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _selectedFilePath ?? 'No file selected',
                            style: TextStyle(
                              color: _selectedFilePath != null
                                  ? Colors.black
                                  : Colors.grey,
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.file_upload),
                          label: const Text('Choose File'),
                          style: AppStyles.primaryButtonStyle,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Online Resource',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        labelText: 'URL',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.link),
                          onPressed: _validateUrl,
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          setState(() {
                            _selectedFilePath = null; // Clear local file selection
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 