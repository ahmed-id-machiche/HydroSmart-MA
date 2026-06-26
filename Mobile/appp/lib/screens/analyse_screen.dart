import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/plot.dart';
import '../services/api_services.dart';
import '../widgets/analyse_info_row.dart';
import '../widgets/notification_bell.dart';

class AnalyseScreen extends StatefulWidget {
  final Plot? initialPlot;

  const AnalyseScreen({super.key, this.initialPlot});

  @override
  State<AnalyseScreen> createState() => _AnalyseScreenState();
}

class _AnalyseScreenState extends State<AnalyseScreen> {
  bool loading = true;
  bool generating = false;

  List<Plot> plots = [];
  Plot? selectedPlot;

  double temperature = 0;
  double humidity = 0;
  double windSpeed = 0;
  double rainfall = 0;

  double et0 = 0;
  double etc = 0;
  double netNeed = 0;
  double grossNeed = 0;
  double volumeM3 = 0;

  double? ndvi;
  double? soilMoisture;
  String kcSource = "base_db";

  String message = "Select a plot then generate a recommendation.";
  String frequency = "-";
  String duration = "-";
  bool usedDefaultLocation = false;

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
        if (widget.initialPlot != null) {
          try {
            selectedPlot = data.firstWhere((p) => p.id == widget.initialPlot!.id);
          } catch (_) {
            selectedPlot = widget.initialPlot;
          }
        } else {
          selectedPlot = data.isNotEmpty ? data.first : null;
        }
        loading = false;
      });

      if (widget.initialPlot != null) {
        generateRecommendation();
      }
    } catch (error) {
      setState(() {
        loading = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading plots: $error")),
      );
    }
  }

  Future<void> generateRecommendation() async {
    if (selectedPlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Choose a plot.")),
      );
      return;
    }

    try {
      setState(() {
        generating = true;
      });

      final result = await ApiService.generateRecommendationForPlot(
        selectedPlot!,
      );

      final weather = result["weather"] as Map<String, dynamic>;
      final recommendation =
          result["recommendation"] as Map<String, dynamic>;
      final metadata = recommendation["metadata"] as Map<String, dynamic>?;

      final recVolume =
          double.tryParse(recommendation["volumeM3"].toString()) ?? 0;

      setState(() {
        temperature =
            double.tryParse(weather["temperature"].toString()) ?? 0;
        humidity = double.tryParse(weather["humidite"].toString()) ?? 0;
        windSpeed =
            double.tryParse(weather["vitesseVent"].toString()) ?? 0;
        rainfall =
            double.tryParse(weather["precipitation"].toString()) ?? 0;

        et0 = double.tryParse(recommendation["et0"].toString()) ?? 0;
        etc = double.tryParse(recommendation["etc"].toString()) ?? 0;
        netNeed =
            double.tryParse(recommendation["netNeedMm"].toString()) ?? 0;
        grossNeed =
            double.tryParse(recommendation["grossNeedMm"].toString()) ?? 0;
        volumeM3 = recVolume;

        ndvi = metadata?["ndvi"] != null 
            ? double.tryParse(metadata!["ndvi"].toString()) 
            : null;
        soilMoisture = metadata?["soilMoisture"] != null 
            ? double.tryParse(metadata!["soilMoisture"].toString()) 
            : null;
        kcSource = metadata?["kcSource"]?.toString() ?? "base_db";

        message = recommendation["message"] ??
            "Recommendation generated successfully.";

        frequency = recommendation["frequence"]?.toString() ?? 
            (recVolume > 0 ? "once/day" : "none");
        duration = recommendation["dureeText"]?.toString() ?? 
            (recVolume > 0 ? "45 min" : "0 min");

        usedDefaultLocation = result["usedDefaultLocation"] == true;
        generating = false;
      });

      if (usedDefaultLocation && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "GPS missing for this plot. Agadir location used by default.",
            ),
          ),
        );
      }
    } catch (error) {
      setState(() {
        generating = false;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error generating recommendation: $error")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final plot = selectedPlot;

    return Scaffold(
      backgroundColor: lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
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
                        "Analyse",
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
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD9F8D9),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: loading
                        ? const Center(child: CircularProgressIndicator())
                        : plots.isEmpty
                            ? const Text(
                                "No plots available.",
                                style: TextStyle(
                                  color: darkText,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : Row(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.grass,
                                      color: primaryGreen,
                                      size: 34,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<Plot>(
                                        value: selectedPlot,
                                        isExpanded: true,
                                        items: plots.map((item) {
                                          return DropdownMenuItem<Plot>(
                                            value: item,
                                            child: Text(
                                              "${item.nom} - ${item.superficie} ha",
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: darkText,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          setState(() {
                                            selectedPlot = value;
                                            message =
                                                "Click Generate to calculate recommendations.";
                                            et0 = 0;
                                            etc = 0;
                                            netNeed = 0;
                                            grossNeed = 0;
                                            volumeM3 = 0;
                                            ndvi = null;
                                            soilMoisture = null;
                                            kcSource = "base_db";
                                            frequency = "-";
                                            duration = "-";
                                          });
                                        },
                                      ),
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
                  if (plot != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: primaryGreen,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              "${plot.crop?.nom ?? 'Crop'} • ${plot.typeSol} • ${plot.localisation}",
                              style: const TextStyle(
                                color: darkText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  Container(
                    padding: const EdgeInsets.all(20),
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
                                color: Colors.blue.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.opacity,
                                color: Colors.blue,
                                size: 16,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              "Water need today",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: darkText,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${grossNeed.toStringAsFixed(2)} mm",
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: primaryGreen,
                                    letterSpacing: -1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    "Real ETc: ${etc.toStringAsFixed(2)} mm",
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: darkText.withOpacity(0.7),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0F9FF),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.lightBlueAccent.withOpacity(0.2),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    "ET0 (Weather)",
                                    style: TextStyle(
                                      color: Colors.lightBlue[800],
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "${et0.toStringAsFixed(2)} mm",
                                    style: TextStyle(
                                      color: Colors.lightBlue[900],
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "Kc : ${plot?.crop?.coefficientKc ?? 0.0}",
                                    style: TextStyle(
                                      color: Colors.lightBlue[800],
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(18),
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
                    child: Column(
                      children: [
                        AnalyseInfoRow(
                          icon: Icons.water_drop_outlined,
                          label: "Recommended volume",
                          value: "${volumeM3.toStringAsFixed(2)} m³",
                        ),
                        const Divider(height: 20, thickness: 0.6),
                        AnalyseInfoRow(
                          icon: Icons.timer_outlined,
                          label: "Irrigation duration",
                          value: duration,
                        ),
                        const Divider(height: 20, thickness: 0.6),
                        AnalyseInfoRow(
                          icon: Icons.calendar_month_outlined,
                          label: "Frequency",
                          value: frequency,
                        ),
                        const Divider(height: 20, thickness: 0.6),
                        AnalyseInfoRow(
                          icon: Icons.access_time_outlined,
                          label: "Best time",
                          value: "Early morning",
                        ),
                      ],
                    ),
                  ),
                  
                  if (ndvi != null || soilMoisture != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(18),
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
                                  Icons.settings_input_antenna,
                                  color: primaryGreen,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                "Sentinel-2 Satellite Measurements",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: darkText,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          if (ndvi != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.spa_outlined, color: primaryGreen, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Plant health (NDVI)",
                                      style: TextStyle(
                                        color: darkText.withOpacity(0.7),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  "${(ndvi! * 100).toStringAsFixed(0)}%",
                                  style: const TextStyle(
                                    color: darkText,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: ndvi!.clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  ndvi! < 0.35
                                      ? Colors.orange
                                      : (ndvi! < 0.6
                                          ? Colors.lightGreen
                                          : primaryGreen),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          if (soilMoisture != null) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.opacity, color: Colors.blue, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Soil moisture",
                                      style: TextStyle(
                                        color: darkText.withOpacity(0.7),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  "${(soilMoisture! * 100).toStringAsFixed(1)}%",
                                  style: const TextStyle(
                                    color: darkText,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: soilMoisture!.clamp(0.0, 1.0),
                                minHeight: 6,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  soilMoisture! < 0.2
                                      ? Colors.redAccent
                                      : (soilMoisture! < 0.4
                                          ? Colors.blueAccent
                                          : Colors.blue[800]!),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Crop coefficient source (Kc):",
                                style: TextStyle(
                                  color: darkText.withOpacity(0.6),
                                  fontSize: 11,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: kcSource == "satellite_ndvi"
                                      ? primaryGreen.withOpacity(0.1)
                                      : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  kcSource == "satellite_ndvi" ? "Satellite" : "FAO standard",
                                  style: TextStyle(
                                    color: kcSource == "satellite_ndvi"
                                        ? primaryGreen
                                        : Colors.black54,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(18),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Weather data used",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: darkText,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            WeatherSmallStat(
                              label: "Temp",
                              value: "${temperature.toStringAsFixed(1)}°C",
                              icon: Icons.thermostat,
                              iconColor: Colors.orange,
                            ),
                            WeatherSmallStat(
                              label: "Humidity",
                              value: "${humidity.toStringAsFixed(0)}%",
                              icon: Icons.water_drop_outlined,
                              iconColor: Colors.blue,
                            ),
                            WeatherSmallStat(
                              label: "Wind",
                              value: "${windSpeed.toStringAsFixed(1)} m/s",
                              icon: Icons.air,
                              iconColor: Colors.teal,
                            ),
                            WeatherSmallStat(
                              label: "Rain",
                              value: "${rainfall.toStringAsFixed(1)} mm",
                              icon: Icons.cloudy_snowing,
                              iconColor: Colors.lightBlue,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.lightBlue.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.lightBlue,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            message,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: darkText,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Container(
                    height: 54,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF4DB6AC),
                          Color(0xFF2E7D32),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2E7D32).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed: generating ? null : generateRecommendation,
                      icon: generating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.water_drop),
                      label: Text(
                        generating
                            ? "Calculating..."
                            : "Generate recommendation",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          letterSpacing: 0.5,
                        ),
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

class WeatherSmallStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const WeatherSmallStat({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: darkText.withOpacity(0.5),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: darkText,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}