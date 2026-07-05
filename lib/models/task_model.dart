import 'dart:convert';

import 'package:flutter/material.dart';

enum TaskCategory { work, personal, shopping, health, education, other }

extension TaskCategoryExtension on TaskCategory {
  IconData get icon {
    switch (this) {
      case TaskCategory.work: return Icons.work;
      case TaskCategory.personal: return Icons.person;
      case TaskCategory.shopping: return Icons.shopping_cart;
      case TaskCategory.health: return Icons.health_and_safety;
      case TaskCategory.education: return Icons.school;
      case TaskCategory.other: return Icons.category;
    }
  }
}

enum TaskPriority { must, should, could, wont }

extension TaskPriorityExtension on TaskPriority {
  IconData get icon {
    switch (this) {
      case TaskPriority.must: return Icons.priority_high;
      case TaskPriority.should: return Icons.low_priority;
      case TaskPriority.could: return Icons.outlined_flag;
      case TaskPriority.wont: return Icons.block;
    }
  }
}

class SubTask {
  String id;
  String title;
  bool isCompleted;

  SubTask({required this.id, required this.title, this.isCompleted = false});

  Map<String, dynamic> toMap() =>
      {'id': id, 'title': title, 'isCompleted': isCompleted};

  factory SubTask.fromMap(Map<String, dynamic> map) => SubTask(
        id: map['id'],
        title: map['title'],
        isCompleted: map['isCompleted'] ?? false,
      );
}

class Task {
  String id;
  String title;
  String description;
  DateTime dueDate;
  bool isCompleted;
  bool isRepeating;
  List<int> repeatDays; // 1=Mon ... 7=Sun
  TaskCategory category;
  List<SubTask> subTasks;
  DateTime? notificationTime;
  bool isDeletedForToday;
  TaskPriority priority;
  int focusTimeMinutes;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    required this.dueDate,
    this.isCompleted = false,
    this.isRepeating = false,
    this.repeatDays = const [],
    this.category = TaskCategory.other,
    this.subTasks = const [],
    this.notificationTime,
    this.isDeletedForToday = false,
    this.priority = TaskPriority.should,
    this.focusTimeMinutes = 0,
  });

  double get progress {
    if (subTasks.isEmpty) return isCompleted ? 1.0 : 0.0;
    int done = subTasks.where((s) => s.isCompleted).length;
    return done / subTasks.length;
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'dueDate': dueDate.toIso8601String(),
        'isCompleted': isCompleted,
        'isRepeating': isRepeating,
        'repeatDays': repeatDays,
        'category': category.index,
        'subTasks': subTasks.map((s) => s.toMap()).toList(),
        'notificationTime': notificationTime?.toIso8601String(),
        'isDeletedForToday': isDeletedForToday,
        'priority': priority.index,
        'focusTimeMinutes': focusTimeMinutes,
      };

  factory Task.fromMap(Map<String, dynamic> map) => Task(
        id: map['id'],
        title: map['title'],
        description: map['description'] ?? '',
        dueDate: DateTime.parse(map['dueDate']),
        isCompleted: map['isCompleted'] ?? false,
        isRepeating: map['isRepeating'] ?? false,
        repeatDays: List<int>.from(map['repeatDays'] ?? []),
        category: TaskCategory.values[map['category'] ?? (TaskCategory.other.index)],
        subTasks: (map['subTasks'] as List<dynamic>? ?? [])
            .map((s) => SubTask.fromMap(s))
            .toList(),
        notificationTime: map['notificationTime'] != null
            ? DateTime.parse(map['notificationTime'])
            : null,
        isDeletedForToday: map['isDeletedForToday'] ?? false,
        priority: TaskPriority.values[map['priority'] ?? TaskPriority.should.index],
        focusTimeMinutes: map['focusTimeMinutes'] ?? 0,
      );

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    bool? isRepeating,
    List<int>? repeatDays,
    TaskCategory? category,
    List<SubTask>? subTasks,
    DateTime? notificationTime,
    bool? isDeletedForToday,
    TaskPriority? priority,
    int? focusTimeMinutes,
  }) =>
      Task(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        dueDate: dueDate ?? this.dueDate,
        isCompleted: isCompleted ?? this.isCompleted,
        isRepeating: isRepeating ?? this.isRepeating,
        repeatDays: repeatDays ?? this.repeatDays,
        category: category ?? this.category,
        subTasks: subTasks ?? List.from(this.subTasks),
        notificationTime: notificationTime ?? this.notificationTime,
        isDeletedForToday: isDeletedForToday ?? this.isDeletedForToday,
        priority: priority ?? this.priority,
        focusTimeMinutes: focusTimeMinutes ?? this.focusTimeMinutes,
      );
}