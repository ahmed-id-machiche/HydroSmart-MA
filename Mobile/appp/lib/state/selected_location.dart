class SelectedLocation {
  static double? latitude;
  static double? longitude;
  static String? name;

  static void update({
    required double lat,
    required double lon,
    required String locationName,
  }) {
    latitude = lat;
    longitude = lon;
    name = locationName;
  }

  static bool get hasLocation {
    return latitude != null && longitude != null && name != null;
  }

  static void clear() {
    latitude = null;
    longitude = null;
    name = null;
  }
}