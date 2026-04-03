import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';
import 'core/services/notification_service.dart';
import 'data/db/app_database.dart';
import 'features/settings/presentation/controllers/app_settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  if (!kIsWeb) {
    await AppDatabase.instance.database;
  }

  final settingsController = await AppSettingsController.load();

  if (!kIsWeb) {
    await NotificationService.instance.initialize();
    await NotificationService.instance.rescheduleAllForActiveTasks(
      database: AppDatabase.instance,
      settings: settingsController,
    );
  }

  runApp(TaskManagementApp(settingsController: settingsController));
}
