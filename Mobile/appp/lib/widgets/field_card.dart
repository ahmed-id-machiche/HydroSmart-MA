import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class FieldCard extends StatelessWidget {
  final String label;

  const FieldCard({
    super.key,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      decoration: BoxDecoration(
        color: cardGreen,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}