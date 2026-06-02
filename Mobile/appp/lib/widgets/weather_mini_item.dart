import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class WeatherMiniItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const WeatherMiniItem({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: primaryGreen, size: 18),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}