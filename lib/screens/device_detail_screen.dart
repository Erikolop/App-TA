import 'dart:async';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
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
  bool _retryingDevice = false;
  bool _retryingReadings = false;
  Timer? _pollTimer;
  final _api = ApiService();

  @override
  void initState() {
    super.initState();
    _loadDevice();
    _loadReadings();
    _pollTimer = Timer.periodic(
        const Duration(seconds: 5), (_) => _loadDevice(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDevice({bool silent = false}) async {
    if (!silent && mounted) setState(() { _loadingDevice = true; _deviceError = false; });
    try {
      final d = await context.read<DeviceProvider>().fetchDevice(widget.deviceId);
      if (mounted) setState(() { _device = d; _deviceError = false; });
    } catch (_) {
      if (mounted && !silent) setState(() => _deviceError = true);
    } finally {
      if (mounted) setState(() => _loadingDevice = false);
    }
  }

  Future<void> _loadReadings() async {
    if (mounted) setState(() { _loadingReadings = true; _readingsError = false; });
    try {
      final r = await _api.fetchReadings(widget.deviceId, hours: 24);
      if (mounted) setState(() => _readings = r);
    } catch (_) {
      if (mounted) setState(() => _readingsError = true);
    } finally {
      if (mounted) setState(() => _loadingReadings = false);
    }
  }

  Future<void> _retryDevice() async {
    setState(() => _retryingDevice = true);
    await _loadDevice();
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _retryingDevice = false);
  }

  Future<void> _retryReadings() async {
    setState(() => _retryingReadings = true);
    await _loadReadings();
    if (mounted) setState(() => _retryingReadings = false);
  }

  Future<void> _onRefresh() =>
      Future.wait([_loadDevice(), _loadReadings()]);

  void _patch(Map<String, dynamic> changes) =>
      context.read<DeviceProvider>().updateDevice(widget.deviceId, changes);

  @override
  Widget build(BuildContext context) {
    // Keep device in sync with provider's optimistic updates.
    final providerDevice = context
        .watch<DeviceProvider>()
        .devices
        .where((d) => d.id == widget.deviceId)
        .firstOrNull;
    final device = providerDevice ?? _device;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: Text(device?.name ?? 'Device')),
      body: _loadingDevice && device == null
          ? _deviceError
              ? _buildDeviceError()
              : _buildShimmer()
          : _deviceError && device == null
              ? _buildDeviceError()
              : RefreshIndicator(
                  color: AppColors.accent,
                  onRefresh: _onRefresh,
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    children: [
                      if (device != null) ...[
                        _MoistureAirCard(device: device, onPatch: _patch),
                        const SizedBox(height: AppSpacing.sm),
                        _ModeCard(device: device, onPatch: _patch),
                        const SizedBox(height: AppSpacing.sm),
                        _ThresholdsCard(device: device, onPatch: _patch),
                        const SizedBox(height: AppSpacing.sm),
                        _ChartCard(
                          readings: _readings,
                          loading: _loadingReadings,
                          error: _readingsError,
                          retrying: _retryingReadings,
                          onRetry: _retryReadings,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _InfoCard(device: device),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.divider,
      highlightColor: AppColors.canvas,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.base),
        child: Column(children: [
          _shimmerBox(height: 140),
          const SizedBox(height: AppSpacing.sm),
          _shimmerBox(height: 100),
          const SizedBox(height: AppSpacing.sm),
          _shimmerBox(height: 120),
          const SizedBox(height: AppSpacing.sm),
          _shimmerBox(height: 220),
          const SizedBox(height: AppSpacing.sm),
          _shimmerBox(height: 180),
        ]),
      ),
    );
  }

  Widget _shimmerBox({required double height}) => Container(
    height: height,
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadius.cardBorderRadius,
    ),
  );

  Widget _buildDeviceError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off, size: 48, color: AppColors.textSecondary),
        const SizedBox(height: AppSpacing.base),
        const Text('Could not load device', style: TextStyle(fontSize: 15, color: AppColors.textPrimary)),
        const SizedBox(height: AppSpacing.base),
        _RetryButton(retrying: _retryingDevice, onTap: _retryDevice),
      ]),
    ),
  );
}

// ── Shared retry button ───────────────────────────────────────────────────

