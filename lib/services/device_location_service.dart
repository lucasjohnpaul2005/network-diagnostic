import 'package:geolocator/geolocator.dart';
import '../models/user_position.dart';

enum LocationAvailability {
  ready,
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
}

/// SERVICE LAYER: the ONLY file that imports the `geolocator` package.
/// Everything else receives plain [UserPosition] objects.
class DeviceLocationService {
  /// Checks that the phone's location switch is on and that the app has
  /// permission (asking the user if needed).
  Future<LocationAvailability> ensureReady() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return LocationAvailability.serviceDisabled;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      return LocationAvailability.permissionDeniedForever;
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      return LocationAvailability.permissionDenied;
    }
    return LocationAvailability.ready;
  }

  /// Live position updates (a new one each time the phone moves ~3 m).
  Stream<UserPosition> positionStream() {
        const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 3,
    );
    return Geolocator.getPositionStream(locationSettings: settings).map(_toUserPosition);
  }

  /// One-off position fix, used to show something immediately.
  Future<UserPosition> currentPosition() async {
    final position = await Geolocator.getCurrentPosition();
    return _toUserPosition(position);
  }

  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  UserPosition _toUserPosition(Position position) {
    return UserPosition(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracyMeters: position.accuracy,
    );
  }
}
