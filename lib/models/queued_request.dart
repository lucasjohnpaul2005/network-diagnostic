enum RequestStatus { inProgress, success, queued }

class QueuedRequest {
  final int id;
  final String label;
  RequestStatus status;
  double progress; 
  int retryCount;
  String? lastError;

  QueuedRequest({
    required this.id,
    required this.label,
    required this.status,
    this.progress = 0,
    this.retryCount = 0,
    this.lastError,
  });
}
