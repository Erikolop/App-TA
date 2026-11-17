import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/device.dart';
import '../models/reading.dart';
import '../providers/device_provider.dart';
import '../services/api_service.dart';

class DeviceDetailScreen extends StatefulWidget {
  final int deviceId;
  const DeviceDetailScreen({super.key, required this.deviceId});

  @override
  State<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends State<DeviceDetailScreen> {
  Device? _device;
  List<Reading> _readings = [];
  bool _loadingDevice = true;
  bool _loadingReadings = true;
  bool _deviceError = false;
  bool _readingsError = false;
  Timer? _pollTimer;
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _loadDevice();
    _loadReadings();
    _pollTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _loadDevice());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDevice() async {
    try {
      final d = await context.read<DeviceProvider>().fetchDevice(widget.deviceId);
      if (mounted) setState(() { _device = d; _deviceError = false; });
    } catch (_) {
      if (mounted) setState(() => _deviceError = true);
    } finally {
      if (mounted) setState(() => _loadingDevice = false);
    }
  }

  Future<void> _loadReadings() async {
    setState(() { _loadingReadings = true; _readingsError = false; });
    try {
      final r = await _api.fetchReadings(widget.deviceId, hours: 24);
      if (mounted) setState(() => _readings = r);
    } catch (_) {
      if (mounted) setState(() => _readingsError = true);
    } finally {
      if (mounted) setState(() => _loadingReadings = false);
    }
  }

  Future<void> _onRefresh() =>
      Future.wait([_loadDevice(), _loadReadings()]);

  void _patch(Map<String, dynamic> changes) =>
      context.read<DeviceProvider>().updateDevice(widget.deviceId, changes);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(_device?.name ?? 'Device'),
      ),
      body: _loadingDevice && _device == null
          ? _deviceError
              ? _buildError()
              : _buildShimmer()
          : _deviceError && _device == null
              ? _buildError()
              : RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: _onRefresh,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm),
                    children: [
                      if (_device != null) ...[
                        _MoistureAirCard(
                            device: _device!, onPatch: _patch),
                        const SizedBox(height: AppSpacing.sm),
                        _ModeCard(device: _device!, onPatch: _patch),
                        const SizedBox(height: AppSpacing.sm),
                        _ThresholdsCard(device: _device!, onPatch: _patch),
                        const SizedBox(height: AppSpacing.sm),
                        _ChartCard(
                          readings: _readings,
                          loading: _loadingReadings,
                          error: _readingsError,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _InfoCard(device: _device!),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildShimmer() => ListView(
        padding: const EdgeInsets.all(AppSpacing.base),
        children: List.generate(
          4,
          (_) => Container(
            height: 120,
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: AppRadius.cardBorderRadius,
            ),
          ),
        ),
      );

  Widget _buildError() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.base),
            const Text('Failed to load device'),
            const SizedBox(height: AppSpacing.base),
            ElevatedButton(
              onPressed: () { setState(() { _loadingDevice = true; _deviceError = false; }); _loadDevice(); },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white, shape: const StadiumBorder()),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
}

// ── Cards ─────────────────────────────────────────────────────────────────

class _MoistureAirCard extends StatelessWidget {
  final Device device;
  final void Function(Map<String, dynamic>) onPatch;
  const _MoistureAirCard({required this.device, required this.onPatch});

