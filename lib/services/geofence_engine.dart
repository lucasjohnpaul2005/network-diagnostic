import 'dart:math';
import '../models/geofence_event.dart';
import '../models/geofence_location.dart';
import '../models/user_position.dart';

/// DOMAIN LOGIC: decides which geofences the user is inside and emits an
/// "entered" / "exited" event only when that changes.
///
/// Pure Dart -- no Flutter, no GPS plugin, no map -- so it can be unit
/// tested without a phone (see test/geofence_engine_test.dart).
class GeofenceEngine {
  /// GPS jitter can make a user standing right on the edge of a circle
  /// flip in and out every second. To prevent that, once inside you must
  /// move this much PAST the radius before an "exited" event fires.
  static const double exitBufferMeters = 10;

  final Set<String> _insideIds = {};

  Set<String> get insideIds => Set<String>.unmodifiable(_insideIds);

  void reset() => _insideIds.clear();

  /// Compares [position] with every location and returns only the events
  /// that happened since the previous call.
  List<GeofenceEvent> evaluate({
    required UserPosition position,
    required List<GeofenceLocation> locations,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    final events = <GeofenceEvent>[];
    final stillInside = <String>{};

    for (final location in locations) {
      final distance = distanceMeters(
        position.latitude,
        position.longitude,
        location.latitude,
        location.longitude,
      );
      final wasInside = _insideIds.contains(location.id);
      final threshold =
          wasInside ? location.radiusMeters + exitBufferMeters : location.radiusMeters;
      final isInside = distance <= threshold;

      if (isInside) {
        stillInside.add(location.id);
      }
      if (isInside && !wasInside) {
        events.add(GeofenceEvent(
          locationId: location.id,
          locationName: location.name,
          type: GeofenceEventType.entered,
          timestamp: timestamp,
        ));
      } else if (!isInside && wasInside) {
        events.add(GeofenceEvent(
          locationId: location.id,
          locationName: location.name,
          type: GeofenceEventType.exited,
          timestamp: timestamp,
        ));
      }
    }

    _insideIds
      ..clear()
      ..addAll(stillInside);
    return events;
  }

  /// Great-circle distance in meters between two coordinates (haversine).
  static double distanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusMeters = 6371000.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  static double _toRadians(double degrees) => degrees * pi / 180;
}
