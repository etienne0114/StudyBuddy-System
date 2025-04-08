import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:study_scheduler/app.dart';
import 'package:study_scheduler/services/notification_service.dart';

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
    
    // Load environment variables
    await dotenv.load(fileName: '.env');
    
    // Initialize notifications
    final notificationService = NotificationService();
    await notificationService.init();
    
    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    
    // Run the app
    runApp(const StudySchedulerApp());
  }, (error, stackTrace) {
    // Log all uncaught errors
    print('Uncaught error: $error');
    print(stackTrace);
    
    // Here you could integrate with a crash reporting service like Firebase Crashlytics
    // or send the error to your own backend
  });
}