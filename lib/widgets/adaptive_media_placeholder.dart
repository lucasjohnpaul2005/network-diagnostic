import 'package:flutter/material.dart';
import '../models/network_diagnostic_result.dart';

class AdaptiveMediaPlaceholder extends StatelessWidget {
  final NetworkHealthTier tier;

  const AdaptiveMediaPlaceholder({super.key, required this.tier});

  bool get _showHighRes =>
      tier == NetworkHealthTier.excellent || tier == NetworkHealthTier.fair;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: _showHighRes
          ? const _HighResCard(key: ValueKey('highres'))
          : const _LightweightCard(key: ValueKey('lightweight')),
    );
  }
}

class _HighResCard extends StatelessWidget {
  const _HighResCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade300, Colors.purple.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.high_quality, color: Colors.white, size: 36),
          SizedBox(height: 8),
          Text('High-resolution content loaded',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _LightweightCard extends StatelessWidget {
  const _LightweightCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_not_supported_outlined, color: Colors.grey.shade600, size: 32),
          const SizedBox(height: 8),
          Text('Lightweight placeholder - saving data',
              style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
