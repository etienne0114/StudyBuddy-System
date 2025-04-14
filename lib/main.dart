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
import 'package:study_scheduler/managers/ai_assistant_manager.dart';
import 'package:flutter/foundation.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Initialize AI functionality
  try {
    // Initialize AI tables
    final studyMaterialsRepository = StudyMaterialsRepository();
    await studyMaterialsRepository.ensureAITablesExist();
    
    // Initialize AI Assistant Manager
    await AIAssistantManager.instance.initialize();
    
    if (kDebugMode) {
      print('AI functionality initialized successfully');
    }
  } catch (e) {
    // Silently handle errors to prevent app crashes
    if (kDebugMode) {
      print('Error initializing AI functionality (handled): $e');
    }
    // App will continue normally even if AI initialization fails
  }
  
  // Start the app
  runApp(const AppLoader());
}

// Widget to handle initialization and show loading state
class AppLoader extends StatefulWidget {
  const AppLoader({Key? key}) : super(key: key);

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> {
  bool _isInitialized = false;
  String _errorMessage = '';
  
  // Services
  late DatabaseHelper _databaseHelper;
  late NotificationService _notificationService;
  late ScheduleRepository _scheduleRepository;
  late StudyMaterialsRepository _materialsRepository;
  late AuthService _authService;
  
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    try {
      // Initialize core services
      _databaseHelper = DatabaseHelper.instance;
      _notificationService = NotificationService();
      _materialsRepository = StudyMaterialsRepository();
      _authService = AuthService();
      
      // Initialize notification service
      await _notificationService.init();
      
      // Initialize schedule repository
      _scheduleRepository = ScheduleRepository(
        dbHelper: _databaseHelper,
        notificationService: _notificationService,
      );
      
      // Mark as initialized
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      // If anything fails, show a generic message
      setState(() {
        _errorMessage = 'Could not initialize app. Please restart.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // If not initialized, show loading screen
    if (!_isInitialized) {
      return MaterialApp(
        title: 'Study Scheduler',
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: _errorMessage.isNotEmpty
                ? Text(_errorMessage)
                : const CircularProgressIndicator(),
          ),
        ),
      );
    }
    
    // Once initialized, start the app with providers
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authService),
        Provider.value(value: _scheduleRepository),
        Provider.value(value: _notificationService),
        Provider.value(value: _materialsRepository),
      ],
      child: const StudySchedulerApp(),
    );
  }
}