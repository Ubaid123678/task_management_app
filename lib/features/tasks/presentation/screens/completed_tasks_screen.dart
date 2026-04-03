import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/db/app_database.dart';
import '../../../../data/models/task.dart';
import '../../../settings/presentation/controllers/app_settings_controller.dart';
import '../widgets/task_list_card.dart';

enum _CompletedWindow { today, week, all }

class CompletedTasksScreen extends StatefulWidget {
  const CompletedTasksScreen({super.key});

  @override
  State<CompletedTasksScreen> createState() => _CompletedTasksScreenState();
}

class _CompletedTasksScreenState extends State<CompletedTasksScreen> {
  final AppDatabase _database = AppDatabase.instance;
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  StreamSubscription<int>? _tasksChangedSub;

  List<Task> _tasks = const <Task>[];
  int _allTaskCount = 0;
  int _streakDays = 0;
  bool _isLoading = true;
  bool _newestFirst = true;
  _CompletedWindow _window = _CompletedWindow.all;

  @override
  void initState() {
    super.initState();
    _load();
    _tasksChangedSub = _database.tasksChanged.listen((_) {
      if (!mounted) {
        return;
      }
      _load(showLoader: false);
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _tasksChangedSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 220), () {
      if (!mounted) {
        return;
      }
      _load();
    });
  }

  Future<void> _load({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final startsOnMonday = context
        .read<AppSettingsController>()
        .weekStartsOnMonday;

    final filteredCompleted = await _database.getCompletedTasks(
      search: _searchController.text,
      newestFirst: _newestFirst,
    );
    final allCompleted = await _database.getCompletedTasks(
      search: '',
      newestFirst: true,
    );
    final allTasks = await _database.getAllTasks();

    final scoped = _applyWindowFilter(
      filteredCompleted,
      startsOnMonday: startsOnMonday,
    );
    final streak = _calculateStreak(allCompleted);

    if (!mounted) {
      return;
    }

    setState(() {
      _tasks = scoped;
      _streakDays = streak;
      _allTaskCount = allTasks.length;
      _isLoading = false;
    });
  }

  List<Task> _applyWindowFilter(
    List<Task> tasks, {
    required bool startsOnMonday,
  }) {
    if (_window == _CompletedWindow.all) {
      return tasks;
    }

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final daysToSubtract = startsOnMonday ? now.weekday - 1 : now.weekday % 7;
    final weekStart = todayStart.subtract(Duration(days: daysToSubtract));

    return tasks
        .where((task) {
          final updated = task.updatedAt;
          if (_window == _CompletedWindow.today) {
            return !updated.isBefore(todayStart);
          }
          return !updated.isBefore(weekStart);
        })
        .toList(growable: false);
  }

  int _calculateStreak(List<Task> completed) {
    if (completed.isEmpty) {
      return 0;
    }

    final completedDays = completed
        .map(
          (task) => DateTime(
            task.updatedAt.year,
            task.updatedAt.month,
            task.updatedAt.day,
          ),
        )
        .toSet();

    var streak = 0;
    var cursor = DateTime.now();
    cursor = DateTime(cursor.year, cursor.month, cursor.day);

    while (completedDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  int get _productivityScore {
    if (_allTaskCount <= 0) {
      return 0;
    }
    final ratio = _tasks.length / _allTaskCount;
    return (ratio * 100).clamp(0, 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 390;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.fromLTRB(12, compact ? 8 : 10, 12, 96),
                children: [
                  Container(
                    padding: EdgeInsets.all(compact ? 12 : 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Execution Report',
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontSize: compact ? 18 : 20,
                                    ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _newestFirst = !_newestFirst;
                                });
                                _load();
                              },
                              tooltip: 'Toggle sort',
                              icon: const Icon(
                                Icons.swap_vert,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$_productivityScore% score  ·  $_streakDays day streak',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontSize: compact ? 13 : 14,
                              ),
                        ),
                        SizedBox(height: compact ? 10 : 12),
                        Row(
                          children: [
                            Expanded(
                              child: _InsightBlock(
                                label: 'Completed',
                                value: '${_tasks.length}',
                                icon: Icons.task_alt,
                                compact: compact,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _InsightBlock(
                                label: 'Streak',
                                value: '$_streakDays',
                                icon: Icons.local_fire_department,
                                compact: compact,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    textInputAction: TextInputAction.search,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search completed tasks',
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _WindowChip(
                        label: 'Today',
                        compact: compact,
                        selected: _window == _CompletedWindow.today,
                        onTap: () {
                          setState(() => _window = _CompletedWindow.today);
                          _load();
                        },
                      ),
                      _WindowChip(
                        label: 'This Week',
                        compact: compact,
                        selected: _window == _CompletedWindow.week,
                        onTap: () {
                          setState(() => _window = _CompletedWindow.week);
                          _load();
                        },
                      ),
                      _WindowChip(
                        label: 'All Time',
                        compact: compact,
                        selected: _window == _CompletedWindow.all,
                        onTap: () {
                          setState(() => _window = _CompletedWindow.all);
                          _load();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_tasks.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF334155)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.incomplete_circle_outlined,
                            size: 40,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No completed tasks in this window',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    )
                  else
                    ..._tasks.map((task) {
                      return TaskListCard(
                        task: task,
                        onToggleComplete: (value) async {
                          if (task.id == null) {
                            return;
                          }
                          await _database.applyTaskCompletion(
                            task: task,
                            isCompleted: value,
                          );
                          final refreshed = await _database.getTaskById(
                            task.id!,
                          );
                          if (refreshed != null && context.mounted) {
                            final settings = context
                                .read<AppSettingsController>();
                            await NotificationService.instance
                                .scheduleTaskReminder(
                                  task: refreshed,
                                  settings: settings,
                                );
                          }
                          await _load();
                        },
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

class _InsightBlock extends StatelessWidget {
  const _InsightBlock({
    required this.label,
    required this.value,
    required this.icon,
    required this.compact,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 8 : 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.2),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: compact ? 18 : 20),
          SizedBox(width: compact ? 6 : 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontSize: compact ? 15 : 17,
                ),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: compact ? 10 : 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WindowChip extends StatelessWidget {
  const _WindowChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.compact,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: compact ? 4 : 8),
      child: ChoiceChip(
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: AppTheme.brandTeal.withValues(alpha: 0.2),
      ),
    );
  }
}
