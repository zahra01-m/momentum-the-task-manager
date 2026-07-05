import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/task_model.dart';
import '../models/user_model.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('task_manager.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const boolType = 'INTEGER NOT NULL'; // 0 for false, 1 for true
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE users (
        email TEXT PRIMARY KEY,
        name $textType,
        password $textType
      )
    ''');

    await db.execute('''
      CREATE TABLE tasks (
        id $idType,
        user_email $textType,
        title $textType,
        description TEXT,
        dueDate $textType,
        isCompleted $boolType,
        isRepeating $boolType,
        repeatDays TEXT,
        category $intType,
        notificationTime TEXT,
        isDeletedForToday $boolType,
        priority $intType,
        focusTimeMinutes $intType,
        FOREIGN KEY (user_email) REFERENCES users (email) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE subtasks (
        id $idType,
        task_id $textType,
        title $textType,
        isCompleted $boolType,
        FOREIGN KEY (task_id) REFERENCES tasks (id) ON DELETE CASCADE
      )
    ''');
  }

  // User Operations
  Future<void> insertUser(User user) async {
    final db = await instance.database;
    await db.insert('users', user.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<User?> getUser(String email) async {
    final db = await instance.database;
    final maps = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.toLowerCase().trim()],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<List<User>> getAllUsers() async {
    final db = await instance.database;
    final result = await db.query('users');
    return result.map((json) => User.fromMap(json)).toList();
  }

  // Task Operations
  Future<void> insertTask(Task task, String userEmail) async {
    final db = await instance.database;
    final taskMap = task.toMap();
    taskMap['user_email'] = userEmail.toLowerCase().trim();
    // Convert repeatDays list to JSON string for SQLite
    taskMap['repeatDays'] = jsonEncode(task.repeatDays);
    // Remove subtasks from task map as they go in their own table
    taskMap.remove('subTasks');

    await db.insert('tasks', taskMap, conflictAlgorithm: ConflictAlgorithm.replace);

    // Insert subtasks
    for (var sub in task.subTasks) {
      await insertSubTask(sub, task.id);
    }
  }

  Future<void> insertSubTask(SubTask sub, String taskId) async {
    final db = await instance.database;
    final map = sub.toMap();
    map['task_id'] = taskId;
    await db.insert('subtasks', map, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Task>> getTasks(String userEmail) async {
    final db = await instance.database;
    final userEmailNormalized = userEmail.toLowerCase().trim();
    final taskMaps = await db.query(
      'tasks',
      where: 'user_email = ?',
      whereArgs: [userEmailNormalized],
    );

    List<Task> tasks = [];
    for (var taskMap in taskMaps) {
      final subtaskMaps = await db.query(
        'subtasks',
        where: 'task_id = ?',
        whereArgs: [taskMap['id']],
      );

      final mutableTaskMap = Map<String, dynamic>.from(taskMap);
      mutableTaskMap['subTasks'] = subtaskMaps;
      mutableTaskMap['repeatDays'] = jsonDecode(taskMap['repeatDays'] as String);
      
      // Fix types for boolean fields from INTEGER back to bool
      mutableTaskMap['isCompleted'] = taskMap['isCompleted'] == 1;
      mutableTaskMap['isRepeating'] = taskMap['isRepeating'] == 1;
      mutableTaskMap['isDeletedForToday'] = taskMap['isDeletedForToday'] == 1;

      tasks.add(Task.fromMap(mutableTaskMap));
    }
    return tasks;
  }

  Future<void> updateTask(Task task, String userEmail) async {
    final db = await instance.database;
    final taskMap = task.toMap();
    taskMap['user_email'] = userEmail.toLowerCase().trim();
    taskMap['repeatDays'] = jsonEncode(task.repeatDays);
    taskMap.remove('subTasks');

    // Convert bools to ints for SQLite update
    taskMap['isCompleted'] = task.isCompleted ? 1 : 0;
    taskMap['isRepeating'] = task.isRepeating ? 1 : 0;
    taskMap['isDeletedForToday'] = task.isDeletedForToday ? 1 : 0;

    await db.update(
      'tasks',
      taskMap,
      where: 'id = ?',
      whereArgs: [task.id],
    );

    // Update subtasks: simplest way is delete and re-insert
    await db.delete('subtasks', where: 'task_id = ?', whereArgs: [task.id]);
    for (var sub in task.subTasks) {
      await insertSubTask(sub, task.id);
    }
  }

  Future<void> deleteTask(String id) async {
    final db = await instance.database;
    // Cascading delete should handle subtasks if foreign key is set up correctly, 
    // but some SQLite versions need it manually if not enabled.
    await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
