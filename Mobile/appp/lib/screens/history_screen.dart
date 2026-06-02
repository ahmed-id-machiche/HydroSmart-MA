import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/api_services.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool loading = true;
  List<Map<String, dynamic>> history = [];

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      final data = await ApiService.getIrrigationHistory();

      if (!mounted) return;

      setState(() {
        history = data;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur chargement historique: $error")),
      );
    }
  }

  Future<void> refreshHistory() async {
    setState(() {
      loading = true;
    });

    await loadHistory();
  }

  String getPlotName(Map<String, dynamic> item) {
    final plot = item["plots"];

    if (plot is Map<String, dynamic>) {
      return plot["nom"]?.toString() ?? "Parcelle";
    }

    return "Parcelle";
  }

  String getCropName(Map<String, dynamic> item) {
    final plot = item["plots"];

    if (plot is Map<String, dynamic>) {
      final crop = plot["crops"];

      if (crop is Map<String, dynamic>) {
        return crop["nom"]?.toString() ?? "Culture";
      }
    }

    return "Culture";
  }

  double getDouble(Map<String, dynamic> item, String key) {
    return double.tryParse(item[key].toString()) ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
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
              child: const Row(
                children: [
                  Icon(Icons.arrow_back, color: Colors.white),
                  Spacer(),
                  Text(
                    "Historique",
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
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: refreshHistory,
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : history.isEmpty
                        ? ListView(
                            padding: const EdgeInsets.all(18),
                            children: const [
                              SizedBox(height: 180),
                              Center(
                                child: Text(
                                  "Aucun historique d’irrigation trouvé.",
                                  style: TextStyle(color: Colors.black54),
                                ),
                              ),
                            ],
                          )
                        : ListView(
                            padding: const EdgeInsets.all(18),
                            children: [
                              const Text(
                                "Mes irrigations",
                                style: TextStyle(
                                  color: darkText,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 14),
                              ...history.map((item) {
                                final plotName = getPlotName(item);
                                final cropName = getCropName(item);
                                final date = item["date"]?.toString() ?? "-";
                                final et0 = getDouble(item, "et0");
                                final etc = getDouble(item, "etc");
                                final water = getDouble(item, "quantite_eau");

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: cardGreen,
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 52,
                                            height: 52,
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.85),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: const Icon(
                                              Icons.water_drop,
                                              color: Colors.lightBlueAccent,
                                              size: 32,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  plotName,
                                                  style: const TextStyle(
                                                    color: darkText,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  "$cropName • $date",
                                                  style: const TextStyle(
                                                    color: Colors.black54,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            "${water.toStringAsFixed(2)} m³",
                                            style: const TextStyle(
                                              color: primaryGreen,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: HistoryMiniStat(
                                              label: "ET0",
                                              value: et0.toStringAsFixed(2),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: HistoryMiniStat(
                                              label: "ETc",
                                              value: etc.toStringAsFixed(2),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: HistoryMiniStat(
                                              label: "Eau",
                                              value:
                                                  "${water.toStringAsFixed(1)} m³",
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              }),
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

class HistoryMiniStat extends StatelessWidget {
  final String label;
  final String value;

  const HistoryMiniStat({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: darkText,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}