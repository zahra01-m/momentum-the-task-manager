import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'screens/home_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/notification_service.dart';
import 'providers/task_provider.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await NotificationService.initialize();
  runApp(const TaskManagerApp());
}

class TaskManagerApp extends StatefulWidget {
  const TaskManagerApp({super.key});
  static _TaskManagerAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_TaskManagerAppState>();

  @override
  State<TaskManagerApp> createState() => _TaskManagerAppState();
}

class _TaskManagerAppState extends State<TaskManagerApp> {
  ThemeMode _themeMode = ThemeMode.light;
  final TaskProvider taskProvider = TaskProvider();

  void toggleTheme() {
    setState(() {
      _themeMode =
      _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  bool get isDark => _themeMode == ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Manager',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB298E7),
          primary: const Color(0xFFB298E7),
          surface: const Color(0xFFF9BEDC),
          onSurface: const Color(0xFF4A4A4A),
          secondary: const Color(0xFFB8E3E9),
          tertiary: const Color(0xFFF5B8D5),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB298E7),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: WelcomeScreen(taskProvider: taskProvider),
    );
  }
}