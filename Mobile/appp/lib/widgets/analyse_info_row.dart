import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AnalyseInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const AnalyseInfoRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: primaryGreen),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: darkText,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: darkText,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(
          Icons.chevron_right,
          color: Colors.black45,
        ),
      ],
    );
  }
}