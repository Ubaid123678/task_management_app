import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/export_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/db/app_database.dart';
import '../../../../data/models/task.dart';
import '../../../settings/presentation/controllers/app_settings_controller.dart';
import '../widgets/subtask_sheet.dart';
import '../widgets/task_form_sheet.dart';
import '../widgets/task_list_card.dart';

enum _TodayFilter { all, overdue, dueSoon, recurring }

class TodayTasksScreen extends StatefulWidget {
  const TodayTasksScreen({super.key});

  @override
  State<TodayTasksScreen> createState() => _TodayTasksScreenState();
}

class _TodayTasksScreenState extends State<TodayTasksScreen>
    with WidgetsBindingObserver {
  final AppDatabase _database = AppDatabase.instance;
  final ExportService _exportService = ExportService.instance;
  final TextEditingController _searchController = TextEditingController();

  List<Task> _tasks = const <Task>[];
  bool _isLoading = true;
  bool _includeBacklog = false;
  _TodayFilter _todayFilter = _TodayFilter.all;
  Timer? _ticker;
  StreamSubscription<int>? _tasksChangedSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadTasks();
    _tasksChangedSub = _database.tasksChanged.listen((_) {
      if (!mounted) {
        return;
      }
      _loadTasks(showLoader: false);
    });
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      _loadTasks(showLoader: false);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _tasksChangedSub?.cancel();
    _searchController.dispose();
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

    final tasks = await _database.getAllTasks();
    final active =
        tasks.where((task) => !task.isCompleted).toList(growable: false)
          ..sort((a, b) {
            final dueA = a.dueDateTime;
            final dueB = b.dueDateTime;
            if (dueA == null && dueB == null) {
              return b.updatedAt.compareTo(a.updatedAt);
            }
            if (dueA == null) {
              return 1;
            }
            if (dueB == null) {
              return -1;
            }
            return dueA.compareTo(dueB);
          });

    if (!mounted) {
      return;
    }

    setState(() {
      _tasks = active;
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

  List<Task> _baseScopedTasks() {
    if (_includeBacklog) {
      return _tasks;
    }

    final now = DateTime.now();
    final dayStart = DateTime(now.year, now.month, now.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    return _tasks
        .where((task) {
          final due = task.dueDateTime;
          if (due == null) {
            return false;
          }
          return !due.isBefore(dayStart) && due.isBefore(dayEnd);
        })
        .toList(growable: false);
  }

  List<Task> _visibleTasks() {
    final now = DateTime.now();
    final search = _searchController.text.trim().toLowerCase();

    return _baseScopedTasks()
        .where((task) {
          if (search.isNotEmpty) {
            final matchTitle = task.title.toLowerCase().contains(search);
            final matchDesc =
                task.description?.toLowerCase().contains(search) ?? false;
            if (!matchTitle && !matchDesc) {
              return false;
            }
          }

          switch (_todayFilter) {
            case _TodayFilter.all:
              return true;
            case _TodayFilter.overdue:
              final due = task.dueDateTime;
              return due != null && due.isBefore(now);
            case _TodayFilter.dueSoon:
              final due = task.dueDateTime;
              if (due == null) {
                return false;
              }
              return due.isAfter(now) &&
                  due.isBefore(now.add(const Duration(hours: 6)));
            case _TodayFilter.recurring:
              return task.repeatType != RepeatType.none;
          }
        })
        .toList(growable: false);
  }

  Map<String, List<Task>> _groupedByWindow(List<Task> source) {
    final grouped = <String, List<Task>>{};

    for (final task in source) {
      final bucket = _bucketFor(task);
      grouped.putIfAbsent(bucket, () => <Task>[]).add(task);
    }

    return grouped;
  }

  String _bucketFor(Task task) {
    final due = task.dueDateTime;
    if (due == null) {
      return 'Backlog';
    }

    if (due.hour < 12) {
      return 'Morning';
    }
    if (due.hour < 17) {
      return 'Afternoon';
    }
    return 'Evening';
  }

  int get _overdueCount {
    final now = DateTime.now();
    return _baseScopedTasks().where((task) {
      final due = task.dueDateTime;
      return due != null && due.isBefore(now);
    }).length;
  }

  int get _dueSoonCount {
    final now = DateTime.now();
    return _baseScopedTasks().where((task) {
      final due = task.dueDateTime;
      if (due == null) {
        return false;
      }
      return due.isAfter(now) &&
          due.isBefore(now.add(const Duration(hours: 6)));
    }).length;
  }

  Future<void> _openTaskForm([Task? task]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
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
          content: Text('Delete "${task.title}" from your board?'),
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
                  subtitle: Text('Generate reports from your task database.'),
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
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 390;
    final visibleTasks = _visibleTasks();
    final groupedTasks = _groupedByWindow(visibleTasks);
    final scopedCount = _baseScopedTasks().length;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTaskForm(),
        tooltip: 'Create task',
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTasks,
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: compact ? 172 : 186,
              toolbarHeight: compact ? 52 : 56,
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text('Focus Board'),
              actions: [
                IconButton(
                  onPressed: _openExportOptions,
                  icon: const Icon(Icons.ios_share_outlined),
                  tooltip: 'Export',
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.brandTeal,
                        AppTheme.brandCoral.withValues(alpha: 0.95),
                      ],
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 14 : 16,
                        0,
                        compact ? 14 : 16,
                        compact ? 42 : 50,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Shape your day',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineMedium
                                      ?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: compact ? 26 : 30,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Smart view of today, urgency, and backlog.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                        fontSize: compact ? 13 : 14,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: compact ? 58 : 66,
                            height: compact ? 58 : 66,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(
                                compact ? 14 : 16,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$scopedCount',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: compact ? 24 : 28,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: Column(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final stacked = constraints.maxWidth < 360;
                        if (stacked) {
                          return Column(
                            children: [
                              _MetricCard(
                                label: 'Overdue',
                                value: '$_overdueCount',
                                color: AppTheme.errorColor,
                                icon: Icons.warning_amber_rounded,
                                compact: true,
                              ),
                              const SizedBox(height: 8),
                              _MetricCard(
                                label: 'Due in 6h',
                                value: '$_dueSoonCount',
                                color: AppTheme.warningColor,
                                icon: Icons.flash_on,
                                compact: true,
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(
                              child: _MetricCard(
                                label: 'Overdue',
                                value: '$_overdueCount',
                                color: AppTheme.errorColor,
                                icon: Icons.warning_amber_rounded,
                                compact: compact,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _MetricCard(
                                label: 'Due in 6h',
                                value: '$_dueSoonCount',
                                color: AppTheme.warningColor,
                                icon: Icons.flash_on,
                                compact: compact,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      textInputAction: TextInputAction.search,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Search your active tasks',
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _FilterChipButton(
                            label: 'All',
                            compact: compact,
                            selected: _todayFilter == _TodayFilter.all,
                            onTap: () =>
                                setState(() => _todayFilter = _TodayFilter.all),
                          ),
                          _FilterChipButton(
                            label: 'Overdue',
                            compact: compact,
                            selected: _todayFilter == _TodayFilter.overdue,
                            onTap: () => setState(
                              () => _todayFilter = _TodayFilter.overdue,
                            ),
                          ),
                          _FilterChipButton(
                            label: 'Due Soon',
                            compact: compact,
                            selected: _todayFilter == _TodayFilter.dueSoon,
                            onTap: () => setState(
                              () => _todayFilter = _TodayFilter.dueSoon,
                            ),
                          ),
                          _FilterChipButton(
                            label: 'Recurring',
                            compact: compact,
                            selected: _todayFilter == _TodayFilter.recurring,
                            onTap: () => setState(
                              () => _todayFilter = _TodayFilter.recurring,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile.adaptive(
                      value: _includeBacklog,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Include backlog items'),
                      subtitle: const Text(
                        'Show tasks without a due date and outside today',
                      ),
                      onChanged: (value) =>
                          setState(() => _includeBacklog = value),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (visibleTasks.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: BoxDecoration(
                            color: AppTheme.brandTeal.withValues(alpha: 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.task_alt,
                            color: AppTheme.brandTeal,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No tasks in this view',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Adjust your filters or create a new task to get moving.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else ...[
              for (final entry in groupedTasks.entries) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                    child: Text(
                      entry.key,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
                SliverList.builder(
                  itemCount: entry.value.length,
                  itemBuilder: (context, index) {
                    final task = entry.value[index];
                    return TaskListCard(
                      task: task,
                      onToggleComplete: (value) => _toggleTask(task, value),
                      onManageSubtasks: () => _openSubtasks(task),
                      onEdit: () => _openTaskForm(task),
                      onDelete: () => _deleteTask(task),
                    );
                  },
                ),
              ],
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 88)),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    this.compact = false,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(compact ? 10 : 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 30 : 34,
            height: compact ? 30 : 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: compact ? 16 : 18),
          ),
          SizedBox(width: compact ? 8 : 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: color,
                  fontSize: compact ? 16 : 18,
                ),
              ),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(fontSize: compact ? 10 : 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
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
        labelPadding: EdgeInsets.symmetric(horizontal: compact ? 4 : 6),
        label: Text(label, overflow: TextOverflow.visible, softWrap: false),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
