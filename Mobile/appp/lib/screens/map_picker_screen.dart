import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../constants/app_colors.dart';

class MapPickerResult {
  final double latitude;
  final double longitude;

  const MapPickerResult({
    required this.latitude,
    required this.longitude,
  });
}

class MapPickerScreen extends StatefulWidget {
  final double initialLat;
  final double initialLon;

  const MapPickerScreen({
    super.key,
    this.initialLat = 31.7917,
    this.initialLon = -7.0926,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late LatLng selectedPoint;
  LatLng? userLocation;
  final MapController _mapController = MapController();
  bool locating = false;
  bool _autoCentered = false;

  Future<void> _fetchLiveLocationBackground() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        final permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.whileInUse ||
            permission == LocationPermission.always) {
          Position? position;
          try {
            position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
              timeLimit: const Duration(seconds: 4),
            );
          } catch (_) {
            position = await Geolocator.getLastKnownPosition();
          }
          final pos = position;
          if (pos != null) {
            final latlng = LatLng(pos.latitude, pos.longitude);
            setState(() {
              userLocation = latlng;
            });
            // Auto-center map and select the point if we haven't already
            _maybeAutoCenter(latlng);
            return;
          }
        }
      }

      // Fallback to IP geolocation silently
      final headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
      };
      double? lat;
      double? lon;
      try {
        final response = await http.get(Uri.parse("https://freeipapi.com/api/json"), headers: headers).timeout(const Duration(seconds: 3));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          lat = double.parse(data["latitude"].toString());
          lon = double.parse(data["longitude"].toString());
        }
      } catch (_) {}

      if (lat == null || lon == null) {
        try {
          final response = await http.get(Uri.parse("https://ipapi.co/json/"), headers: headers).timeout(const Duration(seconds: 3));
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            lat = double.parse(data["latitude"].toString());
            lon = double.parse(data["longitude"].toString());
          }
        } catch (_) {}
      }

      if (lat != null && lon != null) {
        final latlng = LatLng(lat!, lon!);
        setState(() {
          userLocation = latlng;
        });
        _maybeAutoCenter(latlng);
      }
    } catch (e) {
      print("Background live location fetch failed: $e");
    }
  }

  void _maybeAutoCenter(LatLng latlng) {
    // Only auto-center if we haven't already and the user didn't provide a custom initial location
    final isDefault = (widget.initialLat == 31.7917 && widget.initialLon == -7.0926) ||
                      (widget.initialLat == 30.418 && widget.initialLon == -9.558);
    if (!_autoCentered && isDefault) {
      _autoCentered = true;
      setState(() {
        selectedPoint = latlng;
      });
      try {
        _mapController.move(latlng, 13.0);
      } catch (_) {}
    }
  }

  Future<void> _locateUser() async {
    try {
      setState(() {
        locating = true;
      });

      void _show(String msg) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
          );
        }
        print(msg);
      }

      // 1. Try GPS sensor first
      bool gpsSuccess = false;
      String? gpsErrorMessage;
      try {
        final serviceEnabled = await Geolocator.isLocationServiceEnabled();
        _show(serviceEnabled ? 'Location services enabled' : 'Location services disabled');
        if (serviceEnabled) {
          LocationPermission permission = await Geolocator.checkPermission();
          _show('Location permission status: $permission');
          if (permission == LocationPermission.denied) {
            permission = await Geolocator.requestPermission();
            _show('Permission requested: $permission');
          }

          if (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always) {
            // Try fresh position first, fallback to last known
            Position? position;
            try {
              position = await Geolocator.getCurrentPosition(
                desiredAccuracy: LocationAccuracy.high,
                timeLimit: const Duration(seconds: 6),
              );
            } catch (e) {
              print("GPS getCurrentPosition failed: $e. Trying last known.");
              position = await Geolocator.getLastKnownPosition();
            }

            final pos = position;
            if (pos != null) {
              final point = LatLng(pos.latitude, pos.longitude);
              setState(() {
                selectedPoint = point;
                userLocation = point;
              });
              _mapController.move(point, 13.0);
              _show('GPS position obtained: ${pos.latitude}, ${pos.longitude}');
              gpsSuccess = true;
            } else {
              gpsErrorMessage = "No GPS position returned.";
            }
          } else {
            gpsErrorMessage = "Location permission denied.";
          }
        } else {
          gpsErrorMessage = "Location services are disabled on this device.";
        }
      } catch (gpsError) {
        gpsErrorMessage = gpsError.toString();
        print("GPS auto-detect failed: $gpsError");
      }

      // 2. Fallback to IP-based Geolocation if GPS failed
      if (!gpsSuccess) {
        double? lat;
        double? lon;
        String? activeService;
        final headers = {
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        };

        // Try freeipapi.com (HTTPS, very reliable, no keys needed)
        try {
          final response = await http.get(Uri.parse("https://freeipapi.com/api/json"), headers: headers).timeout(const Duration(seconds: 4));
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            lat = double.parse(data["latitude"].toString());
            lon = double.parse(data["longitude"].toString());
            activeService = "freeipapi.com";
          }
        } catch (e) {
          print("freeipapi.com failed in map picker: $e");
        }

        // Try ipapi.co (HTTPS) second
        if (lat == null || lon == null) {
          try {
            final response = await http.get(Uri.parse("https://ipapi.co/json/"), headers: headers).timeout(const Duration(seconds: 4));
            if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              lat = double.parse(data["latitude"].toString());
              lon = double.parse(data["longitude"].toString());
              activeService = "ipapi.co";
            }
          } catch (e) {
            print("ipapi.co failed in map picker: $e");
          }
        }

        // Try ipinfo.io (HTTPS) third
        if (lat == null || lon == null) {
          try {
            final response = await http.get(Uri.parse("https://ipinfo.io/json"), headers: headers).timeout(const Duration(seconds: 4));
            if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              if (data["loc"] != null) {
                final parts = data["loc"].toString().split(',');
                if (parts.length == 2) {
                  lat = double.parse(parts[0]);
                  lon = double.parse(parts[1]);
                  activeService = "ipinfo.io";
                }
              }
            }
          } catch (e) {
            print("ipinfo.io failed in map picker: $e");
          }
        }

        // Try ip-api.com (HTTP) as last resort
        if (lat == null || lon == null) {
          try {
            final response = await http.get(Uri.parse("http://ip-api.com/json"), headers: headers).timeout(const Duration(seconds: 4));
            if (response.statusCode == 200) {
              final data = jsonDecode(response.body);
              if (data["status"] == "success") {
                lat = double.parse(data["lat"].toString());
                lon = double.parse(data["lon"].toString());
                activeService = "ip-api.com";
              }
            }
          } catch (e) {
            print("ip-api.com failed in map picker: $e");
          }
        }

        if (lat != null && lon != null) {
          final point = LatLng(lat, lon);
          setState(() {
            selectedPoint = point;
            userLocation = point;
          });
          _mapController.move(point, 13.0);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  gpsErrorMessage != null
                      ? "GPS failed ($gpsErrorMessage). Fallback to network location ($activeService)."
                      : "Using network location ($activeService).",
                ),
                duration: const Duration(seconds: 4),
              ),
            );
            _show('Network location used: $activeService -> $lat,$lon');
          }
        } else {
          throw Exception("All IP Geolocation services failed.");
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to auto-detect location: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          locating = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    selectedPoint = LatLng(widget.initialLat, widget.initialLon);

    // Fetch user's live location in the background
    _fetchLiveLocationBackground();

    // Auto-locate if the screen is initialized with the fallback defaults
    final isDefault = (widget.initialLat == 31.7917 && widget.initialLon == -7.0926) ||
                      (widget.initialLat == 30.418 && widget.initialLon == -9.558);
    if (isDefault) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _locateUser();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDefault = (widget.initialLat == 31.7917 && widget.initialLon == -7.0926) ||
                      (widget.initialLat == 30.418 && widget.initialLon == -9.558);
    final initialZoom = isDefault ? 5.6 : 13.0;

    return Scaffold(
      backgroundColor: lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
              decoration: const BoxDecoration(
                color: primaryGreen,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Expanded(
                    child: Text(
                      "Choose Location",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: selectedPoint,
                      initialZoom: initialZoom,
                      onTap: (tapPosition, point) {
                        setState(() {
                          selectedPoint = point;
                        });
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                        userAgentPackageName: "com.example.appp",
                      ),
                      MarkerLayer(
                        markers: [
                          if (userLocation != null)
                            Marker(
                              point: userLocation!,
                              width: 40,
                              height: 40,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.3),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Container(
                                    width: 14,
                                    height: 14,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Marker(
                            point: selectedPoint,
                            width: 56,
                            height: 56,
                            child: const Icon(
                              Icons.location_pin,
                              color: Colors.red,
                              size: 48,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  Positioned(
                    left: 16,
                    right: 16,
                    top: 16,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.92),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        "Tap the map to choose the weather location.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: darkText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton(
                      onPressed: locating
                          ? null
                          : () async {
                              if (userLocation != null) {
                                // Immediate feedback using cached background location
                                setState(() {
                                  selectedPoint = userLocation!;
                                });
                                try {
                                  _mapController.move(userLocation!, 13.0);
                                } catch (_) {}

                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Using cached location — refreshing GPS in background')),
                                  );
                                }

                                // Also refresh GPS in background to get a fresher position
                                _locateUser();
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Locating...')),
                                  );
                                }
                                await _locateUser();
                              }
                            },
                      backgroundColor: primaryGreen,
                      foregroundColor: Colors.white,
                      child: locating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.my_location),
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  Text(
                    "Lat: ${selectedPoint.latitude.toStringAsFixed(5)} | Lon: ${selectedPoint.longitude.toStringAsFixed(5)}",
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(
                          context,
                          MapPickerResult(
                            latitude: selectedPoint.latitude,
                            longitude: selectedPoint.longitude,
                          ),
                        );
                      },
                      icon: const Icon(Icons.check),
                      label: const Text(
                        "Confirm Location",
                        style: TextStyle(fontWeight: FontWeight.bold),
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