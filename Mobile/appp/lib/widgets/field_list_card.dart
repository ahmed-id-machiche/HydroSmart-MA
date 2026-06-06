import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class FieldListCard extends StatelessWidget {
  final String title;
  final String crop;
  final String surface;
  final String soil;
  final IconData icon;
  final VoidCallback onTap;

  const FieldListCard({
    super.key,
    required this.title,
    required this.crop,
    required this.surface,
    required this.soil,
    required this.icon,
    required this.onTap,
  });

  String getCropImagePath(String cropName) {
    final name = cropName.toLowerCase();
    if (name.contains("tomate") || name.contains("tomato")) {
      return "assets/images/tomato.png";
    } else if (name.contains("oliv") || name.contains("olive")) {
      return "assets/images/olive.png";
    } else if (name.contains("agrume") || name.contains("citrus") || name.contains("orange")) {
      return "assets/images/citrus.png";
    } else if (name.contains("ble") || name.contains("wheat")) {
      return "assets/images/wheat.png";
    } else if (name.contains("pomme de terre") || name.contains("potato")) {
      return "assets/images/potato.png";
    } else if (name.contains("banan") || name.contains("bananier")) {
      return "assets/images/banana.png";
    }
    return "assets/images/default.png";
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: cardGreen,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    getCropImagePath(crop),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        icon,
                        color: primaryGreen,
                        size: 32,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: darkText,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$crop • $surface • $soil",
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right,
                color: Colors.black45,
              ),
            ],
          ),
        ),
      ),
    );
  }
}