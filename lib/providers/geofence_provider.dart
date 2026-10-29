import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/location_repository.dart';
import '../models/geofence_event.dart';
import '../models/geofence_location.dart';
import '../models/user_position.dart';
import '../services/device_location_service.dart';
import '../services/geofence_engine.dart';

enum TrackingStatus { idle, starting, tracking, error }

/// APPLICATION LOGIC: owns the marker list, the user's position, the
/// geofence engine and the activity log. No map widgets and no plugin
/// code here -- just state and the rules for changing it.
class GeofenceProvider extends ChangeNotifier {
  /// The midterm requires at least this many custom markers.
  static const int requiredMarkerCount = 5;
  static const int _maxLoggedEvents = 100;

  final DeviceLocationService _locationService;
  final LocationRepository _repository;
  final GeofenceEngine _engine;

  GeofenceProvider({
    DeviceLocationService? locationService,
    LocationRepository? repository,
    GeofenceEngine? engine,
  })  : _locationService = locationService ?? DeviceLocationService(),
        _repository = repository ?? LocationRepository(),
        _engine = engine ?? GeofenceEngine();

  bool _isLoaded = false;
  List<GeofenceLocation> _locations = [];
  UserPosition? _position;
  final List<GeofenceEvent> _events = [];
  TrackingStatus _status = TrackingStatus.idle;
  String? _errorMessage;
  LocationAvailability? _lastAvailability;
  bool _isSimulating = false;
  StreamSubscription<UserPosition>? _positionSubscription;

  bool get isLoaded => _isLoaded;
  List<GeofenceLocation> get locations => List.unmodifiable(_locations);
  UserPosition? get position => _position;
  List<GeofenceEvent> get events => List.unmodifiable(_events);
  TrackingStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isSimulating => _isSimulating;
  bool get isTracking => _status == TrackingStatus.tracking;
  Set<String> get insideIds => _engine.insideIds;
  bool get meetsMarkerRequirement => _locations.length >= requiredMarkerCount;

  /// Loads the markers. Called by the screen when it opens (not at app
  /// start), so the rest of the app never waits on this.
  Future<void> load() async {
    if (_isLoaded) return;
    _locations = await _repository.loadAll();
    _isLoaded = true;
    notifyListeners();
  }

  // ---------------------------------------------------------------
  // GPS tracking
  // ---------------------------------------------------------------

  Future<void> startTracking() async {
    if (_status == TrackingStatus.tracking || _status == TrackingStatus.starting) return;

    _status = TrackingStatus.starting;
    _errorMessage = null;
    notifyListeners();

    final availability = await _locationService.ensureReady();
    _lastAvailability = availability;
    if (availability != LocationAvailability.ready) {
      _status = TrackingStatus.error;
      _errorMessage = _messageFor(availability);
      notifyListeners();
      return;
    }

    await _positionSubscription?.cancel();
    _positionSubscription = _locationService.positionStream().listen(
      _onDevicePosition,
      onError: (Object error) {
        _status = TrackingStatus.error;
        _errorMessage = 'Location error: $error';
        notifyListeners();
      },
    );
    _status = TrackingStatus.tracking;
    notifyListeners();

    await _refreshFromDevice();
  }

  Future<void> stopTracking() async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;
    _status = TrackingStatus.idle;
    if (!_isSimulating) {
      _position = null;
      _engine.reset();
    }
    notifyListeners();
  }

  Future<void> openSystemSettings() async {
    if (_lastAvailability == LocationAvailability.serviceDisabled) {
      await _locationService.openLocationSettings();
    } else {
      await _locationService.openAppSettings();
    }
  }

  void _onDevicePosition(UserPosition position) {
    if (_isSimulating) return; // simulation wins while it is switched on
    _handlePosition(position);
  }

  Future<void> _refreshFromDevice() async {
    try {
      final position = await _locationService.currentPosition();
      if (!_isSimulating && isTracking) _handlePosition(position);
    } catch (_) {
      // The live stream reports persistent problems; ignore a failed one-off fix.
    }
  }

  // ---------------------------------------------------------------
  // Simulation (move around by tapping the map -- great for demos)
  // ---------------------------------------------------------------

  void setSimulationMode(bool enabled) {
    if (_isSimulating == enabled) return;
    _isSimulating = enabled;
    if (!enabled) {
      _position = null;
      _engine.reset();
      if (isTracking) _refreshFromDevice();
    }
    notifyListeners();
  }

  void simulatePosition(double latitude, double longitude) {
    if (!_isSimulating) return;
    _handlePosition(UserPosition(
      latitude: latitude,
      longitude: longitude,
      isSimulated: true,
    ));
  }

  // ---------------------------------------------------------------
  // Markers
  // ---------------------------------------------------------------

  Future<void> addLocation({
    required String name,
    String description = '',
    required double latitude,
    required double longitude,
    double radiusMeters = 50,
  }) async {
    final location = GeofenceLocation(
      id: 'user-${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      description: description.trim(),
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      isUserAdded: true,
    );
    _locations = [..._locations, location];
    _reevaluate();
    await _persistUserLocations();
  }

  Future<void> removeLocation(String id) async {
    final matches = _locations.where((l) => l.id == id);
    if (matches.isEmpty || !matches.first.isUserAdded) return;
    _locations = _locations.where((l) => l.id != id).toList();
    _reevaluate();
    await _persistUserLocations();
  }

  void clearEvents() {
    _events.clear();
    notifyListeners();
  }

  /// Distance from the user to [location], or null if we have no position.
  double? distanceTo(GeofenceLocation location) {
    final position = _position;
    if (position == null) return null;
    return GeofenceEngine.distanceMeters(
      position.latitude,
      position.longitude,
      location.latitude,
      location.longitude,
    );
  }

  // ---------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------

  void _handlePosition(UserPosition position) {
    _position = position;
    final newEvents = _engine.evaluate(position: position, locations: _locations);
    for (final event in newEvents) {
      _events.insert(0, event);
    }
    if (_events.length > _maxLoggedEvents) {
      _events.removeRange(_maxLoggedEvents, _events.length);
    }
    notifyListeners();
  }

  void _reevaluate() {
    final position = _position;
    if (position != null) {
      _handlePosition(position);
    } else {
      notifyListeners();
    }
  }

  Future<void> _persistUserLocations() {
    return _repository.saveUserLocations(
      _locations.where((l) => l.isUserAdded).toList(),
    );
  }

  String _messageFor(LocationAvailability availability) {
    switch (availability) {
      case LocationAvailability.serviceDisabled:
        return 'Location is turned off. Switch on Location/GPS in your phone settings.';
      case LocationAvailability.permissionDenied:
        return 'Location permission was denied. Allow it to track your position.';
      case LocationAvailability.permissionDeniedForever:
        return 'Location permission is blocked. Enable it in the app settings.';
      case LocationAvailability.ready:
        return '';
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    super.dispose();
  }
}
