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

  @override
  void initState() {
    super.initState();
    loadPlots();
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

  @override
  Widget build(BuildContext context) {
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
                  const Row(
                    children: [
                      Icon(Icons.arrow_back, color: Colors.white),
                      Spacer(),
                      Text(
                        "Fields",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.notifications_none, color: Colors.white),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Container(
                    height: 46,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search, color: Colors.white),
                        SizedBox(width: 10),
                        Text(
                          "Search field",
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
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
                    : plots.isEmpty
                        ? ListView(
                            padding: const EdgeInsets.all(18),
                            children: const [
                              SizedBox(height: 180),
                              Center(
                                child: Text(
                                  "Aucune parcelle trouvée.",
                                  style: TextStyle(color: Colors.black54),
                                ),
                              ),
                            ],
                          )
                        : ListView(
                            padding: const EdgeInsets.all(18),
                            children: [
                              const Text(
                                "Mes parcelles",
                                style: TextStyle(
                                  color: darkText,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 14),
                              ...plots.map((plot) {
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