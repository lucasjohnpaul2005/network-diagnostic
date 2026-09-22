import 'package:connectivity_plus/connectivity_plus.dart';

enum NetworkStatus { wifi, cellular, offline, other }


class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  /// One-shot check, used to set the initial state on app start.
  Future<NetworkStatus> checkCurrentStatus() async {
    final results = await _connectivity.checkConnectivity();
    return _mapResults(results);
  }


  Stream<NetworkStatus> get onStatusChanged =>
      _connectivity.onConnectivityChanged.map(_mapResults);

  NetworkStatus _mapResults(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi)) return NetworkStatus.wifi;
    if (results.contains(ConnectivityResult.mobile)) return NetworkStatus.cellular;
    if (results.contains(ConnectivityResult.ethernet) ||
        results.contains(ConnectivityResult.vpn) ||
        results.contains(ConnectivityResult.bluetooth)) {
      return NetworkStatus.other;
    }
    return NetworkStatus.offline;
  }
}
