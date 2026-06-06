class Soil {
  final String id;
  final String nom;

  Soil({
    required this.id,
    required this.nom,
  });

  factory Soil.fromJson(Map<String, dynamic> json) {
    return Soil(
      id: json["id"] ?? "",
      nom: json["nom"] ?? "",
    );
  }
}
