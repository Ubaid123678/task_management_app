import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
      dueDateTime: _selectedDateTime,
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
                Text(
                  _isEdit ? 'Edit Task' : 'Create Task',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Task title',
                    hintText: 'Prepare project presentation',
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
                    hintText: 'Add notes for this task',
                  ),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 16),
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
                        color: Theme.of(context).colorScheme.outlineVariant,
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
                const SizedBox(height: 16),
                DropdownButtonFormField<RepeatType>(
                  initialValue: _repeatType,
                  decoration: const InputDecoration(labelText: 'Repeat type'),
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
                    label: Text(_isEdit ? 'Save Changes' : 'Create Task'),
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
