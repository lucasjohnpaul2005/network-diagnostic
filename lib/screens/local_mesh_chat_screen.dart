import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/local_mesh_chat_provider.dart';
import '../widgets/peer_tile.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/handshake_prompt_card.dart';

/// UI = f(state): this screen has no mutable fields of its own. Every
/// pixel on it is derived from LocalMeshChatProvider via context.watch,
/// so the whole screen re-renders declaratively whenever discovery,
/// handshake, or message state changes.
class LocalMeshChatScreen extends StatefulWidget {
  const LocalMeshChatScreen({super.key});

  static const routeName = '/local-mesh-chat';

  @override
  State<LocalMeshChatScreen> createState() => _LocalMeshChatScreenState();
}

/// StatefulWidget only because of the TextEditingController/ScrollController
/// lifecycle (need dispose()) -- the actual chat/peer data is NOT local
/// state, it all comes from the provider above.
class _LocalMeshChatScreenState extends State<LocalMeshChatScreen> {
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LocalMeshChatProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Mesh Chat'),
        actions: [
          IconButton(
            tooltip: provider.status == MeshStatus.searching ? 'Stop session' : 'Start session',
            icon: Icon(
              provider.status == MeshStatus.searching
                  ? Icons.stop_circle_outlined
                  : Icons.play_circle_outline,
            ),
            onPressed: () {
              final p = context.read<LocalMeshChatProvider>();
              if (provider.status == MeshStatus.searching || provider.status == MeshStatus.starting) {
                p.stopMeshSession();
              } else {
                p.startMeshSession();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;
              final peerPanel = _PeerPanel(provider: provider);
              final chatPanel = _ChatPanel(provider: provider, controller: _messageController);

              if (isWide) {
                // Responsive: side-by-side on wide screens/tablets.
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: 260, child: peerPanel),
                    const SizedBox(width: 16),
                    Expanded(child: chatPanel),
                  ],
                );
              }
              // Responsive: stacked on narrow phones.
              return Column(
                children: [
                  SizedBox(height: 180, child: peerPanel),
                  const SizedBox(height: 12),
                  Expanded(child: chatPanel),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PeerPanel extends StatelessWidget {
  final LocalMeshChatProvider provider;
  const _PeerPanel({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Nearby devices', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: 8),
            if (provider.status == MeshStatus.searching)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
        ),
        if (provider.status == MeshStatus.error)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              provider.errorMessage ?? 'Something went wrong.',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        const SizedBox(height: 8),
        Expanded(
          child: provider.peers.isEmpty
              ? Center(
                  child: Text(
                    provider.status == MeshStatus.searching
                        ? 'Searching for nearby devices…'
                        : 'Tap the play button above to start advertising & scanning.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              : ListView.builder(
                  itemCount: provider.peers.length,
                  itemBuilder: (context, index) {
                    final peer = provider.peers[index];
                    return PeerTile(
                      peer: peer,
                      onConnect: () => context
                          .read<LocalMeshChatProvider>()
                          .requestConnection(peer.endpointId),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _ChatPanel extends StatelessWidget {
  final LocalMeshChatProvider provider;
  final TextEditingController controller;
  const _ChatPanel({required this.provider, required this.controller});

  @override
  Widget build(BuildContext context) {
    final handshake = provider.pendingHandshake;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (handshake != null)
          HandshakePromptCard(
            endpointName: handshake.endpointName,
            authenticationToken: handshake.authenticationToken,
            onAccept: () => context.read<LocalMeshChatProvider>().acceptPendingHandshake(),
            onReject: () => context.read<LocalMeshChatProvider>().rejectPendingHandshake(),
          ),
        Text('Chat', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Expanded(
          child: provider.messages.isEmpty
              ? Center(
                  child: Text(
                    'Messages will appear here once you connect to a peer.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              : ListView.builder(
                  itemCount: provider.messages.length,
                  itemBuilder: (context, index) => ChatBubble(message: provider.messages[index]),
                ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                enabled: provider.hasConnectedPeer,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  hintText: provider.hasConnectedPeer
                      ? 'Type a message…'
                      : 'Connect to a peer to start chatting',
                ),
                onSubmitted: (_) => _send(context),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: provider.hasConnectedPeer ? () => _send(context) : null,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ],
    );
  }

  void _send(BuildContext context) {
    final text = controller.text;
    if (text.trim().isEmpty) return;
    context.read<LocalMeshChatProvider>().sendMessage(text);
    controller.clear();
  }
}
