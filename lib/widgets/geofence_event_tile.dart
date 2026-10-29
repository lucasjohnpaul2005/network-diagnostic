import 'package:flutter/material.dart';
import '../models/geofence_event.dart';

/// One line in the activity log: "Entered Spot 1" / "Exited Spot 1".
class GeofenceEventTile extends StatelessWidget {
  final GeofenceEvent event;

  const GeofenceEventTile({super.key, required this.event});

  String _two(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final entered = event.type == GeofenceEventType.entered;
    final time = event.timestamp;
    return ListTile(
      dense: true,
      leading: Icon(
        entered ? Icons.login : Icons.logout,
        color: entered ? Colors.green : Colors.deepOrange,
      ),
      title: Text('${entered ? 'Entered' : 'Exited'} ${event.locationName}'),
      trailing: Text('${_two(time.hour)}:${_two(time.minute)}:${_two(time.second)}'),
    );
  }
}
