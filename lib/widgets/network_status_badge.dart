import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';

class NetworkStatusBadge extends StatelessWidget {
  final NetworkStatus status;

  const NetworkStatusBadge({super.key, required this.status});

  (IconData, Color, String) get _visual => switch (status) {
        NetworkStatus.wifi => (Icons.wifi, Colors.green, 'Wi-Fi'),
        NetworkStatus.cellular => (Icons.signal_cellular_alt, Colors.blue, 'Cellular'),
        NetworkStatus.other => (Icons.lan, Colors.orange, 'Connected'),
        NetworkStatus.offline => (Icons.wifi_off, Colors.red, 'Offline'),
      };

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = _visual;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
