import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/task.dart';

class TaskFormSheet extends StatefulWidget {
  const TaskFormSheet({super.key, this.initialTask, required this.onSave});

  final Task? initialTask;
  final ValueChanged<Task> onSave;

  @override
  State<TaskFormSheet> createState() => _TaskFormSheetState();
}

class _TaskFormSheetState extends State<TaskFormSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late RepeatType _repeatType;
  late DateTime _selectedDateTime;
  late bool _hasDueDate;
  late List<int> _repeatDays;
  int? _repeatInterval;
  final _formKey = GlobalKey<FormState>();

  bool get _isEdit => widget.initialTask != null;

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(
      text: task?.description ?? '',
    );
    _repeatType = task?.repeatType ?? RepeatType.none;
    _hasDueDate = task?.dueDateTime != null;
    _selectedDateTime =
        task?.dueDateTime ?? DateTime.now().add(const Duration(hours: 1));
    _repeatDays = List<int>.from(task?.repeatDays ?? const <int>[]);
    _repeatInterval = task?.repeatInterval;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    if (!_hasDueDate) {
      return;
    }

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (!mounted || pickedDate == null) {
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
    );

    if (!mounted || pickedTime == null) {
      return;
    }

    setState(() {
      _selectedDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  void _applyPreset(Duration offset, String titleHint, String descriptionHint) {
    final now = DateTime.now();
    setState(() {
      _hasDueDate = true;
      _selectedDateTime = now.add(offset);
    });

    if (_titleController.text.trim().isEmpty) {
      _titleController.text = titleHint;
    }

    if (_descriptionController.text.trim().isEmpty) {
      _descriptionController.text = descriptionHint;
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final now = DateTime.now();
    final oldTask = widget.initialTask;

    final task = Task(
      id: oldTask?.id,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      dueDateTime: _hasDueDate ? _selectedDateTime : null,
      isCompleted: oldTask?.isCompleted ?? false,
      repeatType: _repeatType,
      repeatDays: _repeatType == RepeatType.weekly
          ? _repeatDays.toList(growable: false)
          : const <int>[],
      repeatInterval: _repeatType == RepeatType.interval
          ? _repeatInterval
          : null,
      progress: oldTask?.progress ?? 0,
      createdAt: oldTask?.createdAt ?? now,
      updatedAt: now,
    );

    widget.onSave(task);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.brandTeal.withValues(alpha: 0.16),
                        AppTheme.brandCoral.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: AppTheme.brandTeal,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.bolt, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isEdit ? 'Refine Task' : 'Launch New Task',
                              style: textTheme.titleLarge,
                            ),
                            Text(
                              'Use presets for faster planning',
                              style: textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text('Quick presets', style: textTheme.labelSmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PresetButton(
                      label: 'Deep Work (2h)',
                      onTap: () => _applyPreset(
                        const Duration(hours: 2),
                        'Deep Work Session',
                        'Focus block for high-impact work.',
                      ),
                    ),
                    _PresetButton(
                      label: 'Daily Review',
                      onTap: () => _applyPreset(
                        const Duration(hours: 6),
                        'Daily Review',
                        'Review completed and pending work.',
                      ),
                    ),
                    _PresetButton(
                      label: 'This Weekend',
                      onTap: () => _applyPreset(
                        const Duration(days: 2),
                        'Weekend Plan',
                        'Catch up on personal backlog items.',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Task title',
                    hintText: 'Write release summary',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Title is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'What exactly should be done?',
                  ),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        value: _hasDueDate,
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Has due date'),
                        subtitle: const Text(
                          'Turn off for flexible backlog items',
                        ),
                        onChanged: (value) {
                          setState(() {
                            _hasDueDate = value;
                          });
                        },
                      ),
                      if (_hasDueDate)
                        InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: _pickDateTime,
                          child: Ink(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.schedule),
                                const SizedBox(width: 10),
                                Text(
                                  DateFormat(
                                    'EEE, dd MMM yyyy - hh:mm a',
                                  ).format(_selectedDateTime),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<RepeatType>(
                  initialValue: _repeatType,
                  decoration: const InputDecoration(
                    labelText: 'Repeat cadence',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: RepeatType.none,
                      child: Text('No repeat'),
                    ),
                    DropdownMenuItem(
                      value: RepeatType.daily,
                      child: Text('Daily'),
                    ),
                    DropdownMenuItem(
                      value: RepeatType.weekly,
                      child: Text('Weekly'),
                    ),
                    DropdownMenuItem(
                      value: RepeatType.interval,
                      child: Text('Interval (days)'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _repeatType = value;
                      if (_repeatType != RepeatType.weekly) {
                        _repeatDays = <int>[];
                      }
                      if (_repeatType != RepeatType.interval) {
                        _repeatInterval = null;
                      }
                    });
                  },
                ),
                if (_repeatType == RepeatType.weekly) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(7, (index) {
                      final weekDay = index + 1;
                      final isSelected = _repeatDays.contains(weekDay);
                      const labels = [
                        'Mon',
                        'Tue',
                        'Wed',
                        'Thu',
                        'Fri',
                        'Sat',
                        'Sun',
                      ];
                      return FilterChip(
                        label: Text(labels[index]),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _repeatDays.add(weekDay);
                              _repeatDays.sort();
                            } else {
                              _repeatDays.remove(weekDay);
                            }
                          });
                        },
                      );
                    }),
                  ),
                ],
                if (_repeatType == RepeatType.interval) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _repeatInterval?.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Repeat every (days)',
                      hintText: 'e.g. 3',
                    ),
                    validator: (value) {
                      if (_repeatType != RepeatType.interval) {
                        return null;
                      }
                      final parsed = int.tryParse(value ?? '');
                      if (parsed == null || parsed <= 0) {
                        return 'Enter a valid number of days';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      _repeatInterval = int.tryParse(value);
                    },
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _save,
                    icon: Icon(_isEdit ? Icons.save_outlined : Icons.add_task),
                    label: Text(_isEdit ? 'Save Task' : 'Create Task'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PresetButton extends StatelessWidget {
  const _PresetButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: const Icon(Icons.flash_on, size: 16),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
