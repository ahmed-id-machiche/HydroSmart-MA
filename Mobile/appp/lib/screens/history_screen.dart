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

  List<ChartBarData> getWeeklyChartData() {
    final Map<String, double> dailyVolumes = {};
    final List<DateTime> last7Days = [];
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      last7Days.add(date);
      final dateStr = date.toIso8601String().split('T')[0];
      dailyVolumes[dateStr] = 0.0;
    }

    for (var item in history) {
      final dateStr = item["date"]?.toString().split('T')[0];
      if (dateStr != null && dailyVolumes.containsKey(dateStr)) {
        final volume = double.tryParse(item["quantite_eau"].toString()) ?? 0.0;
        dailyVolumes[dateStr] = dailyVolumes[dateStr]! + volume;
      }
    }

    final List<ChartBarData> chartData = [];
    final weekdayNames = ["Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"];
    
    for (var date in last7Days) {
      final dateStr = date.toIso8601String().split('T')[0];
      final volume = dailyVolumes[dateStr] ?? 0.0;
      final dayLabel = weekdayNames[date.weekday - 1];
      chartData.add(ChartBarData(label: dayLabel, value: volume));
    }

    return chartData;
  }

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
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const Spacer(),
                  const Text(
                    "Historique",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_none, color: Colors.white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
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
                              // 1. Custom Weekly Bar Chart Section
                              WeeklyVolumeChart(data: getWeeklyChartData()),
                              
                              const SizedBox(height: 24),

                              const Text(
                                "Mes irrigations récents",
                                style: TextStyle(
                                  color: darkText,
                                  fontSize: 18,
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
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.02),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF0F9FF),
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(
                                                color: Colors.lightBlueAccent.withOpacity(0.2),
                                              ),
                                            ),
                                            padding: const EdgeInsets.all(4),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(10),
                                              child: Image.asset(
                                                getCropImagePath(cropName),
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return const Icon(
                                                    Icons.water_drop,
                                                    color: Colors.blueAccent,
                                                    size: 26,
                                                  );
                                                },
                                              ),
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
                                                  style: TextStyle(
                                                    color: darkText.withOpacity(0.5),
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFE0F2FE),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              "${water.toStringAsFixed(2)} m³",
                                              style: TextStyle(
                                                color: Colors.blue[900],
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
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
                                              value: "${et0.toStringAsFixed(2)} mm",
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: HistoryMiniStat(
                                              label: "ETc",
                                              value: "${etc.toStringAsFixed(2)} mm",
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: HistoryMiniStat(
                                              label: "Volume",
                                              value: "${water.toStringAsFixed(1)} m³",
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
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.grey[100]!,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black45,
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: darkText,
              fontWeight: FontWeight.bold,
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

class ChartBarData {
  final String label;
  final double value;

  ChartBarData({required this.label, required this.value});
}

class WeeklyVolumeChart extends StatelessWidget {
  final List<ChartBarData> data;

  const WeeklyVolumeChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    double maxVal = 0.0;
    for (var item in data) {
      if (item.value > maxVal) {
        maxVal = item.value;
      }
    }
    if (maxVal == 0.0) maxVal = 10.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bar_chart,
                  color: primaryGreen,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                "Volume d'irrigation 7 derniers jours (m³)",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 140,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.map((item) {
                final percentage = item.value / maxVal;
                final barHeight = percentage * 90;

                return Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (item.value > 0)
                      Text(
                        item.value.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: primaryGreen,
                        ),
                      )
                    else
                      const Text(
                        "0",
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.black26,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Container(
                      width: 14,
                      height: barHeight == 0 ? 4 : barHeight,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: item.value > 0
                              ? [Colors.lightBlueAccent, Colors.blue[600]!]
                              : [Colors.grey[200]!, Colors.grey[300]!],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}