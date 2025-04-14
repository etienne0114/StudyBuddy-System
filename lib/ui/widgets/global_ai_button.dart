// lib/ui/widgets/global_ai_button.dart

import 'package:flutter/material.dart';
import 'package:study_scheduler/ui/screens/materials/compact_ai_assistant_dialog.dart';
import 'package:study_scheduler/data/models/study_material.dart';

class GlobalAIButton extends StatelessWidget {
  final StudyMaterial? material;
  final Color color;
  final double size;
  final EdgeInsets padding;
  
  const GlobalAIButton({
    Key? key,
    this.material,
    this.color = Colors.blue,
    this.size = 56.0,
    this.padding = const EdgeInsets.all(0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: SizedBox(
        width: size,
        height: size,
        child: Material(
          elevation: 4,
          color: color,
          borderRadius: BorderRadius.circular(size / 2),
          child: InkWell(
            onTap: () => _showAIAssistant(context),
            borderRadius: BorderRadius.circular(size / 2),
            child: Center(
              child: Icon(
                Icons.psychology,
                color: Colors.white,
                size: size * 0.6,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  void _showAIAssistant(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CompactAIAssistantDialog(material: material),
    );
  }
}

// Usage example:
// In any scaffold:
// floatingActionButton: const GlobalAIButton(),
// or
// floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
// floatingActionButton: const GlobalAIButton(
//   color: Colors.purple,
//   size: 64,
//   padding: EdgeInsets.only(bottom: 16, right: 16),
// ),