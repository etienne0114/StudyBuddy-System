// lib/ui/screens/materials/material_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:study_scheduler/constants/app_colors.dart';
import 'package:study_scheduler/constants/app_styles.dart';
import 'package:study_scheduler/data/models/study_material.dart';

class MaterialDetailScreen extends StatelessWidget {
  final StudyMaterial material;

  const MaterialDetailScreen({
    Key? key,
    required this.material,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Material Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Edit material functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              _showDeleteConfirmationDialog(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderSection(context),
            const SizedBox(height: 24),
            _buildDescriptionSection(context),
            const SizedBox(height: 24),
            _buildFileSection(context),
            const SizedBox(height: 24),
            _buildMetadataSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getCategoryIcon(),
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        material.title,
                        style: AppStyles.heading2,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          material.category,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection(BuildContext context) {
    if (material.description == null || material.description!.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Description',
              style: AppStyles.heading3,
            ),
            const SizedBox(height: 8),
            Text(
              material.description!,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileSection(BuildContext context) {
    if ((material.filePath == null || material.filePath!.isEmpty) &&
        (material.fileUrl == null || material.fileUrl!.isEmpty)) {
      return const SizedBox.shrink();
    }
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attached File',
              style: AppStyles.heading3,
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(
                _getFileTypeIcon(),
                color: AppColors.primary,
                size: 36,
              ),
              title: Text(
                _getFileName(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                material.isOnline ? 'Online Resource' : 'Local File',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              trailing: IconButton(
                icon: Icon(
                  material.isOnline ? Icons.open_in_new : Icons.download,
                  color: AppColors.primary,
                ),
                onPressed: () {
                  // Open or download file
                },
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataSection(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Details',
              style: AppStyles.heading3,
            ),
            const SizedBox(height: 12),
            _buildMetadataItem(
              context,
              'Created',
              _formatDate(material.createdAt),
              Icons.calendar_today,
            ),
            const Divider(),
            _buildMetadataItem(
              context,
              'Last Updated',
              _formatDate(material.updatedAt),
              Icons.update,
            ),
            if (material.fileType != null) ...[
              const Divider(),
              _buildMetadataItem(
                context,
                'File Type',
                material.fileType!,
                Icons.description,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon() {
    switch (material.category.toLowerCase()) {
      case 'document':
        return Icons.description;
      case 'video':
        return Icons.video_library;
      case 'article':
        return Icons.article;
      case 'quiz':
        return Icons.quiz;
      case 'practice':
        return Icons.school;
      case 'reference':
        return Icons.book;
      default:
        return Icons.folder;
    }
  }

  IconData _getFileTypeIcon() {
    if (material.fileType == null) return Icons.insert_drive_file;
    
    final type = material.fileType!.toLowerCase();
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

  String _getFileName() {
    if (material.filePath != null && material.filePath!.isNotEmpty) {
      return material.filePath!.split('/').last;
    }
    if (material.fileUrl != null && material.fileUrl!.isNotEmpty) {
      return material.fileUrl!.split('/').last;
    }
    return 'File';
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${_padZero(date.hour)}:${_padZero(date.minute)}';
    } catch (e) {
      return dateString;
    }
  }
  
  String _padZero(int number) {
    return number.toString().padLeft(2, '0');
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Material'),
        content: Text('Are you sure you want to delete "${material.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // Delete material and return to previous screen
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to materials list
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}