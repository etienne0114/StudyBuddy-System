// lib/data/models/activity.dart

import 'package:flutter/material.dart';

class Activity {
  final int? id;
  final int scheduleId;
  final String title;
  final String? description;
  final String? location;
  final int dayOfWeek; // 1 = Monday, 7 = Sunday
  final String startTime; // Format: "HH:MM"
  final String endTime; // Format: "HH:MM"
  final int notifyBefore; // minutes before
  final int isRecurring; // 1 = true, 0 = false
  final String createdAt;
  final String updatedAt;
  
  // Optional fields for display purposes
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

  // Create a copy of this Activity with some fields replaced
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
    bool? isRecurringFlag,
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
      isRecurring: isRecurring ?? (isRecurringFlag != null ? (isRecurringFlag ? 1 : 0) : this.isRecurring),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      scheduleTitle: scheduleTitle ?? this.scheduleTitle,
      scheduleColor: scheduleColor ?? this.scheduleColor,
    );
  }

  // Check if activity is recurring
  bool get isRecurringFlag => isRecurring == 1;

  // Get the schedule color as a Color
  Color? get scheduleColorValue => scheduleColor != null ? Color(scheduleColor!) : null;

  // Convert an Activity into a Map
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

  // Create an Activity from a Map
  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'],
      scheduleId: map['scheduleId'],
      title: map['title'],
      description: map['description'],
      location: map['location'],
      dayOfWeek: map['dayOfWeek'],
      startTime: map['startTime'],
      endTime: map['endTime'],
      notifyBefore: map['notifyBefore'] ?? 30,
      isRecurring: map['isRecurring'] ?? 1,
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
      scheduleTitle: map['scheduleTitle'],
      scheduleColor: map['scheduleColor'],
    );
  }

  // Get the day name from the day of week (1-7)
  String get dayName {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final index = dayOfWeek - 1; // Convert 1-7 to 0-6 index
    if (index >= 0 && index < days.length) {
      return days[index];
    }
    return 'Unknown';
  }

  // Format time (e.g., "10:00" to "10:00 AM")
  String formatTime(String time) {
    try {
      final parts = time.split(':');
      if (parts.length != 2) return time; // Invalid format
      
      final hour = int.parse(parts[0]);
      final minute = parts[1];
      final period = hour < 12 ? 'AM' : 'PM';
      final hourIn12 = hour % 12 == 0 ? 12 : hour % 12;
      return '$hourIn12:$minute $period';
    } catch (e) {
      return time; // Return original if parsing fails
    }
  }

  // Formatted start time
  String get formattedStartTime => formatTime(startTime);

  // Formatted end time
  String get formattedEndTime => formatTime(endTime);

  // Duration in minutes
  int get durationMinutes {
    try {
      final startParts = startTime.split(':');
      final endParts = endTime.split(':');
      
      final startHour = int.parse(startParts[0]);
      final startMinute = int.parse(startParts[1]);
      final endHour = int.parse(endParts[0]);
      final endMinute = int.parse(endParts[1]);
      
      int totalMinutes = (endHour * 60 + endMinute) - (startHour * 60 + startMinute);
      
      // Handle crossing midnight
      if (totalMinutes < 0) {
        totalMinutes += 24 * 60; // Add a full day
      }
      
      return totalMinutes;
    } catch (e) {
      return 0; // Return 0 if parsing fails
    }
  }

  // Formatted duration (e.g., "1h 30m")
  String get formattedDuration {
    final minutes = durationMinutes;
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    
    if (hours > 0 && remainingMinutes > 0) {
      return '${hours}h ${remainingMinutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${remainingMinutes}m';
    }
  }

  @override
  String toString() {
    return 'Activity{id: $id, title: $title, day: $dayName, time: $startTime-$endTime}';
  }
}