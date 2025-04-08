import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:study_scheduler/data/database/database_helper.dart';
import 'package:study_scheduler/data/models/schedule.dart';
import 'package:study_scheduler/data/repositories/schedule_repository.dart';
import 'package:study_scheduler/services/notification_service.dart';

// Mock classes
class MockDatabaseHelper extends Mock implements DatabaseHelper {}
class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late ScheduleRepository repository;
  late MockDatabaseHelper mockDatabaseHelper;

  setUp(() {
    mockDatabaseHelper = MockDatabaseHelper();
    repository = ScheduleRepository();
  });

  group('ScheduleRepository', () {
    final testSchedule = Schedule(
      id: 1,
      title: 'Test Schedule',
      description: 'Test Description',
      color: Colors.blue.value, createdAt: '', updatedAt: '',
    );

    final testSchedules = [
      testSchedule,
      Schedule(
        id: 2,
        title: 'Test Schedule 2',
        description: 'Test Description 2',
        color: Colors.red.value, createdAt: '', updatedAt: '',
      ),
    ];

    test('getAllSchedules should return list of schedules', () async {
      // Arrange
      when(mockDatabaseHelper.getSchedules())
          .thenAnswer((_) async => testSchedules);

      // Act
      final result = await repository.getAllSchedules();

      // Assert
      expect(result, equals(testSchedules));
      verify(mockDatabaseHelper.getSchedules()).called(1);
    });

    test('getScheduleById should return schedule when found', () async {
      // Arrange
      when(mockDatabaseHelper.getSchedule(1))
          .thenAnswer((_) async => testSchedule);

      // Act
      final result = await repository.getScheduleById(1);

      // Assert
      expect(result, equals(testSchedule));
      verify(mockDatabaseHelper.getSchedule(1)).called(1);
    });

    test('getScheduleById should return null when not found', () async {
      // Arrange
      when(mockDatabaseHelper.getSchedule(999))
          .thenAnswer((_) async => null);

      // Act
      final result = await repository.getScheduleById(999);

      // Assert
      expect(result, isNull);
      verify(mockDatabaseHelper.getSchedule(999)).called(1);
    });

    test('createSchedule should return ID of created schedule', () async {
      // Arrange
      when(mockDatabaseHelper.insertSchedule(testSchedule))
          .thenAnswer((_) async => 1);

      // Act
      final result = await repository.createSchedule(testSchedule);

      // Assert
      expect(result, equals(1));
      verify(mockDatabaseHelper.insertSchedule(testSchedule)).called(1);
    });

    test('updateSchedule should return number of rows affected', () async {
      // Arrange
      when(mockDatabaseHelper.updateSchedule(testSchedule))
          .thenAnswer((_) async => 1);

      // Act
      final result = await repository.updateSchedule(testSchedule);

      // Assert
      expect(result, equals(1));
      verify(mockDatabaseHelper.updateSchedule(testSchedule)).called(1);
    });

    test('deleteSchedule should return true on success', () async {
      // Arrange
      when(mockDatabaseHelper.getActivitiesByScheduleId(1))
          .thenAnswer((_) async => []);
      when(mockDatabaseHelper.deleteSchedule(1))
          .thenAnswer((_) async => 1);

      // Act
      final result = await repository.deleteSchedule(1);

      // Assert
      expect(result, isTrue);
      verify(mockDatabaseHelper.getActivitiesByScheduleId(1)).called(1);
      verify(mockDatabaseHelper.deleteSchedule(1)).called(1);
    });
  });
}