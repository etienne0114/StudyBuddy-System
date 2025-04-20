// lib/ui/screens/materials/add_material_screen.dart

import 'package:flutter/material.dart';
import 'package:study_scheduler/data/models/study_material.dart';
import 'package:study_scheduler/data/repositories/study_materials_repository.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class AddMaterialScreen extends StatefulWidget {
  final StudyMaterial? material;

  const AddMaterialScreen({
    super.key,
    this.material,
  });

  @override
  State<AddMaterialScreen> createState() => _AddMaterialScreenState();
}

class _AddMaterialScreenState extends State<AddMaterialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _fileUrlController = TextEditingController();
  
  final StudyMaterialsRepository _repository = StudyMaterialsRepository();
  
  String _selectedCategory = 'Document';
  File? _selectedFile;
  String? _filePath;
  String? _fileType;
  bool _isOnline = false;
  bool _isLoading = false;
  
  final List<String> _categories = [
    'Document',
    'Video',
    'Article',
    'Quiz',
    'Practice',
    'Reference',
  ];

  @override
  void initState() {
    super.initState();
    
    if (widget.material != null) {
      // Populate form with existing data
      _titleController.text = widget.material!.title;
      if (widget.material!.description != null) {
        _descriptionController.text = widget.material!.description!;
      }
      _selectedCategory = widget.material!.category;
      _isOnline = widget.material!.isOnline;
      
      if (widget.material!.url != null) {
        _fileUrlController.text = widget.material!.url!;
      }
      
      _filePath = widget.material!.filePath;
      _fileType = widget.material!.fileType;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _fileUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;
        final fileExtension = fileName.split('.').last.toLowerCase();

        setState(() {
          _selectedFile = file;
          _filePath = file.path;
          _fileType = fileExtension;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File selected: $fileName')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  Future<void> _captureImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final fileName = result.files.single.name;

        setState(() {
          _selectedFile = file;
          _filePath = file.path;
          _fileType = 'jpg';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Image selected: $fileName')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing image: $e')),
      );
    }
  }

  String? _validateUrl(String? value) {
    if (_isOnline && (value == null || value.isEmpty)) {
      return 'Please enter a URL';
    }
    if (_isOnline && value != null && value.isNotEmpty) {
      try {
        final uri = Uri.parse(value);
        if (!uri.isAbsolute) {
          return 'Please enter a valid URL';
        }
        if (!uri.hasScheme || (uri.scheme != 'http' && uri.scheme != 'https')) {
          return 'URL must start with http:// or https://';
        }
      } catch (e) {
        return 'Please enter a valid URL';
      }
    }
    return null;
  }

  Future<void> _saveMaterial() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Validate file selection for local files
        if (!_isOnline && (_selectedFile == null || _filePath == null)) {
          throw Exception('Please select a file');
        }

        // Validate URL for online materials
        if (_isOnline && (_fileUrlController.text.isEmpty)) {
          throw Exception('Please enter a valid URL');
        }

        final material = StudyMaterial(
          id: widget.material?.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _selectedCategory,
          filePath: _isOnline ? null : _filePath,
          url: _isOnline ? _fileUrlController.text.trim() : null,
          fileType: _fileType,
          isOnline: _isOnline,
          createdAt: widget.material?.createdAt ?? DateTime.now().toIso8601String(),
          updatedAt: DateTime.now().toIso8601String(),
        );

        int result;
        if (widget.material == null) {
          result = await _repository.addMaterial(material);
          if (result == -1) {
            throw Exception('Failed to add material');
          }
        } else {
          result = await _repository.updateMaterial(material);
          if (result == -1) {
            throw Exception('Failed to update material');
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.material == null
                    ? 'Material added successfully'
                    : 'Material updated successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.material == null ? 'Add Study Material' : 'Edit Study Material'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem<String>(
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
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Material Source',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Local File'),
                            value: false,
                            groupValue: _isOnline,
                            onChanged: (value) {
                              setState(() {
                                _isOnline = value!;
                              });
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            title: const Text('Online URL'),
                            value: true,
                            groupValue: _isOnline,
                            onChanged: (value) {
                              setState(() {
                                _isOnline = value!;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isOnline) ...[
                      TextFormField(
                        controller: _fileUrlController,
                        decoration: const InputDecoration(
                          labelText: 'Resource URL',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.link),
                          hintText: 'https://example.com/resource',
                        ),
                        validator: _validateUrl,
                      ),
                    ] else ...[
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: _selectedFile != null || _filePath != null
                                ? Colors.green
                                : Colors.grey.withOpacity(0.5),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_selectedFile != null || _filePath != null) ...[
                                Row(
                                  children: [
                                    Icon(
                                      _getFileIcon(_fileType ?? ''),
                                      size: 40,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _getFileName() ?? 'Selected File',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          if (_fileType != null)
                                            Text(
                                              'File type: ${_fileType!.toUpperCase()}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
                                          _selectedFile = null;
                                          _filePath = null;
                                          _fileType = null;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ] else ...[
                                const Text(
                                  'Select a file or capture an image',
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _pickFile,
                                      icon: const Icon(Icons.upload_file),
                                      label: const Text('Pick File'),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: _captureImage,
                                      icon: const Icon(Icons.camera_alt),
                                      label: const Text('Capture Image'),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveMaterial,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          widget.material == null ? 'Add Material' : 'Update Material',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String? _getFileName() {
    if (_selectedFile != null) {
      return _selectedFile!.path.split('/').last;
    } else if (_filePath != null) {
      return _filePath!.split('/').last;
    }
    return null;
  }

  IconData _getFileIcon(String fileType) {
    final type = fileType.toLowerCase();
    if (type.contains('pdf')) return Icons.picture_as_pdf;
    if (type.contains('doc')) return Icons.description;
    if (type.contains('xls')) return Icons.table_chart;
    if (type.contains('ppt')) return Icons.slideshow;
    if (type.contains('jpg') || type.contains('png') || type.contains('image')) {
      return Icons.image;
    }
    if (type.contains('mp4') || type.contains('avi') || type.contains('video')) {
      return Icons.video_file;
    }
    
    return Icons.insert_drive_file;
  }
}