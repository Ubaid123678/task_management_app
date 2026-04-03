import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/db/app_database.dart';
import '../../../settings/presentation/controllers/app_settings_controller.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../tasks/presentation/screens/completed_tasks_screen.dart';
import '../../../tasks/presentation/screens/repeated_tasks_screen.dart';
import '../../../tasks/presentation/screens/today_tasks_screen.dart';

class HomeShellScreen extends StatefulWidget {
  const HomeShellScreen({super.key});

  @override
  State<HomeShellScreen> createState() => _HomeShellScreenState();
}

class _HomeShellScreenState extends State<HomeShellScreen> {
  int _selectedIndex = 0;
  final AppDatabase _database = AppDatabase.instance;
  Timer? _dueTicker;
  bool _isDueAutomationRunning = false;

  static const List<Widget> _screens = <Widget>[
    TodayTasksScreen(),
    CompletedTasksScreen(),
    RepeatedTasksScreen(),
    SettingsScreen(),
  ];

  static const List<String> _labels = <String>['Focus', 'Wins', 'Loops', 'Lab'];

  static const List<IconData> _icons = <IconData>[
    Icons.radar_outlined,
    Icons.emoji_events_outlined,
    Icons.sync_alt,
    Icons.tune,
  ];

  @override
  void initState() {
    super.initState();
    _runDueAutomation();
    _dueTicker = Timer.periodic(const Duration(seconds: 15), (_) {
      _runDueAutomation();
    });
  }

  @override
  void dispose() {
    _dueTicker?.cancel();
    super.dispose();
  }

  Future<void> _runDueAutomation() async {
    if (!mounted || _isDueAutomationRunning) {
      return;
    }

    _isDueAutomationRunning = true;
    try {
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
    } finally {
      _isDueAutomationRunning = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 390;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (isDark ? const Color(0xFF0F172A) : const Color(0xFFE6FFFB))
                        .withValues(alpha: 0.65),
                    isDark ? const Color(0xFF111827) : const Color(0xFFFDFBF7),
                  ],
                ),
              ),
            ),
          ),
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    12,
                    compact ? 4 : 6,
                    12,
                    compact ? 4 : 6,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: compact ? 34 : 38,
                        height: compact ? 34 : 38,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                          ),
                        ),
                        child: Icon(
                          Icons.checklist_rounded,
                          color: Colors.white,
                          size: compact ? 18 : 20,
                        ),
                      ),
                      SizedBox(width: compact ? 8 : 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Task Orbit',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              _labels[_selectedIndex],
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: compact ? 8 : 9,
                          vertical: compact ? 4 : 5,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: AppTheme.brandCoral.withValues(alpha: 0.14),
                        ),
                        child: Text(
                          '${_selectedIndex + 1}/4',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: AppTheme.brandCoral,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: IndexedStack(index: _selectedIndex, children: _screens),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: SafeArea(
          top: false,
          child: _FloatingDock(
            selectedIndex: _selectedIndex,
            labels: _labels,
            icons: _icons,
            compact: compact,
            onChanged: (index) => setState(() => _selectedIndex = index),
          ),
        ),
      ),
    );
  }
}

class _FloatingDock extends StatelessWidget {
  const _FloatingDock({
    required this.selectedIndex,
    required this.labels,
    required this.icons,
    required this.compact,
    required this.onChanged,
  });

  final int selectedIndex;
  final List<String> labels;
  final List<IconData> icons;
  final bool compact;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 20 : 24),
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: List<Widget>.generate(labels.length, (index) {
          final selected = index == selectedIndex;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onChanged(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                padding: EdgeInsets.symmetric(vertical: compact ? 8 : 10),
                margin: EdgeInsets.all(compact ? 5 : 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(compact ? 14 : 16),
                  gradient: selected
                      ? const LinearGradient(
                          colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                        )
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icons[index],
                      size: compact ? 20 : 22,
                      color: selected
                          ? Colors.white
                          : (isDark
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF64748B)),
                    ),
                    SizedBox(height: compact ? 2 : 3),
                    Text(
                      labels[index],
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: compact ? 10 : 11,
                        color: selected
                            ? Colors.white
                            : (isDark
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF64748B)),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
