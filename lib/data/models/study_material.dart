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
  final List<String>? tags;
  final Map<String, dynamic>? metadata;

  StudyMaterial({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    this.filePath,
    this.fileType,
    this.fileUrl,
    this.isOnline = false,
    required this.createdAt,
    required this.updatedAt,
    this.tags,
    this.metadata,
  });

  // Create a StudyMaterial from a database map
  factory StudyMaterial.fromMap(Map<String, dynamic> map) {
    return StudyMaterial(
      id: map['id'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      category: map['category'] as String,
      filePath: map['filePath'] as String?,
      fileType: map['fileType'] as String?,
      fileUrl: map['fileUrl'] as String?,
      isOnline: (map['isOnline'] as int?) == 1,
      createdAt: map['createdAt'] as String,
      updatedAt: map['updatedAt'] as String,
      tags: null, // Tags not stored in local database
      metadata: null, // Metadata not stored in local database
    );
  }

  // Create a StudyMaterial from JSON (for API responses)
  factory StudyMaterial.fromJson(Map<String, dynamic> json) {
    return StudyMaterial(
      id: json['id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String,
      filePath: json['filePath'] as String?,
      fileType: json['fileType'] as String?,
      fileUrl: json['fileUrl'] as String?,
      isOnline: json['isOnline'] as bool? ?? false,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String,
      tags: json['tags'] != null 
          ? List<String>.from(json['tags'] as List)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  // Convert to a map for database storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
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

  // Convert to JSON for API requests
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'filePath': filePath,
      'fileType': fileType,
      'fileUrl': fileUrl,
      'isOnline': isOnline,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      if (tags != null) 'tags': tags,
      if (metadata != null) 'metadata': metadata,
    };
  }

  // Create a copy with some fields changed
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
    List<String>? tags,
    Map<String, dynamic>? metadata,
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
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'StudyMaterial(id: $id, title: $title, category: $category)';
  }
}