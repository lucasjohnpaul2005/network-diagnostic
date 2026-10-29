import 'package:flutter/material.dart';

/// What the user typed in the "add marker" dialog.
class NewMarkerInput {
  final String name;
  final String description;
  final double radiusMeters;

  const NewMarkerInput({
    required this.name,
    required this.description,
    required this.radiusMeters,
  });
}

/// Dialog for naming a new custom marker and choosing its geofence radius.
/// StatefulWidget only for its text controllers and the slider value.
class AddMarkerDialog extends StatefulWidget {
  final double latitude;
  final double longitude;

  const AddMarkerDialog({super.key, required this.latitude, required this.longitude});

  @override
  State<AddMarkerDialog> createState() => _AddMarkerDialogState();
}

class _AddMarkerDialogState extends State<AddMarkerDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  double _radius = 50;
  String? _nameError;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'Please give this place a name');
      return;
    }
    Navigator.of(context).pop(NewMarkerInput(
      name: name,
      description: _descriptionController.text.trim(),
      radiusMeters: _radius,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add custom marker'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.latitude.toStringAsFixed(5)}, ${widget.longitude.toStringAsFixed(5)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Name (e.g. My house)',
                errorText: _nameError,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text('Geofence radius: ${_radius.round()} m'),
            Slider(
              value: _radius,
              min: 10,
              max: 200,
              divisions: 19,
              label: '${_radius.round()} m',
              onChanged: (value) => setState(() => _radius = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Add marker')),
      ],
    );
  }
}
