import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
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
    final compact = MediaQuery.sizeOf(context).width < 390;
    final now = DateTime.now();
    final due = task.dueDateTime;
    final isOverdue = due != null && !task.isCompleted && due.isBefore(now);
    final dueText = due == null
        ? 'No due date'
        : DateFormat('EEE, dd MMM - hh:mm a').format(due);

    final progressPercent = (task.progress * 100)
        .clamp(0, 100)
        .toStringAsFixed(0);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contentColor = isDark
        ? const Color(0xFFE2E8F0)
        : const Color(0xFF1F2937);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 18 : 20),
        border: Border.all(color: borderColor, width: 1),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF0F172A), Color(0xFF1E293B)]
              : const [Colors.white, Color(0xFFF8FAFC)],
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(compact ? 18 : 20),
          child: Padding(
            padding: EdgeInsets.all(compact ? 12 : 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Transform.scale(
                      scale: compact ? 0.95 : 1.0,
                      child: Checkbox(
                        value: task.isCompleted,
                        onChanged: (value) => onToggleComplete(value ?? false),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        side: BorderSide(color: borderColor, width: 1.2),
                      ),
                    ),
                    SizedBox(width: compact ? 6 : 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: task.isCompleted
                                      ? subColor
                                      : contentColor,
                                  fontSize: compact ? 16 : 17,
                                  decoration: task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : TextDecoration.none,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (task.description != null &&
                              task.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              task.description!,
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(color: subColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: compact ? 6 : 8),
                    Container(
                      width: compact ? 8 : 10,
                      height: compact ? 34 : 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: _getProgressColor(task.progress.clamp(0, 1)),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: compact ? 10 : 12),
                Wrap(
                  spacing: compact ? 6 : 8,
                  runSpacing: 8,
                  children: [
                    _TagPill(
                      icon: Icons.schedule_outlined,
                      label: dueText,
                      isAlert: isOverdue,
                    ),
                    if (isOverdue)
                      const _TagPill(
                        icon: Icons.warning_amber_rounded,
                        label: 'Overdue',
                        isAlert: true,
                      ),
                    if (task.repeatType != RepeatType.none)
                      _TagPill(icon: Icons.repeat, label: task.repeatType.name),
                  ],
                ),
                SizedBox(height: compact ? 10 : 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        Text(
                          '$progressPercent%',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: _getProgressColor(
                                  double.parse(progressPercent) / 100,
                                ),
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: compact ? 5 : 6,
                        value: task.progress.clamp(0, 1),
                        backgroundColor: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getProgressColor(task.progress.clamp(0, 1)),
                        ),
                      ),
                    ),
                  ],
                ),
                if (onEdit != null ||
                    onDelete != null ||
                    onManageSubtasks != null) ...[
                  SizedBox(height: compact ? 8 : 10),
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (onManageSubtasks != null)
                        _ActionChipButton(
                          icon: Icons.checklist_rtl,
                          label: 'Subtasks',
                          onPressed: onManageSubtasks!,
                        ),
                      if (onEdit != null)
                        _ActionChipButton(
                          icon: Icons.edit_outlined,
                          label: 'Edit',
                          onPressed: onEdit!,
                        ),
                      if (onDelete != null)
                        _ActionChipButton(
                          icon: Icons.delete_outline,
                          label: 'Delete',
                          isDestructive: true,
                          onPressed: onDelete!,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) return AppTheme.successColor;
    if (progress >= 0.75) return const Color(0xFF3B82F6);
    if (progress >= 0.5) return const Color(0xFF06B6D4);
    if (progress >= 0.25) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({
    required this.icon,
    required this.label,
    this.isAlert = false,
  });

  final IconData icon;
  final String label;
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: isAlert
            ? AppTheme.errorColor.withValues(alpha: isDark ? 0.25 : 0.1)
            : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isAlert
              ? AppTheme.errorColor.withValues(alpha: 0.3)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: isAlert
                ? AppTheme.errorColor
                : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B)),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: isAlert ? FontWeight.w700 : FontWeight.w600,
              color: isAlert
                  ? AppTheme.errorColor
                  : (isDark
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFF334155)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChipButton extends StatelessWidget {
  const _ActionChipButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? AppTheme.errorColor
        : Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FilledButton.tonalIcon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14),
      style: FilledButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        foregroundColor: color,
        backgroundColor: isDark
            ? const Color(0xFF334155).withValues(alpha: 0.8)
            : color.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      label: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
