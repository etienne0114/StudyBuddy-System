// lib/main.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:study_scheduler/app.dart';
import 'package:study_scheduler/data/database/database_helper.dart';
import 'package:study_scheduler/data/repositories/schedule_repository.dart';
import 'package:study_scheduler/data/repositories/study_materials_repository.dart';
import 'package:study_scheduler/services/auth_service.dart';
import 'package:study_scheduler/services/notification_service.dart';
import 'package:study_scheduler/utils/ai_assistant_utils.dart';

void main() async {
  // Catch all errors in the app for better debugging and analytics
  await runZonedGuarded(() async {
    // Ensure Flutter is initialized
    WidgetsFlutterBinding.ensureInitialized();
    
    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    
    // Initialize services
    final databaseHelper = DatabaseHelper.instance;
    final notificationService = NotificationService();
    await notificationService.init();
    
    // Initialize materials repository and ensure AI tables exist
    final materialsRepository = StudyMaterialsRepository();
    await materialsRepository.ensureAITablesExist();
    
    // Create repository
    final scheduleRepository = ScheduleRepository(
      dbHelper: databaseHelper,
      notificationService: notificationService,
    );
    
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    
    // Run the app with all the required providers
    runApp(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthService()),
          Provider.value(value: scheduleRepository),
          Provider.value(value: notificationService),
          Provider.value(value: materialsRepository), // Add materials repository to providers
        ],
        child: const StudySchedulerApp(),
      ),
    );
  }, (error, stackTrace) {
    // Log all uncaught errors
    print('Uncaught error: $error');
    print(stackTrace);
  });
}