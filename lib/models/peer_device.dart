/// Lifecycle of a nearby device, from first being seen to a live
/// connection.
enum PeerConnectionState { discovered, connecting, connected, disconnected }

/// Plain data holder - no networking logic here. The provider owns the
/// mutable `state` field as peers move through the handshake.
class ChatPeer {
  final String endpointId;
  final String name;
  PeerConnectionState state;

  ChatPeer({
    required this.endpointId,
    required this.name,
    this.state = PeerConnectionState.discovered,
  });
}
