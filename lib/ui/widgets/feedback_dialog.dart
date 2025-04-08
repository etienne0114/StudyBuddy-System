import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_scheduler/constants/app_colors.dart';
import 'package:study_scheduler/constants/app_styles.dart';
import 'package:study_scheduler/services/analytics_service.dart';

class FeedbackDialog extends StatefulWidget {
  const FeedbackDialog({Key? key}) : super(key: key);

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  int _rating = 0;
  final _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Give us your feedback',
              style: AppStyles.heading2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your feedback helps us improve the app',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            // Rating stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                return IconButton(
                  onPressed: () {
                    setState(() {
                      _rating = starValue;
                    });
                  },
                  icon: Icon(
                    starValue <= _rating
                        ? Icons.star
                        : Icons.star_border,
                    color: starValue <= _rating
                        ? Colors.amber
                        : Colors.grey,
                    size: 36,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            
            // Feedback text field
            TextField(
              controller: _feedbackController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Tell us what you think or suggest improvements',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 20),
            
            // Submit button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitFeedback,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Submit Feedback'),
            ),
            const SizedBox(height: 8),
            
            // Cancel button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('No thanks'),
            ),
          ],
        ),
      ),
    );
  }

  void _submitFeedback() {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    // Get analytics service
    final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
    
    // Track feedback
    analyticsService.trackFeedback(_rating, _feedbackController.text);
    
    // Simulate API call delay
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _isSubmitting = false;
      });
      
      // Close dialog and show success message
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thank you for your feedback!'),
          backgroundColor: AppColors.success,
        ),
      );
    });
  }

  // Show the feedback dialog
}