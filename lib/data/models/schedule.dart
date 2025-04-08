// lib/data/models/schedule.dart

class Schedule {
  int? id;
  final String title;
  final String? description;
  final int? color;
  final int isActive; // 1 = active, 0 = inactive
  final String createdAt;
  final String updatedAt;

  Schedule({
    this.id,
    required this.title,
    this.description,
    this.color,
    this.isActive = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  // Create a Schedule from a map (database row)
  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      color: map['color'] as int?,
      isActive: map['isActive'] as int? ?? 1,
      createdAt: map['createdAt'] as String,
      updatedAt: map['updatedAt'] as String,
    );
  }

  get scheduleColor => null;

  // Convert Schedule to a map (for database insertion/update)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'color': color,
      'isActive': isActive,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Copy with method for creating a new Schedule with updated fields
  Schedule copyWith({
    int? id,
    String? title,
    String? description,
    int? color,
    int? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return Schedule(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Schedule{id: $id, title: $title, isActive: $isActive}';
  }
}