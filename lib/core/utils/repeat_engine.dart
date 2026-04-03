import '../../data/models/task.dart';

class RepeatEngine {
  const RepeatEngine._();

  static DateTime? calculateNextDue(Task task, DateTime completedAt) {
    final due = task.dueDateTime;
    if (due == null) {
      return null;
    }

    final anchor = completedAt.isAfter(due) ? completedAt : due;

    switch (task.repeatType) {
      case RepeatType.none:
        return null;
      case RepeatType.daily:
        return anchor.add(const Duration(days: 1));
      case RepeatType.interval:
        final interval = task.repeatInterval;
        if (interval == null || interval <= 0) {
          return null;
        }
        return anchor.add(Duration(days: interval));
      case RepeatType.weekly:
        final weekDays = task.repeatDays;
        if (weekDays.isEmpty) {
          return anchor.add(const Duration(days: 7));
        }
        return _nextWeeklyDate(anchor, weekDays);
    }
  }

  static DateTime _nextWeeklyDate(DateTime anchor, List<int> weekDays) {
    final uniqueSorted = weekDays.toSet().toList()..sort();

    for (var offset = 1; offset <= 14; offset++) {
      final candidate = anchor.add(Duration(days: offset));
      if (uniqueSorted.contains(candidate.weekday)) {
        return DateTime(
          candidate.year,
          candidate.month,
          candidate.day,
          anchor.hour,
          anchor.minute,
        );
      }
    }

    return anchor.add(const Duration(days: 7));
  }
}
