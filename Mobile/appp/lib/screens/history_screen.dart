import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../services/api_services.dart';
import '../widgets/notification_bell.dart';

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
        SnackBar(content: Text("Error loading history: $error")),
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

  void showRecommendationDetails(Map<String, dynamic> item) {
    final plotName = getPlotName(item);
    final cropName = getCropName(item);
    final date = item["date"]?.toString() ?? "-";
    final et0 = getDouble(item, "et0");
    final etc = getDouble(item, "etc");
    final water = getDouble(item, "quantite_eau");

    final rec = item["irrigation_recommendations"];
    String message = "No recommendation details available.";
    String duration = "-";
    String frequency = "-";
    double netNeed = 0.0;
    double grossNeed = 0.0;

    if (rec is Map<String, dynamic>) {
      message = rec["message"]?.toString() ?? "No message saved.";
      frequency = rec["frequence"]?.toString() ?? "-";
      final rawDuration = double.tryParse(rec["duree_irrigation"]?.toString() ?? "") ?? 0;
      if (rawDuration > 0) {
        duration = "${(rawDuration * 60).round()} min";
      } else {
        duration = "0 min";
      }
      netNeed = double.tryParse(rec["besoin_net"]?.toString() ?? "") ?? 0.0;
      grossNeed = double.tryParse(rec["besoin_brut"]?.toString() ?? "") ?? 0.0;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F9FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        getCropImagePath(cropName),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.water_drop,
                          color: Colors.blueAccent,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          plotName,
                          style: const TextStyle(
                            color: darkText,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const Divider(height: 24),
              const Text(
                "Recommendation Details",
                style: TextStyle(
                  color: darkText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: primaryGreen.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: primaryGreen.withOpacity(0.12),
                  ),
                ),
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _buildDetailCard(
                      icon: Icons.opacity,
                      color: Colors.blue,
                      title: "Volume",
                      value: "${water.toStringAsFixed(2)} m³",
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDetailCard(
                      icon: Icons.timer,
                      color: Colors.orange,
                      title: "Duration",
                      value: duration,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDetailCard(
                      icon: Icons.event_repeat,
                      color: Colors.teal,
                      title: "Frequency",
                      value: frequency,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Text(
                "Water Requirements & Weather Metrics",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricRow("Reference ET (ET0):", "${et0.toStringAsFixed(2)} mm"),
                  ),
                  Expanded(
                    child: _buildMetricRow("Crop Need (ETc):", "${etc.toStringAsFixed(2)} mm"),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricRow("Net Deficit:", "${netNeed.toStringAsFixed(2)} mm"),
                  ),
                  Expanded(
                    child: _buildMetricRow("Gross Deficit:", "${grossNeed.toStringAsFixed(2)} mm"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[100]!),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            title,
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
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            color: darkText,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
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
    final weekdayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];
    
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
    } else if (name.contains("pommier") || name.contains("apple")) {
      return "assets/images/apple.png";
    } else if (name.contains("avocat") || name.contains("avocado")) {
      return "assets/images/avocado.png";
    } else if (name.contains("vigne") || name.contains("grape")) {
      return "assets/images/grape.png";
    } else if (name.contains("pasteque") || name.contains("watermelon")) {
      return "assets/images/watermelon.png";
    } else if (name.contains("carotte") || name.contains("carrot")) {
      return "assets/images/carrot.png";
    } else if (name.contains("menthe") || name.contains("mint")) {
      return "assets/images/mint.png";
    } else if (name.contains("luzerne") || name.contains("alfalfa")) {
      return "assets/images/alfalfa.png";
    } else if (name.contains("poivron") || name.contains("pepper")) {
      return "assets/images/pepper.png";
    } else if (name.contains("poirier") || name.contains("pear") ||
               name.contains("grenadier") || name.contains("pomegranate") ||
               name.contains("figuier") || name.contains("fig") ||
               name.contains("amandier") || name.contains("almond")) {
      return "assets/images/citrus.png"; // Fallback tree image
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
                  if (Navigator.canPop(context))
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  else
                    const SizedBox(width: 24),
                  const Spacer(),
                  const Text(
                    "History",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  const NotificationBell(),
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
                                  "No irrigation history found.",
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
                                "Recent Irrigations",
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
                                return GestureDetector(
                                  onTap: () => showRecommendationDetails(item),
                                  child: Container(
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
                "Irrigation volume last 7 days (m³)",
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