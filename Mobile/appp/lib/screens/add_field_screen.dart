import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../models/crop.dart';
import '../services/api_services.dart';
import '../state/selected_location.dart';

class AddFieldScreen extends StatefulWidget {
  const AddFieldScreen({super.key});

  @override
  State<AddFieldScreen> createState() => _AddFieldScreenState();
}

class _AddFieldScreenState extends State<AddFieldScreen> {
  bool loading = true;
  bool saving = false;

  List<Crop> crops = [];
  Crop? selectedCrop;

  double? selectedSurface;
  String selectedSoil = "limoneux";

  final List<double> surfaceOptions = const [
    0.5,
    1,
    2,
    3,
    5,
    10,
  ];

  final soilTypes = const [
    "argileux",
    "limoneux",
    "sableux",
    "calcaire",
  ];

  @override
  void initState() {
    super.initState();
    loadCrops();
  }

  Future<void> loadCrops() async {
    try {
      final data = await ApiService.getCrops();

      if (!mounted) return;

      setState(() {
        crops = data;
        selectedCrop = data.isNotEmpty ? data.first : null;
        selectedSurface = surfaceOptions.first;
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur chargement cultures: $error")),
      );
    }
  }

  String generatedFieldName() {
    if (selectedCrop == null) {
      return "Parcelle";
    }

    return "Parcelle ${selectedCrop!.nom}";
  }

  Future<void> saveField() async {
    final selectedLocationName = SelectedLocation.name?.trim();
    final selectedLatitude = SelectedLocation.latitude;
    final selectedLongitude = SelectedLocation.longitude;

    if (selectedCrop == null || selectedSurface == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez sélectionner les informations.")),
      );
      return;
    }

    if (!SelectedLocation.hasLocation ||
        selectedLocationName == null ||
        selectedLocationName.isEmpty ||
        selectedLatitude == null ||
        selectedLongitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Veuillez choisir la localisation depuis l'écran Home avant d'ajouter une parcelle.",
          ),
        ),
      );
      return;
    }

    try {
      setState(() {
        saving = true;
      });

      await ApiService.addPlot(
        cropId: selectedCrop!.id,
        nom: generatedFieldName(),
        superficie: selectedSurface!,
        localisation: selectedLocationName,
        typeSol: selectedSoil,
        latitude: selectedLatitude,
        longitude: selectedLongitude,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur ajout parcelle: $error")),
      );
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationName = SelectedLocation.name;
    final latitude = SelectedLocation.latitude;
    final longitude = SelectedLocation.longitude;
    final hasLocation = SelectedLocation.hasLocation;

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
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context, false),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Spacer(),
                  const Text(
                    "Ajouter parcelle",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(18),
                      children: [
                        LocationCard(
                          hasLocation: hasLocation,
                          locationName: locationName,
                          latitude: latitude,
                          longitude: longitude,
                        ),

                        const SizedBox(height: 18),

                        SectionCard(
                          title: "Choisir la culture",
                          subtitle: "Sélectionnez ce qui est planté.",
                          child: crops.isEmpty
                              ? const Text(
                                  "Aucune culture disponible.",
                                  style: TextStyle(color: Colors.black54),
                                )
                              : Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: crops.map((crop) {
                                    final selected = selectedCrop?.id == crop.id;

                                    return ChoiceChipCard(
                                      label: crop.nom,
                                      icon: Icons.eco_outlined,
                                      selected: selected,
                                      onTap: () {
                                        setState(() {
                                          selectedCrop = crop;
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                        ),

                        const SizedBox(height: 18),

                        SectionCard(
                          title: "Choisir la superficie",
                          subtitle: "Surface approximative en hectare.",
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: surfaceOptions.map((surface) {
                              final selected = selectedSurface == surface;

                              return ChoiceChipCard(
                                label: "${formatSurface(surface)} ha",
                                icon: Icons.square_foot_outlined,
                                selected: selected,
                                onTap: () {
                                  setState(() {
                                    selectedSurface = surface;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 18),

                        SectionCard(
                          title: "Choisir le type de sol",
                          subtitle: "Sélectionnez le sol dominant.",
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: soilTypes.map((soil) {
                              final selected = selectedSoil == soil;

                              return ChoiceChipCard(
                                label: soil,
                                icon: Icons.terrain_outlined,
                                selected: selected,
                                onTap: () {
                                  setState(() {
                                    selectedSoil = soil;
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 18),

                        PreviewCard(
                          fieldName: generatedFieldName(),
                          cropName: selectedCrop?.nom ?? "-",
                          surface: selectedSurface,
                          soil: selectedSoil,
                          location: locationName,
                        ),

                        const SizedBox(height: 100),
                      ],
                    ),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
              decoration: BoxDecoration(
                color: lightBackground,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 14,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                height: 54,
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: hasLocation ? primaryGreen : Colors.grey,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed: saving || !hasLocation ? null : saveField,
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.add),
                  label: Text(
                    saving
                        ? "Ajout en cours..."
                        : hasLocation
                            ? "Ajouter la parcelle"
                            : "Choisir localisation dans Home",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String formatSurface(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toString();
  }
}

class LocationCard extends StatelessWidget {
  final bool hasLocation;
  final String? locationName;
  final double? latitude;
  final double? longitude;

  const LocationCard({
    super.key,
    required this.hasLocation,
    required this.locationName,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: hasLocation ? Colors.white : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: hasLocation ? Colors.transparent : Colors.orange.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor:
                hasLocation ? primaryGreen.withOpacity(0.12) : Colors.orange.shade100,
            child: Icon(
              hasLocation ? Icons.location_on_outlined : Icons.warning_amber_rounded,
              color: hasLocation ? primaryGreen : Colors.orange,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: hasLocation
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Localisation depuis Home",
                        style: TextStyle(
                          color: darkText,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        locationName ?? "Maroc",
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 14,
                        ),
                      ),
                      if (latitude != null && longitude != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          "Lat: ${latitude!.toStringAsFixed(5)} | Lon: ${longitude!.toStringAsFixed(5)}",
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  )
                : const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Aucune localisation sélectionnée",
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        "Retournez à Home puis appuyez sur “Changer” pour choisir une localisation.",
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const SectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: darkText,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class ChoiceChipCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const ChoiceChipCard({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: selected ? primaryGreen : lightBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? primaryGreen : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 17,
              color: selected ? Colors.white : primaryGreen,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : darkText,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PreviewCard extends StatelessWidget {
  final String fieldName;
  final String cropName;
  final double? surface;
  final String soil;
  final String? location;

  const PreviewCard({
    super.key,
    required this.fieldName,
    required this.cropName,
    required this.surface,
    required this.soil,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: primaryGreen.withOpacity(0.09),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: primaryGreen.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Résumé",
            style: TextStyle(
              color: primaryGreen,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          PreviewLine(label: "Nom", value: fieldName),
          PreviewLine(label: "Culture", value: cropName),
          PreviewLine(
            label: "Surface",
            value: surface == null ? "-" : "${formatPreviewSurface(surface!)} ha",
          ),
          PreviewLine(label: "Sol", value: soil),
          PreviewLine(label: "Localisation", value: location ?? "-"),
        ],
      ),
    );
  }

  String formatPreviewSurface(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }

    return value.toString();
  }
}

class PreviewLine extends StatelessWidget {
  final String label;
  final String value;

  const PreviewLine({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: darkText,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}