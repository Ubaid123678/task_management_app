import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_constants.dart';
import 'features/home/presentation/screens/home_shell_screen.dart';
import 'features/onboarding/presentation/screens/app_intro_screen.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/controllers/app_settings_controller.dart';

class TaskManagementApp extends StatelessWidget {
  const TaskManagementApp({super.key, required this.settingsController});

  final AppSettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: settingsController,
      child: Consumer<AppSettingsController>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.themeMode,
            home: settings.hasSeenIntro
                ? const HomeShellScreen()
                : AppIntroScreen(
                    onDone: () async {
                      await settings.markIntroSeen();
                    },
                  ),
            onGenerateRoute: AppRouter.onGenerateRoute,
          );
        },
      ),
    );
  }
}
