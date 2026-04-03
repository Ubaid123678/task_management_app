import 'package:flutter/material.dart';

import '../../features/home/presentation/screens/home_shell_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/tasks/presentation/screens/completed_tasks_screen.dart';
import '../../features/tasks/presentation/screens/repeated_tasks_screen.dart';
import '../../features/tasks/presentation/screens/today_tasks_screen.dart';
import 'app_routes.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeShellScreen());
      case AppRoutes.todayTasks:
        return MaterialPageRoute(builder: (_) => const TodayTasksScreen());
      case AppRoutes.completedTasks:
        return MaterialPageRoute(builder: (_) => const CompletedTasksScreen());
      case AppRoutes.repeatedTasks:
        return MaterialPageRoute(builder: (_) => const RepeatedTasksScreen());
      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Route not found'))),
        );
    }
  }
}
