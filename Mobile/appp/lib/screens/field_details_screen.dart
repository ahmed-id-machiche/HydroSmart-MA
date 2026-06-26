import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/plot.dart';
import '../services/api_services.dart';
import '../widgets/analyse_info_row.dart';
import 'add_field_screen.dart';
import 'analyse_screen.dart';

class FieldDetailsScreen extends StatefulWidget {
  final Plot plot;

  const FieldDetailsScreen({
    super.key,
    required this.plot,
  });

  @override
  State<FieldDetailsScreen> createState() => _FieldDetailsScreenState();
}

class _FieldDetailsScreenState extends State<FieldDetailsScreen> {
  late Plot _plot;
  bool deleting = false;

  @override
  void initState() {
    super.initState();
    _plot = widget.plot;
  }

  Future<void> _editPlot() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddFieldScreen(plotToEdit: _plot),
      ),
    );
    if (result == true && mounted) {
      Navigator.pop(context, true);
    }
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Plot"),
        content: Text("Are you sure you want to delete ${_plot.nom}?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() {
                deleting = true;
              });
              try {
                await ApiService.deletePlot(_plot.id);
                if (mounted) {
                  Navigator.pop(context, true);
                }
              } catch (error) {
                if (mounted) {
                  setState(() {
                    deleting = false;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error deleting plot: $error")),
                  );
                }
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cropName = _plot.crop?.nom ?? "Crop";
    final surfaceText = "${_plot.superficie} ha";

    return Scaffold(
      backgroundColor: lightBackground,
      body: SafeArea(
        child: deleting
            ? const Center(child: CircularProgressIndicator())
            : Column(
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
                            IconButton(
                              onPressed: _editPlot,
                              icon: const Icon(Icons.edit, color: Colors.white),
                            ),
                            IconButton(
                              onPressed: _confirmDelete,
                              icon: const Icon(Icons.delete, color: Colors.white),
                            ),
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
                                      _plot.nom,
                                      style: const TextStyle(
                                        color: darkText,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "$cropName • $surfaceText",
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
                                label: "Crop",
                                value: cropName,
                              ),
                              const Divider(height: 24),
                              AnalyseInfoRow(
                                icon: Icons.square_foot_outlined,
                                label: "Area",
                                value: surfaceText,
                              ),
                              const Divider(height: 24),
                              AnalyseInfoRow(
                                icon: Icons.terrain_outlined,
                                label: "Soil Type",
                                value: _plot.typeSol,
                              ),
                              const Divider(height: 24),
                              AnalyseInfoRow(
                                icon: Icons.location_on_outlined,
                                label: "Location",
                                value: _plot.localisation,
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
                                  "Last weather: 25°C, humidity 61%, rain 0 mm.",
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
                                  "Recommendation: irrigation recommended early morning.",
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
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AnalyseScreen(initialPlot: _plot),
                                ),
                              );
                            },
                            icon: const Icon(Icons.analytics_outlined),
                            label: const Text(
                              "View Full Analysis",
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