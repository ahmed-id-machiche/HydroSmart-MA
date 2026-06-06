import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/plot.dart';
import '../services/api_services.dart';
import '../widgets/field_list_card.dart';
import 'add_field_screen.dart';
import 'field_details_screen.dart';

class FieldsScreen extends StatefulWidget {
  const FieldsScreen({super.key});

  @override
  State<FieldsScreen> createState() => _FieldsScreenState();
}

class _FieldsScreenState extends State<FieldsScreen> {
  bool loading = true;
  List<Plot> plots = [];
  String searchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadPlots();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> loadPlots() async {
    try {
      final data = await ApiService.getPlots();

      setState(() {
        plots = data;
        loading = false;
      });
    } catch (error) {
      setState(() {
        loading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur chargement parcelles: $error")),
      );
    }
  }

  Future<void> openAddFieldScreen() async {
    final added = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddFieldScreen(),
      ),
    );

    if (added == true) {
      setState(() {
        loading = true;
      });

      await loadPlots();
    }
  }

  Widget _buildSummaryStat(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFD9F8D9).withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primaryGreen, size: 24),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.black54, fontSize: 11),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: darkText,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Filter plots dynamically based on search query
    final filteredPlots = plots.where((plot) {
      final query = searchQuery.toLowerCase().trim();
      if (query.isEmpty) return true;

      final name = plot.nom.toLowerCase();
      final crop = (plot.crop?.nom ?? "").toLowerCase();
      final soil = plot.typeSol.toLowerCase();
      final loc = plot.localisation.toLowerCase();

      return name.contains(query) ||
          crop.contains(query) ||
          soil.contains(query) ||
          loc.contains(query);
    }).toList();

    // 2. Compute summary statistics
    final totalArea = plots.fold<double>(0.0, (sum, plot) => sum + plot.superficie);
    final plotCount = plots.length;

    return Scaffold(
      backgroundColor: lightBackground,
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        onPressed: openAddFieldScreen,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
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
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          Navigator.maybePop(context);
                        },
                      ),
                      const Spacer(),
                      const Text(
                        "Mes Parcelles",
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
                  const SizedBox(height: 16),
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white),
                      cursorColor: Colors.white,
                      decoration: const InputDecoration(
                        icon: Icon(Icons.search, color: Colors.white),
                        hintText: "Rechercher une parcelle...",
                        hintStyle: TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: loadPlots,
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: const EdgeInsets.all(18),
                        children: [
                          // Farm summary stats card
                          if (plots.isNotEmpty) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 18),
                              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildSummaryStat(
                                    Icons.grid_view_rounded,
                                    "Parcelles",
                                    "$plotCount",
                                  ),
                                  Container(width: 1, height: 36, color: Colors.black12),
                                  _buildSummaryStat(
                                    Icons.landscape_rounded,
                                    "Superficie totale",
                                    "${totalArea.toStringAsFixed(1)} ha",
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (filteredPlots.isEmpty) ...[
                            SizedBox(height: plots.isEmpty ? 100 : 40),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    plots.isEmpty ? Icons.grass : Icons.search_off,
                                    size: 72,
                                    color: Colors.black12,
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    plots.isEmpty 
                                        ? "Vous n'avez pas encore de parcelles." 
                                        : "Aucune parcelle ne correspond.",
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    plots.isEmpty 
                                        ? "Ajoutez votre première parcelle pour commencer l'irrigation intelligente." 
                                        : "Essayez avec d'autres termes de recherche.",
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.black38,
                                      fontSize: 12,
                                    ),
                                  ),
                                  if (plots.isEmpty) ...[
                                    const SizedBox(height: 18),
                                    ElevatedButton.icon(
                                      onPressed: openAddFieldScreen,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryGreen,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                      ),
                                      icon: const Icon(Icons.add),
                                      label: const Text("Ajouter une parcelle"),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ] else ...[
                            const Text(
                              "Mes parcelles",
                              style: TextStyle(
                                color: darkText,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 14),
                            ...filteredPlots.map((plot) {
                              return FieldListCard(
                                title: plot.nom,
                                crop: plot.crop?.nom ?? "Culture",
                                surface: "${plot.superficie} ha",
                                soil: plot.typeSol,
                                icon: Icons.grass,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FieldDetailsScreen(
                                        title: plot.nom,
                                        crop: plot.crop?.nom ?? "Culture",
                                        surface: "${plot.superficie} ha",
                                        soil: plot.typeSol,
                                        location: plot.localisation,
                                      ),
                                    ),
                                  );
                                },
                              );
                            }),
                          ],
                          const SizedBox(height: 80),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}