/// The user's position, independent of any GPS package. The location
/// service converts the plugin's own type into this one, so nothing else
/// in the app depends on the plugin.
class UserPosition {
  final double latitude;
  final double longitude;
  final double accuracyMeters;

  /// true when the position came from tapping the map in simulation mode
  /// instead of from the phone's GPS.
  final bool isSimulated;

  const UserPosition({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters = 0,
    this.isSimulated = false,
  });
}
