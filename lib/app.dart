import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_scheduler/constants/app_colors.dart';
import 'package:study_scheduler/providers/schedule_provider.dart';
import 'package:study_scheduler/providers/study_materials_provider.dart';
import 'package:study_scheduler/providers/theme_mode_provider.dart';
import 'package:study_scheduler/services/analytics_service.dart';
import 'package:study_scheduler/services/auth_service.dart';
import 'package:study_scheduler/services/connectivity_service.dart';
import 'package:study_scheduler/ui/screens/splash_screen.dart';

class StudySchedulerApp extends StatefulWidget {
  const StudySchedulerApp({Key? key}) : super(key: key);

  @override
  State<StudySchedulerApp> createState() => _StudySchedulerAppState();
}

class _StudySchedulerAppState extends State<StudySchedulerApp> {
  // Initialize services
  final _analyticsService = AnalyticsService();
  final _connectivityService = ConnectivityService();
  final _themeModeProvider = ThemeModeProvider();
  
  @override
  void initState() {
    super.initState();
    
    // Initialize services
    _analyticsService.initialize();
    _connectivityService.initialize();
    _themeModeProvider.initialize();
  }

  @override
  void dispose() {
    _connectivityService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        Provider<AnalyticsService>.value(value: _analyticsService),
        Provider<ConnectivityService>.value(value: _connectivityService),
        
        // Auth service
        ChangeNotifierProvider(create: (_) => AuthService()),
        
        // Theme provider
        ChangeNotifierProvider.value(value: _themeModeProvider),
        
        // Data providers
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
        ChangeNotifierProvider(create: (_) => StudyMaterialsProvider()),
      ],
      child: Consumer<ThemeModeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Study Scheduler',
            theme: _getLightTheme(), // Direct light theme implementation
            darkTheme: _getDarkTheme(), // Direct dark theme implementation
            themeMode: themeProvider.themeMode,
            home: const SplashScreen(),
            debugShowCheckedModeBanner: false,
            navigatorObservers: [
              // Track screen views
              _AnalyticsNavigatorObserver(_analyticsService),
            ],
          );
        },
      ),
    );
  }
  
  // Light theme implementation
  ThemeData _getLightTheme() {
    return ThemeData(
      primarySwatch: createMaterialColor(AppColors.primary),
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: Colors.white,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  // Dark theme implementation
  ThemeData _getDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primarySwatch: createMaterialColor(AppColors.primary),
      primaryColor: AppColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: Color(0xFF1E1E1E),
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
    );
  }
  
  // Create material color helper
  MaterialColor createMaterialColor(Color color) {
    List<double> strengths = <double>[.05, .1, .2, .3, .4, .5, .6, .7, .8, .9];
    Map<int, Color> swatch = <int, Color>{};
    final int r = color.red, g = color.green, b = color.blue;

    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }
}

/// Navigator observer for analytics
class _AnalyticsNavigatorObserver extends NavigatorObserver {
  final AnalyticsService _analyticsService;
  
  _AnalyticsNavigatorObserver(this._analyticsService);
  
  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    
    // Track screen view when a new screen is pushed
    if (route.settings.name != null) {
      _analyticsService.trackScreenView(route.settings.name!);
    } else {
      // Use runtimeType as fallback
      final screenName = route.settings.toString();
      _analyticsService.trackScreenView(screenName);
    }
  }
}