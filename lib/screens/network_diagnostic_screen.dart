import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/network_diagnostic_provider.dart';
import '../widgets/network_health_badge.dart';
import '../widgets/diagnostic_progress_stepper.dart';
import '../widgets/adaptive_media_placeholder.dart';

/// All dynamic content comes from NetworkDiagnosticProvider via
/// context.watch, so this stays a StatelessWidget -- no local mutable
/// UI state of its own.
class NetworkDiagnosticScreen extends StatelessWidget {
  const NetworkDiagnosticScreen({super.key});

  static const routeName = '/network-diagnostics';

  String _fmtMbps(double v) => '${v.toStringAsFixed(1)} Mbps';
  String _fmtMs(double v) => '${v.toStringAsFixed(0)} ms';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NetworkDiagnosticProvider>();
    final result = provider.latestResult;

    return Scaffold(
      appBar: AppBar(title: const Text('Network Diagnostic Dashboard')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Connection health', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              NetworkHealthBadge(tier: provider.currentTier),
              const SizedBox(height: 6),
              Text(
                'Auto-tests every ${NetworkDiagnosticProvider.autoRunInterval.inSeconds}s. '
                'You can also trigger one manually below.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              Text('Diagnostic sequence', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 14),
              DiagnosticProgressStepper(step: provider.step),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: provider.isRunning
                          ? null
                          : () => context.read<NetworkDiagnosticProvider>().runDiagnostics(),
                      icon: const Icon(Icons.play_arrow),
                      label: Text(provider.isRunning ? 'Running...' : 'Run diagnostic now'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (result != null) ...[
                Text('Latest results', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                _ResultRow(label: 'Idle ping', value: _fmtMs(result.idlePingMs)),
                _ResultRow(
                  label: 'Download',
                  value: '${_fmtMbps(result.downloadMbps)}  ·  ping ${_fmtMs(result.downloadPingMs)}',
                ),
                _ResultRow(
                  label: 'Upload',
                  value: '${_fmtMbps(result.uploadMbps)}  ·  ping ${_fmtMs(result.uploadPingMs)}',
                ),
                _ResultRow(
                  label: 'Tested at',
                  value: '${result.testedAt.hour.toString().padLeft(2, '0')}:'
                      '${result.testedAt.minute.toString().padLeft(2, '0')}:'
                      '${result.testedAt.second.toString().padLeft(2, '0')}',
                ),
                const SizedBox(height: 24),
              ],
              Text('Adaptive content preview', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'This card swaps automatically based on the health tier above.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              AdaptiveMediaPlaceholder(tier: provider.currentTier),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;

  const _ResultRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
