import 'dart:io';
import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';

class ExportScreen extends StatelessWidget {
  final TaskProvider provider;
  const ExportScreen({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export & Report')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.upload_file, size: 80, color: Colors.grey),
              const SizedBox(height: 20),
              const Text('Export Tasks',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Export your tasks to share or backup',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _exportCsv(context),
                  icon: const Icon(Icons.table_chart),
                  label: const Text('Export as CSV'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _exportText(context),
                  icon: const Icon(Icons.text_snippet),
                  label: const Text('Export as Text / Email'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showStats(context),
                  icon: const Icon(Icons.bar_chart),
                  label: const Text('View Statistics'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context) async {
    final tasks = provider.tasks;
    final rows = [
      ['Title', 'Description', 'Due Date', 'Status', 'Category', 'Repeating', 'Progress'],
      ...tasks.map((t) => [
            t.title,
            t.description,
            DateFormat('yyyy-MM-dd').format(t.dueDate),
            t.isCompleted ? 'Completed' : 'Pending',
            t.category.name,
            t.isRepeating ? 'Yes' : 'No',
            '${(t.progress * 100).toInt()}%',
          ]),
    ];
    final csv = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/tasks_export.csv');
    await file.writeAsString(csv);
    await Share.shareXFiles([XFile(file.path)],
        text: 'My Tasks Export', subject: 'Tasks Export');
  }

  Future<void> _exportText(BuildContext context) async {
    final tasks = provider.tasks;
    final buffer = StringBuffer();
    buffer.writeln('=== TASK MANAGER EXPORT ===');
    buffer.writeln('Date: ${DateFormat('dd MMM yyyy').format(DateTime.now())}');
    buffer.writeln('Total Tasks: ${tasks.length}');
    buffer.writeln('');
    for (final t in tasks) {
      buffer.writeln('📌 ${t.title}');
      buffer.writeln('   Status: ${t.isCompleted ? "✅ Completed" : "⏳ Pending"}');
      buffer.writeln('   Category: ${t.category.name}');
      buffer.writeln('   Due: ${DateFormat('dd MMM yyyy').format(t.dueDate)}');
      if (t.description.isNotEmpty) buffer.writeln('   Desc: ${t.description}');
      if (t.subTasks.isNotEmpty) {
        buffer.writeln('   Subtasks: ${t.subTasks.where((s) => s.isCompleted).length}/${t.subTasks.length} done');
      }
      buffer.writeln('');
    }
    await Share.share(buffer.toString(), subject: 'My Tasks');
  }

  void _showStats(BuildContext context) {
    final tasks = provider.tasks;
    final completed = tasks.where((t) => t.isCompleted).length;
    final pending = tasks.length - completed;
    final repeating = tasks.where((t) => t.isRepeating).length;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Task Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _statRow('Total Tasks', tasks.length, Icons.list),
            _statRow('Completed', completed, Icons.check_circle, Colors.green),
            _statRow('Pending', pending, Icons.hourglass_empty, Colors.orange),
            _statRow('Repeating', repeating, Icons.repeat, Colors.blue),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, int count, IconData icon, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(child: Text(label)),
          Text('$count', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        ],
      ),
    );
  }
}
