// lib/data/models/schedule.dart

import 'package:flutter/material.dart';

class Schedule {
  final int? id;
  final String title;
  final String? description;
  final int color;
  final int isActive; // 1 = active, 0 = inactive
  final String createdAt;
  final String updatedAt;

  Schedule({
    this.id,
    required this.title,
    this.description,
    required this.color,
    this.isActive = 1,
    required this.createdAt,
    required this.updatedAt,
  });

  // Get the color as a Color object
  Color get scheduleColor => Color(color);
  
  // Check if schedule is active
  bool get isActiveFlag => isActive == 1;

  // Create a copy of this Schedule with some fields replaced
  Schedule copyWith({
    int? id,
    String? title,
    String? description,
    int? color,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return Schedule(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      color: color ?? this.color,
      isActive: isActive != null ? (isActive ? 1 : 0) : this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Convert a Schedule into a Map
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

  // Create a Schedule from a Map
  factory Schedule.fromMap(Map<String, dynamic> map) {
    return Schedule(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      color: map['color'],
      isActive: map['isActive'] ?? 1,
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
    );
  }

  @override
  String toString() {
    return 'Schedule{id: $id, title: $title, color: $color, isActive: $isActive}';
  }
}