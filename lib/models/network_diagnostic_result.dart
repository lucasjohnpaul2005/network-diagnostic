/// Categorized connection health, computed from the latest diagnostic run.
/// Thresholds (download bandwidth in Mbps unless offline/extreme latency):
///   excellent > 10 Mbps
///   fair      2 - 10 Mbps
///   poor      < 2 Mbps
///   degraded  offline, or extreme latency / heavy packet loss regardless
///             of bandwidth -- this tier "wins" over the bandwidth-based
///             ones because a very slow/lossy link is unusable even if a
///             burst of bandwidth briefly looked okay.
enum NetworkHealthTier { excellent, fair, poor, degraded }

/// Which stage the diagnostic tool is currently running. The tool always
/// executes in this order: idle ping -> download (+ concurrent ping) ->
/// upload (+ concurrent ping).
enum DiagnosticStep { idle, testingPing, testingDownload, testingUpload, completed }

/// Immutable snapshot of one completed diagnostic run.
class NetworkDiagnosticResult {
  final double idlePingMs;
  final double downloadMbps;
  final double downloadPingMs;
  final double uploadMbps;
  final double uploadPingMs;
  final NetworkHealthTier tier;
  final DateTime testedAt;

  const NetworkDiagnosticResult({
    required this.idlePingMs,
    required this.downloadMbps,
    required this.downloadPingMs,
    required this.uploadMbps,
    required this.uploadPingMs,
    required this.tier,
    required this.testedAt,
  });
}
