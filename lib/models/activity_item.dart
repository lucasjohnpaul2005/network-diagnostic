import 'package:flutter/material.dart';

class ActivityItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final String routeName;
  final Color color;

  const ActivityItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.routeName,
    required this.color,
  });
}
