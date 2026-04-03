import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/notification_service.dart';
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
  List<Task> _tasks = const <Task>[];
  bool _isLoading = true;
  bool _newestFirst = true;
  _CompletedWindow _window = _CompletedWindow.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
    });
    final tasks = await _database.getCompletedTasks(
      search: _searchController.text,
      newestFirst: _newestFirst,
    );

    final filtered = _applyWindowFilter(tasks);

    if (!mounted) {
      return;
    }
    setState(() {
      _tasks = filtered;
      _isLoading = false;
    });
  }

  List<Task> _applyWindowFilter(List<Task> tasks) {
    if (_window == _CompletedWindow.all) {
      return tasks;
    }

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));

    return tasks
        .where((task) {
          final updated = task.updatedAt;
          if (_window == _CompletedWindow.today) {
            return updated.isAfter(todayStart);
          }
          return updated.isAfter(weekStart);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Completed Tasks')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
          ? Center(
              child: Text(
                'No completed tasks yet.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            )
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_rounded),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${_tasks.length} completed task(s)',
                                style: Theme.of(context).textTheme.titleMedium,
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
                              icon: Icon(
                                _newestFirst
                                    ? Icons.south_rounded
                                    : Icons.north_rounded,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => _load(),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search completed tasks',
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Today'),
                          selected: _window == _CompletedWindow.today,
                          onSelected: (_) {
                            setState(() {
                              _window = _CompletedWindow.today;
                            });
                            _load();
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('This Week'),
                          selected: _window == _CompletedWindow.week,
                          onSelected: (_) {
                            setState(() {
                              _window = _CompletedWindow.week;
                            });
                            _load();
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _window == _CompletedWindow.all,
                          onSelected: (_) {
                            setState(() {
                              _window = _CompletedWindow.all;
                            });
                            _load();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final task in _tasks)
                    TaskListCard(
                      task: task,
                      onToggleComplete: (value) async {
                        if (task.id == null) {
                          return;
                        }
                        await _database.applyTaskCompletion(
                          task: task,
                          isCompleted: value,
                        );
                        final refreshed = await _database.getTaskById(task.id!);
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
                    ),
                ],
              ),
            ),
    );
  }
}
