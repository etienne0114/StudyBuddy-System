// lib/data/models/activity.dart

import 'package:flutter/material.dart';

class Activity {
  final int? id;
  final int scheduleId;
  final String title;
  final String? description;
  final String? location;
  final int dayOfWeek;
  final String startTime;
  final String endTime;
  final int notifyBefore;
  final int isRecurring;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Non-database properties for UI
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
    required this.notifyBefore,
    required this.isRecurring,
    required this.createdAt,
    required this.updatedAt,
    this.scheduleTitle,
    this.scheduleColor,
  });

  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'] as int?,
      scheduleId: map['schedule_id'] as int,
      title: map['title'] as String,
      description: map['description'] as String?,
      location: map['location'] as String?,
      dayOfWeek: map['day_of_week'] as int,
      startTime: map['start_time'] as String,
      endTime: map['end_time'] as String,
      notifyBefore: map['notify_before'] as int,
      isRecurring: map['is_recurring'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      scheduleTitle: map['scheduleTitle'] as String?,
      scheduleColor: map['scheduleColor'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schedule_id': scheduleId,
      'title': title,
      'description': description,
      'location': location,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'notify_before': notifyBefore,
      'is_recurring': isRecurring,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

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
    DateTime? createdAt,
    DateTime? updatedAt,
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
      scheduleTitle: scheduleTitle,
      scheduleColor: scheduleColor,
    );
  }

  // Helper getters
  bool get isRecurringFlag => isRecurring == 1;
  
  String get formattedStartTime {
    final parts = startTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
  
  String get formattedEndTime {
    final parts = endTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }
  
  String get formattedDuration {
    final startParts = startTime.split(':');
    final endParts = endTime.split(':');
    
    final startHour = int.parse(startParts[0]);
    final startMinute = int.parse(startParts[1]);
    final endHour = int.parse(endParts[0]);
    final endMinute = int.parse(endParts[1]);
    
    final startTotalMinutes = startHour * 60 + startMinute;
    final endTotalMinutes = endHour * 60 + endMinute;
    
    var durationMinutes = endTotalMinutes - startTotalMinutes;
    if (durationMinutes < 0) {
      durationMinutes += 24 * 60; // Add a day if end time is on next day
    }
    
    final hours = durationMinutes ~/ 60;
    final minutes = durationMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes > 0 ? '${minutes}m' : ''}';
    } else {
      return '${minutes}m';
    }
  }
  
  Color? get scheduleColorValue {
    return scheduleColor != null ? Color(scheduleColor!) : null;
  }
}