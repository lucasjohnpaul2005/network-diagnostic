import '../models/geofence_location.dart';

/// ============================================================
///  EDIT THIS FILE  ->  put YOUR real custom locations here.
/// ============================================================
///
/// The midterm needs at least 5 custom markers inside ONE area (your
/// barangay, Lianga, etc.) that are NOT on Google Maps: your house,
/// a favorite hangout, an undiscovered spot...
///
/// The coordinates below are PLACEHOLDERS clustered around Lianga, Surigao
/// del Sur so the app runs out of the box. Replace the names and
/// coordinates with your real places. Two easy ways to get coordinates:
///   * In Google Maps: long-press a spot -> tap the coordinates at the top
///     of the sheet to copy "latitude, longitude".
///   * Inside this app: long-press the map (or stand at the spot and use
///     the "add marker at my position" button) -- those markers are saved
///     on the phone without touching this file.
///
/// radiusMeters = how big the geofence circle around the spot is.
const List<GeofenceLocation> seedLocations = [
  GeofenceLocation(
    id: 'seed-1',
    name: 'My Boarding house',
    description: 'A place to sleep and study',
    latitude: 8.63094,
    longitude: 126.09348,
    radiusMeters: 50,
  ),
  GeofenceLocation(
    id: 'seed-2',
    name: 'Our House',
    description: 'Diri ko naga relax',
    latitude: 8.59740,
    longitude: 125.90962,
    radiusMeters: 50,
  ),
  GeofenceLocation(
    id: 'seed-3',
    name: 'Our Store',
    description: 'Dry Goods store',
    latitude: 9.01302,
    longitude: 126.17220,
    radiusMeters: 50,
  ),
  GeofenceLocation(
    id: 'seed-4',
    name: 'Our Storage',
    description: 'Where we keep our supplies',
    latitude: 8.93428,
    longitude: 126.03695,
    radiusMeters: 50,
  ),
  GeofenceLocation(
    id: 'seed-5',
    name: 'Second House',
    description: 'Where we relax and unwind',
    latitude: 9.03813,
    longitude: 125.52097,
    radiusMeters: 50,
  ),
];
