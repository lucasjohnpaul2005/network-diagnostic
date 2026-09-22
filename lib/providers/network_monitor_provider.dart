import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/queued_request.dart';
import '../services/connectivity_service.dart';
import '../services/network_request_service.dart';

/// Holds everything the Network Monitor screen needs: the live network
/// status and the queue of simulated requests. Kept as its own provider

class NetworkMonitorProvider extends ChangeNotifier {
  final ConnectivityService _connectivityService;
  final NetworkRequestService _requestService;

  NetworkMonitorProvider({
    ConnectivityService? connectivityService,
    NetworkRequestService? requestService,
  })  : _connectivityService = connectivityService ?? ConnectivityService(),
        _requestService = requestService ?? NetworkRequestService() {
    _init();
  }

  NetworkStatus _status = NetworkStatus.offline;
  NetworkStatus get status => _status;

  final List<QueuedRequest> _requests = [];
  List<QueuedRequest> get requests => List.unmodifiable(_requests);

  StreamSubscription<NetworkStatus>? _subscription;
  int _nextId = 1;

  Future<void> _init() async {
    _status = await _connectivityService.checkCurrentStatus();
    notifyListeners();

    // NETWORK STREAM LISTENER: subscribe once, for the lifetime of this
    // provider, to real-time connectivity changes.
    _subscription = _connectivityService.onStatusChanged.listen(_onStatusChanged);
  }

  void _onStatusChanged(NetworkStatus newStatus) {
    final wasOffline = _status == NetworkStatus.offline;
    _status = newStatus;
    notifyListeners();

    // GRACEFUL RECOVERY: the instant we come back online (Wi-Fi or
    // Cellular, doesn't matter which), retry anything that got queued
    // while we were offline or mid-handover.
    if (wasOffline && newStatus != NetworkStatus.offline) {
      _retryQueuedRequests();
    }
  }

  /// Kicks off a new simulated "large dataset" fetch.
  Future<void> simulateFetch() async {
    final request = QueuedRequest(
      id: _nextId++,
      label: 'Dataset fetch #$_nextId',
      status: RequestStatus.inProgress,
    );
    _requests.insert(0, request);
    notifyListeners();
    await _runRequest(request);
  }

  Future<void> retryNow(int requestId) async {
    final request = _requests.firstWhere((r) => r.id == requestId);
    request.retryCount++;
    await _runRequest(request);
  }

  Future<void> _runRequest(QueuedRequest request) async {
    request
      ..status = RequestStatus.inProgress
      ..lastError = null;
    notifyListeners();

    try {
      await _requestService.simulateFetch(
        isOnline: () => _status != NetworkStatus.offline,
        onProgress: (step, total) {
          request.progress = step / total;
          notifyListeners();
        },
      );
      request.status = RequestStatus.success;
    } on NetworkDroppedException catch (e) {
      // REQUEST QUEUING: catch the drop, don't crash, park it instead.
      request.status = RequestStatus.queued;
      request.lastError = e.message;
    }
    notifyListeners();
  }

  Future<void> _retryQueuedRequests() async {
    final queued = _requests.where((r) => r.status == RequestStatus.queued).toList();
    for (final request in queued) {
      request.retryCount++;
      await _runRequest(request);
    }
  }

  void clearCompleted() {
    _requests.removeWhere((r) => r.status == RequestStatus.success);
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
