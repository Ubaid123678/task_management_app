import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/task.dart';

class TaskListCard extends StatelessWidget {
  const TaskListCard({
    super.key,
    required this.task,
    required this.onToggleComplete,
    this.onEdit,
    this.onDelete,
    this.onManageSubtasks,
  });

  final Task task;
  final ValueChanged<bool> onToggleComplete;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onManageSubtasks;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dueText = task.dueDateTime == null
        ? 'No due date'
        : DateFormat('EEE, dd MMM - hh:mm a').format(task.dueDateTime!);
    final isOverdue =
        task.dueDateTime != null &&
        !task.isCompleted &&
        task.dueDateTime!.isBefore(now);

    final progressPercent = (task.progress * 100)
        .clamp(0, 100)
        .toStringAsFixed(0);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                ),
                Checkbox(
                  value: task.isCompleted,
                  onChanged: (value) => onToggleComplete(value ?? false),
                ),
              ],
            ),
            if (task.description != null && task.description!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                task.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TagChip(
                  icon: Icons.schedule_outlined,
                  label: dueText,
                  isAlert: isOverdue,
                ),
                if (isOverdue)
                  const _TagChip(
                    icon: Icons.warning_amber_rounded,
                    label: 'OVERDUE',
                    isAlert: true,
                  ),
                if (task.repeatType != RepeatType.none)
                  _TagChip(
                    icon: Icons.repeat,
                    label: task.repeatType.name.toUpperCase(),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: task.progress.clamp(0, 1),
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  'Progress',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '$progressPercent%',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            if (onEdit != null ||
                onDelete != null ||
                onManageSubtasks != null) ...[
              const SizedBox(height: 6),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 4,
                children: [
                  if (onManageSubtasks != null)
                    TextButton.icon(
                      onPressed: onManageSubtasks,
                      icon: const Icon(Icons.checklist_rtl),
                      label: const Text('Subtasks'),
                    ),
                  if (onEdit != null)
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                  if (onDelete != null)
                    TextButton.icon(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Delete'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.icon,
    required this.label,
    this.isAlert = false,
  });

  final IconData icon;
  final String label;
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isAlert
            ? Theme.of(context).colorScheme.errorContainer
            : Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isAlert
                ? Theme.of(context).colorScheme.onErrorContainer
                : null,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: isAlert
                  ? Theme.of(context).colorScheme.onErrorContainer
                  : null,
              fontWeight: isAlert ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
