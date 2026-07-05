import 'package:flutter/material.dart';
import '../providers/task_provider.dart';
import '../main.dart';
import 'today_tasks_screen.dart';
import 'completed_tasks_screen.dart';
import 'repeated_tasks_screen.dart';
import 'add_edit_task_screen.dart';
import 'analysis_screen.dart';
import 'welcome_screen.dart';
import '../widgets/task_search_delegate.dart';
import '../widgets/confirmation_dialog.dart';

class HomeScreen extends StatefulWidget {
  final TaskProvider taskProvider;
  const HomeScreen({super.key, required this.taskProvider});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      TodayTasksScreen(provider: widget.taskProvider),
      CompletedTasksScreen(provider: widget.taskProvider),
      RepeatedTasksScreen(provider: widget.taskProvider),
      AnalysisScreen(provider: widget.taskProvider),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final app = TaskManagerApp.of(context);
    return AnimatedBuilder(
      animation: widget.taskProvider,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Momentum',
                style: TextStyle(fontWeight: FontWeight.bold)),
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                showSearch(
                  context: context,
                  delegate: TaskSearchDelegate(widget.taskProvider),
                );
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  final confirmed = await ConfirmationDialog.show(
                    context,
                    title: 'Sign Out',
                    content: 'Are you sure you want to sign out?',
                    confirmLabel: 'Sign Out',
                    confirmColor: Colors.red,
                  );
                  if (confirmed == true) {
                    await widget.taskProvider.setUser(null);
                    if (!mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              WelcomeScreen(taskProvider: widget.taskProvider)),
                      (route) => false,
                    );
                  }
                },
                tooltip: 'Sign Out',
              ),
              IconButton(
                icon: Icon(app?.isDark == true
                    ? Icons.light_mode
                    : Icons.dark_mode),
                onPressed: () => app?.toggleTheme(),
                tooltip: 'Toggle Theme',
              ),
            ],
          ),
          body: _screens[_selectedIndex],
          floatingActionButton: _selectedIndex < 3
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddEditTaskScreen(
                            provider: widget.taskProvider),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Task'),
                )
              : null,
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.today), label: 'Today'),
              NavigationDestination(
                  icon: Icon(Icons.check_circle), label: 'Completed'),
              NavigationDestination(
                  icon: Icon(Icons.repeat), label: 'Repeated'),
              NavigationDestination(
                  icon: Icon(Icons.analytics), label: 'Analysis'),
            ],
          ),
        );
      },
    );
  }
}