  @override
  Widget build(BuildContext context) {
    final pump = device.pumpOn ?? false;
    final isManual = device.mode == 'manual';

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${device.soilMoisture ?? '--'}',
                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 2),
                child: Text('%', style: TextStyle(fontSize: 20, color: AppColors.textSecondary)),
              ),
            ],
          ),
          Text('Soil Moisture', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          if (device.airTemp != null || device.airHumidity != null) ...[
            const SizedBox(height: AppSpacing.md),
            Row(children: [
              if (device.airTemp != null) ...[
                Icon(Icons.thermostat_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('${device.airTemp!.toStringAsFixed(1)}°C', style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                const SizedBox(width: AppSpacing.md),
              ],
              if (device.airHumidity != null) ...[
                Icon(Icons.water_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text('${device.airHumidity!.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
              ],
            ]),
          ],
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Text('Pump', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
              const Spacer(),
              Text(
                pump ? 'ON' : 'OFF',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: pump ? AppColors.accent : AppColors.textSecondary),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: isManual ? () => onPatch({'manual_pump': !pump}) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 48, height: 26,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: pump ? AppColors.accent : AppColors.tabUnselected,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 150),
                    alignment: pump ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color: isManual ? Colors.white : Colors.white.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final Device device;
  final void Function(Map<String, dynamic>) onPatch;
  const _ModeCard({required this.device, required this.onPatch});

  @override
  Widget build(BuildContext context) {
    const modes = ['auto', 'manual', 'off'];
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Watering Mode', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: modes.map((m) {
              final selected = device.mode == m;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: m != modes.last ? 6 : 0),
                  child: GestureDetector(
                    onTap: () => onPatch({'mode': m}),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.accent : AppColors.tabUnselected,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        m[0].toUpperCase() + m.substring(1),
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.textSecondary),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ThresholdsCard extends StatefulWidget {
  final Device device;
  final void Function(Map<String, dynamic>) onPatch;
  const _ThresholdsCard({required this.device, required this.onPatch});

  @override
  State<_ThresholdsCard> createState() => _ThresholdsCardState();
}

class _ThresholdsCardState extends State<_ThresholdsCard> {
  late double _dry;
  late double _wet;

  @override
  void initState() {
    super.initState();
    _dry = widget.device.dryThreshold.toDouble().clamp(10, 89);
    _wet = widget.device.wetThreshold.toDouble().clamp(11, 90);
  }

  @override
  void didUpdateWidget(_ThresholdsCard old) {
    super.didUpdateWidget(old);
    _dry = widget.device.dryThreshold.toDouble().clamp(10, 89);
    _wet = widget.device.wetThreshold.toDouble().clamp(11, 90);
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thresholds', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.md),
          _SliderRow(
            label: 'Dry',
            value: _dry,
            min: 10, max: _wet - 1,
            onChanged: (v) => setState(() => _dry = v),
            onChangeEnd: (v) => widget.onPatch({'dry_threshold': v.round()}),
          ),
          const SizedBox(height: AppSpacing.sm),
          _SliderRow(
            label: 'Wet',
            value: _wet,
            min: _dry + 1, max: 90,
            onChanged: (v) => setState(() => _wet = v),
            onChangeEnd: (v) => widget.onPatch({'wet_threshold': v.round()}),
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;
  const _SliderRow({required this.label, required this.value, required this.min, required this.max, required this.onChanged, required this.onChangeEnd});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SizedBox(width: 36, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
      Expanded(
        child: SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.accent,
            thumbColor: AppColors.accent,
            inactiveTrackColor: AppColors.divider,
            overlayColor: AppColors.accent.withValues(alpha: 0.12),
          ),
          child: Slider(value: value.clamp(min, max), min: min, max: max, divisions: (max - min).round().clamp(1, 80), onChanged: onChanged, onChangeEnd: onChangeEnd),
        ),
      ),
      SizedBox(width: 40, child: Text('${value.round()}%', textAlign: TextAlign.end, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
    ]);
  }
}

class _ChartCard extends StatelessWidget {
  final List<Reading> readings;
  final bool loading;
  final bool error;
  const _ChartCard({required this.readings, required this.loading, required this.error});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('HH:mm');
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Last 24 Hours', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 180,
            child: loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                : error
                    ? Center(child: Text('Could not load chart', style: TextStyle(color: AppColors.textSecondary)))
                    : readings.isEmpty
                        ? Center(child: Text('No readings yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)))
                        : LineChart(LineChartData(
                            minY: 0, maxY: 100,
                            gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => FlLine(color: AppColors.divider, strokeWidth: 1)),
                            borderData: FlBorderData(show: false),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32, interval: 25, getTitlesWidget: (v, _) => Text('${v.toInt()}%', style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)))),
                              rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(sideTitles: SideTitles(
                                showTitles: true, reservedSize: 24,
                                interval: (readings.length / 4).ceilToDouble().clamp(1, 999),
                                getTitlesWidget: (v, _) {
                                  final idx = v.toInt();
                                  if (idx < 0 || idx >= readings.length) return const SizedBox.shrink();
                                  return Text(fmt.format(readings[idx].createdAt.toLocal()), style: const TextStyle(fontSize: 9, color: AppColors.textSecondary));
                                },
                              )),
                            ),
                            lineBarsData: [LineChartBarData(
                              spots: readings.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value.soilMoisture ?? 0).toDouble())).toList(),
                              isCurved: true, color: AppColors.accent, barWidth: 2,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(show: true, color: AppColors.accent.withValues(alpha: 0.08)),
                            )],
                          )),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Device device;
  const _InfoCard({required this.device});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM HH:mm');
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Device Info', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.sm),
          _Row('HW ID', device.hwId),
          _Row('Last seen', fmt.format(device.lastSeen.toLocal())),
          _Row('Mode', device.mode),
          _Row('Dry threshold', '${device.dryThreshold}%'),
          _Row('Wet threshold', '${device.wetThreshold}%'),
          _Row('Max run', '${device.maxRunS}s'),
          _Row('Cooldown', '${device.cooldownMin}min'),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Expanded(flex: 2, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
        Expanded(flex: 3, child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary), textAlign: TextAlign.end)),
      ]),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.base),
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardBorderRadius,
        border: Border.all(color: AppColors.divider),
      ),
      child: child,
    );
  }
}
