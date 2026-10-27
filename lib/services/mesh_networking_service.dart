import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:nearby_connections/nearby_connections.dart';
import 'package:permission_handler/permission_handler.dart';

/// Raised while discovering, whenever a nearby advertiser is found.
class PeerFoundEvent {
  final String endpointId;
  final String endpointName;
  const PeerFoundEvent({required this.endpointId, required this.endpointName});
}

/// Raised on both sides of a connection attempt -- this is the
/// "handshake" moment: the UI should show endpointName/authentication
/// info and let the user confirm before the socket is actually opened.
class ConnectionInitiatedEvent {
  final String endpointId;
  final String endpointName;
  final String authenticationToken;
  final bool isIncoming;
  const ConnectionInitiatedEvent({
    required this.endpointId,
    required this.endpointName,
    required this.authenticationToken,
    required this.isIncoming,
  });
}

/// Raised once the OS reports whether a connection attempt succeeded.
class ConnectionResultEvent {
  final String endpointId;
  final bool isConnected;
  const ConnectionResultEvent({required this.endpointId, required this.isConnected});
}

/// Raised whenever a text payload arrives over an already-established
/// connection.
class MessageReceivedEvent {
  final String endpointId;
  final String text;
  const MessageReceivedEvent({required this.endpointId, required this.text});
}

/// SERVICE LAYER: the ONLY class in the app that imports
/// `nearby_connections` directly. The provider and UI depend on this
/// class's Stream-based API instead of the plugin's raw callback API --
/// if the mesh transport ever needs to change (e.g. a multipeer
/// wrapper for iOS), only this file changes.
///
/// IMPORTANT PLATFORM NOTE: nearby_connections wraps Google's Nearby
/// Connections API, which is ANDROID ONLY. This feature needs two
/// physical (or emulated, with Play Services) Android devices to
/// actually discover and connect to each other -- it will not work on
/// iOS, web, or desktop targets.
class MeshNetworkingService {
  static const String _serviceId = 'com.portfolio.local_mesh_chat';
  static const Strategy _strategy = Strategy.P2P_CLUSTER;

  final _peerFoundController = StreamController<PeerFoundEvent>.broadcast();
  final _peerLostController = StreamController<String>.broadcast();
  final _connectionInitiatedController =
      StreamController<ConnectionInitiatedEvent>.broadcast();
  final _connectionResultController = StreamController<ConnectionResultEvent>.broadcast();
  final _disconnectedController = StreamController<String>.broadcast();
  final _messageReceivedController = StreamController<MessageReceivedEvent>.broadcast();

  Stream<PeerFoundEvent> get onPeerFound => _peerFoundController.stream;
  Stream<String> get onPeerLost => _peerLostController.stream;
  Stream<ConnectionInitiatedEvent> get onConnectionInitiated =>
      _connectionInitiatedController.stream;
  Stream<ConnectionResultEvent> get onConnectionResult => _connectionResultController.stream;
  Stream<String> get onDisconnected => _disconnectedController.stream;
  Stream<MessageReceivedEvent> get onMessageReceived => _messageReceivedController.stream;

  /// Requests the runtime permissions Nearby Connections needs to
  /// broadcast/scan over Bluetooth + local Wi-Fi. Returns true only if
  /// every required permission was granted.
  Future<bool> requestPermissions() async {
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
      Permission.nearbyWifiDevices,
    ].request();
    return statuses.values.every((status) => status.isGranted || status.isLimited);
  }

  /// LOCAL DISCOVERY (broadcast half): announces this device so other
  /// devices running startDiscovery() can see it.
  Future<bool> startAdvertising(String displayName) {
    return Nearby().startAdvertising(
      displayName,
      _strategy,
      serviceId: _serviceId,
      onConnectionInitiated: _handleConnectionInitiated,
      onConnectionResult: _handleConnectionResult,
      onDisconnected: _handleDisconnected,
    );
  }

  /// LOCAL DISCOVERY (scan half): actively looks for nearby advertisers.
  Future<bool> startDiscovery(String displayName) {
    return Nearby().startDiscovery(
      displayName,
      _strategy,
      serviceId: _serviceId,
      onEndpointFound: (id, name, serviceId) {
        _peerFoundController.add(PeerFoundEvent(endpointId: id, endpointName: name));
      },
      onEndpointLost: (id) {
        if (id != null) _peerLostController.add(id);
      },
    );
  }

  /// CONNECTION & HANDSHAKE (initiator side): asks a discovered peer to
  /// connect. The result arrives via onConnectionInitiated /
  /// onConnectionResult on both ends.
  Future<bool> requestConnection(String displayName, String endpointId) {
    return Nearby().requestConnection(
      displayName,
      endpointId,
      onConnectionInitiated: _handleConnectionInitiated,
      onConnectionResult: _handleConnectionResult,
      onDisconnected: _handleDisconnected,
    );
  }

  void _handleConnectionInitiated(String id, ConnectionInfo info) {
    _connectionInitiatedController.add(ConnectionInitiatedEvent(
      endpointId: id,
      endpointName: info.endpointName,
      authenticationToken: info.authenticationToken,
      isIncoming: info.isIncomingConnection,
    ));
  }

  void _handleConnectionResult(String id, Status status) {
    _connectionResultController.add(ConnectionResultEvent(
      endpointId: id,
      isConnected: status == Status.CONNECTED,
    ));
  }

  void _handleDisconnected(String id) {
    _disconnectedController.add(id);
  }

  /// CONNECTION & HANDSHAKE (completion): call after the user approves
  /// the pairing prompt. This is what actually opens the socket and
  /// starts listening for payloads.
  void acceptConnection(String endpointId) {
    Nearby().acceptConnection(
      endpointId,
      onPayLoadRecieved: (endId, payload) {
        if (payload.type != PayloadType.BYTES) return;
        final bytes = payload.bytes;
        if (bytes == null) return;
        final text = utf8.decode(bytes);
        _messageReceivedController.add(MessageReceivedEvent(endpointId: endId, text: text));
      },
      onPayloadTransferUpdate: (endId, update) {
        // Simple text payloads complete in one shot; progress updates
        // aren't needed here, but the plugin requires this callback.
      },
    );
  }

  void rejectConnection(String endpointId) {
    Nearby().rejectConnection(endpointId);
  }

  /// PAYLOAD ROUTING: encodes a chat message as UTF-8 bytes and sends
  /// it down an already-established connection socket.
  Future<void> sendMessage(String endpointId, String text) {
    final bytes = Uint8List.fromList(utf8.encode(text));
    return Nearby().sendBytesPayload(endpointId, bytes);
  }

  void disconnect(String endpointId) {
    Nearby().disconnectFromEndpoint(endpointId);
  }

  Future<void> stopAdvertising() => Nearby().stopAdvertising();
  Future<void> stopDiscovery() => Nearby().stopDiscovery();
  Future<void> stopAll() => Nearby().stopAllEndpoints();

  void dispose() {
    _peerFoundController.close();
    _peerLostController.close();
    _connectionInitiatedController.close();
    _connectionResultController.close();
    _disconnectedController.close();
    _messageReceivedController.close();
  }
}