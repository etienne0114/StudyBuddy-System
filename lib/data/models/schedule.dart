// lib/data/models/schedule.dart

import 'package:flutter/material.dart';

class Schedule {
  final int? id;
  final String title;
  final String? description;
  final int color;
  final DateTime createdAt;
  final DateTime updatedAt;

  Schedule({
    this.id,
    required this.title,
    this.description,
    required this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  // Get the color as a Color object
  Color get scheduleColor => Color(color);
  
  // Check if schedule is active
  bool get isActiveFlag => true; // Assuming the schedule is always active

  // Create a copy of this Schedule with some fields replaced
  Schedule copyWith({
    int? id,
    String? title,
    String? description,
    int? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Schedule(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert a Schedule into a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'color': color,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Create a Schedule from a Map
  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      color: map['color'] as int,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  @override
  String toString() {
    return 'Schedule{id: $id, title: $title, color: $color, isActive: $isActiveFlag}';
  }
}