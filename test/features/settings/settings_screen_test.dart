import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:task_managemnt_app/features/settings/presentation/controllers/app_settings_controller.dart';
import 'package:task_managemnt_app/features/settings/presentation/screens/settings_screen.dart';

void main() {
  testWidgets('Settings screen renders appearance and notifications', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final controller = await AppSettingsController.load();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Theme mode'), findsOneWidget);
    expect(find.text('Enable task reminders'), findsOneWidget);
  });
}
