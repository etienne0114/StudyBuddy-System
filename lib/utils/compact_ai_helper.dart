// lib/utils/compact_ai_helper.dart

import 'package:flutter/material.dart';
import 'package:study_scheduler/data/models/study_material.dart';
import 'package:study_scheduler/ui/screens/materials/compact_ai_assistant_dialog.dart';

/// Singleton helper class to manage AI Assistant functionality throughout the app
class CompactAIHelper {
  // Singleton instance
  static final CompactAIHelper _instance = CompactAIHelper._internal();
  factory CompactAIHelper() => _instance;
  CompactAIHelper._internal();
  
  // The most recent question asked
  String? _lastQuestion;
  String? get lastQuestion => _lastQuestion;
  
  // The most recent material used with AI
  StudyMaterial? _lastMaterial;
  StudyMaterial? get lastMaterial => _lastMaterial;
  
  // Track if the AI Assistant is currently showing
  bool _isShowing = false;
  bool get isShowing => _isShowing;
  
  /// Show the AI Assistant dialog
  void showAssistant(BuildContext context, {
    StudyMaterial? material,
    String? initialQuestion,
  }) {
    // Don't show multiple instances
    if (_isShowing) return;
    
    _isShowing = true;
    _lastMaterial = material;
    _lastQuestion = initialQuestion;
    
    showDialog(
      context: context,
      builder: (context) => CompactAIAssistantDialog(
        material: material,
      ),
    ).then((_) {
      _isShowing = false;
    });
  }
  
  /// Show the AI Assistant with a quick question about scheduling
  void showSchedulingAssistant(BuildContext context) {
    showAssistant(
      context,
      initialQuestion: 'Help me plan my schedule for studying',
    );
  }
  
  /// Show the AI Assistant with a quick question about a specific subject
  void showSubjectAssistant(BuildContext context, String subject) {
    showAssistant(
      context,
      initialQuestion: 'Help me understand $subject',
    );
  }
  
  /// Create a floating button that can be added anywhere
  Widget createFloatingButton(BuildContext context, {
    StudyMaterial? material,
    double size = 56.0,
    Color? color,
    EdgeInsetsGeometry padding = EdgeInsets.zero,
  }) {
    return Padding(
      padding: padding,
      child: SizedBox(
        width: size,
        height: size,
        child: FloatingActionButton(
          heroTag: 'compact_ai_fab_${DateTime.now().millisecondsSinceEpoch}',
          backgroundColor: color ?? Colors.blue,
          mini: size < 50,
          child: const Icon(Icons.psychology),
          onPressed: () => showAssistant(context, material: material),
        ),
      ),
    );
  }
  
  /// Create an app bar action for AI assistance
  IconButton createAppBarAction(BuildContext context, {StudyMaterial? material}) {
    return IconButton(
      icon: const Icon(Icons.psychology),
      tooltip: 'AI Assistant',
      onPressed: () => showAssistant(context, material: material),
    );
  }
  
  /// Create a standard button for AI assistance
  Widget createButton(BuildContext context, {
    StudyMaterial? material,
    String? label,
    Color? color,
  }) {
    if (label != null) {
      return ElevatedButton.icon(
        icon: const Icon(Icons.psychology),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? Colors.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        onPressed: () => showAssistant(context, material: material),
      );
    } else {
      return IconButton(
        icon: Icon(Icons.psychology, color: color ?? Colors.blue),
        tooltip: 'AI Assistant',
        onPressed: () => showAssistant(context, material: material),
      );
    }
  }
}