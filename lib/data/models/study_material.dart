// lib/data/models/study_material.dart

class StudyMaterial {
  final int id;
  final String title;
  final String? description;
  final String category;
  final String? filePath;
  final String? fileType;
  final String? fileUrl;
  final bool isOnline;
  final String createdAt;
  final String updatedAt;

  StudyMaterial({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    this.filePath,
    this.fileType,
    this.fileUrl,
    required this.isOnline,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory method to create a StudyMaterial from a map (database record)
  factory StudyMaterial.fromMap(Map<String, dynamic> map) {
    return StudyMaterial(
      id: map['id'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      category: map['category'] as String,
      filePath: map['filePath'] as String?,
      fileType: map['fileType'] as String?,
      fileUrl: map['fileUrl'] as String?,
      isOnline: map['isOnline'] == 1,
      createdAt: map['createdAt'] as String,
      updatedAt: map['updatedAt'] as String,
    );
  }

  // Convert StudyMaterial to a map for database operations
  Map<String, dynamic> toMap() {
    return {
      'id': id == 0 ? null : id, // Let SQLite assign ID if 0
      'title': title,
      'description': description,
      'category': category,
      'filePath': filePath,
      'fileType': fileType,
      'fileUrl': fileUrl,
      'isOnline': isOnline ? 1 : 0,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Create a copy of this material with updated properties
  StudyMaterial copyWith({
    int? id,
    String? title,
    String? description,
    String? category,
    String? filePath,
    String? fileType,
    String? fileUrl,
    bool? isOnline,
    String? createdAt,
    String? updatedAt,
  }) {
    return StudyMaterial(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      filePath: filePath ?? this.filePath,
      fileType: fileType ?? this.fileType,
      fileUrl: fileUrl ?? this.fileUrl,
      isOnline: isOnline ?? this.isOnline,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}