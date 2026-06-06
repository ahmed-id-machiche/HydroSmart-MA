import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/api_config.dart';
import '../models/crop.dart';
import '../models/plot.dart';
import '../models/soil.dart';

class ApiService {
  static String getCurrentUserId() {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      throw Exception("Utilisateur non connecté.");
    }

    return user.id;
  }

  static Future<void> createFarmerProfile({
    required String id,
    required String email,
    String? fullName,
    String? phone,
    String? region,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/api/farmers"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "id": id,
        "email": email,
        "fullName": fullName,
        "phone": phone,
        "region": region,
        "role": "farmer",
      }),
    );

    if (response.statusCode != 201) {
      throw Exception("Failed to create farmer profile: ${response.body}");
    }
  }

  static Future<Map<String, dynamic>> getFarmerProfile() async {
    final userId = getCurrentUserId();
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/api/farmers?userId=$userId"),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to load farmer profile: ${response.body}");
    }

    final List data = jsonDecode(response.body);
    if (data.isEmpty) {
      // Fallback: create profile if it doesn't exist yet
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await createFarmerProfile(
          id: user.id,
          email: user.email ?? "",
        );
        return {
          "id": user.id,
          "email": user.email,
          "role": "farmer",
        };
      }
      throw Exception("Aucun profil trouvé.");
    }
    return Map<String, dynamic>.from(data.first);
  }

  static Future<Map<String, dynamic>> updateFarmerProfile({
    String? fullName,
    String? phone,
    String? region,
    String? role,
  }) async {
    final userId = getCurrentUserId();
    final response = await http.patch(
      Uri.parse("${ApiConfig.baseUrl}/api/farmers"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "id": userId,
        "fullName": fullName,
        "phone": phone,
        "region": region,
        "role": role,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to update profile: ${response.body}");
    }

    return jsonDecode(response.body);
  }

  static Future<List<Plot>> getPlots() async {
    final userId = getCurrentUserId();

    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/api/plots?userId=$userId"),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to load plots: ${response.body}");
    }

    final List data = jsonDecode(response.body);
    return data.map((item) => Plot.fromJson(item)).toList();
  }

  static Future<List<Crop>> getCrops() async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/api/crops"),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to load crops: ${response.body}");
    }

    final List data = jsonDecode(response.body);
    return data.map((item) => Crop.fromJson(item)).toList();
  }

  static Future<List<Soil>> getSoils() async {
    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/api/soils"),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to load soils: ${response.body}");
    }

    final List data = jsonDecode(response.body);
    final List<Soil> soilsList = [];
    for (var item in data) {
      if (item is Map) {
        soilsList.add(Soil.fromJson(Map<String, dynamic>.from(item)));
      } else if (item is String) {
        soilsList.add(Soil(id: item, nom: item[0].toUpperCase() + item.substring(1)));
      }
    }
    return soilsList;
  }

  static Future<Crop> createCrop({
    required String nom,
    double coefficientKc = 0.85,
    String stadeCroissance = "mi-saison",
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/api/crops"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "nom": nom,
        "coefficient_kc": coefficientKc,
        "stade_croissance": stadeCroissance,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception("Failed to create crop: ${response.body}");
    }

    return Crop.fromJson(jsonDecode(response.body));
  }

  static Future<List<Map<String, dynamic>>> getRecommendations() async {
    final userId = getCurrentUserId();

    final response = await http.get(
      Uri.parse(
        "${ApiConfig.baseUrl}/api/irrigation-recommendations?userId=$userId",
      ),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to load recommendations: ${response.body}");
    }

    final List data = jsonDecode(response.body);

    return data.map((item) {
      return Map<String, dynamic>.from(item);
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> getIrrigationHistory() async {
    final userId = getCurrentUserId();

    final response = await http.get(
      Uri.parse("${ApiConfig.baseUrl}/api/irrigation-history?userId=$userId"),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to load history: ${response.body}");
    }

    final List data = jsonDecode(response.body);

    return data.map((item) {
      return Map<String, dynamic>.from(item);
    }).toList();
  }

  static Future<void> addPlot({
    required String cropId,
    required String nom,
    required double superficie,
    required String localisation,
    required String typeSol,
    double? latitude,
    double? longitude,
  }) async {
    final userId = getCurrentUserId();

    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/api/plots"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "userId": userId,
        "cropId": cropId,
        "nom": nom,
        "superficie": superficie,
        "localisation": localisation,
        "typeSol": typeSol,
        "latitude": latitude,
        "longitude": longitude,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception("Failed to add plot: ${response.body}");
    }
  }

  static Future<Map<String, dynamic>> fetchOpenWeather({
    required double lat,
    required double lon,
  }) async {
    final response = await http.get(
      Uri.parse(
        "${ApiConfig.baseUrl}/api/weather/openweather?lat=$lat&lon=$lon",
      ),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to fetch weather: ${response.body}");
    }

    return jsonDecode(response.body);
  }

  static Future<double> calculateEt0({
    required double temperature,
    required double humidity,
    required double windSpeed,
    required double solarRadiation,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/api/calculate-et0"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "tMin": temperature - 3,
        "tMax": temperature + 4,
        "tMean": temperature,
        "humidity": humidity,
        "windSpeed": windSpeed,
        "solarRadiation": solarRadiation,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to calculate ET0: ${response.body}");
    }

    final data = jsonDecode(response.body);
    return double.tryParse(data["et0"].toString()) ?? 0;
  }

  static Future<Map<String, dynamic>> generateIrrigationRecommendation({
    required double et0,
    required double kc,
    required double rainfall,
    required double irrigationEfficiency,
    required double surfaceHectare,
    String? plotId,
    double? latitude,
    double? longitude,
    String? soilType,
    String? cropName,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/api/recommendations"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "et0": et0,
        "kc": kc,
        "rainfall": rainfall,
        "irrigationEfficiency": irrigationEfficiency,
        "surfaceHectare": surfaceHectare,
        if (plotId != null) "plotId": plotId,
        if (latitude != null) "latitude": latitude,
        if (longitude != null) "longitude": longitude,
        if (soilType != null) "soilType": soilType,
        if (cropName != null) "cropName": cropName,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to generate recommendation: ${response.body}");
    }

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> saveIrrigationRecommendation({
    required String plotId,
    required double quantiteEau,
    required double dureeIrrigation,
    required String frequence,
    required double et0,
    required double etc,
    required double besoinNet,
    required double besoinBrut,
    required String message,
    required String date,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/api/irrigation-recommendations"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "plotId": plotId,
        "quantiteEau": quantiteEau,
        "dureeIrrigation": dureeIrrigation,
        "frequence": frequence,
        "et0": et0,
        "etc": etc,
        "besoinNet": besoinNet,
        "besoinBrut": besoinBrut,
        "message": message,
        "date": date,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception("Failed to save recommendation: ${response.body}");
    }

    return jsonDecode(response.body);
  }

  static Future<void> saveIrrigationHistory({
    required String plotId,
    required String recommendationId,
    required double et0,
    required double etc,
    required double quantiteEau,
    required String date,
  }) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/api/irrigation-history"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "plotId": plotId,
        "recommendationId": recommendationId,
        "et0": et0,
        "etc": etc,
        "quantiteEau": quantiteEau,
        "date": date,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception("Failed to save history: ${response.body}");
    }
  }

  static Future<Map<String, dynamic>> generateRecommendationForPlot(
    Plot plot,
  ) async {
    if (plot.crop == null) {
      throw Exception("Cette parcelle n'a pas de culture associée.");
    }

    if (plot.latitude == null || plot.longitude == null) {
      throw Exception(
        "Cette parcelle n'a pas de localisation GPS. Modifie ou recrée cette parcelle avec une localisation sur la carte.",
      );
    }

    final weather = await fetchOpenWeather(
      lat: plot.latitude!,
      lon: plot.longitude!,
    );

    final temperature =
        double.tryParse(weather["temperature"].toString()) ?? 0;
    final humidity = double.tryParse(weather["humidite"].toString()) ?? 0;
    final windSpeed =
        double.tryParse(weather["vitesseVent"].toString()) ?? 0;
    final solarRadiation =
        double.tryParse(weather["rayonnementSolaire"].toString()) ?? 20;
    final rainfall =
        double.tryParse(weather["precipitation"].toString()) ?? 0;

    final et0 = await calculateEt0(
      temperature: temperature,
      humidity: humidity,
      windSpeed: windSpeed,
      solarRadiation: solarRadiation,
    );

    final recommendation = await generateIrrigationRecommendation(
      et0: et0,
      kc: plot.crop!.coefficientKc,
      rainfall: rainfall,
      irrigationEfficiency: 0.8,
      surfaceHectare: plot.superficie,
      plotId: plot.id,
      latitude: plot.latitude,
      longitude: plot.longitude,
      soilType: plot.typeSol,
      cropName: plot.crop!.nom,
    );

    final volumeM3 =
        double.tryParse(recommendation["volumeM3"].toString()) ?? 0;
    final etc = double.tryParse(recommendation["etc"].toString()) ?? 0;
    final netNeed =
        double.tryParse(recommendation["netNeedMm"].toString()) ?? 0;
    final grossNeed =
        double.tryParse(recommendation["grossNeedMm"].toString()) ?? 0;
    final message = recommendation["message"]?.toString() ??
        "Recommandation générée avec succès.";
    final today = DateTime.now().toIso8601String().split("T")[0];

    // Retrieve dynamically calculated duration and frequency from the API response
    final durationHours =
        double.tryParse(recommendation["dureeIrrigation"].toString()) ?? (volumeM3 > 0 ? 2.0 : 0.0);
    final frequencyText =
        recommendation["frequence"]?.toString() ?? (volumeM3 > 0 ? "journalière" : "aucune");

    final savedRecommendation = await saveIrrigationRecommendation(
      plotId: plot.id,
      quantiteEau: volumeM3,
      dureeIrrigation: durationHours,
      frequence: frequencyText,
      et0: et0,
      etc: etc,
      besoinNet: netNeed,
      besoinBrut: grossNeed,
      message: message,
      date: today,
    );

    final recommendationId = savedRecommendation["id"]?.toString();

    if (recommendationId != null) {
      await saveIrrigationHistory(
        plotId: plot.id,
        recommendationId: recommendationId,
        et0: et0,
        etc: etc,
        quantiteEau: volumeM3,
        date: today,
      );
    }

    return {
      "weather": weather,
      "et0": et0,
      "recommendation": recommendation,
      "savedRecommendation": savedRecommendation,
    };
  }

  static Future<String> getChatResponse(String message) async {
    final userId = getCurrentUserId();

    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/api/chatboot"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "userId": userId,
        "message": message,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Erreur de communication avec l'assistant.");
    }

    final data = jsonDecode(response.body);
    return data["reply"]?.toString() ?? "Pas de réponse.";
  }
}