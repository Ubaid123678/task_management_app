import 'package:flutter/material.dart';

import '../../../../data/db/app_database.dart';
import '../../../../data/models/subtask.dart';
import '../../../../data/models/task.dart';

class SubtaskSheet extends StatefulWidget {
  const SubtaskSheet({super.key, required this.task, required this.onChanged});

  final Task task;
  final VoidCallback onChanged;

  @override
  State<SubtaskSheet> createState() => _SubtaskSheetState();
}

class _SubtaskSheetState extends State<SubtaskSheet> {
  final AppDatabase _database = AppDatabase.instance;
  final TextEditingController _controller = TextEditingController();

  List<Subtask> _subtasks = const <Subtask>[];
  bool _isLoading = true;

  int get _doneCount => _subtasks.where((s) => s.isDone).length;

  @override
  void initState() {
    super.initState();
    _loadSubtasks();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSubtasks() async {
    final taskId = widget.task.id;
    if (taskId == null) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final data = await _database.getSubtasksByTask(taskId);

    if (!mounted) {
      return;
    }

    setState(() {
      _subtasks = data;
      _isLoading = false;
    });
  }

  Future<void> _addSubtask() async {
    final taskId = widget.task.id;
    if (taskId == null) {
      return;
    }

    final title = _controller.text.trim();
    if (title.isEmpty) {
      return;
    }

    await _database.addSubtask(taskId: taskId, title: title);
    _controller.clear();
    await _loadSubtasks();
    widget.onChanged();
  }

  Future<void> _toggleSubtask(Subtask subtask, bool value) async {
    await _database.toggleSubtask(subtask: subtask, isDone: value);
    await _loadSubtasks();
    widget.onChanged();
  }

  Future<void> _deleteSubtask(Subtask subtask) async {
    await _database.removeSubtask(subtask);
    await _loadSubtasks();
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Subtasks - ${widget.task.title}',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              '$_doneCount / ${_subtasks.length} completed',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Add subtask'),
                    onSubmitted: (_) => _addSubtask(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _addSubtask, child: const Text('Add')),
              ],
            ),
            const SizedBox(height: 12),
            Flexible(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _subtasks.isEmpty
                  ? Center(
                      child: Text(
                        'No subtasks yet. Add one to track progress.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: _subtasks.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final subtask = _subtasks[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Checkbox(
                            value: subtask.isDone,
                            onChanged: (value) {
                              _toggleSubtask(subtask, value ?? false);
                            },
                          ),
                          title: Text(
                            subtask.title,
                            style: TextStyle(
                              decoration: subtask.isDone
                                  ? TextDecoration.lineThrough
                                  : TextDecoration.none,
                            ),
                          ),
                          trailing: IconButton(
                            onPressed: () => _deleteSubtask(subtask),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
