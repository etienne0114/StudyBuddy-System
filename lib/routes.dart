import 'package:flutter/material.dart';
import 'package:study_scheduler/ui/screens/schedule/schedule_screen.dart';
import 'package:study_scheduler/ui/screens/schedule/add_activity_screen.dart';
import 'package:study_scheduler/ui/screens/schedule/ai_schedule_planner_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) => const ScheduleScreen(),
  '/add-activity': (context) => const AddActivityScreen(),
  '/ai-planner': (context) => const AISchedulePlannerScreen(),
};
