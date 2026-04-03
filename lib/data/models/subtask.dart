class Subtask {
  const Subtask({
    this.id,
    required this.taskId,
    required this.title,
    this.isDone = false,
  });

  final int? id;
  final int taskId;
  final String title;
  final bool isDone;

  Subtask copyWith({int? id, int? taskId, String? title, bool? isDone}) {
    return Subtask(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'task_id': taskId,
      'title': title,
      'is_done': isDone ? 1 : 0,
    };
  }

  factory Subtask.fromMap(Map<String, Object?> map) {
    return Subtask(
      id: map['id'] as int?,
      taskId: map['task_id'] as int,
      title: map['title'] as String,
      isDone: (map['is_done'] as int? ?? 0) == 1,
    );
  }
}
