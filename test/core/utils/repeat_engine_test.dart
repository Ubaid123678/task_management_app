import 'package:flutter_test/flutter_test.dart';
import 'package:task_managemnt_app/core/utils/repeat_engine.dart';
import 'package:task_managemnt_app/data/models/task.dart';

void main() {
  Task baseTask({
    required RepeatType type,
    DateTime? due,
    List<int> repeatDays = const <int>[],
    int? interval,
  }) {
    final now = DateTime(2026, 3, 29, 10, 0);
    return Task(
      id: 1,
      title: 'Task',
      dueDateTime: due ?? now,
      repeatType: type,
      repeatDays: repeatDays,
      repeatInterval: interval,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('daily repeat adds one day', () {
    final task = baseTask(type: RepeatType.daily, due: DateTime(2026, 3, 29, 9, 0));
    final next = RepeatEngine.calculateNextDue(task, DateTime(2026, 3, 29, 11, 0));

    expect(next, DateTime(2026, 3, 30, 11, 0));
  });

  test('interval repeat respects repeatInterval days', () {
    final task = baseTask(
      type: RepeatType.interval,
      due: DateTime(2026, 3, 29, 9, 0),
      interval: 3,
    );
    final next = RepeatEngine.calculateNextDue(task, DateTime(2026, 3, 29, 11, 0));

    expect(next, DateTime(2026, 4, 1, 11, 0));
  });

  test('weekly repeat moves to next selected weekday', () {
    final task = baseTask(
      type: RepeatType.weekly,
      due: DateTime(2026, 3, 30, 9, 0),
      repeatDays: const <int>[1, 4],
    );

    final next = RepeatEngine.calculateNextDue(task, DateTime(2026, 3, 30, 11, 0));

    expect(next, DateTime(2026, 4, 2, 11, 0));
  });

  test('none repeat returns null', () {
    final task = baseTask(type: RepeatType.none);
    final next = RepeatEngine.calculateNextDue(task, DateTime(2026, 3, 29, 11, 0));

    expect(next, isNull);
  });
}
