import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state_provider.dart';
import '../widgets/custom_button.dart';

class ActivityTwoScreen extends StatefulWidget {
  const ActivityTwoScreen({super.key});

  static const routeName = '/activity-two';

  @override
  State<ActivityTwoScreen> createState() => _ActivityTwoScreenState();
}

class _ActivityTwoScreenState extends State<ActivityTwoScreen> {
  final _controller = TextEditingController();
  String _submitted = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _submitted = _controller.text);
    context.read<AppStateProvider>().markActivityCompleted();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity 2: Forms & Input')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Type a short note and submit it:',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Write something...',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CustomButton(label: 'Submit', onPressed: _submit),
                ],
              ),
              const SizedBox(height: 24),
              if (_submitted.isNotEmpty) ...[
                Text('You submitted:', style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_submitted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
