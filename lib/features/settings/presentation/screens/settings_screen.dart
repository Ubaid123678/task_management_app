import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/db/app_database.dart';
import '../controllers/app_settings_controller.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _updatingNotifications = false;

  Future<void> _applyNotificationChanges(AppSettingsController settings) async {
    setState(() {
      _updatingNotifications = true;
    });

    await NotificationService.instance.rescheduleAllForActiveTasks(
      database: AppDatabase.instance,
      settings: settings,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _updatingNotifications = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final compact = screenWidth < 390;
    final settings = context.watch<AppSettingsController>();

    return Scaffold(
      body: ListView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(12, compact ? 8 : 10, 12, 92),
        children: [
          _SettingsHero(
            title: 'Control Center',
            subtitle: 'Tune your workflow, automation, and reminders.',
            compact: compact,
            trailing: _updatingNotifications
                ? SizedBox(
                    width: compact ? 18 : 20,
                    height: compact ? 18 : 20,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(
                    Icons.tune,
                    color: Colors.white,
                    size: compact ? 18 : 20,
                  ),
          ),
          const SizedBox(height: 12),
          _SettingsSection(
            icon: Icons.palette_outlined,
            title: 'Appearance',
            compact: compact,
            child: DropdownButtonFormField<ThemeMode>(
              initialValue: settings.themeMode,
              decoration: const InputDecoration(labelText: 'Theme mode'),
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('System default'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text('Light mode'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text('Dark mode'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  settings.setThemeMode(value);
                }
              },
            ),
          ),
          const SizedBox(height: 10),
          _SettingsSection(
            icon: Icons.notifications_active_outlined,
            title: 'Notifications',
            compact: compact,
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable task reminders'),
                  subtitle: const Text('Get alerts at scheduled due times.'),
                  value: settings.notificationsEnabled,
                  onChanged: (value) async {
                    await settings.setNotificationsEnabled(value);
                    await _applyNotificationChanges(settings);
                  },
                ),
                DropdownButtonFormField<NotificationSoundOption>(
                  initialValue: settings.notificationSound,
                  decoration: const InputDecoration(
                    labelText: 'Notification sound',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: NotificationSoundOption.defaultTone,
                      child: Text('Default tone'),
                    ),
                    DropdownMenuItem(
                      value: NotificationSoundOption.silent,
                      child: Text('Silent'),
                    ),
                  ],
                  onChanged: settings.notificationsEnabled
                      ? (value) async {
                          if (value == null) {
                            return;
                          }
                          await settings.setNotificationSound(value);
                          await _applyNotificationChanges(settings);
                        }
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SettingsSection(
            icon: Icons.auto_mode_outlined,
            title: 'Task Automation',
            compact: compact,
            child: Column(
              children: [
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Auto-complete overdue tasks'),
                  subtitle: const Text(
                    'Automatically complete due tasks in background checks.',
                  ),
                  value: settings.autoCompleteOnDue,
                  onChanged: (value) => settings.setAutoCompleteOnDue(value),
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Week starts on Monday'),
                  subtitle: const Text('Affects weekly insights and grouping.'),
                  value: settings.weekStartsOnMonday,
                  onChanged: (value) => settings.setWeekStartsOnMonday(value),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _SettingsSection(
            icon: Icons.info_outline,
            title: 'About This Build',
            compact: compact,
            child: Row(
              children: [
                Icon(
                  Icons.bolt,
                  color: AppTheme.brandTeal,
                  size: compact ? 18 : 20,
                ),
                SizedBox(width: compact ? 6 : 8),
                Expanded(
                  child: Text(
                    'Task Orbit redesign with smart filters, streak metrics, and recurring insights.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsHero extends StatelessWidget {
  const _SettingsHero({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.compact,
  });

  final String title;
  final String subtitle;
  final Widget trailing;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontSize: compact ? 18 : 20,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: compact ? 13 : 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.child,
    required this.compact,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.brandTeal, size: compact ? 18 : 20),
              SizedBox(width: compact ? 6 : 8),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          SizedBox(height: compact ? 8 : 10),
          child,
        ],
      ),
    );
  }
}
