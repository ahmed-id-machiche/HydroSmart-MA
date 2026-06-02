import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/plot.dart';
import '../services/api_services.dart';
import '../widgets/analyse_info_row.dart';

class AnalyseScreen extends StatefulWidget {
  const AnalyseScreen({super.key});

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

  String message = "Sélectionnez une parcelle puis générez une recommandation.";
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
        selectedPlot = data.isNotEmpty ? data.first : null;
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

  Future<void> generateRecommendation() async {
    if (selectedPlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Choisissez une parcelle.")),
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

        message = recommendation["message"] ??
            "Recommandation générée avec succès.";

        frequency = recVolume > 0 ? "1 fois/jour" : "Aucune";
        duration = recVolume > 0 ? "45 min" : "0 min";

        usedDefaultLocation = result["usedDefaultLocation"] == true;
        generating = false;
      });

      if (usedDefaultLocation && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "GPS absent pour cette parcelle. Localisation Agadir utilisée par défaut.",
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
        SnackBar(content: Text("Erreur recommandation: $error")),
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
                  const Row(
                    children: [
                      Icon(Icons.arrow_back, color: Colors.white),
                      Spacer(),
                      Text(
                        "Analyse",
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
                                "Aucune parcelle disponible.",
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
                                                "Cliquez sur Générer pour calculer la recommandation.";
                                            et0 = 0;
                                            etc = 0;
                                            netNeed = 0;
                                            grossNeed = 0;
                                            volumeM3 = 0;
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
                              "${plot.crop?.nom ?? 'Culture'} • ${plot.typeSol} • ${plot.localisation}",
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
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardGreen,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Besoin en eau aujourd’hui",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: darkText,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.78),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "${grossNeed.toStringAsFixed(2)} mm",
                                      style: const TextStyle(
                                        fontSize: 34,
                                        fontWeight: FontWeight.bold,
                                        color: primaryGreen,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "ET0 ${et0.toStringAsFixed(2)} mm   Kc ${plot?.crop?.coefficientKc ?? 0}",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "ETc ${etc.toStringAsFixed(2)} mm",
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 82,
                                height: 82,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE9F8FF),
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: const Icon(
                                  Icons.water_drop,
                                  size: 58,
                                  color: Colors.lightBlueAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardGreen,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        AnalyseInfoRow(
                          icon: Icons.water_drop_outlined,
                          label: "Volume recommandé",
                          value: "${volumeM3.toStringAsFixed(2)} m³",
                        ),
                        const Divider(height: 24),
                        AnalyseInfoRow(
                          icon: Icons.timer_outlined,
                          label: "Durée d’irrigation",
                          value: duration,
                        ),
                        const Divider(height: 24),
                        AnalyseInfoRow(
                          icon: Icons.calendar_month_outlined,
                          label: "Fréquence",
                          value: frequency,
                        ),
                        const Divider(height: 24),
                        AnalyseInfoRow(
                          icon: Icons.access_time_outlined,
                          label: "Meilleur moment",
                          value: "Tôt le matin",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardGreen,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Météo utilisée",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: darkText,
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
                            ),
                            WeatherSmallStat(
                              label: "Humidité",
                              value: "${humidity.toStringAsFixed(0)}%",
                              icon: Icons.water_drop_outlined,
                            ),
                            WeatherSmallStat(
                              label: "Vent",
                              value: "${windSpeed.toStringAsFixed(1)} m/s",
                              icon: Icons.air,
                            ),
                            WeatherSmallStat(
                              label: "Pluie",
                              value: "${rainfall.toStringAsFixed(1)} mm",
                              icon: Icons.cloudy_snowing,
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
                      color: const Color(0xFFE9F8FF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.lightBlueAccent.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            message,
                            style: const TextStyle(
                              fontSize: 12,
                              color: darkText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    height: 54,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF49AE62),
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
                            ? "Calcul en cours..."
                            : "Générer recommandation",
                        style: const TextStyle(fontWeight: FontWeight.bold),
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

  const WeatherSmallStat({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: primaryGreen),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black54,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: darkText,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}