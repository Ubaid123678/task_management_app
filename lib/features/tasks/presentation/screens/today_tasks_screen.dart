import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/export_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../data/db/app_database.dart';
import '../../../../data/models/task.dart';
import '../../../settings/presentation/controllers/app_settings_controller.dart';
import '../widgets/task_form_sheet.dart';
import '../widgets/subtask_sheet.dart';
import '../widgets/task_list_card.dart';

class TodayTasksScreen extends StatefulWidget {
  const TodayTasksScreen({super.key});

  @override
  State<TodayTasksScreen> createState() => _TodayTasksScreenState();
}

class _TodayTasksScreenState extends State<TodayTasksScreen>
    with WidgetsBindingObserver {
  final AppDatabase _database = AppDatabase.instance;
  final ExportService _exportService = ExportService.instance;
  List<Task> _tasks = const <Task>[];
  bool _isLoading = true;
  Timer? _ticker;

  int get _highPriorityCount {
    final now = DateTime.now();
    return _tasks.where((task) {
      final due = task.dueDateTime;
      if (due == null) {
        return false;
      }
      return due.isBefore(now.add(const Duration(hours: 6)));
    }).length;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTasks();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      _loadTasks(showLoader: false);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadTasks(showLoader: false);
    }
  }

  Future<void> _loadTasks({bool showLoader = true}) async {
    if (showLoader && mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    await _runDueTaskAutomation();

    final tasks = await _database.getTodayTasks(DateTime.now());

    if (!mounted) {
      return;
    }

    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });
  }

  Future<void> _runDueTaskAutomation() async {
    final settings = context.read<AppSettingsController>();
    if (!settings.autoCompleteOnDue) {
      return;
    }

    final updatedTasks = await _database.processDueTasks(DateTime.now());
    if (updatedTasks.isEmpty) {
      return;
    }

    for (final task in updatedTasks) {
      await NotificationService.instance.scheduleTaskReminder(
        task: task,
        settings: settings,
      );
    }
  }

  Future<void> _openTaskForm([Task? task]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return TaskFormSheet(
          initialTask: task,
          onSave: (payload) async {
            Task savedTask;
            if (task == null) {
              final id = await _database.insertTask(payload);
              savedTask = payload.copyWith(id: id);
            } else {
              await _database.updateTask(payload);
              savedTask = payload;
            }
            await _syncTaskNotification(savedTask);
            await _loadTasks();
          },
        );
      },
    );
  }

  Future<void> _toggleTask(Task task, bool isCompleted) async {
    if (task.id == null) {
      return;
    }
    await _database.applyTaskCompletion(task: task, isCompleted: isCompleted);

    final refreshed = await _database.getTaskById(task.id!);
    if (refreshed != null) {
      await _syncTaskNotification(refreshed);
    }

    await _loadTasks();
  }

  Future<void> _openSubtasks(Task task) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SubtaskSheet(task: task, onChanged: _loadTasks);
      },
    );

    await _loadTasks();
  }

  Future<void> _deleteTask(Task task) async {
    if (task.id == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete task'),
          content: Text('Are you sure you want to delete "${task.title}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    await _database.deleteTask(task.id!);
    await NotificationService.instance.cancelTaskReminder(task.id!);
    await _loadTasks();
  }

  Future<void> _syncTaskNotification(Task task) async {
    final settings = context.read<AppSettingsController>();
    await NotificationService.instance.scheduleTaskReminder(
      task: task,
      settings: settings,
    );
  }

  Future<void> _openExportOptions() async {
    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ListTile(
                  title: Text('Export Tasks'),
                  subtitle: Text(
                    'Generate reports from all tasks in your database.',
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.table_view_outlined),
                  title: const Text('Export CSV'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _runExport(
                      (tasks) => _exportService.exportAndShareCsv(tasks),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf_outlined),
                  title: const Text('Export PDF'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _runExport(
                      (tasks) => _exportService.exportAndSharePdf(tasks),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Share by Email'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _runExport((tasks) => _exportService.shareByEmail(tasks));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _runExport(
    Future<void> Function(List<Task> tasks) action,
  ) async {
    final tasks = await _database.getAllTasks();
    if (!mounted) {
      return;
    }

    if (tasks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No tasks available to export.')),
      );
      return;
    }

    try {
      await action(tasks);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export failed. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTaskForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Task'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTasks,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 220,
              toolbarHeight: 68,
              backgroundColor: Theme.of(context).colorScheme.surface,
              title: const Text('Today Tasks'),
              actions: [
                IconButton(
                  onPressed: _openExportOptions,
                  icon: const Icon(Icons.ios_share_outlined),
                  tooltip: 'Export',
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.86),
                        Theme.of(
                          context,
                        ).colorScheme.secondary.withValues(alpha: 0.88),
                      ],
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 66),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Focus. Execute. Complete.',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(color: Colors.white, height: 1),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Plan your day with clarity and finish what matters.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (!_isLoading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Expanded(
                            child: _MetricTile(
                              label: 'Due Today',
                              value: _tasks.length.toString(),
                              icon: Icons.today,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MetricTile(
                              label: 'Next 6 Hours',
                              value: _highPriorityCount.toString(),
                              icon: Icons.bolt,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_tasks.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.event_available, size: 62),
                        const SizedBox(height: 14),
                        Text(
                          'No tasks scheduled for today',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap Add Task to plan your day and stay ahead.',
                          style: Theme.of(context).textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverList.builder(
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  final task = _tasks[index];
                  return TaskListCard(
                    task: task,
                    onToggleComplete: (value) => _toggleTask(task, value),
                    onManageSubtasks: () => _openSubtasks(task),
                    onEdit: () => _openTaskForm(task),
                    onDelete: () => _deleteTask(task),
                  );
                },
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 90)),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
