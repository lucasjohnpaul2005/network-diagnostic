import 'package:flutter/material.dart';

/// Rendered whenever LocalMeshChatProvider.pendingHandshake is
/// non-null -- declarative pairing prompt instead of an imperative
/// dialog push. Shows the peer name and the authentication token so
/// both sides can visually confirm they're pairing with each other.
class HandshakePromptCard extends StatelessWidget {
  final String endpointName;
  final String authenticationToken;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const HandshakePromptCard({
    super.key,
    required this.endpointName,
    required this.authenticationToken,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lock_outline),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Pairing request from $endpointName',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Confirm this code matches on both devices: $authenticationToken'),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: onReject, child: const Text('Reject')),
                const SizedBox(width: 8),
                FilledButton(onPressed: onAccept, child: const Text('Accept')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
