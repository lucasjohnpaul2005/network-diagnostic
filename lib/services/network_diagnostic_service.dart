import 'dart:math';
import '../models/network_diagnostic_result.dart';


/// The three steps run in the order the activity specifies:
///   1. measureIdlePing()  -- baseline latency, no transfer happening
///   2. measureDownload()  -- download throughput + ping while it's busy
///   3. measureUpload()    -- upload throughput + ping while it's busy
class NetworkDiagnosticService {
  final Random _random = Random();

  Future<double> measureIdlePing({required bool isOnline}) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (!isOnline) return 999; // unreachable
    return 20 + _random.nextDouble() * 80; // ~20-100ms baseline
  }

  Future<({double mbps, double pingMs})> measureDownload({required bool isOnline}) async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (!isOnline) return (mbps: 0.0, pingMs: 999.0);
    final mbps = 1 + _random.nextDouble() * 30; // ~1-31 Mbps
    final pingMs = 30 + _random.nextDouble() * 200; // ping rises under load
    return (mbps: mbps, pingMs: pingMs);
  }

  Future<({double mbps, double pingMs})> measureUpload({required bool isOnline}) async {
    await Future.delayed(const Duration(milliseconds: 900));
    if (!isOnline) return (mbps: 0.0, pingMs: 999.0);
    final mbps = 0.5 + _random.nextDouble() * 15; // upload is typically slower
    final pingMs = 30 + _random.nextDouble() * 220;
    return (mbps: mbps, pingMs: pingMs);
  }

  NetworkHealthTier classify({
    required double downloadMbps,
    required double idlePingMs,
    required bool isOnline,
  }) {
    if (!isOnline || idlePingMs > 500) return NetworkHealthTier.degraded;
    if (downloadMbps > 10) return NetworkHealthTier.excellent;
    if (downloadMbps >= 2) return NetworkHealthTier.fair;
    return NetworkHealthTier.poor;
  }
}
