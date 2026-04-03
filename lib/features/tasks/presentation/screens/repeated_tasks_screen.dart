import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_theme.dart';
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
  Timer? _searchDebounce;
  StreamSubscription<int>? _tasksChangedSub;

  List<Task> _tasks = const <Task>[];
  bool _isLoading = true;
  _RepeatStatusFilter _statusFilter = _RepeatStatusFilter.active;
  RepeatType? _typeFilter;

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

  int get _dailyCount =>
      _tasks.where((task) => task.repeatType == RepeatType.daily).length;
  int get _weeklyCount =>
      _tasks.where((task) => task.repeatType == RepeatType.weekly).length;
  int get _intervalCount =>
      _tasks.where((task) => task.repeatType == RepeatType.interval).length;

  String _preferredCycleText() {
    final counts = <String, int>{
      'Daily': _dailyCount,
      'Weekly': _weeklyCount,
      'Interval': _intervalCount,
    };

    var bestKey = 'Daily';
    var bestValue = -1;
    counts.forEach((key, value) {
      if (value > bestValue) {
        bestKey = key;
        bestValue = value;
      }
    });

    return bestValue <= 0
        ? 'No recurring pattern yet'
        : '$bestKey cadence is dominant';
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 390;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<AppSettingsController>();

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
                        colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recurring Engine',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontSize: compact ? 18 : 20,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _preferredCycleText(),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.92),
                                fontSize: compact ? 13 : 14,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          settings.weekStartsOnMonday
                              ? 'Week grid: Monday first'
                              : 'Week grid: Sunday first',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                        ),
                        SizedBox(height: compact ? 10 : 12),
                        Row(
                          children: [
                            Expanded(
                              child: _CountBlock(
                                label: 'Daily',
                                value: _dailyCount.toString(),
                                compact: compact,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _CountBlock(
                                label: 'Weekly',
                                value: _weeklyCount.toString(),
                                compact: compact,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _CountBlock(
                                label: 'Interval',
                                value: _intervalCount.toString(),
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
                      hintText: 'Search recurring tasks',
                    ),
                  ),
                  const SizedBox(height: 10),
                  _FilterRow(
                    title: 'Status',
                    compact: compact,
                    children: [
                      _FilterChip(
                        label: 'Active',
                        compact: compact,
                        selected: _statusFilter == _RepeatStatusFilter.active,
                        onTap: () {
                          setState(
                            () => _statusFilter = _RepeatStatusFilter.active,
                          );
                          _load();
                        },
                      ),
                      _FilterChip(
                        label: 'Completed',
                        compact: compact,
                        selected:
                            _statusFilter == _RepeatStatusFilter.completed,
                        onTap: () {
                          setState(
                            () => _statusFilter = _RepeatStatusFilter.completed,
                          );
                          _load();
                        },
                      ),
                      _FilterChip(
                        label: 'All',
                        compact: compact,
                        selected: _statusFilter == _RepeatStatusFilter.all,
                        onTap: () {
                          setState(
                            () => _statusFilter = _RepeatStatusFilter.all,
                          );
                          _load();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _FilterRow(
                    title: 'Type',
                    compact: compact,
                    children: [
                      _FilterChip(
                        label: 'All Types',
                        compact: compact,
                        selected: _typeFilter == null,
                        onTap: () {
                          setState(() => _typeFilter = null);
                          _load();
                        },
                      ),
                      _FilterChip(
                        label: 'Daily',
                        compact: compact,
                        selected: _typeFilter == RepeatType.daily,
                        onTap: () {
                          setState(() => _typeFilter = RepeatType.daily);
                          _load();
                        },
                      ),
                      _FilterChip(
                        label: 'Weekly',
                        compact: compact,
                        selected: _typeFilter == RepeatType.weekly,
                        onTap: () {
                          setState(() => _typeFilter = RepeatType.weekly);
                          _load();
                        },
                      ),
                      _FilterChip(
                        label: 'Interval',
                        compact: compact,
                        selected: _typeFilter == RepeatType.interval,
                        onTap: () {
                          setState(() => _typeFilter = RepeatType.interval);
                          _load();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
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
                            Icons.repeat_rounded,
                            size: 40,
                            color: AppTheme.brandTeal,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No recurring tasks in this view',
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

class _CountBlock extends StatelessWidget {
  const _CountBlock({
    required this.label,
    required this.value,
    required this.compact,
  });

  final String label;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withValues(alpha: 0.2),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
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
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.title,
    required this.children,
    required this.compact,
  });

  final String title;
  final List<Widget> children;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 6),
        Wrap(spacing: compact ? 6 : 8, runSpacing: 8, children: children),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
      ),
    );
  }
}
