class Reading {
  final int? soilMoisture;
  final double? airTemp;
  final double? airHumidity;
  final DateTime createdAt;

  const Reading({
    this.soilMoisture,
    this.airTemp,
    this.airHumidity,
    required this.createdAt,
  });

  factory Reading.fromJson(Map<String, dynamic> j) => Reading(
        soilMoisture: _parseInt(j['soil_moisture']),
        airTemp: _parseDouble(j['air_temp']),
        airHumidity: _parseDouble(j['air_humidity']),
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '') ??
            DateTime.now(),
      );

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }
}
