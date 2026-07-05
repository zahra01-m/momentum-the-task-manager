import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';
import '../services/database_service.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  String? _currentUserEmail;
  bool _notificationSound = true;
  bool _notificationVibration = true;
  
  static const String _soundKey = 'notif_sound';
  static const String _vibrationKey = 'notif_vibration';
  static const String _usersKey = 'app_users';
  static const String _migrationDoneKey = 'sqlite_migration_done';

  List<Task> get tasks => _tasks;
  bool get notificationSound => _notificationSound;
  bool get notificationVibration => _notificationVibration;

  // Auth Methods
  Future<bool> signup(String name, String email, String password) async {
    final normalizedEmail = email.toLowerCase().trim();
    final existingUser = await DatabaseService.instance.getUser(normalizedEmail);
    
    if (existingUser != null) {
      return false; // User already exists
    }

    final newUser = User(name: name, email: normalizedEmail, password: password);
    await DatabaseService.instance.insertUser(newUser);
    return true;
  }

  Future<bool> login(String email, String password) async {
    final normalizedEmail = email.toLowerCase().trim();
    final user = await DatabaseService.instance.getUser(normalizedEmail);
    
    if (user == null) return false;
    return user.password == password;
  }

  List<Task> get todayTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _tasks.where((t) {
      if (t.isDeletedForToday) return false;
      if (t.isCompleted) return false;
      
      final taskDate = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
      final isDueToday = taskDate.isAtSameMomentAs(today);
      
      return isDueToday || t.isRepeating;
    }).toList();
  }

  List<Task> get completedTasks =>
      _tasks.where((t) => t.isCompleted).toList();

  List<Task> get repeatingTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _tasks.where((t) {
      final taskDate = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
      final isDueToday = taskDate.isAtSameMomentAs(today);
      
      return t.isRepeating || isDueToday;
    }).toList();
  }

  TaskProvider() {
    loadSettings();
    _initStorage();
  }

  Future<void> _initStorage() async {
    await _migrateIfNeeded();
    await loadTasks();
  }

  Future<void> _migrateIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_migrationDoneKey) ?? false) return;

    debugPrint('Starting migration from SharedPreferences to SQLite...');

    // 1. Migrate Users
    final String? usersData = prefs.getString(_usersKey);
    if (usersData != null) {
      final List decoded = jsonDecode(usersData);
      final users = decoded.map((e) => User.fromMap(e)).toList();
      for (var user in users) {
        await DatabaseService.instance.insertUser(user);
        
        // 2. Migrate Tasks for each user
        final userKey = 'tasks_data_${user.email.toLowerCase().trim()}';
        final String? taskData = prefs.getString(userKey);
        if (taskData != null) {
          final List decodedTasks = jsonDecode(taskData);
          final tasks = decodedTasks.map((e) => Task.fromMap(e)).toList();
          for (var task in tasks) {
            await DatabaseService.instance.insertTask(task, user.email);
          }
        }
      }
    }

    // Handle legacy global tasks if any
    final String? globalTasks = prefs.getString('tasks_data');
    if (globalTasks != null) {
       // We'll skip these or assign to a guest if needed, but per code 
       // most tasks are user-specific now.
    }

    await prefs.setBool(_migrationDoneKey, true);
    debugPrint('Migration complete.');
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationSound = prefs.getBool(_soundKey) ?? true;
    _notificationVibration = prefs.getBool(_vibrationKey) ?? true;
    notifyListeners();
  }

  Future<void> setNotificationSound(bool value) async {
    _notificationSound = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_soundKey, value);
    notifyListeners();
  }

  Future<void> setNotificationVibration(bool value) async {
    _notificationVibration = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_vibrationKey, value);
    notifyListeners();
  }

  Future<void> setUser(String? email) async {
    _currentUserEmail = email?.toLowerCase().trim();
    _tasks = [];
    await loadTasks();
  }

  Future<void> loadTasks() async {
    if (_currentUserEmail == null) {
      _tasks = [];
    } else {
      _tasks = await DatabaseService.instance.getTasks(_currentUserEmail!);
    }
    notifyListeners();
  }

  Future<void> addTask(Task task) async {
    if (_currentUserEmail == null) return;
    await DatabaseService.instance.insertTask(task, _currentUserEmail!);
    await loadTasks();
  }

  Future<void> updateTask(Task task) async {
    if (_currentUserEmail == null) return;
    await DatabaseService.instance.updateTask(task, _currentUserEmail!);
    await loadTasks();
  }

  Future<void> deleteTask(String id) async {
    await DatabaseService.instance.deleteTask(id);
    await loadTasks();
  }

  Future<void> markCompleted(String id) async {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1 && _currentUserEmail != null) {
      final updatedTask = _tasks[index].copyWith(isCompleted: true);
      await DatabaseService.instance.updateTask(updatedTask, _currentUserEmail!);
      await loadTasks();
    }
  }

  Future<void> resetRepeatingTasks() async {
    if (_currentUserEmail == null) return;
    for (int i = 0; i < _tasks.length; i++) {
      if (_tasks[i].isRepeating) {
        final updatedTask = _tasks[i].copyWith(
          isCompleted: false,
          isDeletedForToday: false,
        );
        await DatabaseService.instance.updateTask(updatedTask, _currentUserEmail!);
      }
    }
    await loadTasks();
  }
}
