import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../constants/app_colors.dart';
import '../models/plot.dart';
import '../services/api_services.dart';
import '../state/selected_location.dart';
import '../widgets/field_card.dart';
import '../widgets/weather_mini_item.dart';
import 'chatbot_screen.dart';
import 'map_picker_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onViewAllFields;

  const HomeScreen({
    super.key,
    required this.onViewAllFields,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool loadingWeather = true;
  bool loadingFields = true;

  List<Plot> plots = [];

  String locationName = "Localisation...";
  double temperature = 0;
  double humidity = 0;
  double windSpeed = 0;
  double precipitation = 0;
  double solarRadiation = 0;

  @override
  void initState() {
    super.initState();
    loadCurrentWeather();
    loadFields();
  }

  Future<void> loadFields() async {
    try {
      final data = await ApiService.getPlots();

      if (!mounted) return;

      setState(() {
        plots = data;
        loadingFields = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        loadingFields = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur chargement parcelles: $error")),
      );
    }
  }

  Future<void> loadCurrentWeather() async {
    try {
      setState(() {
        loadingWeather = true;
      });

      final position = await getCurrentPosition();

      await loadWeatherByCoordinates(
        lat: position.latitude,
        lon: position.longitude,
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        loadingWeather = false;
        locationName = "Position indisponible";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur météo: $error")),
      );
    }
  }

  Future<void> loadWeatherByCoordinates({
    required double lat,
    required double lon,
  }) async {
    try {
      setState(() {
        loadingWeather = true;
        locationName = "Chargement localisation...";
      });

      final placeName = await getPlaceName(lat, lon);

      SelectedLocation.update(
        lat: lat,
        lon: lon,
        locationName: placeName,
      );

      final weather = await ApiService.fetchOpenWeather(
        lat: lat,
        lon: lon,
      );

      if (!mounted) return;

      setState(() {
        locationName = placeName;
        temperature = double.tryParse(weather["temperature"].toString()) ?? 0;
        humidity = double.tryParse(weather["humidite"].toString()) ?? 0;
        windSpeed = double.tryParse(weather["vitesseVent"].toString()) ?? 0;
        precipitation =
            double.tryParse(weather["precipitation"].toString()) ?? 0;
        solarRadiation =
            double.tryParse(weather["rayonnementSolaire"].toString()) ?? 0;
        loadingWeather = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        loadingWeather = false;
        locationName = "Maroc";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur météo: $error")),
      );
    }
  }

  Future<void> openMapPicker() async {
    final result = await Navigator.push<MapPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => const MapPickerScreen(),
      ),
    );

    if (result == null) return;

    await loadWeatherByCoordinates(
      lat: result.latitude,
      lon: result.longitude,
    );
  }

  void openChatbot() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ChatbotScreen(),
      ),
    );
  }

  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception("Le service GPS est désactivé.");
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception("Permission GPS refusée.");
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        "Permission GPS refusée définitivement. Active-la dans les paramètres.",
      );
    }

    return Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
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

  String todayText() {
    final now = DateTime.now();

    const months = [
      "Janvier",
      "Février",
      "Mars",
      "Avril",
      "Mai",
      "Juin",
      "Juillet",
      "Août",
      "Septembre",
      "Octobre",
      "Novembre",
      "Décembre",
    ];

    return "${now.day} ${months[now.month - 1]} ${now.year}";
  }

  Future<void> refreshHome() async {
    await loadCurrentWeather();
    await loadFields();
  }

  @override
  Widget build(BuildContext context) {
    final visiblePlots = plots.take(3).toList();

    return Scaffold(
      backgroundColor: lightBackground,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                  decoration: const BoxDecoration(
                    color: primaryGreen,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(32),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.arrow_back, color: Colors.white),
                          Spacer(),
                          Text(
                            "Home",
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
                      const Text(
                        "Hello, Good Morning",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        todayText(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
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
                              "Search",
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
                    onRefresh: refreshHome,
                    child: ListView(
                      padding: const EdgeInsets.all(20),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7ED67E),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: loadingWeather
                              ? const SizedBox(
                                  height: 190,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            locationName,
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.white70,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        InkWell(
                                          onTap: openMapPicker,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color:
                                                  Colors.white.withOpacity(0.25),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons
                                                      .edit_location_alt_outlined,
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  "Changer",
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "${temperature.toStringAsFixed(1)}°C",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 42,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const CircleAvatar(
                                          backgroundColor: Colors.white,
                                          child: Icon(
                                            Icons.cloud,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 18),
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.85),
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          WeatherMiniItem(
                                            label: "Humidity",
                                            value:
                                                "${humidity.toStringAsFixed(0)}%",
                                            icon: Icons.water_drop_outlined,
                                          ),
                                          WeatherMiniItem(
                                            label: "Wind",
                                            value:
                                                "${windSpeed.toStringAsFixed(1)} m/s",
                                            icon: Icons.air,
                                          ),
                                          WeatherMiniItem(
                                            label: "Rain",
                                            value:
                                                "${precipitation.toStringAsFixed(1)} mm",
                                            icon: Icons.cloudy_snowing,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      precipitation > 0
                                          ? "Pluie détectée, l’irrigation peut être réduite."
                                          : "Aujourd’hui est adapté pour surveiller l’irrigation.",
                                      textAlign: TextAlign.center,
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            const Text(
                              "Fields",
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            InkWell(
                              onTap: widget.onViewAllFields,
                              child: const Text(
                                "View all",
                                style: TextStyle(color: primaryGreen),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (loadingFields)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (plots.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: cardGreen,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Center(
                              child: Text(
                                "Aucune parcelle trouvée.",
                                style: TextStyle(color: Colors.black54),
                              ),
                            ),
                          )
                        else
                          Row(
                            children: visiblePlots.map((plot) {
                              final isLast = plot == visiblePlots.last;

                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: isLast ? 0 : 10,
                                  ),
                                  child: FieldCard(
                                    label: plot.nom,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        const SizedBox(height: 90),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              right: 18,
              bottom: 22,
              child: InkWell(
                onTap: openChatbot,
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: primaryGreen,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: primaryGreen.withOpacity(0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.smart_toy_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Assistant",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}