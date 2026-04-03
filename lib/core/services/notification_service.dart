import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../../data/db/app_database.dart';
import '../../data/models/task.dart';
import '../../features/settings/presentation/controllers/app_settings_controller.dart';

class NotificationService {
  NotificationService._internal();

  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (kIsWeb) {
      return;
    }

    if (_initialized) {
      return;
    }

    tz.initializeTimeZones();
    await _configureLocalTimezone();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings();

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      ),
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestExactAlarmsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  Future<void> scheduleTaskReminder({
    required Task task,
    required AppSettingsController settings,
  }) async {
    if (kIsWeb) {
      return;
    }

    if (task.id == null) {
      return;
    }

    final due = task.dueDateTime;
    if (!settings.notificationsEnabled || due == null || task.isCompleted) {
      await cancelTaskReminder(task.id!);
      return;
    }

    final scheduleTime = tz.TZDateTime.from(due, tz.local);
    if (scheduleTime.isBefore(tz.TZDateTime.now(tz.local))) {
      await cancelTaskReminder(task.id!);
      return;
    }

    final playSound =
        settings.notificationSound != NotificationSoundOption.silent;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'task_due_channel',
        'Task Due Reminders',
        channelDescription: 'Notifications for upcoming task due times',
        importance: Importance.max,
        priority: Priority.high,
        playSound: playSound,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: playSound,
      ),
      macOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: playSound,
      ),
    );

    try {
      await _plugin.zonedSchedule(
        task.id!,
        'Task Reminder',
        task.title,
        scheduleTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: task.id.toString(),
      );
    } catch (_) {
      try {
        await _plugin.zonedSchedule(
          task.id!,
          'Task Reminder',
          task.title,
          scheduleTime,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: task.id.toString(),
        );
      } catch (_) {
        await cancelTaskReminder(task.id!);
      }
    }
  }

  Future<void> cancelTaskReminder(int taskId) async {
    if (kIsWeb) {
      return;
    }
    await _plugin.cancel(taskId);
  }

  Future<void> cancelAll() async {
    if (kIsWeb) {
      return;
    }
    await _plugin.cancelAll();
  }

  Future<void> rescheduleAllForActiveTasks({
    required AppDatabase database,
    required AppSettingsController settings,
  }) async {
    await cancelAll();

    if (!settings.notificationsEnabled) {
      return;
    }

    final tasks = await database.getActiveTasksWithDueDate();
    for (final task in tasks) {
      await scheduleTaskReminder(task: task, settings: settings);
    }
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final local = await FlutterTimezone.getLocalTimezone();
      final location = tz.getLocation(local);
      tz.setLocalLocation(location);
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }
}
