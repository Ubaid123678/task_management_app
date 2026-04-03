import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/notification_service.dart';
import '../../../../data/db/app_database.dart';
import '../../../../data/models/task.dart';
import '../../../settings/presentation/controllers/app_settings_controller.dart';
import '../widgets/task_list_card.dart';

enum _RepeatStatusFilter { active, completed, all }

class RepeatedTasksScreen extends StatefulWidget {
  const RepeatedTasksScreen({super.key});

  @override
  State<RepeatedTasksScreen> createState() => _RepeatedTasksScreenState();
}

class _RepeatedTasksScreenState extends State<RepeatedTasksScreen> {
  final AppDatabase _database = AppDatabase.instance;
  final TextEditingController _searchController = TextEditingController();
  List<Task> _tasks = const <Task>[];
  bool _isLoading = true;
  _RepeatStatusFilter _statusFilter = _RepeatStatusFilter.active;
  RepeatType? _typeFilter;

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
    final tasks = await _database.getRepeatedTasks(
      isCompleted: _statusFilter == _RepeatStatusFilter.all
          ? null
          : _statusFilter == _RepeatStatusFilter.completed,
      repeatType: _typeFilter,
      search: _searchController.text,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Repeated Tasks')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
          ? Center(
              child: Text(
                'No repeated tasks configured yet.',
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
                            const Icon(Icons.repeat_rounded),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${_tasks.length} repeated task(s)',
                                style: Theme.of(context).textTheme.titleMedium,
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
                        hintText: 'Search repeated tasks',
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
                          label: const Text('Active'),
                          selected: _statusFilter == _RepeatStatusFilter.active,
                          onSelected: (_) {
                            setState(() {
                              _statusFilter = _RepeatStatusFilter.active;
                            });
                            _load();
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Completed'),
                          selected:
                              _statusFilter == _RepeatStatusFilter.completed,
                          onSelected: (_) {
                            setState(() {
                              _statusFilter = _RepeatStatusFilter.completed;
                            });
                            _load();
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _statusFilter == _RepeatStatusFilter.all,
                          onSelected: (_) {
                            setState(() {
                              _statusFilter = _RepeatStatusFilter.all;
                            });
                            _load();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('All Types'),
                          selected: _typeFilter == null,
                          onSelected: (_) {
                            setState(() {
                              _typeFilter = null;
                            });
                            _load();
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Daily'),
                          selected: _typeFilter == RepeatType.daily,
                          onSelected: (_) {
                            setState(() {
                              _typeFilter = RepeatType.daily;
                            });
                            _load();
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Weekly'),
                          selected: _typeFilter == RepeatType.weekly,
                          onSelected: (_) {
                            setState(() {
                              _typeFilter = RepeatType.weekly;
                            });
                            _load();
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Interval'),
                          selected: _typeFilter == RepeatType.interval,
                          onSelected: (_) {
                            setState(() {
                              _typeFilter = RepeatType.interval;
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
