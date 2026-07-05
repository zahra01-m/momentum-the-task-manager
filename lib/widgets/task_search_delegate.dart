import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../screens/add_edit_task_screen.dart';

class TaskSearchDelegate extends SearchDelegate {
  final TaskProvider provider;

  TaskSearchDelegate(this.provider);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = provider.tasks.where((t) =>
        t.title.toLowerCase().contains(query.toLowerCase()) ||
        t.description.toLowerCase().contains(query.toLowerCase())).toList();

    return _buildList(results);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = provider.tasks.where((t) =>
        t.title.toLowerCase().contains(query.toLowerCase())).toList();

    return _buildList(suggestions);
  }

  Widget _buildList(List<Task> tasks) {
    if (tasks.isEmpty) {
      return const Center(child: Text('No tasks found.'));
    }

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return ListTile(
          leading: Icon(task.category.icon, color: Theme.of(context).colorScheme.primary),
          title: Text(task.title),
          subtitle: Row(
            children: [
              Text(task.category.name),
              const SizedBox(width: 8),
              Icon(task.priority.icon, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text(task.priority.name, style: const TextStyle(fontSize: 12)),
            ],
          ),
          trailing: Icon(task.isCompleted ? Icons.check_circle : Icons.circle_outlined, 
              color: task.isCompleted ? Colors.green : Colors.grey),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddEditTaskScreen(provider: provider, task: task),
              ),
            );
          },
        );
      },
    );
  }
}
