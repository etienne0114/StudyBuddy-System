// lib/helpers/ai_helper.dart
// This provides a simple way to access AI functionality across the app

import 'package:flutter/material.dart';
import 'package:study_scheduler/data/models/study_material.dart';
import 'package:study_scheduler/ui/dialogs/ai_assistant_dialog.dart';

class AIHelper {
  // Private constructor to prevent instantiation
  AIHelper._();
  
  // Show AI assistant dialog
  static void showAssistant(BuildContext context, {
    StudyMaterial? material,
    String? initialQuestion,
  }) {
    AIAssistantDialog.show(
      context,
      material: material,
      initialQuestion: initialQuestion,
    );
  }
  
  // Create a floating action button for AI
  static Widget createFloatingButton(BuildContext context, {
    StudyMaterial? material,
    String? initialQuestion,
    double size = 56.0,
    Color? color,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: FloatingActionButton(
        heroTag: 'ai_floating_button_${DateTime.now().millisecondsSinceEpoch}',
        backgroundColor: color ?? Colors.blue,
        mini: size < 50,
        child: const Icon(Icons.psychology_alt, color: Colors.white),
        onPressed: () => showAssistant(
          context,
          material: material,
          initialQuestion: initialQuestion,
        ),
      ),
    );
  }
  
  // Create an AppBar action for AI assistant
  static IconButton createAppBarAction(BuildContext context, {
    StudyMaterial? material,
    String? initialQuestion,
  }) {
    return IconButton(
      icon: const Icon(Icons.psychology_alt),
      tooltip: 'AI Assistant',
      onPressed: () => showAssistant(
        context,
        material: material,
        initialQuestion: initialQuestion,
      ),
    );
  }
  
  // Create a text button with AI icon
  static Widget createTextButton(BuildContext context, {
    String? label,
    StudyMaterial? material,
    String? initialQuestion,
  }) {
    return TextButton.icon(
      icon: const Icon(Icons.psychology_alt, size: 16),
      label: Text(label ?? 'AI Help'),
      onPressed: () => showAssistant(
        context,
        material: material,
        initialQuestion: initialQuestion,
      ),
    );
  }
  
  // Create a mini-button that can be placed anywhere
  static Widget createMiniButton(BuildContext context, {
    StudyMaterial? material,
    String? initialQuestion,
  }) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Material(
        color: Colors.blue,
        shape: const CircleBorder(),
        elevation: 2,
        child: InkWell(
          onTap: () => showAssistant(
            context,
            material: material,
            initialQuestion: initialQuestion,
          ),
          customBorder: const CircleBorder(),
          child: const Center(
            child: Icon(
              Icons.psychology_alt,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
  
  // Show assistant for study planning
  static void showStudyPlanningAssistant(BuildContext context) {
    showAssistant(
      context,
      initialQuestion: 'Help me create a study plan',
    );
  }
  
  // Show assistant for material explanation
  static void showExplanationAssistant(BuildContext context, StudyMaterial material) {
    showAssistant(
      context,
      material: material,
      initialQuestion: 'Explain the concepts in ${material.title}',
    );
  }
}