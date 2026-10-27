import 'package:flutter/material.dart';
import '../models/peer_device.dart';

/// Purely presentational -> StatelessWidget. Renders a ChatPeer and
/// reports a "connect" tap upward; owns no state of its own.
class PeerTile extends StatelessWidget {
  final ChatPeer peer;
  final VoidCallback onConnect;

  const PeerTile({super.key, required this.peer, required this.onConnect});

  (IconData, Color, String) get _visual => switch (peer.state) {
        PeerConnectionState.discovered => (Icons.bluetooth_searching, Colors.blueGrey, 'Discovered'),
        PeerConnectionState.connecting => (Icons.sync, Colors.orange, 'Connecting…'),
        PeerConnectionState.connected => (Icons.link, Colors.green, 'Connected'),
        PeerConnectionState.disconnected => (Icons.link_off, Colors.red, 'Disconnected'),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = _visual;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(peer.name, overflow: TextOverflow.ellipsis),
        subtitle: Text(label, style: TextStyle(color: color)),
        trailing: peer.state == PeerConnectionState.discovered
            ? TextButton(onPressed: onConnect, child: const Text('Connect'))
            : null,
      ),
    );
  }
}
