class WeatherData {
  final String id;
  final String? plotId;
  final double temperature;
  final double humidite;
  final double vitesseVent;
  final double rayonnementSolaire;
  final double precipitation;
  final String date;
  final String? plotName;

  WeatherData({
    required this.id,
    this.plotId,
    required this.temperature,
    required this.humidite,
    required this.vitesseVent,
    required this.rayonnementSolaire,
    required this.precipitation,
    required this.date,
    this.plotName,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      id: json["id"],
      plotId: json["plot_id"],
      temperature: double.tryParse(json["temperature"].toString()) ?? 0,
      humidite: double.tryParse(json["humidite"].toString()) ?? 0,
      vitesseVent: double.tryParse(json["vitesse_vent"].toString()) ?? 0,
      rayonnementSolaire:
          double.tryParse(json["rayonnement_solaire"].toString()) ?? 0,
      precipitation: double.tryParse(json["precipitation"].toString()) ?? 0,
      date: json["date"],
      plotName: json["plots"] != null ? json["plots"]["nom"] : null,
    );
  }
}