class _RetryButton extends StatelessWidget {
  final bool retrying;
  final VoidCallback onTap;
  const _RetryButton({required this.retrying, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: retrying ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: retrying
            ? const SizedBox(width: 16, height: 16,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Retry', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── Cards ─────────────────────────────────────────────────────────────────

class _MoistureAirCard extends StatelessWidget {
  final Device device;
  final void Function(Map<String, dynamic>) onPatch;
  const _MoistureAirCard({required this.device, required this.onPatch});

  @override
  Widget build(BuildContext context) {
    // manualPump = the command we sent (what the user set).
    // pumpOn     = physical state from the last ESP32 reading.
    // The toggle controls manualPump. pumpOn is display-only.
    final manualPump = device.manualPump;
    final pumpOn = device.pumpOn ?? false;
    final isManual = device.mode == 'manual';

    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            '${device.soilMoisture ?? '--'}',
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 6, left: 2),
            child: Text('%', style: TextStyle(fontSize: 20, color: AppColors.textSecondary)),
          ),
        ]),
        Text('Soil Moisture', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        if (device.airTemp != null || device.airHumidity != null) ...[
          const SizedBox(height: AppSpacing.md),
          Row(children: [
            if (device.airTemp != null) ...[
              Icon(Icons.thermostat_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text('${device.airTemp!.toStringAsFixed(1)}°C',
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
              const SizedBox(width: AppSpacing.md),
            ],
            if (device.airHumidity != null) ...[
              Icon(Icons.water_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text('${device.airHumidity!.toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
            ],
          ]),
        ],
        // Physical pump state indicator (read-only)
        if (pumpOn) ...[
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 7, height: 7, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.accent)),
              const SizedBox(width: 6),
              const Text('Pump running', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.accent)),
            ]),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        // Pump command toggle — controls manualPump, only active in manual mode
        Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Pump Switch', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            Text(
              isManual ? 'Tap to toggle' : 'Set mode to Manual first',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ]),
          const Spacer(),
          Text(
            manualPump ? 'ON' : 'OFF',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isManual
                  ? (manualPump ? AppColors.accent : AppColors.textSecondary)
                  : AppColors.divider,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isManual ? () => onPatch({'manual_pump': !manualPump}) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 52, height: 28,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isManual
                    ? (manualPump ? AppColors.accent : AppColors.tabUnselected)
                    : AppColors.divider,
                borderRadius: BorderRadius.circular(999),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 150),
                alignment: manualPump ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 22, height: 22,
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                ),
              ),
            ),
          ),
        ]),
      ]),
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Watering Mode',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: modes.map((m) {
            final selected = device.mode == m;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: m != modes.last ? 6 : 0),
                child: GestureDetector(
                  // onTap on GestureDetector is immediate — no delay
                  onTap: selected ? null : () => onPatch({'mode': m}),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.accent : AppColors.tabUnselected,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      m[0].toUpperCase() + m.substring(1),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ]),
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
  bool _dragging = false; // don't sync from server while user is dragging

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_ThresholdsCard old) {
    super.didUpdateWidget(old);
    // Only accept server values when the user is not touching the sliders.
    if (!_dragging) _sync();
  }

  void _sync() {
    _dry = widget.device.dryThreshold.toDouble().clamp(10.0, 89.0);
    _wet = widget.device.wetThreshold.toDouble().clamp(11.0, 90.0);
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Thresholds',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: AppSpacing.md),
        _SliderRow(
          label: 'Dry', value: _dry,
          min: 10, max: _wet - 1,
          onChanged: (v) => setState(() { _dragging = true; _dry = v; }),
          onChangeEnd: (v) { setState(() => _dragging = false); widget.onPatch({'dry_threshold': v.round()}); },
        ),
        const SizedBox(height: AppSpacing.sm),
        _SliderRow(
          label: 'Wet', value: _wet,
          min: _dry + 1, max: 90,
          onChanged: (v) => setState(() { _dragging = true; _wet = v; }),
          onChangeEnd: (v) { setState(() => _dragging = false); widget.onPatch({'wet_threshold': v.round()}); },
        ),
      ]),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label;
  final double value, min, max;
  final ValueChanged<double> onChanged, onChangeEnd;
  const _SliderRow({required this.label, required this.value, required this.min, required this.max, required this.onChanged, required this.onChangeEnd});

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(min, max);
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
          child: Slider(
            value: clamped,
            min: min, max: max,
            divisions: (max - min).round().clamp(1, 80),
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
      ),
      SizedBox(
        width: 40,
        child: Text('${clamped.round()}%',
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ),
    ]);
  }
}

class _ChartCard extends StatelessWidget {
  final List<Reading> readings;
  final bool loading, error, retrying;
  final VoidCallback onRetry;
  const _ChartCard({required this.readings, required this.loading, required this.error, required this.retrying, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('HH:mm');
    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Last 24 Hours',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 200,
          child: loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
              : error
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text('Could not load chart',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                        const SizedBox(height: AppSpacing.sm),
                        _RetryButton(retrying: retrying, onTap: onRetry),
                      ]),
                    )
                  : readings.isEmpty
                      ? Center(
                          child: Text('No readings yet',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 14)))
                      : _buildChart(fmt),
        ),
      ]),
    );
  }

  Widget _buildChart(DateFormat fmt) {
    // Filter out readings with null moisture
    final valid = readings.where((r) => r.soilMoisture != null).toList();
    if (valid.isEmpty) {
      return Center(child: Text('No moisture data', style: TextStyle(color: AppColors.textSecondary)));
    }

    final spots = valid.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.soilMoisture!.toDouble()))
        .toList();

    final interval = (valid.length / 4).ceilToDouble().clamp(1.0, 999.0);

    return LineChart(
      LineChartData(
        minY: 0, maxY: 100,
        clipData: const FlClipData.all(),
        gridData: FlGridData(
          show: true, drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppColors.divider, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true, reservedSize: 36, interval: 25,
              getTitlesWidget: (v, _) => Text('${v.toInt()}%',
                  style: const TextStyle(fontSize: 9, color: AppColors.textSecondary)),
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true, reservedSize: 24, interval: interval,
              getTitlesWidget: (v, _) {
                final idx = v.toInt();
                if (idx < 0 || idx >= valid.length) return const SizedBox.shrink();
                return Text(
                  fmt.format(valid[idx].createdAt.toLocal()),
                  style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true, color: AppColors.accent, barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true, color: AppColors.accent.withValues(alpha: 0.08)),
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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Device Info',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: AppSpacing.sm),
        _Row('HW ID', device.hwId),
        _Row('Last seen', fmt.format(device.lastSeen.toLocal())),
        _Row('Mode', device.mode),
        _Row('Dry threshold', '${device.dryThreshold}%'),
        _Row('Wet threshold', '${device.wetThreshold}%'),
        _Row('Max run', '${device.maxRunS}s'),
        _Row('Cooldown', '${device.cooldownMin}min'),
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
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
