import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';
import '../services/notification_service.dart';

class AddEditTaskScreen extends StatefulWidget {
  final TaskProvider provider;
  final Task? task;
  const AddEditTaskScreen({super.key, required this.provider, this.task});

  @override
  State<AddEditTaskScreen> createState() => _AddEditTaskScreenState();
}

class _AddEditTaskScreenState extends State<AddEditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late DateTime _dueDate;
  late TaskCategory _category;
  late TaskPriority _priority;
  bool _isRepeating = false;
  List<int> _repeatDays = [];
  List<SubTask> _subTasks = [];
  DateTime? _notificationTime;
  late bool _playSound;
  late bool _enableVibration;
  final _subTaskCtrl = TextEditingController();

  static const List<String> _dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
    _dueDate = t?.dueDate ?? DateTime.now();
    _category = t?.category ?? TaskCategory.other;
    _priority = t?.priority ?? TaskPriority.should;
    _isRepeating = t?.isRepeating ?? false;
    _repeatDays = List.from(t?.repeatDays ?? []);
    _subTasks = List.from(t?.subTasks ?? []);
    _notificationTime = t?.notificationTime;
    _playSound = widget.provider.notificationSound;
    _enableVibration = widget.provider.notificationVibration;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _subTaskCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.task != null;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Task' : 'Add Task'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Task Title *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Title required' : null,
              ),
              const SizedBox(height: 14),

              // Description
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 14),

              const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: TaskCategory.values.length,
                  itemBuilder: (context, index) {
                    final cat = TaskCategory.values[index];
                    final isSelected = _category == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        avatar: Icon(cat.icon, size: 18, 
                            color: isSelected ? Colors.white : colorScheme.primary),
                        label: Text(cat.name.toUpperCase()),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) setState(() => _category = cat);
                        },
                        selectedColor: colorScheme.primary,
                        labelStyle: TextStyle(
                            color: isSelected ? Colors.white : colorScheme.onSurface,
                            fontSize: 12),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              // Priority
              DropdownButtonFormField<TaskPriority>(
                value: _priority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: TaskPriority.values.map((p) {
                  return DropdownMenuItem(
                    value: p,
                    child: Row(
                      children: [
                        Icon(p.icon, size: 18),
                        const SizedBox(width: 8),
                        Text(p.name.toUpperCase(), style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _priority = v!),
              ),
              const SizedBox(height: 14),

              // Notification Time
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.notifications),
                title: Text(_notificationTime == null
                    ? 'Set Notification'
                    : 'Notif: ${DateFormat('hh:mm a').format(_notificationTime!)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_notificationTime != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _notificationTime = null),
                      ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: _pickNotificationTime,
              ),

              if (_notificationTime != null) ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Notification Sound'),
                  secondary: const Icon(Icons.volume_up, size: 20),
                  value: _playSound,
                  onChanged: (v) => setState(() => _playSound = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Notification Vibration'),
                  secondary: const Icon(Icons.vibration, size: 20),
                  value: _enableVibration,
                  onChanged: (v) => setState(() => _enableVibration = v),
                ),
              ],
              const Divider(),

              // Repeating
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Repeat Task'),
                value: _isRepeating,
                onChanged: (v) => setState(() => _isRepeating = v),
              ),

              if (_isRepeating) ...[
                Wrap(
                  spacing: 8,
                  children: List.generate(7, (i) {
                    final day = i + 1;
                    final selected = _repeatDays.contains(day);
                    return FilterChip(
                      label: Text(_dayNames[day]),
                      selected: selected,
                      onSelected: (s) {
                        setState(() {
                          if (s) {
                            _repeatDays.add(day);
                          } else {
                            _repeatDays.remove(day);
                          }
                        });
                      },
                    );
                  }),
                ),
              ],
              const Divider(),

              // Subtasks
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Checklist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('${_subTasks.where((s) => s.isCompleted).length}/${_subTasks.length}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _subTaskCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Add step...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addSubTask,
                    icon: Icon(Icons.add_circle, color: colorScheme.primary, size: 30),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._subTasks.asMap().entries.map((entry) {
                final i = entry.key;
                final sub = entry.value;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Checkbox(
                    value: sub.isCompleted,
                    onChanged: (v) {
                      setState(() {
                        _subTasks[i] = SubTask(
                          id: sub.id,
                          title: sub.title,
                          isCompleted: v!,
                        );
                      });
                    },
                  ),
                  title: Text(sub.title, style: TextStyle(
                    decoration: sub.isCompleted ? TextDecoration.lineThrough : null,
                    color: sub.isCompleted ? Colors.grey : null,
                  )),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    onPressed: () => setState(() => _subTasks.removeAt(i)),
                  ),
                );
              }),

              const SizedBox(height: 30),
              OutlinedButton.icon(
                onPressed: _saveWithMomentum,
                icon: const Icon(Icons.bolt),
                label: const Text('Momentum Button'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: BorderSide(color: colorScheme.primary, width: 2),
                  foregroundColor: colorScheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.check_circle),
                  label: Text(isEdit ? 'Update Momentum' : 'Add to Momentum',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveWithMomentum() {
    setState(() => _priority = TaskPriority.must);
    _save();
  }

  void _addSubTask() {
    if (_subTaskCtrl.text.trim().isNotEmpty) {
      setState(() {
        _subTasks.add(SubTask(
          id: const Uuid().v4(),
          title: _subTaskCtrl.text.trim(),
        ));
        _subTaskCtrl.clear();
      });
    }
  }

  Future<void> _pickNotificationTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_notificationTime ?? DateTime.now()),
    );
    if (time == null) return;
    setState(() {
      _notificationTime = DateTime(
          _dueDate.year, _dueDate.month, _dueDate.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final id = widget.task?.id ?? const Uuid().v4();
    final task = Task(
      id: id,
      title: _titleCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      dueDate: _dueDate,
      isCompleted: widget.task?.isCompleted ?? false,
      isRepeating: _isRepeating,
      repeatDays: _repeatDays,
      category: _category,
      subTasks: _subTasks,
      notificationTime: _notificationTime,
      priority: _priority,
      focusTimeMinutes: widget.task?.focusTimeMinutes ?? 0,
    );

    if (widget.task == null) {
      await widget.provider.addTask(task);
    } else {
      await widget.provider.updateTask(task);
    }

    if (_notificationTime != null &&
        _notificationTime!.isAfter(DateTime.now())) {
      await NotificationService.scheduleNotification(
        id: id.hashCode,
        title: 'Task Reminder: ${task.title}',
        body: task.description.isNotEmpty ? task.description : 'You have a task due!',
        scheduledDate: _notificationTime!,
        playSound: _playSound,
        enableVibration: _enableVibration,
      );
    }

    if (mounted) Navigator.pop(context);
  }
}