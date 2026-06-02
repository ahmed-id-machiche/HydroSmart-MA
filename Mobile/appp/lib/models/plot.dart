import 'crop.dart';

class Plot {
  final String id;
  final String nom;
  final double superficie;
  final String localisation;
  final String typeSol;
  final double? latitude;
  final double? longitude;
  final Crop? crop;

  Plot({
    required this.id,
    required this.nom,
    required this.superficie,
    required this.localisation,
    required this.typeSol,
    this.latitude,
    this.longitude,
    this.crop,
  });

  factory Plot.fromJson(Map<String, dynamic> json) {
    return Plot(
      id: json["id"] ?? "",
      nom: json["nom"] ?? "",
      superficie: double.tryParse(json["superficie"].toString()) ?? 0,
      localisation: json["localisation"] ?? "",
      typeSol: json["type_sol"] ?? "",
      latitude: json["latitude"] == null
          ? null
          : double.tryParse(json["latitude"].toString()),
      longitude: json["longitude"] == null
          ? null
          : double.tryParse(json["longitude"].toString()),
      crop: json["crops"] != null ? Crop.fromJson(json["crops"]) : null,
    );
  }
}