import 'package:flutter/material.dart';
import '../providers/task_provider.dart';
import '../models/task_model.dart';
import 'add_edit_task_screen.dart';
import '../widgets/confirmation_dialog.dart';

class RepeatedTasksScreen extends StatelessWidget {
  final TaskProvider provider;
  const RepeatedTasksScreen({super.key, required this.provider});

  static const List<String> _dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: provider,
      builder: (context, _) {
        final tasks = provider.repeatingTasks;
        if (tasks.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.repeat, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text("No repeating tasks!", style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                leading: Icon(
                  task.isRepeating ? Icons.repeat : Icons.today,
                  color: Colors.blue,
                ),
                title: Text(task.title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.isRepeating
                          ? (task.repeatDays.isEmpty
                              ? 'Daily'
                              : task.repeatDays
                                  .map((d) => _dayNames[d])
                                  .join(', '))
                          : 'Due Today (One-time)',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Row(
                      children: [
                        Icon(task.category.icon, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(task.category.name, style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 8),
                        Icon(task.priority.icon, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(task.priority.name, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _editTask(context, task),
                      tooltip: 'Edit Task',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteTask(context, task),
                      tooltip: 'Delete Task',
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _editTask(BuildContext context, Task task) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Edit Task',
      content: 'Are you sure you want to edit "${task.title}"?',
      confirmLabel: 'Edit',
    );
    if (confirmed == true && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AddEditTaskScreen(provider: provider, task: task),
        ),
      );
    }
  }

  void _deleteTask(BuildContext context, Task task) async {
    final confirmed = await ConfirmationDialog.show(
      context,
      title: 'Delete Task',
      content: 'Are you sure you want to delete "${task.title}"?',
      confirmLabel: 'Delete',
      confirmColor: Colors.red,
    );
    if (confirmed == true) {
      provider.deleteTask(task.id);
    }
  }
}
