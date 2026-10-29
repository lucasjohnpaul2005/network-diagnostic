enum GeofenceEventType { entered, exited }

/// One entry in the activity log: "you entered / left geofence X at time T".
class GeofenceEvent {
  final String locationId;
  final String locationName;
  final GeofenceEventType type;
  final DateTime timestamp;

  const GeofenceEvent({
    required this.locationId,
    required this.locationName,
    required this.type,
    required this.timestamp,
  });
}
