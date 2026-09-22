import 'package:flutter/material.dart';
import '../models/network_diagnostic_result.dart';

class NetworkHealthBadge extends StatelessWidget {
  final NetworkHealthTier tier;

  const NetworkHealthBadge({super.key, required this.tier});

  (IconData, Color, String) get _visual => switch (tier) {
        NetworkHealthTier.excellent => (Icons.signal_cellular_alt, Colors.green, 'Excellent'),
        NetworkHealthTier.fair => (Icons.signal_cellular_alt_2_bar, Colors.amber, 'Fair'),
        NetworkHealthTier.poor => (Icons.signal_cellular_alt_1_bar, Colors.deepOrange, 'Poor'),
        NetworkHealthTier.degraded => (Icons.signal_cellular_connected_no_internet_0_bar,
            Colors.red, 'Degraded'),
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
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}
