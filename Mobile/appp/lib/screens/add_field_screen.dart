import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

import '../constants/app_colors.dart';
import '../models/crop.dart';
import '../models/soil.dart';
import '../services/api_services.dart';
import '../state/selected_location.dart';
import 'map_picker_screen.dart';

import '../models/plot.dart';

class AddFieldScreen extends StatefulWidget {
  final Plot? plotToEdit;
  const AddFieldScreen({super.key, this.plotToEdit});

  @override
  State<AddFieldScreen> createState() => _AddFieldScreenState();
}

class _AddFieldScreenState extends State<AddFieldScreen> {
  bool loading = true;
  bool saving = false;

  List<Crop> crops = [];
  Crop? selectedCrop;
  bool isCustomCrop = false;
  String? selectedCategory;
  String? selectedCategoryCrop;
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
        soils = soilsData;

        initializeCropDropdowns(cropsData);

        if (widget.plotToEdit != null) {
          selectedSoil = soilsData.firstWhere(
            (s) => s.id == widget.plotToEdit!.typeSol,
            orElse: () => soilsData.isNotEmpty ? soilsData.first : Soil(id: "limoneux", nom: "Limoneux"),
          );

          selectedSurface = widget.plotToEdit!.superficie;
          surfaceController.text = selectedSurface.toString();

          if (widget.plotToEdit!.latitude != null && widget.plotToEdit!.longitude != null) {
            SelectedLocation.update(
              lat: widget.plotToEdit!.latitude!,
              lon: widget.plotToEdit!.longitude!,
              locationName: widget.plotToEdit!.localisation,
            );
          }
        } else {
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
        }
        loading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error loading data: $error")),
      );
    }
  }

  void initializeCropDropdowns(List<Crop> cropsData) {
    if (widget.plotToEdit == null || widget.plotToEdit!.crop == null) {
      // Default to first category and first crop
      selectedCategory = cropCategories.first.name;
      selectedCategoryCrop = cropCategories.first.cropNames.first;
      final cleanName = cleanCropName(selectedCategoryCrop!);
      selectedCrop = cropsData.firstWhere(
        (c) => c.nom.toLowerCase() == cleanName.toLowerCase(),
        orElse: () => cropsData.isNotEmpty ? cropsData.first : Crop(id: "dummy", nom: cleanName, coefficientKc: 0.85),
      );
      isCustomCrop = !cropsData.any((c) => c.id == selectedCrop?.id);
      if (isCustomCrop) {
        customCropController.text = cleanName;
      }
      return;
    }

    final cropName = widget.plotToEdit!.crop!.nom.trim();
    final isDbCrop = cropsData.any((c) => c.id == widget.plotToEdit!.crop!.id);

    for (final cat in cropCategories) {
      for (final cName in cat.cropNames) {
        if (cleanCropName(cName).toLowerCase() == cropName.toLowerCase()) {
          selectedCategory = cat.name;
          selectedCategoryCrop = cName;
          isCustomCrop = !isDbCrop;
          if (isDbCrop) {
            selectedCrop = cropsData.firstWhere((c) => c.id == widget.plotToEdit!.crop!.id);
          } else {
            customCropController.text = cropName;
          }
          return;
        }
      }
    }

    // Default fallback to "Other" entered manually
    selectedCategory = "Other crop (Enter)...";
    selectedCategoryCrop = null;
    isCustomCrop = true;
    selectedCrop = null;
    customCropController.text = cropName;
  }

  String generatedFieldName() {
    if (widget.plotToEdit != null) {
      return widget.plotToEdit!.nom;
    }
    if (isCustomCrop) {
      final name = customCropController.text.trim();
      return name.isNotEmpty ? "Plot $name" : "Plot Other";
    }
    if (selectedCrop == null) {
      return "Plot";
    }

    return "Plot ${selectedCrop!.nom}";
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
        return "Morocco";
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

      return "Morocco";
    } catch (_) {
      return "Morocco";
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
        locationName: "Morocco",
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
        const SnackBar(content: Text("Please enter a valid area.")),
      );
      return;
    }

    if (selectedSoil == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a soil type.")),
      );
      return;
    }

    if (isCustomCrop && customCropController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter the crop name.")),
      );
      return;
    }

    if (!isCustomCrop && selectedCrop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a crop.")),
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
            "Please choose a location from this screen or Home before adding/editing a plot.",
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

      if (widget.plotToEdit != null) {
        await ApiService.updatePlot(
          id: widget.plotToEdit!.id,
          cropId: cropId,
          nom: generatedFieldName(),
          superficie: inputSurface,
          localisation: selectedLocationName,
          typeSol: selectedSoil!.id,
          latitude: selectedLatitude,
          longitude: selectedLongitude,
          customCropName: isCustomCrop ? customCropController.text.trim() : null,
        );
      } else {
        await ApiService.addPlot(
          cropId: cropId,
          nom: generatedFieldName(),
          superficie: inputSurface,
          localisation: selectedLocationName,
          typeSol: selectedSoil!.id,
          latitude: selectedLatitude,
          longitude: selectedLongitude,
          customCropName: isCustomCrop ? customCropController.text.trim() : null,
        );
      }

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.plotToEdit != null ? "Error updating plot: $error" : "Error adding plot: $error")),
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
                  Text(
                    widget.plotToEdit != null ? "Edit Plot" : "Add Plot",
                    style: const TextStyle(
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
                          title: "Choose Crop",
                          subtitle: "Select what is planted.",
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonFormField<String>(
                                value: selectedCategory,
                                decoration: InputDecoration(
                                  labelText: "Crop Category",
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
                                hint: const Text("Select Category"),
                                items: [
                                  ...cropCategories.map((cat) {
                                    return DropdownMenuItem<String>(
                                      value: cat.name,
                                      child: Text(
                                        cat.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: darkText,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  const DropdownMenuItem<String>(
                                    value: "Other crop (Enter)...",
                                    child: Text(
                                      "Other crop (Enter)...",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    selectedCategory = value;
                                    if (value == "Other crop (Enter)...") {
                                      selectedCategoryCrop = null;
                                      isCustomCrop = true;
                                      selectedCrop = null;
                                      customCropController.clear();
                                    } else if (value != null) {
                                      final cat = cropCategories.firstWhere((c) => c.name == value);
                                      selectedCategoryCrop = cat.cropNames.first;
                                      final cleanName = cleanCropName(selectedCategoryCrop!);
                                      final matched = crops.firstWhere(
                                        (c) => c.nom.toLowerCase() == cleanName.toLowerCase(),
                                        orElse: () => Crop(id: "dummy", nom: cleanName, coefficientKc: 0.85),
                                      );
                                      if (crops.any((c) => c.id == matched.id)) {
                                        selectedCrop = matched;
                                        isCustomCrop = false;
                                      } else {
                                        selectedCrop = null;
                                        isCustomCrop = true;
                                        customCropController.text = cleanName;
                                      }
                                    }
                                  });
                                },
                              ),
                              if (selectedCategory != null && selectedCategory != "Other crop (Enter)...") ...[
                                const SizedBox(height: 14),
                                DropdownButtonFormField<String>(
                                  value: selectedCategoryCrop,
                                  decoration: InputDecoration(
                                    labelText: "Select Crop",
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
                                  hint: const Text("Select Crop"),
                                  items: cropCategories
                                      .firstWhere((cat) => cat.name == selectedCategory)
                                      .cropNames
                                      .map((cName) {
                                    return DropdownMenuItem<String>(
                                      value: cName,
                                      child: Text(
                                        cName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: darkText,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      selectedCategoryCrop = value;
                                      if (value != null) {
                                        final cleanName = cleanCropName(value);
                                        final matched = crops.firstWhere(
                                          (c) => c.nom.toLowerCase() == cleanName.toLowerCase(),
                                          orElse: () => Crop(id: "dummy", nom: cleanName, coefficientKc: 0.85),
                                        );
                                        if (crops.any((c) => c.id == matched.id)) {
                                          selectedCrop = matched;
                                          isCustomCrop = false;
                                        } else {
                                          selectedCrop = null;
                                          isCustomCrop = true;
                                          customCropController.text = cleanName;
                                        }
                                      }
                                    });
                                  },
                                ),
                              ],
                              if (selectedCategory == "Other crop (Enter)...") ...[
                                const SizedBox(height: 14),
                                TextFormField(
                                  controller: customCropController,
                                  decoration: InputDecoration(
                                    labelText: "Custom Crop Name",
                                    hintText: "e.g. Mint, Avocado, Fig",
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
                          title: "Choose Area",
                          subtitle: "Plot area in hectares.",
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: surfaceController,
                                keyboardType: const TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                decoration: InputDecoration(
                                  labelText: "Area (ha)",
                                  hintText: "e.g. 1.5, 0.75, 12.0",
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
                                "Quick area options:",
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
                          title: "Choose Soil Type",
                          subtitle: "Select the dominant soil.",
                          child: soils.isEmpty
                              ? const Text(
                                  "No soil available.",
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
                      : Icon(widget.plotToEdit != null ? Icons.save : Icons.add),
                  label: Text(
                    saving
                        ? (widget.plotToEdit != null ? "Saving..." : "Adding...")
                        : hasLocation
                            ? (widget.plotToEdit != null ? "Save Changes" : "Add Plot")
                            : "Choose Location",
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
                                  "Plot Location",
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
                                  "Edit",
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
                              locationName ?? "Morocco",
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
                              "No location selected",
                              style: TextStyle(
                                color: Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              "Tap here to choose the location on the map.",
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
            "Summary",
            style: TextStyle(
              color: primaryGreen,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          PreviewLine(label: "Name", value: fieldName),
          PreviewLine(label: "Crop", value: cropName),
          PreviewLine(
            label: "Area",
            value: surface == null ? "-" : "${formatPreviewSurface(surface!)} ha",
          ),
          PreviewLine(label: "Soil", value: soil),
          PreviewLine(label: "Location", value: location ?? "-"),
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

class CropCategory {
  final String name;
  final List<String> cropNames;

  const CropCategory({
    required this.name,
    required this.cropNames,
  });
}

const List<CropCategory> cropCategories = [
  CropCategory(
    name: "Fruits",
    cropNames: [
      "Olivier (Olive)",
      "Agrumes (Citrus)",
      "Fraise (Strawberry)",
      "Pommier (Apple)",
      "Poirier (Pear)",
      "Avocat (Avocado)",
      "Grenadier (Pomegranate)",
      "Figuier (Fig)",
      "Vigne (Grape)",
      "Pasteque (Watermelon)",
      "Melon",
      "Amandier (Almond)",
    ],
  ),
  CropCategory(
    name: "Vegetables",
    cropNames: [
      "Tomate (Tomato)",
      "Carotte (Carrot)",
      "Pomme de terre (Potato)",
      "Oignon (Onion)",
      "Poivron (Pepper)",
      "Courgette (Zucchini)",
      "Ail (Garlic)",
      "Aubergine (Eggplant)",
      "Concombre (Cucumber)",
      "Laitue (Lettuce)",
    ],
  ),
  CropCategory(
    name: "Cereals & Forages",
    cropNames: [
      "Blé (Wheat)",
      "Maïs (Corn)",
      "Orge (Barley)",
      "Fève (Faba bean)",
      "Luzerne (Alfalfa)",
    ],
  ),
  CropCategory(
    name: "Herbs & Others",
    cropNames: [
      "Menthe (Mint)",
    ],
  ),
];

String cleanCropName(String rawName) {
  if (rawName.contains('(')) {
    return rawName.split('(')[0].trim();
  }
  return rawName.trim();
}