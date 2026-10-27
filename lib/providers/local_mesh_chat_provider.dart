import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/peer_device.dart';
import '../models/chat_message.dart';
import '../services/mesh_networking_service.dart';

/// Overall state of this device's mesh session.
enum MeshStatus { idle, starting, searching, error }

/// APPLICATION LOGIC LAYER: owns the peer list, the chat log, and the
/// pending handshake, and reacts to the service's streams. No
/// networking code and no Flutter widget code live here -- just state
/// + the rules for how that state changes.
class LocalMeshChatProvider extends ChangeNotifier {
  final MeshNetworkingService _service;
  final String displayName;

  LocalMeshChatProvider({MeshNetworkingService? service, String? displayName})
      : _service = service ?? MeshNetworkingService(),
        displayName = displayName ?? 'Device-${DateTime.now().millisecondsSinceEpoch % 1000}' {
    _subscriptions = [
      _service.onPeerFound.listen(_onPeerFound),
      _service.onPeerLost.listen(_onPeerLost),
      _service.onConnectionInitiated.listen(_onConnectionInitiated),
      _service.onConnectionResult.listen(_onConnectionResult),
      _service.onDisconnected.listen(_onDisconnected),
      _service.onMessageReceived.listen(_onMessageReceived),
    ];
  }

  late final List<StreamSubscription> _subscriptions;

  MeshStatus _status = MeshStatus.idle;
  MeshStatus get status => _status;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  final List<ChatPeer> _peers = [];
  List<ChatPeer> get peers => List.unmodifiable(_peers);

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  /// A handshake waiting on the user to accept/reject. Null when there
  /// is nothing pending. The screen renders a pairing card whenever
  /// this is non-null -- UI = f(state), no imperative dialog popping.
  ConnectionInitiatedEvent? _pendingHandshake;
  ConnectionInitiatedEvent? get pendingHandshake => _pendingHandshake;

  bool get hasConnectedPeer =>
      _peers.any((p) => p.state == PeerConnectionState.connected);

  /// LOCAL DISCOVERY: starts broadcasting this device's presence AND
  /// scanning for others at the same time.
  Future<void> startMeshSession() async {
    _status = MeshStatus.starting;
    _errorMessage = null;
    notifyListeners();

    final granted = await _service.requestPermissions();
    if (!granted) {
      _status = MeshStatus.error;
      _errorMessage = 'Bluetooth and Location permissions are required to discover devices.';
      notifyListeners();
      return;
    }

    try {
      // Defensive cleanup: a hot reload/restart (or a stray double tap)
      // can leave the native Android side still advertising/discovering
      // from a previous session even though our Dart state thinks it's
      // idle. Stopping first makes starting idempotent instead of
      // throwing STATUS_ALREADY_ADVERTISING / STATUS_ALREADY_DISCOVERING.
      // Swallow errors here deliberately: if nothing was running, the
      // native side may throw on stop too, and that's fine to ignore.
      try {
        await _service.stopAll();
      } catch (_) {
        // Nothing was running -- safe to continue to a fresh start.
      }

      await _service.startAdvertising(displayName);
      await _service.startDiscovery(displayName);
      _status = MeshStatus.searching;
    } catch (e) {
      _status = MeshStatus.error;
      _errorMessage = e.toString();
    }
    notifyListeners();
  }

  Future<void> stopMeshSession() async {
    await _service.stopAdvertising();
    await _service.stopDiscovery();
    await _service.stopAll();
    _peers.clear();
    _pendingHandshake = null;
    _status = MeshStatus.idle;
    notifyListeners();
  }

  void _onPeerFound(PeerFoundEvent event) {
    final exists = _peers.any((p) => p.endpointId == event.endpointId);
    if (!exists) {
      _peers.add(ChatPeer(endpointId: event.endpointId, name: event.endpointName));
      notifyListeners();
    }
  }

  void _onPeerLost(String endpointId) {
    _peers.removeWhere((p) => p.endpointId == endpointId);
    notifyListeners();
  }

  /// CONNECTION & HANDSHAKE: surfaces the pairing prompt (with the
  /// auth token) so the user can confirm the connection on both ends.
  void _onConnectionInitiated(ConnectionInitiatedEvent event) {
    _pendingHandshake = event;
    _setPeerState(event.endpointId, PeerConnectionState.connecting, fallbackName: event.endpointName);
    notifyListeners();
  }

  void _onConnectionResult(ConnectionResultEvent event) {
    _setPeerState(
      event.endpointId,
      event.isConnected ? PeerConnectionState.connected : PeerConnectionState.disconnected,
    );
    if (_pendingHandshake?.endpointId == event.endpointId) {
      _pendingHandshake = null;
    }
    if (event.isConnected) {
      _addSystemMessage('Connected to ${_peerName(event.endpointId)}');
    }
    notifyListeners();
  }

  void _onDisconnected(String endpointId) {
    _setPeerState(endpointId, PeerConnectionState.disconnected);
    _addSystemMessage('Disconnected from ${_peerName(endpointId)}');
    notifyListeners();
  }

  void _onMessageReceived(MessageReceivedEvent event) {
    _messages.add(ChatMessage(
      id: '${event.endpointId}-${DateTime.now().microsecondsSinceEpoch}',
      senderName: _peerName(event.endpointId),
      text: event.text,
      direction: MessageDirection.received,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  /// User taps "Connect" on a discovered peer -- starts the handshake
  /// from our side.
  Future<void> requestConnection(String endpointId) async {
    _setPeerState(endpointId, PeerConnectionState.connecting);
    notifyListeners();
    await _service.requestConnection(displayName, endpointId);
  }

  /// User approves the pairing prompt shown via [pendingHandshake].
  void acceptPendingHandshake() {
    final handshake = _pendingHandshake;
    if (handshake == null) return;
    _service.acceptConnection(handshake.endpointId);
  }

  void rejectPendingHandshake() {
    final handshake = _pendingHandshake;
    if (handshake == null) return;
    _service.rejectConnection(handshake.endpointId);
    _setPeerState(handshake.endpointId, PeerConnectionState.disconnected);
    _pendingHandshake = null;
    notifyListeners();
  }

  /// PAYLOAD ROUTING: sends a text payload to every currently connected
  /// peer, so the chat works the same way for one peer or a whole mesh.
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final connected = _peers.where((p) => p.state == PeerConnectionState.connected);
    for (final peer in connected) {
      await _service.sendMessage(peer.endpointId, trimmed);
    }

    _messages.add(ChatMessage(
      id: 'me-${DateTime.now().microsecondsSinceEpoch}',
      senderName: displayName,
      text: trimmed,
      direction: MessageDirection.sent,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  void _setPeerState(String endpointId, PeerConnectionState state, {String? fallbackName}) {
    final index = _peers.indexWhere((p) => p.endpointId == endpointId);
    if (index != -1) {
      _peers[index].state = state;
    } else if (fallbackName != null) {
      _peers.add(ChatPeer(endpointId: endpointId, name: fallbackName, state: state));
    }
  }

  String _peerName(String endpointId) {
    final match = _peers.where((p) => p.endpointId == endpointId);
    return match.isNotEmpty ? match.first.name : 'Unknown device';
  }

  void _addSystemMessage(String text) {
    _messages.add(ChatMessage(
      id: 'system-${DateTime.now().microsecondsSinceEpoch}',
      senderName: 'System',
      text: text,
      direction: MessageDirection.system,
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _service.stopAll();
    _service.dispose();
    super.dispose();
  }
}