import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'login_screen.dart';
import '../providers/task_provider.dart';

class WelcomeScreen extends StatelessWidget {
  final TaskProvider taskProvider;
  const WelcomeScreen({super.key, required this.taskProvider});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeInDown(
                duration: const Duration(milliseconds: 1000),
                child: Icon(
                  Icons.auto_graph_rounded,
                  size: 100,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 30),
              FadeInDown(
                duration: const Duration(milliseconds: 1000),
                delay: const Duration(milliseconds: 200),
                child: Text(
                  'Momentum',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFB298E7), // Using primary color for name
                    letterSpacing: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              FadeInDown(
                duration: const Duration(milliseconds: 1000),
                delay: const Duration(milliseconds: 400),
                child: Text(
                  'Turn intent into action.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
              const SizedBox(height: 60),
              FadeInUp(
                duration: const Duration(milliseconds: 1000),
                delay: const Duration(milliseconds: 600),
                child: SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginScreen(taskProvider: taskProvider),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 5,
                    ),
                    child: const Text(
                      'Get Started',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
