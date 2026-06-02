class Crop {
  final String id;
  final String nom;
  final double coefficientKc;
  final String? stadeCroissance;

  Crop({
    required this.id,
    required this.nom,
    required this.coefficientKc,
    this.stadeCroissance,
  });

  factory Crop.fromJson(Map<String, dynamic> json) {
    return Crop(
      id: json["id"] ?? "",
      nom: json["nom"] ?? "",
      coefficientKc: double.tryParse(json["coefficient_kc"].toString()) ?? 0,
      stadeCroissance: json["stade_croissance"],
    );
  }
}