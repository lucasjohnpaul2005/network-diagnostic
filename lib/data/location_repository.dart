import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/geofence_location.dart';
import 'seed_locations.dart';

/// DATA LAYER: the only place that knows where locations come from.
///
/// seed markers (lib/data/seed_locations.dart)  +  markers the user added
/// in the app (saved with shared_preferences)  =  what the map shows.
///
/// Only user-added markers are stored on the phone, so editing the seed
/// file always takes effect immediately -- no stale saved copies.
class LocationRepository {
  static const String _userLocationsKey = 'user_geofence_locations_v1';

  Future<List<GeofenceLocation>> loadAll() async {
    final userLocations = await _loadUserLocations();
    return [...seedLocations, ...userLocations];
  }

  Future<void> saveUserLocations(List<GeofenceLocation> userLocations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(userLocations.map((l) => l.toJson()).toList());
      await prefs.setString(_userLocationsKey, encoded);
    } catch (_) {
      // Saving is best-effort: the markers still work for this session.
    }
  }

  Future<List<GeofenceLocation>> _loadUserLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_userLocationsKey);
      if (raw == null) return [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => GeofenceLocation.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Corrupt or unavailable storage: fall back to the seed list only.
      return [];
    }
  }
}
