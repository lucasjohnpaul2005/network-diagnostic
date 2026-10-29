import 'package:flutter/material.dart';
import '../models/geofence_location.dart';

/// One row in the "Locations" list. Stateless: it shows what it is given
/// and reports taps upward.
class GeofenceLocationTile extends StatelessWidget {
  final int number;
  final GeofenceLocation location;
  final bool isInside;
  final double? distanceMeters;
  final VoidCallback onTap;

  /// null for seed markers (they are edited in lib/data/seed_locations.dart).
  final VoidCallback? onDelete;

  const GeofenceLocationTile({
    super.key,
    required this.number,
    required this.location,
    required this.isInside,
    required this.distanceMeters,
    required this.onTap,
    this.onDelete,
  });

  String get _distanceText {
    final meters = distanceMeters;
    if (meters == null) return 'distance unknown';
    if (meters >= 1000) return '${(meters / 1000).toStringAsFixed(2)} km away';
    return '${meters.round()} m away';
  }

  @override
  Widget build(BuildContext context) {
    final color = isInside ? Colors.green : Colors.indigo;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: color,
          child: Text(
            '$number',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
        title: Text(location.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${isInside ? 'INSIDE' : 'Outside'} | $_distanceText | r = ${location.radiusMeters.round()} m\n'
          '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
        ),
        isThreeLine: true,
        trailing: onDelete == null
            ? null
            : IconButton(
                tooltip: 'Delete marker',
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
              ),
      ),
    );
  }
}
