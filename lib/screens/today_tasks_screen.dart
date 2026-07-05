import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/task_provider.dart';
import '../models/task_model.dart';
import 'add_edit_task_screen.dart';
import 'focus_timer_screen.dart';
import '../widgets/confirmation_dialog.dart';

class TodayTasksScreen extends StatelessWidget {
  final TaskProvider provider;
  const TodayTasksScreen({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: provider,
      builder: (context, _) {
        final tasks = provider.todayTasks;
        if (tasks.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.task_alt, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text("No tasks for today!", style: TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: tasks.length,
          itemBuilder: (context, index) {
            final task = tasks[index];
            return FadeInLeft(
              delay: Duration(milliseconds: index * 100),
              child: _buildTaskCard(context, task),
            );
          },
        );
      },
    );
  }

  Widget _buildTaskCard(BuildContext context, Task task) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => _editTask(context, task),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              icon: Icons.edit,
              label: 'Edit',
            ),
            SlidableAction(
              onPressed: (_) => _deleteTask(context, task),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              label: 'Delete',
            ),
          ],
        ),
        child: Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(task.title,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                    _buildPriorityBadge(task.priority),
                    const SizedBox(width: 8),
                    Chip(
                      avatar: Icon(task.category.icon, size: 16),
                      label: Text(task.category.name,
                          style: const TextStyle(fontSize: 11)),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                if (task.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(task.description,
                      style: const TextStyle(color: Colors.grey)),
                ],
                const SizedBox(height: 8),
                if (task.subTasks.isNotEmpty) ...[
                  LinearPercentIndicator(
                    lineHeight: 8,
                    percent: task.progress,
                    backgroundColor: Colors.grey.shade300,
                    progressColor: Colors.green,
                    barRadius: const Radius.circular(4),
                  ),
                  const SizedBox(height: 4),
                  Text(
                      '${(task.progress * 100).toInt()}% complete (${task.subTasks.where((s) => s.isCompleted).length}/${task.subTasks.length} subtasks)'),
                  const SizedBox(height: 4),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Due: ${task.dueDate.day}/${task.dueDate.month}/${task.dueDate.year}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FocusTimerScreen(task: task, provider: provider),
                              ),
                            );
                          },
                          icon: const Icon(Icons.timer, size: 20, color: Colors.orange),
                          tooltip: 'Start Focus',
                        ),
                        IconButton(
                          onPressed: () => _editTask(context, task),
                          icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Edit Task',
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () => provider.markCompleted(task.id),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Done'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(TaskPriority priority) {
    Color color;
    String label;
    switch (priority) {
      case TaskPriority.must:
        color = Colors.red;
        label = 'MUST';
        break;
      case TaskPriority.should:
        color = Colors.orange;
        label = 'SHOULD';
        break;
      case TaskPriority.could:
        color = Colors.blue;
        label = 'COULD';
        break;
      case TaskPriority.wont:
        color = Colors.grey;
        label = 'WONT';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(priority.icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
          ),
        ],
      ),
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

  void _deleteTask(BuildContext context, Task task) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Delete "${task.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.deleteTask(task.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}