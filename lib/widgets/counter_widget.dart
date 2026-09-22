import 'package:flutter/material.dart';

class CounterWidget extends StatefulWidget {
  final String label;

  const CounterWidget({super.key, this.label = 'Tap counter'});

  @override
  State<CounterWidget> createState() => _CounterWidgetState();
}

class _CounterWidgetState extends State<CounterWidget> {
  int _count = 0;

  void _increment() => setState(() => _count++);
  void _decrement() => setState(() => _count = _count > 0 ? _count - 1 : 0);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              '${widget.label}: $_count',
              style: Theme.of(context).textTheme.titleMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _decrement,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              IconButton(
                onPressed: _increment,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
