import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../constants/app_colors.dart';
import '../models/plot.dart';
import '../services/api_services.dart';
import '../state/selected_location.dart';
import '../widgets/field_card.dart';
import '../widgets/weather_mini_item.dart';
import '../widgets/notification_bell.dart';
import '../services/notification_storage.dart';
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
  bool loadingRecs = true;

  List<Plot> plots = [];
  List<Map<String, dynamic>> recommendations = [];
  List<String> readIds = [];

  String locationName = "Location...";
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
    loadRecommendations();
  }

  Future<void> loadRecommendations() async {
    try {
      final recData = await ApiService.getRecommendations();
      final readData = await NotificationStorage.getReadIds();
      if (!mounted) return;
      setState(() {
        recommendations = recData;
        readIds = readData;
        loadingRecs = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          loadingRecs = false;
        });
      }
    }
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
        SnackBar(content: Text("Error loading plots: $error")),
      );
    }
  }

  Future<Position?> _getIPLocation() async {
    final headers = {
      "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    };

    // 1. Try freeipapi.com (HTTPS, very reliable, no keys needed)
    try {
      final response = await http.get(Uri.parse("https://freeipapi.com/api/json"), headers: headers).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final double lat = double.parse(data["latitude"].toString());
        final double lon = double.parse(data["longitude"].toString());
        return _createPosition(lat, lon);
      }
    } catch (e) {
      print("freeipapi.com failed: $e");
    }

    // 2. Try ipapi.co (HTTPS)
    try {
      final response = await http.get(Uri.parse("https://ipapi.co/json/"), headers: headers).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final double lat = double.parse(data["latitude"].toString());
        final double lon = double.parse(data["longitude"].toString());
        return _createPosition(lat, lon);
      }
    } catch (e) {
      print("ipapi.co failed: $e");
    }

    // 3. Try ipinfo.io (HTTPS)
    try {
      final response = await http.get(Uri.parse("https://ipinfo.io/json"), headers: headers).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["loc"] != null) {
          final parts = data["loc"].toString().split(',');
          if (parts.length == 2) {
            final double lat = double.parse(parts[0]);
            final double lon = double.parse(parts[1]);
            return _createPosition(lat, lon);
          }
        }
      }
    } catch (e) {
      print("ipinfo.io failed: $e");
    }

    // 4. Try ip-api.com (HTTP) as last resort
    try {
      final response = await http.get(Uri.parse("http://ip-api.com/json"), headers: headers).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data["status"] == "success") {
          final double lat = double.parse(data["lat"].toString());
          final double lon = double.parse(data["lon"].toString());
          return _createPosition(lat, lon);
        }
      }
    } catch (e) {
      print("ip-api.com failed: $e");
    }

    return null;
  }

  Position _createPosition(double lat, double lon) {
    return Position(
      latitude: lat,
      longitude: lon,
      timestamp: DateTime.now(),
      accuracy: 100,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }

  Future<void> loadCurrentWeather() async {
    try {
      setState(() {
        loadingWeather = true;
      });

      // 1. Try loading previously saved location first
      await SelectedLocation.load();
      if (SelectedLocation.hasLocation) {
        await loadWeatherByCoordinates(
          lat: SelectedLocation.latitude!,
          lon: SelectedLocation.longitude!,
        );
        return;
      }

      // 2. Try loading from database plots next
      List<Plot> dbPlots = [];
      try {
        dbPlots = await ApiService.getPlots();
      } catch (_) {}

      if (dbPlots.isNotEmpty) {
        final firstPlot = dbPlots.first;
        if (firstPlot.latitude != null && firstPlot.longitude != null) {
          await loadWeatherByCoordinates(
            lat: firstPlot.latitude!,
            lon: firstPlot.longitude!,
          );
          return;
        }
      }

      // 3. Try loading from farmer profile region
      Map<String, dynamic>? profile;
      try {
        profile = await ApiService.getFarmerProfile();
      } catch (_) {}

      if (profile != null && profile["region"] != null && profile["region"].toString().trim().isNotEmpty) {
        final regionName = profile["region"].toString().trim();
        try {
          final locations = await locationFromAddress(regionName);
          if (locations.isNotEmpty) {
            await loadWeatherByCoordinates(
              lat: locations.first.latitude,
              lon: locations.first.longitude,
            );
            return;
          }
        } catch (e) {
          print("Failed to geocode profile region '$regionName': $e");
        }
      }

      // 4. Fallback to GPS / IP auto-detection
      Position? position;
      try {
        position = await getCurrentPosition();
      } catch (gpsError) {
        print("GPS location detection failed, falling back to IP: $gpsError");
        position = await _getIPLocation();
      }

      if (position == null) {
        throw Exception("Could not retrieve GPS or IP location.");
      }

      await loadWeatherByCoordinates(
        lat: position.latitude,
        lon: position.longitude,
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        loadingWeather = false;
        locationName = "Location unavailable";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Weather error: $error")),
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
        locationName = "Loading location...";
      });

      final placeName = await getPlaceName(lat, lon);

      SelectedLocation.update(
        lat: lat,
        lon: lon,
        locationName: placeName,
      );

      try {
        await ApiService.updateFarmerProfile(region: placeName);
      } catch (profileError) {
        print("Failed to sync farmer region to database: $profileError");
      }

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
        locationName = "Morocco";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Weather error: $error")),
      );
    }
  }

  Future<void> openMapPicker() async {
    final result = await Navigator.push<MapPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          initialLat: SelectedLocation.latitude ?? 31.7917,
          initialLon: SelectedLocation.longitude ?? -7.0926,
        ),
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
      throw Exception("GPS service is disabled.");
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception("GPS permission denied.");
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        "GPS permission permanently denied. Enable it in settings.",
      );
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 6),
      );
    } catch (e) {
      print("GPS getCurrentPosition failed: $e. Trying last known.");
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        return lastKnown;
      }
      rethrow;
    }
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

  String todayText() {
    final now = DateTime.now();

    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];

    return "${now.day} ${months[now.month - 1]} ${now.year}";
  }

  Future<void> refreshHome() async {
    await loadCurrentWeather();
    await loadFields();
    await loadRecommendations();
  }

  Widget _buildIrrigationAlertBanner(Map<String, dynamic> alertRec) {
    final plot = alertRec["plots"] != null ? Map<String, dynamic>.from(alertRec["plots"]) : null;
    final plotName = plot != null ? plot["nom"]?.toString() ?? "Plot" : "Plot";
    final vol = double.tryParse(alertRec["quantite_eau"].toString()) ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.lightBlue.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.blue.shade100,
            child: const Icon(Icons.water_drop, color: Colors.blue),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Irrigation Alert",
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "It's time to irrigate $plotName. Recommended: ${vol.toStringAsFixed(1)} m³.",
                  style: const TextStyle(
                    color: darkText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_outline, color: Colors.blue),
            onPressed: () async {
              await NotificationStorage.markAsRead(alertRec["id"].toString());
              loadRecommendations();
            },
          ),
        ],
      ),
    );
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
                      Row(
                        children: [
                          const Icon(Icons.arrow_back, color: Colors.white),
                          const Spacer(),
                          const Text(
                            "Home",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          NotificationBell(key: UniqueKey()),
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
                        if (recommendations.isNotEmpty) ...[
                          () {
                            final today = DateTime.now().toIso8601String().split("T")[0];
                            final alertRecs = recommendations.where((rec) {
                              final recId = rec["id"].toString();
                              final date = rec["date"]?.toString() ?? "";
                              final vol = double.tryParse(rec["quantite_eau"].toString()) ?? 0;
                              return date == today && vol > 0 && !readIds.contains(recId);
                            }).toList();

                            if (alertRecs.isNotEmpty) {
                              return _buildIrrigationAlertBanner(alertRecs.first);
                            }
                            return const SizedBox.shrink();
                          }(),
                        ],
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
                                                  "Change",
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
                                          ? "Rain detected, irrigation can be reduced."
                                          : "Today is suitable for monitoring irrigation.",
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
                                "No plots found.",
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
                                    cropName: plot.crop?.nom ?? "Crop",
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
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            "assets/images/bot_farmer.png",
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
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