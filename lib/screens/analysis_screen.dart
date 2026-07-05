import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/task_provider.dart';
import 'export_screen.dart';

class AnalysisScreen extends StatelessWidget {
  final TaskProvider provider;
  const AnalysisScreen({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: provider,
      builder: (context, _) {
        final totalTasks = provider.tasks.length;
        final completedTasks = provider.tasks.where((t) => t.isCompleted).length;
        final completionRate = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

        return Scaffold(
          backgroundColor: colorScheme.surface,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInLeft(
                  child: Text(
                    'Performance Analysis',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: FadeInDown(
                    child: CircularPercentIndicator(
                      radius: 100.0,
                      lineWidth: 15.0,
                      percent: completionRate,
                      center: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "${(completionRate * 100).toInt()}%",
                            style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary),
                          ),
                          const Text("Done"),
                        ],
                      ),
                      circularStrokeCap: CircularStrokeCap.round,
                      backgroundColor: colorScheme.secondary.withOpacity(0.3),
                      progressColor: colorScheme.primary,
                      animation: true,
                      animationDuration: 1000,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                FadeInUp(
                  child: _buildStatCard(
                    context,
                    title: "Overview",
                    items: [
                      _StatItem("Total Tasks", "$totalTasks", Icons.list),
                      _StatItem("Completed", "$completedTasks", Icons.check_circle),
                      _StatItem("Pending", "${totalTasks - completedTasks}", Icons.pending),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                FadeInUp(
                  delay: const Duration(milliseconds: 200),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ExportScreen(provider: provider),
                          ),
                        );
                      },
                      icon: const Icon(Icons.share),
                      label: const Text("Export & Report"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(BuildContext context, {required String title, required List<_StatItem> items}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.secondary.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(item.icon, size: 20, color: colorScheme.primary),
                      const SizedBox(width: 10),
                      Text(item.label),
                      const Spacer(),
                      Text(item.value, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  _StatItem(this.label, this.value, this.icon);
}
