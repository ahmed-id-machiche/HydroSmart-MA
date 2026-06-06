import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

import '../constants/app_colors.dart';
import '../models/crop.dart';
import '../models/soil.dart';
import '../services/api_services.dart';
import '../state/selected_location.dart';
import 'map_picker_screen.dart';

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
  bool isCustomCrop = false;
  final TextEditingController customCropController = TextEditingController();

  List<Soil> soils = [];
  Soil? selectedSoil;

  final TextEditingController surfaceController = TextEditingController();
  double? selectedSurface;

  final List<double> surfaceOptions = const [
    0.5,
    1,
    2,
    3,
    5,
    10,
  ];

  @override
  void initState() {
    super.initState();
    loadCropsAndSoils();
  }

  @override
  void dispose() {
    customCropController.dispose();
    surfaceController.dispose();
    super.dispose();
  }

  Future<void> loadCropsAndSoils() async {
    try {
      final cropsData = await ApiService.getCrops();
      final soilsData = await ApiService.getSoils();

      if (!mounted) return;

      setState(() {
        crops = cropsData;
        selectedCrop = cropsData.isNotEmpty ? cropsData.first : null;

        soils = soilsData;
        Soil? defaultSoil;
        for (final s in soilsData) {
          if (s.id == "limoneux") {
            defaultSoil = s;
            break;
          }
        }
        selectedSoil = defaultSoil ?? (soilsData.isNotEmpty ? soilsData.first : Soil(id: "limoneux", nom: "Limoneux"));

        selectedSurface = surfaceOptions.first;
        surfaceController.text = selectedSurface.toString();
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur chargement des données: $error")),
      );
    }
  }

  String generatedFieldName() {
    if (isCustomCrop) {
      final name = customCropController.text.trim();
      return name.isNotEmpty ? "Parcelle $name" : "Parcelle Autre";
    }
    if (selectedCrop == null) {
      return "Parcelle";
    }

    return "Parcelle ${selectedCrop!.nom}";
  }

  IconData getCropIcon(String cropName) {
    final name = cropName.toLowerCase();
    if (name.contains("tomate") || name.contains("tomato")) {
      return Icons.spa_outlined;
    } else if (name.contains("oliv") || name.contains("olive")) {
      return Icons.park_outlined;
    } else if (name.contains("agrume") || name.contains("citrus") || name.contains("orange")) {
      return Icons.circle_outlined;
    } else if (name.contains("menthe") || name.contains("mint") || name.contains("herbe")) {
      return Icons.grass_outlined;
    } else if (name.contains("ble") || name.contains("wheat")) {
      return Icons.agriculture;
    } else if (name.contains("pomme de terre") || name.contains("potato")) {
      return Icons.cookie_outlined;
    }
    return Icons.eco_outlined;
  }

  Color getCropColor(String cropName) {
    final name = cropName.toLowerCase();
    if (name.contains("tomate") || name.contains("tomato")) {
      return Colors.red;
    } else if (name.contains("oliv") || name.contains("olive")) {
      return Colors.green.shade800;
    } else if (name.contains("agrume") || name.contains("citrus") || name.contains("orange")) {
      return Colors.orange;
    } else if (name.contains("menthe") || name.contains("mint") || name.contains("herbe")) {
      return Colors.green.shade400;
    } else if (name.contains("ble") || name.contains("wheat")) {
      return Colors.amber.shade700;
    } else if (name.contains("pomme de terre") || name.contains("potato")) {
      return Colors.brown.shade400;
    }
    return primaryGreen;
  }

  Future<String> getPlaceName(double lat, double lon) async {
    try {
      final places = await placemarkFromCoordinates(lat, lon);

      if (places.isEmpty) {
        return "Maroc";
      }

      final place = places.first;

      String clean(String? value) {
        if (value == null) return "";
        return value.trim();
      }

      final locality = clean(place.locality);
      final subAdministrativeArea = clean(place.subAdministrativeArea);
      final administrativeArea = clean(place.administrativeArea);
      final country = clean(place.country);

      final city = locality.isNotEmpty ? locality : subAdministrativeArea;
      final region = administrativeArea;

      if (city.isNotEmpty && region.isNotEmpty) {
        return "$city, $region";
      }

      if (city.isNotEmpty) {
        return city;
      }

      if (region.isNotEmpty) {
        return region;
      }

      if (country.isNotEmpty) {
        return country;
      }

      return "Maroc";
    } catch (_) {
      return "Maroc";
    }
  }

  Future<void> openMapPicker() async {
    final result = await Navigator.push<MapPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          initialLat: SelectedLocation.latitude ?? 30.418,
          initialLon: SelectedLocation.longitude ?? -9.558,
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      saving = true;
    });

    try {
      final placeName = await getPlaceName(result.latitude, result.longitude);
      SelectedLocation.update(
        lat: result.latitude,
        lon: result.longitude,
        locationName: placeName,
      );
    } catch (e) {
      SelectedLocation.update(
        lat: result.latitude,
        lon: result.longitude,
        locationName: "Maroc",
      );
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  Future<void> saveField() async {
    final selectedLocationName = SelectedLocation.name?.trim();
    final selectedLatitude = SelectedLocation.latitude;
    final selectedLongitude = SelectedLocation.longitude;

    final inputSurface = double.tryParse(surfaceController.text);
    if (inputSurface == null || inputSurface <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez entrer une superficie valide.")),
      );
      return;
    }

    if (selectedSoil == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez sélectionner un type de sol.")),
      );
      return;
    }

    if (isCustomCrop && customCropController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez saisir le nom de la culture.")),
      );
      return;
    }

    if (!isCustomCrop && selectedCrop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez sélectionner une culture.")),
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
            "Veuillez choisir la localisation depuis cet écran ou le Home avant d'ajouter une parcelle.",
          ),
        ),
      );
      return;
    }

    try {
      setState(() {
        saving = true;
      });

      String cropId;
      if (isCustomCrop) {
        final createdCrop = await ApiService.createCrop(
          nom: customCropController.text.trim(),
        );
        cropId = createdCrop.id;
      } else {
        cropId = selectedCrop!.id;
      }

      await ApiService.addPlot(
        cropId: cropId,
        nom: generatedFieldName(),
        superficie: inputSurface,
        localisation: selectedLocationName,
        typeSol: selectedSoil!.id,
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
                          onTap: openMapPicker,
                        ),

                        const SizedBox(height: 18),

                        SectionCard(
                          title: "Choisir la culture",
                          subtitle: "Sélectionnez ce qui est planté.",
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<Crop?>(
                                value: isCustomCrop ? null : selectedCrop,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: primaryGreen.withOpacity(0.3),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: primaryGreen.withOpacity(0.3),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: primaryGreen,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                hint: const Text("Sélectionner la culture"),
                                items: [
                                  ...crops.map((crop) {
                                    return DropdownMenuItem<Crop?>(
                                      value: crop,
                                      child: Row(
                                        children: [
                                          Icon(
                                            getCropIcon(crop.nom),
                                            color: getCropColor(crop.nom),
                                            size: 20,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            crop.nom,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: darkText,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  const DropdownMenuItem<Crop?>(
                                    value: null,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.add_circle_outline,
                                          color: Colors.blueGrey,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          "Autre culture (Saisir)...",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueGrey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    if (value == null) {
                                      isCustomCrop = true;
                                      selectedCrop = null;
                                    } else {
                                      isCustomCrop = false;
                                      selectedCrop = value;
                                    }
                                  });
                                },
                              ),
                              if (isCustomCrop) ...[
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: customCropController,
                                  decoration: InputDecoration(
                                    labelText: "Nom de la culture",
                                    hintText: "Ex: Menthe, Carotte, etc.",
                                    prefixIcon: const Icon(
                                      Icons.edit_note,
                                      color: primaryGreen,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: primaryGreen.withOpacity(0.3),
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: primaryGreen.withOpacity(0.3),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: primaryGreen,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  onChanged: (val) {
                                    setState(() {});
                                  },
                                ),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        SectionCard(
                          title: "Choisir la superficie",
                          subtitle: "Superficie de la parcelle en hectares.",
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: surfaceController,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: InputDecoration(
                                  labelText: "Superficie (ha)",
                                  hintText: "Ex: 1.5, 0.75, 12.0",
                                  prefixIcon: const Icon(
                                    Icons.straighten_outlined,
                                    color: primaryGreen,
                                  ),
                                  suffixText: "ha",
                                  suffixStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: primaryGreen,
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: primaryGreen.withOpacity(0.3),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: primaryGreen.withOpacity(0.3),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: primaryGreen,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    selectedSurface = double.tryParse(val);
                                  });
                                },
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                "Options de superficie rapide :",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
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
                                        surfaceController.text = formatSurface(surface);
                                      });
                                    },
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        SectionCard(
                          title: "Choisir le type de sol",
                          subtitle: "Sélectionnez le sol dominant.",
                          child: soils.isEmpty
                              ? const Text(
                                  "Aucun sol disponible.",
                                  style: TextStyle(color: Colors.black54),
                                )
                              : Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: soils.map((soil) {
                                    final selected = selectedSoil?.id == soil.id;

                                    return ChoiceChipCard(
                                      label: soil.nom,
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
                          cropName: isCustomCrop
                              ? customCropController.text
                              : (selectedCrop?.nom ?? "-"),
                          surface: selectedSurface,
                          soil: selectedSoil?.nom ?? "-",
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
                            : "Choisir localisation",
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
  final VoidCallback onTap;

  const LocationCard({
    super.key,
    required this.hasLocation,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: hasLocation
                      ? primaryGreen.withOpacity(0.12)
                      : Colors.orange.shade100,
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
                            Row(
                              children: [
                                const Text(
                                  "Localisation de la parcelle",
                                  style: TextStyle(
                                    color: darkText,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const Spacer(),
                                const Icon(Icons.edit_location_alt, size: 16, color: primaryGreen),
                                const SizedBox(width: 4),
                                const Text(
                                  "Modifier",
                                  style: TextStyle(
                                    color: primaryGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
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
                              "Appuyez ici pour choisir la localisation sur la carte.",
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
          ),
        ),
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