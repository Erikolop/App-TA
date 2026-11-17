class WateringEvent {
  final int id;
  final int deviceId;
  final String trigger; // 'auto' | 'manual'
  final int durationS;
  final int? moistureBefore;
  final int? moistureAfter;
  final DateTime startedAt;
  final DateTime endedAt;

  // Joined from devices table
  final String deviceName;
  final String plant;

  const WateringEvent({
    required this.id,
    required this.deviceId,
    required this.trigger,
    required this.durationS,
    this.moistureBefore,
    this.moistureAfter,
    required this.startedAt,
    required this.endedAt,
    required this.deviceName,
    required this.plant,
  });

  factory WateringEvent.fromJson(Map<String, dynamic> j) => WateringEvent(
        id: j['id'] as int,
        deviceId: j['device_id'] as int,
        trigger: j['trigger'] as String? ?? 'auto',
        durationS: j['duration_s'] as int? ?? 0,
        moistureBefore: _parseInt(j['moisture_before']),
        moistureAfter: _parseInt(j['moisture_after']),
        startedAt: DateTime.tryParse(j['started_at'] as String? ?? '') ??
            DateTime.now(),
        endedAt:
            DateTime.tryParse(j['ended_at'] as String? ?? '') ?? DateTime.now(),
        deviceName: j['device_name'] as String? ?? '',
        plant: j['plant'] as String? ?? '',
      );

  String get durationLabel {
    if (durationS < 60) return '${durationS}s';
    final m = durationS ~/ 60;
    final s = durationS % 60;
    return s == 0 ? '${m}m' : '${m}m ${s}s';
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }
}
