import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class FieldCard extends StatelessWidget {
  final String label;
  final String cropName;

  const FieldCard({
    super.key,
    required this.label,
    required this.cropName,
  });

  String getCropImagePath(String name) {
    final lower = name.toLowerCase();
    if (lower.contains("tomate") || lower.contains("tomato")) {
      return "assets/images/tomato.png";
    } else if (lower.contains("oliv") || lower.contains("olive")) {
      return "assets/images/olive.png";
    } else if (lower.contains("agrume") || lower.contains("citrus") || lower.contains("orange")) {
      return "assets/images/citrus.png";
    } else if (lower.contains("ble") || lower.contains("wheat")) {
      return "assets/images/wheat.png";
    } else if (lower.contains("pomme de terre") || lower.contains("potato")) {
      return "assets/images/potato.png";
    } else if (lower.contains("banan") || lower.contains("bananier")) {
      return "assets/images/banana.png";
    } else if (lower.contains("pommier") || lower.contains("apple")) {
      return "assets/images/apple.png";
    } else if (lower.contains("avocat") || lower.contains("avocado")) {
      return "assets/images/avocado.png";
    } else if (lower.contains("vigne") || lower.contains("grape")) {
      return "assets/images/grape.png";
    } else if (lower.contains("pasteque") || lower.contains("watermelon")) {
      return "assets/images/watermelon.png";
    } else if (lower.contains("carotte") || lower.contains("carrot")) {
      return "assets/images/carrot.png";
    } else if (lower.contains("menthe") || lower.contains("mint")) {
      return "assets/images/mint.png";
    } else if (lower.contains("luzerne") || lower.contains("alfalfa")) {
      return "assets/images/alfalfa.png";
    } else if (lower.contains("poivron") || lower.contains("pepper")) {
      return "assets/images/pepper.png";
    } else if (lower.contains("poirier") || lower.contains("pear") ||
               lower.contains("grenadier") || lower.contains("pomegranate") ||
               lower.contains("figuier") || lower.contains("fig") ||
               lower.contains("amandier") || lower.contains("almond")) {
      return "assets/images/citrus.png"; // Fallback tree image
    }
    return "assets/images/default.png";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: cardGreen,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  getCropImagePath(cropName),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.eco_outlined,
                      color: primaryGreen,
                      size: 24,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: darkText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}