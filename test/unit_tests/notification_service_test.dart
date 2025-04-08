// test/unit_tests/notification_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:study_scheduler/data/models/activity.dart';
import 'package:study_scheduler/services/notification_service.dart';

void main() {
  group('NotificationService', () {
    test('can be instantiated', () {
      // This test just verifies that the service can be created
      final service = NotificationService();
      expect(service, isNotNull);
    });
    
    test('should skip notification when notifyBefore is 0', () {
      // This is a non-mocked test that just verifies the early return logic
      final service = NotificationService();
      final activity = Activity(
        id: 1, 
        scheduleId: 1,
        title: 'Test',
        dayOfWeek: 1,
        startTime: '10:00',
        endTime: '11:00',
        notifyBefore: 0,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );
      
      // This should not throw an exception
      expect(() => service.scheduleActivityNotification(activity), returnsNormally);
    });
    
    test('scheduleActivityNotification should skip when id is null', () {
      final service = NotificationService();
      final activity = Activity(
        id: null, // null ID should cause early return
        scheduleId: 1,
        title: 'Test',
        dayOfWeek: 1,
        startTime: '10:00',
        endTime: '11:00',
        notifyBefore: 30,
        createdAt: DateTime.now().toIso8601String(),
        updatedAt: DateTime.now().toIso8601String(),
      );
      
      // This should not throw an exception
      expect(() => service.scheduleActivityNotification(activity), returnsNormally);
    });
  });
}