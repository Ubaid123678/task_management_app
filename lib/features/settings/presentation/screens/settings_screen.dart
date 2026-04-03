import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/notification_service.dart';
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
    final settings = context.watch<AppSettingsController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Appearance',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<ThemeMode>(
                    initialValue: settings.themeMode,
                    decoration: const InputDecoration(labelText: 'Theme mode'),
                    items: const [
                      DropdownMenuItem(
                        value: ThemeMode.system,
                        child: Text('System default'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.light,
                        child: Text('Light'),
                      ),
                      DropdownMenuItem(
                        value: ThemeMode.dark,
                        child: Text('Dark'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        settings.setThemeMode(value);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Notifications',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      if (_updatingNotifications)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable task reminders'),
                    subtitle: const Text(
                      'Alerts are scheduled for due date and time.',
                    ),
                    value: settings.notificationsEnabled,
                    onChanged: (value) async {
                      await settings.setNotificationsEnabled(value);
                      await _applyNotificationChanges(settings);
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<NotificationSoundOption>(
                    initialValue: settings.notificationSound,
                    decoration: const InputDecoration(
                      labelText: 'Notification sound',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: NotificationSoundOption.defaultTone,
                        child: Text('Default'),
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
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Task automation',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Auto-complete when due time passes'),
                    subtitle: const Text(
                      'When you reopen the app, overdue tasks are automatically completed.',
                    ),
                    value: settings.autoCompleteOnDue,
                    onChanged: (value) {
                      settings.setAutoCompleteOnDue(value);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
