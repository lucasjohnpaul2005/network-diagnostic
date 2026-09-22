import 'package:flutter/material.dart';
import '../models/network_diagnostic_result.dart';

/// Renders three stages (Ping, Download, Upload) and highlights whichever
/// one is currently active, reflecting the multi-step sequence the
/// diagnostic tool always runs in order.
class DiagnosticProgressStepper extends StatelessWidget {
  final DiagnosticStep step;

  const DiagnosticProgressStepper({super.key, required this.step});

  int get _activeIndex => switch (step) {
        DiagnosticStep.idle => -1,
        DiagnosticStep.testingPing => 0,
        DiagnosticStep.testingDownload => 1,
        DiagnosticStep.testingUpload => 2,
        DiagnosticStep.completed => 3,
      };

  @override
  Widget build(BuildContext context) {
    const labels = ['Idle ping', 'Download', 'Upload'];
    const icons = [Icons.network_ping, Icons.download, Icons.upload];
    final activeIndex = _activeIndex;

    return Row(
      children: List.generate(labels.length, (i) {
        final isActive = i == activeIndex;
        final isDone = activeIndex > i || activeIndex == 3;
        final color = isActive
            ? Theme.of(context).colorScheme.primary
            : isDone
                ? Colors.green
                : Colors.grey;

        return Expanded(
          child: Column(
            children: [
              if (isActive)
                SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: color),
                )
              else
                Icon(isDone ? Icons.check_circle : icons[i], color: color),
              const SizedBox(height: 6),
              Text(
                labels[i],
                style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        );
      }),
    );
  }
}
