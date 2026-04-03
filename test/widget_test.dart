import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:task_managemnt_app/features/tasks/presentation/widgets/task_list_card.dart';
import 'package:task_managemnt_app/data/models/task.dart';

void main() {
  testWidgets('Task card renders title and progress', (
    WidgetTester tester,
  ) async {
    final now = DateTime.now();
    final task = Task(
      id: 1,
      title: 'Design dashboard',
      description: 'Finalize task dashboard UI',
      dueDateTime: now,
      progress: 0.5,
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TaskListCard(task: task, onToggleComplete: (_) {}),
        ),
      ),
    );

    expect(find.text('Design dashboard'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
  });
}
