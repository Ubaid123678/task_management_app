import 'package:flutter_test/flutter_test.dart';
import 'package:task_managemnt_app/data/models/task.dart';

void main() {
  test('Task map round-trip preserves values', () {
    final now = DateTime(2026, 3, 29, 12, 30);

    final original = Task(
      id: 7,
      title: 'Write report',
      description: 'Prepare final report',
      dueDateTime: now,
      isCompleted: true,
      repeatType: RepeatType.weekly,
      repeatDays: const <int>[1, 3, 5],
      repeatInterval: null,
      progress: 0.75,
      createdAt: now,
      updatedAt: now,
    );

    final rebuilt = Task.fromMap(original.toMap());

    expect(rebuilt.id, original.id);
    expect(rebuilt.title, original.title);
    expect(rebuilt.description, original.description);
    expect(rebuilt.dueDateTime, original.dueDateTime);
    expect(rebuilt.isCompleted, original.isCompleted);
    expect(rebuilt.repeatType, original.repeatType);
    expect(rebuilt.repeatDays, original.repeatDays);
    expect(rebuilt.progress, original.progress);
  });

  test('Task copyWith updates expected fields', () {
    final now = DateTime(2026, 3, 29, 12, 30);

    final task = Task(
      id: 1,
      title: 'Old',
      dueDateTime: now,
      createdAt: now,
      updatedAt: now,
    );

    final updated = task.copyWith(
      title: 'New',
      isCompleted: true,
      progress: 0.5,
    );

    expect(updated.title, 'New');
    expect(updated.isCompleted, isTrue);
    expect(updated.progress, 0.5);
    expect(updated.id, task.id);
  });
}
