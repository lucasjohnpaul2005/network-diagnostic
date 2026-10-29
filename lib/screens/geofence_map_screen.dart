import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../models/geofence_event.dart';
import '../models/geofence_location.dart';
import '../providers/geofence_provider.dart';
import '../widgets/add_marker_dialog.dart';
import '../widgets/geofence_event_tile.dart';
import '../widgets/geofence_location_tile.dart';
import '../widgets/status_pill.dart';

/// Activity 5: custom map + geofencing tracker.
///
/// UI = f(state): the map, the circles, the pills and both lists are all
/// derived from GeofenceProvider. This is a StatefulWidget only because it
/// owns the MapController and loads the markers when it opens.
class GeofenceMapScreen extends StatefulWidget {
  const GeofenceMapScreen({super.key});

  static const routeName = '/geofence-map';

  @override
  State<GeofenceMapScreen> createState() => _GeofenceMapScreenState();
}

class _GeofenceMapScreenState extends State<GeofenceMapScreen> {
  // Only used if there are no markers at all (placeholder area: Lianga).
  static const LatLng _fallbackCenter = LatLng(8.6330, 126.0990);

  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<GeofenceProvider>().load();
    });
  }

  Color _colorFor(GeofenceLocation location, Set<String> insideIds) {
    return insideIds.contains(location.id) ? Colors.green : Colors.indigo;
  }

  void _focusOn(GeofenceLocation location) {
    _mapController.move(LatLng(location.latitude, location.longitude), 18);
  }

  Future<void> _promptAddMarker(double latitude, double longitude) async {
    final input = await showDialog<NewMarkerInput>(
      context: context,
      builder: (_) => AddMarkerDialog(latitude: latitude, longitude: longitude),
    );
    if (input == null || !mounted) return;
    await context.read<GeofenceProvider>().addLocation(
          name: input.name,
          description: input.description,
          latitude: latitude,
          longitude: longitude,
          radiusMeters: input.radiusMeters,
        );
  }

  void _showLocationInfo(GeofenceLocation location) {
    final description = location.description.isEmpty ? '' : '\n${location.description}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${location.name} - ${location.radiusMeters.round()} m radius$description')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<GeofenceProvider>();
    final trackingActive =
        provider.status == TrackingStatus.tracking || provider.status == TrackingStatus.starting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Geofence Map'),
        actions: [
          IconButton(
            tooltip: provider.isSimulating
                ? 'Turn simulation off'
                : 'Simulate: tap the map to move yourself',
            icon: Icon(provider.isSimulating ? Icons.touch_app : Icons.touch_app_outlined),
            onPressed: () => context.read<GeofenceProvider>().setSimulationMode(!provider.isSimulating),
          ),
          IconButton(
            tooltip: trackingActive ? 'Stop GPS tracking' : 'Start GPS tracking',
            icon: Icon(trackingActive ? Icons.gps_fixed : Icons.gps_not_fixed),
            onPressed: () {
              final p = context.read<GeofenceProvider>();
              if (trackingActive) {
                p.stopTracking();
              } else {
                p.startTracking();
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: !provider.isLoaded
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  final map = _buildMap(provider);
                  final panel = _InfoPanel(provider: provider, onFocusLocation: _focusOn);

                  // Responsive: map + side panel on wide screens, stacked on phones.
                  if (constraints.maxWidth >= 800) {
                    return Row(
                      children: [
                        Expanded(flex: 3, child: map),
                        SizedBox(width: 380, child: panel),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      Expanded(flex: 5, child: map),
                      Expanded(flex: 4, child: panel),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildMap(GeofenceProvider provider) {
    final locations = provider.locations;
    final insideIds = provider.insideIds;
    final position = provider.position;
    final center = locations.isEmpty
        ? _fallbackCenter
        : LatLng(locations.first.latitude, locations.first.longitude);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 17,
            onTap: (tapPosition, point) {
              final p = context.read<GeofenceProvider>();
              if (p.isSimulating) {
                p.simulatePosition(point.latitude, point.longitude);
              }
            },
            onLongPress: (tapPosition, point) =>
                _promptAddMarker(point.latitude, point.longitude),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.flutter_portfolio',
            ),
            // The geofence circles, drawn at their real size in meters.
            CircleLayer(
              circles: [
                for (final location in locations)
                  CircleMarker(
                    point: LatLng(location.latitude, location.longitude),
                    radius: location.radiusMeters,
                    useRadiusInMeter: true,
                    color: _colorFor(location, insideIds).withValues(alpha: 0.18),
                    borderColor: _colorFor(location, insideIds),
                    borderStrokeWidth: 2,
                  ),
              ],
            ),
            MarkerLayer(
              markers: [
                for (var i = 0; i < locations.length; i++)
                  Marker(
                    point: LatLng(locations[i].latitude, locations[i].longitude),
                    width: 34,
                    height: 34,
                    child: GestureDetector(
                      onTap: () => _showLocationInfo(locations[i]),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _colorFor(locations[i], insideIds),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                if (position != null)
                  Marker(
                    point: LatLng(position.latitude, position.longitude),
                    width: 36,
                    height: 36,
                    child: Container(
                      decoration: BoxDecoration(
                        color: position.isSimulated ? Colors.orange : Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(Icons.person, size: 18, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const RichAttributionWidget(
              attributions: [
                TextSourceAttribution('OpenStreetMap contributors'),
              ],
            ),
          ],
        ),
        if (provider.isSimulating)
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: Material(
              color: Colors.orange.shade700,
              borderRadius: BorderRadius.circular(8),
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Text(
                  'Simulation ON - tap the map to move yourself',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        Positioned(
          right: 12,
          bottom: 28,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: null,
                tooltip: 'Center on my position',
                onPressed: position == null
                    ? null
                    : () => _mapController.move(LatLng(position.latitude, position.longitude), 18),
                child: const Icon(Icons.my_location),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: null,
                tooltip: 'Add marker at my position',
                onPressed: position == null
                    ? null
                    : () => _promptAddMarker(position.latitude, position.longitude),
                child: const Icon(Icons.add_location_alt_outlined),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Bottom (phone) / right (tablet) panel: status pills + two tabs.
class _InfoPanel extends StatelessWidget {
  final GeofenceProvider provider;
  final void Function(GeofenceLocation) onFocusLocation;

  const _InfoPanel({required this.provider, required this.onFocusLocation});

  @override
  Widget build(BuildContext context) {
    final tracking = provider.isTracking;
    final count = provider.locations.length;
    const required = GeofenceProvider.requiredMarkerCount;
    final enough = count >= required;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  StatusPill(
                    icon: tracking ? Icons.gps_fixed : Icons.gps_off,
                    label: tracking ? 'GPS on' : 'GPS off',
                    color: tracking ? Colors.green : Colors.grey,
                  ),
                  StatusPill(
                    icon: Icons.touch_app,
                    label: provider.isSimulating ? 'Simulation on' : 'Simulation off',
                    color: provider.isSimulating ? Colors.orange : Colors.grey,
                  ),
                  StatusPill(
                    icon: enough ? Icons.check_circle : Icons.warning_amber,
                    label: 'Markers $count/$required',
                    color: enough ? Colors.green : Colors.red,
                  ),
                ],
              ),
            ),
          ),
          const TabBar(
            tabs: [
              Tab(text: 'Locations'),
              Tab(text: 'Activity log'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _LocationsTab(provider: provider, onFocusLocation: onFocusLocation),
                _ActivityTab(provider: provider),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationsTab extends StatelessWidget {
  final GeofenceProvider provider;
  final void Function(GeofenceLocation) onFocusLocation;

  const _LocationsTab({required this.provider, required this.onFocusLocation});

  @override
  Widget build(BuildContext context) {
    final position = provider.position;
    final insideIds = provider.insideIds;
    final locations = provider.locations;
    final insideNames =
        locations.where((l) => insideIds.contains(l.id)).map((l) => l.name).toList();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (provider.status == TrackingStatus.error && provider.errorMessage != null)
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(provider.errorMessage!),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.read<GeofenceProvider>().openSystemSettings(),
                      child: const Text('Open settings'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  position == null
                      ? 'No position yet. Start GPS tracking (top right), or turn on '
                          'simulation and tap the map.'
                      : 'You: ${position.latitude.toStringAsFixed(5)}, '
                          '${position.longitude.toStringAsFixed(5)}'
                          '${position.isSimulated ? ' (simulated)' : ' (+/- ${position.accuracyMeters.round()} m)'}',
                ),
                if (position != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    insideNames.isEmpty
                        ? 'Outside all geofences'
                        : 'Inside: ${insideNames.join(', ')}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: insideNames.isEmpty ? null : Colors.green,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Long-press the map to add a marker.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < locations.length; i++)
          GeofenceLocationTile(
            number: i + 1,
            location: locations[i],
            isInside: insideIds.contains(locations[i].id),
            distanceMeters: provider.distanceTo(locations[i]),
            onTap: () => onFocusLocation(locations[i]),
            onDelete: locations[i].isUserAdded
                ? () => context.read<GeofenceProvider>().removeLocation(locations[i].id)
                : null,
          ),
      ],
    );
  }
}

class _ActivityTab extends StatelessWidget {
  final GeofenceProvider provider;

  const _ActivityTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    final events = provider.events;
    if (events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No geofence events yet. Walk (or simulate) into a marker\'s circle '
            'to see "Entered" and "Exited" events here.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 4),
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () => context.read<GeofenceProvider>().clearEvents(),
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear log'),
          ),
        ),
        for (final GeofenceEvent event in events) GeofenceEventTile(event: event),
      ],
    );
  }
}
