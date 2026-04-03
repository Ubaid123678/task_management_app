enum RepeatType { none, daily, weekly, interval }

class Task {
  const Task({
    this.id,
    required this.title,
    this.description,
    this.dueDateTime,
    this.isCompleted = false,
    this.repeatType = RepeatType.none,
    this.repeatDays = const <int>[],
    this.repeatInterval,
    this.progress = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String title;
  final String? description;
  final DateTime? dueDateTime;
  final bool isCompleted;
  final RepeatType repeatType;
  final List<int> repeatDays;
  final int? repeatInterval;
  final double progress;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? dueDateTime,
    bool? isCompleted,
    RepeatType? repeatType,
    List<int>? repeatDays,
    int? repeatInterval,
    bool clearRepeatInterval = false,
    double? progress,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDateTime: dueDateTime ?? this.dueDateTime,
      isCompleted: isCompleted ?? this.isCompleted,
      repeatType: repeatType ?? this.repeatType,
      repeatDays: repeatDays ?? this.repeatDays,
      repeatInterval: clearRepeatInterval
          ? null
          : (repeatInterval ?? this.repeatInterval),
      progress: progress ?? this.progress,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'due_date_time': dueDateTime?.toIso8601String(),
      'is_completed': isCompleted ? 1 : 0,
      'repeat_type': repeatType.name,
      'repeat_days': _repeatDaysToStorage(repeatDays),
      'repeat_interval': repeatInterval,
      'progress': progress,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Task.fromMap(Map<String, Object?> map) {
    return Task(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      dueDateTime: map['due_date_time'] == null
          ? null
          : DateTime.parse(map['due_date_time'] as String),
      isCompleted: (map['is_completed'] as int? ?? 0) == 1,
      repeatType: _repeatTypeFromStorage(map['repeat_type'] as String?),
      repeatDays: _repeatDaysFromStorage(map['repeat_days'] as String?),
      repeatInterval: map['repeat_interval'] as int?,
      progress: ((map['progress'] as num?) ?? 0).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  static String _repeatDaysToStorage(List<int> days) {
    if (days.isEmpty) {
      return '';
    }
    return days.join(',');
  }

  static List<int> _repeatDaysFromStorage(String? raw) {
    if (raw == null || raw.isEmpty) {
      return const <int>[];
    }

    return raw
        .split(',')
        .where((value) => value.trim().isNotEmpty)
        .map(int.parse)
        .toList(growable: false);
  }

  static RepeatType _repeatTypeFromStorage(String? raw) {
    for (final type in RepeatType.values) {
      if (type.name == raw) {
        return type;
      }
    }
    return RepeatType.none;
  }
}
