import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/api_config.dart';
import '../models/crop.dart';
import '../models/plot.dart';

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

    final savedRecommendation = await saveIrrigationRecommendation(
      plotId: plot.id,
      quantiteEau: volumeM3,
      dureeIrrigation: volumeM3 > 0 ? 2 : 0,
      frequence: volumeM3 > 0 ? "journalière" : "aucune",
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
}