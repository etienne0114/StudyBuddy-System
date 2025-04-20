// lib/data/models/study_material.dart

class StudyMaterial {
  final int? id;
  final String title;
  final String? description;
  final String category;
  final String? filePath;
  final String? url;
  final String? fileType;
  final bool isOnline;
  final String createdAt;
  final String updatedAt;

  const StudyMaterial({
    this.id,
    required this.title,
    this.description,
    required this.category,
    this.filePath,
    this.url,
    this.fileType,
    this.isOnline = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'filePath': filePath,
      'url': url,
      'fileType': fileType,
      'isOnline': isOnline ? 1 : 0,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory StudyMaterial.fromMap(Map<String, dynamic> map) {
    return StudyMaterial(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      category: map['category'] as String,
      filePath: map['filePath'] as String?,
      url: map['url'] as String?,
      fileType: map['fileType'] as String?,
      isOnline: map['isOnline'] == 1,
      createdAt: map['createdAt'] as String,
      updatedAt: map['updatedAt'] as String,
    );
  }

  StudyMaterial copyWith({
    int? id,
    String? title,
    String? description,
    String? category,
    String? filePath,
    String? url,
    String? fileType,
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
      url: url ?? this.url,
      fileType: fileType ?? this.fileType,
      isOnline: isOnline ?? this.isOnline,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'StudyMaterial(id: $id, title: $title, category: $category)';
  }
}