import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_scheduler/constants/app_colors.dart';
import 'package:study_scheduler/services/analytics_service.dart';
import 'package:study_scheduler/services/connectivity_service.dart';

/// A widget to display errors, with options to retry or report the error
class ErrorDisplayWidget extends StatelessWidget {
  /// The error message to display
  final String message;
  
  /// The error details
  final dynamic error;
  
  /// The stack trace
  final StackTrace? stackTrace;
  
  /// Callback to retry the operation
  final VoidCallback? onRetry;
  
  /// Whether the error is likely caused by connectivity issues
  final bool? isConnectivityError;
  
  const ErrorDisplayWidget({
    Key? key,
    required this.message,
    this.error,
    this.stackTrace,
    this.onRetry,
    this.isConnectivityError,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if it's a connectivity error
    final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
    final bool isOffline = isConnectivityError ?? !connectivityService.isConnected();
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            Icon(
              isOffline ? Icons.signal_wifi_off : Icons.error_outline,
              size: 64,
              color: isOffline ? Colors.grey : AppColors.error,
            ),
            const SizedBox(height: 16),
            
            // Error title
            Text(
              isOffline ? 'No Internet Connection' : 'Something went wrong',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Error message
            Text(
              isOffline 
                  ? 'Please check your internet connection and try again'
                  : message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Retry button
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: () {
                  // Report retry attempt
                  final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
                  analyticsService.trackEvent('error_retry', parameters: {
                    'error_message': message,
                    'is_connectivity_error': isOffline,
                  });
                  
                  onRetry!();
                },
                icon: Icon(
                  isOffline ? Icons.refresh : Icons.replay,
                ),
                label: Text(
                  isOffline ? 'Check Connection' : 'Try Again',
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            
            // Report error button (only if not a connectivity error)
            if (!isOffline)
              TextButton.icon(
                onPressed: () => _reportError(context),
                icon: const Icon(Icons.bug_report),
                label: const Text('Report Problem'),
              ),
          ],
        ),
      ),
    );
  }

  void _reportError(BuildContext context) {
    // Track the error
    final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
    analyticsService.trackError(
      'reported_by_user',
      message,
      stackTrace: stackTrace,
    );
    
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thank You'),
        content: const Text(
          'This error has been reported to our team. We\'ll work to fix it as soon as possible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}