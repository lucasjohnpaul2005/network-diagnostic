import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/network_diagnostic_result.dart';
import '../services/connectivity_service.dart';
import '../services/network_diagnostic_service.dart';

class NetworkDiagnosticProvider extends ChangeNotifier {
  final NetworkDiagnosticService _diagnosticService;
  final ConnectivityService _connectivityService;

  static const Duration autoRunInterval = Duration(seconds: 20);

  Timer? _autoRunTimer;

  NetworkDiagnosticProvider({
    NetworkDiagnosticService? diagnosticService,
    ConnectivityService? connectivityService,
  })  : _diagnosticService = diagnosticService ?? NetworkDiagnosticService(),
        _connectivityService = connectivityService ?? ConnectivityService() {
    _autoRunTimer = Timer.periodic(autoRunInterval, (_) => runDiagnostics());
    runDiagnostics(); // first run right away so the dashboard isn't empty
  }

  DiagnosticStep _step = DiagnosticStep.idle;
  DiagnosticStep get step => _step;

  NetworkDiagnosticResult? _latestResult;
  NetworkDiagnosticResult? get latestResult => _latestResult;

  /// The value the rest of the app cares about: the categorized tier.
  /// Defaults to "fair" before the very first run completes.
  NetworkHealthTier get currentTier => _latestResult?.tier ?? NetworkHealthTier.fair;

  bool get isRunning => _step != DiagnosticStep.idle && _step != DiagnosticStep.completed;

  /// Runs the full idle-ping -> download -> upload sequence once.
  /// Safe to call manually (e.g. a "Run now" button) even while the
  /// periodic timer is also active -- overlapping runs are skipped.
  Future<void> runDiagnostics() async {
    if (isRunning) return;

    final networkStatus = await _connectivityService.checkCurrentStatus();
    final isOnline = networkStatus != NetworkStatus.offline;

    _step = DiagnosticStep.testingPing;
    notifyListeners();
    final idlePing = await _diagnosticService.measureIdlePing(isOnline: isOnline);

    _step = DiagnosticStep.testingDownload;
    notifyListeners();
    final download = await _diagnosticService.measureDownload(isOnline: isOnline);

    _step = DiagnosticStep.testingUpload;
    notifyListeners();
    final upload = await _diagnosticService.measureUpload(isOnline: isOnline);

    final tier = _diagnosticService.classify(
      downloadMbps: download.mbps,
      idlePingMs: idlePing,
      isOnline: isOnline,
    );

    _latestResult = NetworkDiagnosticResult(
      idlePingMs: idlePing,
      downloadMbps: download.mbps,
      downloadPingMs: download.pingMs,
      uploadMbps: upload.mbps,
      uploadPingMs: upload.pingMs,
      tier: tier,
      testedAt: DateTime.now(),
    );
    _step = DiagnosticStep.completed;
    notifyListeners();

    // Briefly hold "completed" so it's visible in the stepper UI, then
    // relax back to idle so a manual re-run is obviously available.
    await Future.delayed(const Duration(milliseconds: 800));
    _step = DiagnosticStep.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _autoRunTimer?.cancel();
    super.dispose();
  }
}
