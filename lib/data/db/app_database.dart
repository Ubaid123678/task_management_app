import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../core/utils/repeat_engine.dart';
import '../models/subtask.dart';
import '../models/task.dart';

class AppDatabase {
  AppDatabase._internal();

  static final AppDatabase instance = AppDatabase._internal();

  static const String _databaseName = 'task_management.db';
  static const int _databaseVersion = 1;

  static const String tasksTable = 'tasks';
  static const String subtasksTable = 'subtasks';

  Database? _database;

  final List<Task> _webTasks = <Task>[];
  final List<Subtask> _webSubtasks = <Subtask>[];
  int _webTaskCounter = 0;
  int _webSubtaskCounter = 0;

  int _taskSortDate(DateTime? value) => value?.millisecondsSinceEpoch ?? 0;

  bool _containsSearch(Task task, String search) {
    if (search.isEmpty) {
      return true;
    }

    final key = search.toLowerCase();
    return task.title.toLowerCase().contains(key) ||
        (task.description?.toLowerCase().contains(key) ?? false);
  }

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _databaseName);

    return openDatabase(
      path,
      version: _databaseVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createTables(db);
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE $tasksTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        due_date_time TEXT,
        is_completed INTEGER NOT NULL DEFAULT 0,
        repeat_type TEXT NOT NULL DEFAULT 'none',
        repeat_days TEXT,
        repeat_interval INTEGER,
        progress REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $subtasksTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        is_done INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (task_id) REFERENCES $tasksTable(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<int> insertTask(Task task) async {
    if (kIsWeb) {
      final id = ++_webTaskCounter;
      _webTasks.add(task.copyWith(id: id));
      return id;
    }

    final db = await database;
    return db.insert(tasksTable, task.toMap());
  }

  Future<List<Task>> getAllTasks() async {
    if (kIsWeb) {
      final tasks = List<Task>.from(_webTasks);
      tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return tasks;
    }

    final db = await database;
    final rows = await db.query(tasksTable, orderBy: 'created_at DESC');
    return rows.map(Task.fromMap).toList(growable: false);
  }

  Future<List<Task>> getActiveTasksWithDueDate() async {
    if (kIsWeb) {
      final tasks = _webTasks
          .where((task) => !task.isCompleted && task.dueDateTime != null)
          .toList(growable: false);
      tasks.sort(
        (a, b) => _taskSortDate(
          a.dueDateTime,
        ).compareTo(_taskSortDate(b.dueDateTime)),
      );
      return tasks;
    }

    final db = await database;
    final rows = await db.query(
      tasksTable,
      where: 'is_completed = ? AND due_date_time IS NOT NULL',
      whereArgs: [0],
      orderBy: 'due_date_time ASC',
    );
    return rows.map(Task.fromMap).toList(growable: false);
  }

  Future<List<Task>> processDueTasks(DateTime now) async {
    final nowIso = now.toIso8601String();

    if (kIsWeb) {
      final dueTasks = _webTasks
          .where((task) {
            final due = task.dueDateTime;
            return !task.isCompleted && due != null && !due.isAfter(now);
          })
          .toList(growable: false);

      if (dueTasks.isEmpty) {
        return const <Task>[];
      }

      final updated = <Task>[];
      for (final task in dueTasks) {
        await applyTaskCompletion(task: task, isCompleted: true);
        if (task.id == null) {
          continue;
        }
        final refreshed = await getTaskById(task.id!);
        if (refreshed != null) {
          updated.add(refreshed);
        }
      }

      return updated;
    }

    final db = await database;
    final rows = await db.query(
      tasksTable,
      where:
          'is_completed = ? AND due_date_time IS NOT NULL AND due_date_time <= ?',
      whereArgs: [0, nowIso],
      orderBy: 'due_date_time ASC',
    );

    if (rows.isEmpty) {
      return const <Task>[];
    }

    final dueTasks = rows.map(Task.fromMap).toList(growable: false);
    final updated = <Task>[];

    for (final task in dueTasks) {
      await applyTaskCompletion(task: task, isCompleted: true);
      if (task.id == null) {
        continue;
      }

      final refreshed = await getTaskById(task.id!);
      if (refreshed != null) {
        updated.add(refreshed);
      }
    }

    return updated;
  }

  Future<List<Task>> getTodayTasks(DateTime day) async {
    if (kIsWeb) {
      final start = DateTime(day.year, day.month, day.day);
      final end = start.add(const Duration(days: 1));

      final tasks = _webTasks
          .where((task) {
            final due = task.dueDateTime;
            return !task.isCompleted &&
                due != null &&
                !due.isBefore(start) &&
                due.isBefore(end);
          })
          .toList(growable: false);

      tasks.sort(
        (a, b) => _taskSortDate(
          a.dueDateTime,
        ).compareTo(_taskSortDate(b.dueDateTime)),
      );
      return tasks;
    }

    final db = await database;
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    final rows = await db.query(
      tasksTable,
      where: 'is_completed = ? AND due_date_time >= ? AND due_date_time < ?',
      whereArgs: [0, start.toIso8601String(), end.toIso8601String()],
      orderBy: 'due_date_time ASC',
    );

    return rows.map(Task.fromMap).toList(growable: false);
  }

  Future<List<Task>> getCompletedTasks({
    String search = '',
    bool newestFirst = true,
  }) async {
    if (kIsWeb) {
      for (var i = 0; i < _webTasks.length; i++) {
        final task = _webTasks[i];
        if (task.isCompleted && task.progress < 1) {
          _webTasks[i] = task.copyWith(progress: 1);
        }
      }

      final tasks = _webTasks
          .where(
            (task) => task.isCompleted && _containsSearch(task, search.trim()),
          )
          .toList(growable: false);

      tasks.sort(
        (a, b) => newestFirst
            ? b.updatedAt.compareTo(a.updatedAt)
            : a.updatedAt.compareTo(b.updatedAt),
      );
      return tasks;
    }

    final db = await database;
    await db.update(
      tasksTable,
      {'progress': 1.0},
      where: 'is_completed = ? AND progress < ?',
      whereArgs: [1, 1.0],
    );

    final whereParts = <String>['is_completed = ?'];
    final whereArgs = <Object>[1];

    final trimmed = search.trim();
    if (trimmed.isNotEmpty) {
      whereParts.add('(title LIKE ? OR description LIKE ?)');
      whereArgs.add('%$trimmed%');
      whereArgs.add('%$trimmed%');
    }

    final rows = await db.query(
      tasksTable,
      where: whereParts.join(' AND '),
      whereArgs: whereArgs,
      orderBy: newestFirst ? 'updated_at DESC' : 'updated_at ASC',
    );
    return rows.map(Task.fromMap).toList(growable: false);
  }

  Future<List<Task>> getRepeatedTasks({
    bool? isCompleted,
    RepeatType? repeatType,
    String search = '',
  }) async {
    if (kIsWeb) {
      var tasks = _webTasks.where((task) => task.repeatType != RepeatType.none);

      if (isCompleted != null) {
        tasks = tasks.where((task) => task.isCompleted == isCompleted);
      }

      if (repeatType != null && repeatType != RepeatType.none) {
        tasks = tasks.where((task) => task.repeatType == repeatType);
      }

      final filtered = tasks
          .where((task) => _containsSearch(task, search.trim()))
          .toList(growable: false);

      filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return filtered;
    }

    final db = await database;

    final whereParts = <String>['repeat_type != ?'];
    final whereArgs = <Object>[RepeatType.none.name];

    if (isCompleted != null) {
      whereParts.add('is_completed = ?');
      whereArgs.add(isCompleted ? 1 : 0);
    }

    if (repeatType != null && repeatType != RepeatType.none) {
      whereParts.add('repeat_type = ?');
      whereArgs.add(repeatType.name);
    }

    final trimmed = search.trim();
    if (trimmed.isNotEmpty) {
      whereParts.add('(title LIKE ? OR description LIKE ?)');
      whereArgs.add('%$trimmed%');
      whereArgs.add('%$trimmed%');
    }

    final rows = await db.query(
      tasksTable,
      where: whereParts.join(' AND '),
      whereArgs: whereArgs,
      orderBy: 'updated_at DESC',
    );
    return rows.map(Task.fromMap).toList(growable: false);
  }

  Future<Task?> getTaskById(int id) async {
    if (kIsWeb) {
      for (final task in _webTasks) {
        if (task.id == id) {
          return task;
        }
      }
      return null;
    }

    final db = await database;
    final rows = await db.query(
      tasksTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }
    return Task.fromMap(rows.first);
  }

  Future<int> updateTask(Task task) async {
    if (kIsWeb) {
      final index = _webTasks.indexWhere((item) => item.id == task.id);
      if (index == -1) {
        return 0;
      }

      _webTasks[index] = task;
      return 1;
    }

    final db = await database;
    return db.update(
      tasksTable,
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  double _webProgressForTask(int taskId) {
    final related = _webSubtasks
        .where((subtask) => subtask.taskId == taskId)
        .toList(growable: false);
    final total = related.length;
    if (total == 0) {
      return 0.0;
    }

    final done = related.where((subtask) => subtask.isDone).length;
    return done / total;
  }

  Future<double> _dbProgressForTask(Database db, int taskId) async {
    final totals = await db.rawQuery(
      '''
      SELECT
        COUNT(*) AS total,
        SUM(CASE WHEN is_done = 1 THEN 1 ELSE 0 END) AS done
      FROM $subtasksTable
      WHERE task_id = ?
      ''',
      [taskId],
    );

    final row = totals.first;
    final total = (row['total'] as int?) ?? 0;
    final done = (row['done'] as int?) ?? 0;
    if (total == 0) {
      return 0.0;
    }

    return done / total;
  }

  Future<int> markTaskCompleted({
    required int taskId,
    required bool isCompleted,
  }) async {
    if (kIsWeb) {
      final index = _webTasks.indexWhere((task) => task.id == taskId);
      if (index == -1) {
        return 0;
      }

      final progress = isCompleted ? 1.0 : _webProgressForTask(taskId);

      _webTasks[index] = _webTasks[index].copyWith(
        isCompleted: isCompleted,
        progress: progress,
        updatedAt: DateTime.now(),
      );
      return 1;
    }

    final db = await database;
    final progress = isCompleted ? 1.0 : await _dbProgressForTask(db, taskId);
    return db.update(
      tasksTable,
      {
        'is_completed': isCompleted ? 1 : 0,
        'progress': progress,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<void> applyTaskCompletion({
    required Task task,
    required bool isCompleted,
  }) async {
    if (task.id == null) {
      return;
    }

    if (kIsWeb) {
      final now = DateTime.now();
      final index = _webTasks.indexWhere((item) => item.id == task.id);
      if (index == -1) {
        return;
      }

      if (isCompleted && task.repeatType != RepeatType.none) {
        final nextDue = RepeatEngine.calculateNextDue(task, now);
        if (nextDue != null) {
          _webTasks[index] = task.copyWith(
            isCompleted: false,
            dueDateTime: nextDue,
            progress: 0,
            updatedAt: now,
          );

          for (var i = 0; i < _webSubtasks.length; i++) {
            final subtask = _webSubtasks[i];
            if (subtask.taskId == task.id) {
              _webSubtasks[i] = subtask.copyWith(isDone: false);
            }
          }

          return;
        }
      }

      await markTaskCompleted(taskId: task.id!, isCompleted: isCompleted);
      return;
    }

    final db = await database;
    final now = DateTime.now();

    if (isCompleted && task.repeatType != RepeatType.none) {
      final nextDue = RepeatEngine.calculateNextDue(task, now);
      if (nextDue != null) {
        await db.transaction((txn) async {
          await txn.update(
            tasksTable,
            {
              'is_completed': 0,
              'due_date_time': nextDue.toIso8601String(),
              'progress': 0,
              'updated_at': now.toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [task.id],
          );

          await txn.update(
            subtasksTable,
            {'is_done': 0},
            where: 'task_id = ?',
            whereArgs: [task.id],
          );
        });
        return;
      }
    }

    await markTaskCompleted(taskId: task.id!, isCompleted: isCompleted);
  }

  Future<int> deleteTask(int taskId) async {
    if (kIsWeb) {
      final before = _webTasks.length;
      _webTasks.removeWhere((task) => task.id == taskId);
      _webSubtasks.removeWhere((subtask) => subtask.taskId == taskId);
      return before - _webTasks.length;
    }

    final db = await database;
    return db.delete(tasksTable, where: 'id = ?', whereArgs: [taskId]);
  }

  Future<int> insertSubtask(Subtask subtask) async {
    if (kIsWeb) {
      final id = ++_webSubtaskCounter;
      _webSubtasks.add(subtask.copyWith(id: id));
      return id;
    }

    final db = await database;
    return db.insert(subtasksTable, subtask.toMap());
  }

  Future<void> addSubtask({required int taskId, required String title}) async {
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      return;
    }

    if (kIsWeb) {
      final id = ++_webSubtaskCounter;
      _webSubtasks.add(Subtask(id: id, taskId: taskId, title: trimmed));
      await refreshTaskProgress(taskId);
      return;
    }

    final db = await database;
    await db.transaction((txn) async {
      await txn.insert(
        subtasksTable,
        Subtask(taskId: taskId, title: trimmed).toMap(),
      );
    });
    await refreshTaskProgress(taskId);
  }

  Future<List<Subtask>> getSubtasksByTask(int taskId) async {
    if (kIsWeb) {
      final subtasks = _webSubtasks
          .where((subtask) => subtask.taskId == taskId)
          .toList(growable: false);
      subtasks.sort((a, b) => (a.id ?? 0).compareTo(b.id ?? 0));
      return subtasks;
    }

    final db = await database;
    final rows = await db.query(
      subtasksTable,
      where: 'task_id = ?',
      whereArgs: [taskId],
      orderBy: 'id ASC',
    );
    return rows.map(Subtask.fromMap).toList(growable: false);
  }

  Future<int> updateSubtask(Subtask subtask) async {
    if (kIsWeb) {
      final index = _webSubtasks.indexWhere((item) => item.id == subtask.id);
      if (index == -1) {
        return 0;
      }

      _webSubtasks[index] = subtask;
      return 1;
    }

    final db = await database;
    return db.update(
      subtasksTable,
      subtask.toMap(),
      where: 'id = ?',
      whereArgs: [subtask.id],
    );
  }

  Future<int> deleteSubtask(int subtaskId) async {
    if (kIsWeb) {
      final before = _webSubtasks.length;
      _webSubtasks.removeWhere((subtask) => subtask.id == subtaskId);
      return before - _webSubtasks.length;
    }

    final db = await database;
    return db.delete(subtasksTable, where: 'id = ?', whereArgs: [subtaskId]);
  }

  Future<void> toggleSubtask({
    required Subtask subtask,
    required bool isDone,
  }) async {
    if (kIsWeb) {
      final index = _webSubtasks.indexWhere((item) => item.id == subtask.id);
      if (index == -1) {
        return;
      }

      _webSubtasks[index] = subtask.copyWith(isDone: isDone);
      await refreshTaskProgress(subtask.taskId);
      return;
    }

    final db = await database;
    await db.update(
      subtasksTable,
      {'is_done': isDone ? 1 : 0},
      where: 'id = ?',
      whereArgs: [subtask.id],
    );

    await refreshTaskProgress(subtask.taskId);
  }

  Future<void> removeSubtask(Subtask subtask) async {
    if (subtask.id == null) {
      return;
    }

    await deleteSubtask(subtask.id!);
    await refreshTaskProgress(subtask.taskId);
  }

  Future<double> refreshTaskProgress(int taskId) async {
    if (kIsWeb) {
      final progress = _webProgressForTask(taskId);

      final taskIndex = _webTasks.indexWhere((task) => task.id == taskId);
      if (taskIndex != -1) {
        _webTasks[taskIndex] = _webTasks[taskIndex].copyWith(
          progress: progress,
          updatedAt: DateTime.now(),
        );
      }

      return progress;
    }

    final db = await database;
    final progress = await _dbProgressForTask(db, taskId);

    await db.update(
      tasksTable,
      {'progress': progress, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [taskId],
    );

    return progress;
  }

  Future<void> close() async {
    if (kIsWeb) {
      return;
    }

    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
