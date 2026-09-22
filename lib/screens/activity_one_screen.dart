import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../widgets/counter_widget.dart';
import '../widgets/custom_button.dart';

class ActivityOneScreen extends StatefulWidget {
  const ActivityOneScreen({super.key});

  static const routeName = '/activity-one';

  @override
  State<ActivityOneScreen> createState() => _ActivityOneScreenState();
}

class _ActivityOneScreenState extends State<ActivityOneScreen> {
  bool _isFavorite = false;

  void _toggleFavorite() => setState(() => _isFavorite = !_isFavorite);

  void _complete() {
    context.read<AppStateProvider>().markActivityCompleted();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Activity 1 marked as completed!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity 1: Widgets & Layout')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row + Expanded/Flexible: adapts to available width
              // instead of using a fixed pixel size, avoiding overflow.
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Demonstrates local StatefulWidget interaction '
                      'and responsive Row/Column layout.',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: IconButton(
                      iconSize: 32,
                      icon: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: Colors.redAccent,
                      ),
                      onPressed: _toggleFavorite,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const CounterWidget(label: 'Local counter'),
              const Spacer(),
              CustomButton(
                label: 'Mark activity complete',
                icon: Icons.check_circle_outline,
                onPressed: _complete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
