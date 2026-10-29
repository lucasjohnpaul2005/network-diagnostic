/// A custom place on the map that has a circular geofence around it.
///
/// Plain data only -- no map, GPS, or storage code lives here.
class GeofenceLocation {
  final String id;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final double radiusMeters;

  /// true  -> added inside the app (long-press on the map); stored on the
  ///          device and can be deleted from the app.
  /// false -> comes from lib/data/seed_locations.dart (edit that file to
  ///          change it).
  final bool isUserAdded;

  const GeofenceLocation({
    required this.id,
    required this.name,
    this.description = '',
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 50,
    this.isUserAdded = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters,
        'isUserAdded': isUserAdded,
      };

  factory GeofenceLocation.fromJson(Map<String, dynamic> json) {
    return GeofenceLocation(
      id: json['id'] as String,
      name: json['name'] as String,
      description: (json['description'] as String?) ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusMeters: (json['radiusMeters'] as num).toDouble(),
      isUserAdded: (json['isUserAdded'] as bool?) ?? true,
    );
  }
}
