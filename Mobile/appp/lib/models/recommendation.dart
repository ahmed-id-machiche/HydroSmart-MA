class Recommendation {
  final String id;
  final double quantiteEau;
  final double et0;
  final double etc;
  final double besoinNet;
  final double besoinBrut;
  final String message;
  final String date;
  final String? plotName;
  final String? cropName;

  Recommendation({
    required this.id,
    required this.quantiteEau,
    required this.et0,
    required this.etc,
    required this.besoinNet,
    required this.besoinBrut,
    required this.message,
    required this.date,
    this.plotName,
    this.cropName,
  });

  factory Recommendation.fromJson(Map<String, dynamic> json) {
    return Recommendation(
      id: json["id"],
      quantiteEau: double.tryParse(json["quantite_eau"].toString()) ?? 0,
      et0: double.tryParse(json["et0"].toString()) ?? 0,
      etc: double.tryParse(json["etc"].toString()) ?? 0,
      besoinNet: double.tryParse(json["besoin_net"].toString()) ?? 0,
      besoinBrut: double.tryParse(json["besoin_brut"].toString()) ?? 0,
      message: json["message"] ?? "",
      date: json["date"] ?? "",
      plotName: json["plots"] != null ? json["plots"]["nom"] : null,
      cropName: json["plots"] != null && json["plots"]["crops"] != null
          ? json["plots"]["crops"]["nom"]
          : null,
    );
  }
}