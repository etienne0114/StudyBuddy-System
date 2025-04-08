// lib/data/models/activity.dart

class Activity {
  final int? id;
  final int scheduleId;
  final String title;
  final String? description;
  final String? location;
  final int dayOfWeek; // 0-6 for Monday-Sunday
  final String startTime; // Format: "HH:MM"
  final String endTime; // Format: "HH:MM"
  final int notifyBefore; // Minutes before to notify
  final int isRecurring; // 1 = true, 0 = false
  final String createdAt;
  final String updatedAt;
  
  // Optional fields not stored in database (for UI purposes)
  String? scheduleTitle;
  int? scheduleColor;

  Activity({
    this.id,
    required this.scheduleId,
    required this.title,
    this.description,
    this.location,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.notifyBefore = 30,
    this.isRecurring = 1,
    required this.createdAt,
    required this.updatedAt,
    this.scheduleTitle,
    this.scheduleColor,
  });

  // Create an activity from a map (database row)
  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'] as int?,
      scheduleId: map['scheduleId'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      location: map['location'] as String?,
      dayOfWeek: map['dayOfWeek'] as int,
      startTime: map['startTime'] as String,
      endTime: map['endTime'] as String,
      notifyBefore: map['notifyBefore'] as int? ?? 30,
      isRecurring: map['isRecurring'] as int? ?? 1,
      createdAt: map['createdAt'] as String,
      updatedAt: map['updatedAt'] as String,
      scheduleTitle: map['scheduleTitle'] as String?,
      scheduleColor: map['scheduleColor'] as int?,
    );
  }

  // Convert activity to a map (for database insertion/update)
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'scheduleId': scheduleId,
      'title': title,
      'description': description,
      'location': location,
      'dayOfWeek': dayOfWeek,
      'startTime': startTime,
      'endTime': endTime,
      'notifyBefore': notifyBefore,
      'isRecurring': isRecurring,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Create a copy with some fields changed
  Activity copyWith({
    int? id,
    int? scheduleId,
    String? title,
    String? description,
    String? location,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    int? notifyBefore,
    int? isRecurring,
    String? createdAt,
    String? updatedAt,
    String? scheduleTitle,
    int? scheduleColor,
  }) {
    return Activity(
      id: id ?? this.id,
      scheduleId: scheduleId ?? this.scheduleId,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notifyBefore: notifyBefore ?? this.notifyBefore,
      isRecurring: isRecurring ?? this.isRecurring,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      scheduleTitle: scheduleTitle ?? this.scheduleTitle,
      scheduleColor: scheduleColor ?? this.scheduleColor,
    );
  }

  @override
  String toString() {
    return 'Activity(id: $id, title: $title, dayOfWeek: $dayOfWeek, timeRange: $startTime-$endTime)';
  }
}