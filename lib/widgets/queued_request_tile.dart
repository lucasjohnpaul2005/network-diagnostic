import 'package:flutter/material.dart';
import '../models/queued_request.dart';

/// Renders one QueuedRequest. Stateless: it only reflects whatever
/// state the model currently holds and reports a retry tap upward.
class QueuedRequestTile extends StatelessWidget {
  final QueuedRequest request;
  final VoidCallback onRetry;

  const QueuedRequestTile({
    super.key,
    required this.request,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final (icon, color, statusLabel) = switch (request.status) {
      RequestStatus.inProgress => (Icons.sync, Colors.blue, 'In progress'),
      RequestStatus.success => (Icons.check_circle, Colors.green, 'Completed'),
      RequestStatus.queued => (Icons.hourglass_bottom, Colors.orange, 'Queued'),
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    request.label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(statusLabel, style: TextStyle(color: color)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: request.status == RequestStatus.success ? 1 : request.progress,
                minHeight: 6,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            if (request.status == RequestStatus.queued) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      request.lastError ?? 'Connection dropped',
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(onPressed: onRetry, child: const Text('Retry now')),
                ],
              ),
            ],
            if (request.retryCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Retries: ${request.retryCount}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
