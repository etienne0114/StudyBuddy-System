// lib/utils/logger.dart

import 'package:flutter/foundation.dart';

/// A simple logger utility for consistent logging throughout the app
class Logger {
  /// Log an informational message
  static void info(String message) {
    if (kDebugMode) {
      print('ℹ️ INFO: $message');
    }
  }

  /// Log a warning message
  static void warning(String message) {
    if (kDebugMode) {
      print('⚠️ WARNING: $message');
    }
  }

  /// Log an error message
  static void error(String message) {
    if (kDebugMode) {
      print('❌ ERROR: $message');
    }
  }

  /// Log a debug message
  static void debug(String message) {
    if (kDebugMode) {
      print('🔍 DEBUG: $message');
    }
  }

  /// Log a verbose message
  static void verbose(String message) {
    if (kDebugMode) {
      print('📝 VERBOSE: $message');
    }
  }
}