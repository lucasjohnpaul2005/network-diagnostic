import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/network_monitor_provider.dart';
import '../widgets/network_status_badge.dart';
import '../widgets/queued_request_tile.dart';

class NetworkMonitorScreen extends StatelessWidget {
  const NetworkMonitorScreen({super.key});

  static const routeName = '/network-monitor';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NetworkMonitorProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Network Monitor')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Live connection', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              NetworkStatusBadge(status: provider.status),
              const SizedBox(height: 8),
              Text(
                'Turn Wi-Fi off/on (or toggle airplane mode) on your device '
                'to see this update in real time.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 20),
              // Row + Expanded: stays responsive on narrow screens.
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => context.read<NetworkMonitorProvider>().simulateFetch(),
                      icon: const Icon(Icons.cloud_download_outlined),
                      label: const Text('Simulate large dataset fetch'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Requests', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Expanded(
                child: provider.requests.isEmpty
                    ? Center(
                        child: Text(
                          'No requests yet. Tap the button above to start one, '
                          'then drop your connection mid-fetch to see it queue.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : ListView.builder(
                        itemCount: provider.requests.length,
                        itemBuilder: (context, index) {
                          final request = provider.requests[index];
                          return QueuedRequestTile(
                            request: request,
                            onRetry: () => context
                                .read<NetworkMonitorProvider>()
                                .retryNow(request.id),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
