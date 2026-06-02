import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../widgets/analyse_info_row.dart';

class FieldDetailsScreen extends StatelessWidget {
  final String title;
  final String crop;
  final String surface;
  final String soil;
  final String location;

  const FieldDetailsScreen({
    super.key,
    required this.title,
    required this.crop,
    required this.surface,
    required this.soil,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
              decoration: const BoxDecoration(
                color: primaryGreen,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      const Spacer(),
                      const Text(
                        "Field Details",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.notifications_none, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: lightBackground,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.grass,
                            color: primaryGreen,
                            size: 38,
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
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "$crop • $surface",
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardGreen,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        AnalyseInfoRow(
                          icon: Icons.eco_outlined,
                          label: "Culture",
                          value: crop,
                        ),
                        const Divider(height: 24),
                        AnalyseInfoRow(
                          icon: Icons.square_foot_outlined,
                          label: "Surface",
                          value: surface,
                        ),
                        const Divider(height: 24),
                        AnalyseInfoRow(
                          icon: Icons.terrain_outlined,
                          label: "Type de sol",
                          value: soil,
                        ),
                        const Divider(height: 24),
                        AnalyseInfoRow(
                          icon: Icons.location_on_outlined,
                          label: "Localisation",
                          value: location,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9F8FF),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.cloud, color: Colors.blue),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Dernière météo: 25°C, humidité 61%, pluie 0 mm.",
                            style: TextStyle(
                              color: darkText,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF7E6),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.water_drop, color: Colors.orange),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Recommandation: irrigation recommandée tôt le matin.",
                            style: TextStyle(
                              color: darkText,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed: () {},
                      icon: const Icon(Icons.analytics_outlined),
                      label: const Text(
                        "Voir analyse complète",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}