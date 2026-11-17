class Device {
  final int id;
  final String hwId;
  final String name;
  final String plant;
  final String mode; // 'auto' | 'manual' | 'off'
  final int dryThreshold;
  final int wetThreshold;
  final int maxRunS;
  final int cooldownMin;
  final bool manualPump;
  final DateTime lastSeen;

  // Latest reading fields (nullable — device may not have posted yet)
  final int? soilMoisture;
  final int? soilRaw;
  final double? airTemp;
  final double? airHumidity;
  final int? tankLevel;
  final bool? pumpOn;
  final DateTime? readingAt;

  const Device({
    required this.id,
    required this.hwId,
    required this.name,
    required this.plant,
    required this.mode,
    required this.dryThreshold,
    required this.wetThreshold,
    required this.maxRunS,
    required this.cooldownMin,
    required this.manualPump,
    required this.lastSeen,
    this.soilMoisture,
    this.soilRaw,
    this.airTemp,
    this.airHumidity,
    this.tankLevel,
    this.pumpOn,
    this.readingAt,
  });

  factory Device.fromJson(Map<String, dynamic> j) => Device(
        id: j['id'] as int,
        hwId: j['hw_id'] as String? ?? '',
        name: j['name'] as String? ?? '',
        plant: j['plant'] as String? ?? '',
        mode: j['mode'] as String? ?? 'auto',
        dryThreshold: j['dry_threshold'] as int? ?? 35,
        wetThreshold: j['wet_threshold'] as int? ?? 60,
        maxRunS: j['max_run_s'] as int? ?? 30,
        cooldownMin: j['cooldown_min'] as int? ?? 30,
        manualPump: j['manual_pump'] as bool? ?? false,
        lastSeen: j['last_seen'] != null
            ? DateTime.tryParse(j['last_seen'] as String) ?? DateTime.now()
            : DateTime.now(),
        soilMoisture: _parseInt(j['soil_moisture']),
        soilRaw: _parseInt(j['soil_raw']),
        airTemp: _parseDouble(j['air_temp']),
        airHumidity: _parseDouble(j['air_humidity']),
        tankLevel: _parseInt(j['tank_level']),
        pumpOn: j['pump_on'] as bool?,
        readingAt: j['reading_at'] != null
            ? DateTime.tryParse(j['reading_at'] as String)
            : null,
      );

  Device copyWith({
    String? mode,
    int? dryThreshold,
    int? wetThreshold,
    int? maxRunS,
    int? cooldownMin,
    bool? manualPump,
    bool? pumpOn,
  }) =>
      Device(
        id: id,
        hwId: hwId,
        name: name,
        plant: plant,
        mode: mode ?? this.mode,
        dryThreshold: dryThreshold ?? this.dryThreshold,
        wetThreshold: wetThreshold ?? this.wetThreshold,
        maxRunS: maxRunS ?? this.maxRunS,
        cooldownMin: cooldownMin ?? this.cooldownMin,
        manualPump: manualPump ?? this.manualPump,
        lastSeen: lastSeen,
        soilMoisture: soilMoisture,
        soilRaw: soilRaw,
        airTemp: airTemp,
        airHumidity: airHumidity,
        tankLevel: tankLevel,
        pumpOn: pumpOn ?? this.pumpOn,
        readingAt: readingAt,
      );

  /// True when the device posted a reading recently enough to be considered live.
  bool get isOnline =>
      readingAt != null &&
      DateTime.now().difference(readingAt!).inMinutes < 2;

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
