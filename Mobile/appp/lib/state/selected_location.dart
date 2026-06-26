import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class SelectedLocation {
  static double? latitude;
  static double? longitude;
  static String? name;

  static const String _filename = "saved_location.json";

  static Future<File> _getFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/$_filename");
  }

  static Future<void> load() async {
    try {
      final file = await _getFile();
      if (await file.exists()) {
        final contents = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(contents);
        latitude = double.tryParse(data["latitude"].toString());
        longitude = double.tryParse(data["longitude"].toString());
        name = data["name"]?.toString();
      }
    } catch (e) {
      print("Failed to load saved location: $e");
    }
  }

  static Future<void> update({
    required double lat,
    required double lon,
    required String locationName,
  }) async {
    latitude = lat;
    longitude = lon;
    name = locationName;

    try {
      final file = await _getFile();
      final data = {
        "latitude": lat,
        "longitude": lon,
        "name": locationName,
      };
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      print("Failed to save location: $e");
    }
  }

  static bool get hasLocation {
    return latitude != null && longitude != null && name != null;
  }

  static Future<void> clear() async {
    latitude = null;
    longitude = null;
    name = null;
    try {
      final file = await _getFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print("Failed to clear saved location: $e");
    }
  }
}