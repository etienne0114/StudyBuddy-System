import 'package:flutter/material.dart';
import 'package:study_scheduler/data/models/activity.dart';

/// Extension to convert time strings (HH:MM) to TimeOfDay objects
extension TimeStringExtension on String {
  TimeOfDay toTimeOfDay() {
    final parts = split(':');
    return TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );
  }
}

class UpcomingActivities extends StatelessWidget {
  final List<Activity> activities;
  final Function(Activity)? onActivityTap;

  const UpcomingActivities({
    Key? key,
    required this.activities,
    this.onActivityTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sort activities by start time
    final sortedActivities = [...activities]
      ..sort((a, b) {
        final aTimeOfDay = a.startTime.toTimeOfDay();
        final bTimeOfDay = b.startTime.toTimeOfDay();
        final aTime = aTimeOfDay.hour * 60 + aTimeOfDay.minute;
        final bTime = bTimeOfDay.hour * 60 + bTimeOfDay.minute;
        return aTime.compareTo(bTime);
      });

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedActivities.length,
      itemBuilder: (context, index) {
        final activity = sortedActivities[index];
        
        // Check if current time is between start and end time
        final now = TimeOfDay.now();
        final nowMinutes = now.hour * 60 + now.minute;
        
        final startTimeOfDay = activity.startTime.toTimeOfDay();
        final endTimeOfDay = activity.endTime.toTimeOfDay();
        final startMinutes = startTimeOfDay.hour * 60 + startTimeOfDay.minute;
        final endMinutes = endTimeOfDay.hour * 60 + endTimeOfDay.minute;
        
        final isActive = nowMinutes >= startMinutes && nowMinutes < endMinutes;
        final isPast = nowMinutes > endMinutes;
        
        return _buildActivityCard(context, activity, isActive, isPast);
      },
    );
  }

  Widget _buildActivityCard(
    BuildContext context, 
    Activity activity, 
    bool isActive, 
    bool isPast
  ) {
    return GestureDetector(
      onTap: () {
        if (onActivityTap != null) {
          onActivityTap!(activity);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Color indicator for schedule
            Container(
              width: 8,
              height: 90,
              decoration: BoxDecoration(
                color: Color(activity.scheduleColor ?? 0xFF9E9E9E),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
            ),
            
            // Time column
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getFormattedTime(activity.startTime),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _getFormattedTime(activity.endTime),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            
            // Activity details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            activity.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isPast ? Colors.grey : Colors.black,
                              decoration: isPast ? TextDecoration.lineThrough : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.green),
                            ),
                            child: const Text(
                              'Now',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (activity.scheduleTitle != null)
                      Text(
                        activity.scheduleTitle!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    const SizedBox(height: 4),
                    if (activity.location != null && activity.location!.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              activity.location!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            
            // Right icon
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to format time strings
  String _getFormattedTime(String timeString) {
    final timeOfDay = timeString.toTimeOfDay();
    final hour = timeOfDay.hour;
    final minute = timeOfDay.minute;
    
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final displayMinute = minute.toString().padLeft(2, '0');
    
    return '$displayHour:$displayMinute $period';
  }
}