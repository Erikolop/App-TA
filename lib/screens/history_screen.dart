import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../core/theme.dart';
import '../providers/device_provider.dart';
import '../models/device.dart';
import '../models/reading.dart';
import '../services/api_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int? _selectedDeviceId;
  int _hours = 24;
  List<Reading> _readings = [];
  bool _loading = false;
  bool _retrying = false;
  String? _error;
  final _api = ApiService();

  // Track whether we've kicked off the first load.
  bool _initialLoadDone = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Run once after the provider is available.
    if (!_initialLoadDone) {
      _initialLoadDone = true;
      final devices = context.read<DeviceProvider>().devices;
      if (devices.isNotEmpty) {
        _selectedDeviceId = devices.first.id;
        _load(_selectedDeviceId!);
      }
    }
  }

  Future<void> _load(int deviceId, {bool isRetry = false}) async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final r = await _api.fetchReadings(deviceId, hours: _hours);
      if (mounted) setState(() => _readings = r);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not load readings');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _retry() async {
    if (_selectedDeviceId == null) return;
    setState(() => _retrying = true);
    await _load(_selectedDeviceId!, isRetry: true);
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _retrying = false);
  }

  @override
  Widget build(BuildContext context) {
    // Watch for device list changes (new devices added) but don't reload.
    final devices = context.watch<DeviceProvider>().devices;

    // If devices arrived after the screen was built and we have none selected yet.
    if (_selectedDeviceId == null && devices.isNotEmpty) {
      _selectedDeviceId = devices.first.id;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load(_selectedDeviceId!);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(title: const Text('History')),
      body: devices.isEmpty
          ? const _EmptyDevices()
          : Column(children: [
              // Device selector
              _DeviceSelector(
                devices: devices,
                selectedId: _selectedDeviceId,
                onSelect: (id) {
                  if (id == _selectedDeviceId) return;
                  setState(() {
                    _selectedDeviceId = id;
                    _readings = [];
                    _error = null;
                  });
                  _load(id);
                },
              ),

              // Range chips
              _RangeChips(
                selected: _hours,
                onSelect: (h) {
                  if (h == _hours) return;
                  setState(() => _hours = h);
                  if (_selectedDeviceId != null) _load(_selectedDeviceId!);
                },
              ),

              // Chart area
              Expanded(
                child: _loading
                    ? _buildShimmer()
                    : _error != null
                        ? _buildError()
                        : _readings.isEmpty
                            ? const _EmptyReadings()
                            : _ChartView(readings: _readings),
              ),
            ]),
    );
  }

  Widget _buildShimmer() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Shimmer.fromColors(
        baseColor: AppColors.divider,
        highlightColor: AppColors.canvas,
        child: Column(children: [
          Container(height: 60, decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.cardBorderRadius)),
          const SizedBox(height: AppSpacing.sm),
          Expanded(child: Container(decoration: BoxDecoration(color: AppColors.surface, borderRadius: AppRadius.cardBorderRadius))),
        ]),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.show_chart, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: AppSpacing.base),
          Text(_error!, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.base),
          GestureDetector(
            onTap: _retrying ? null : _retry,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(999)),
              child: _retrying
                  ? const SizedBox(width: 16, height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Retry', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Device selector ───────────────────────────────────────────────────────

class _DeviceSelector extends StatelessWidget {
  final List<Device> devices;
  final int? selectedId;
  final ValueChanged<int> onSelect;

  const _DeviceSelector({required this.devices, required this.selectedId, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: 6),
        itemCount: devices.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final d = devices[i];
          final selected = d.id == selectedId;
          return GestureDetector(
            onTap: () => onSelect(d.id),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? AppColors.accent : AppColors.tabUnselected,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                d.name.isNotEmpty ? d.name : 'Device ${d.id}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.onAccent : AppColors.textSecondary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Range chips ───────────────────────────────────────────────────────────

class _RangeChips extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const _RangeChips({required this.selected, required this.onSelect});

  static const _options = [6, 24, 48, 168];
  static const _labels = ['6h', '24h', '48h', '7d'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.sm),
      child: Row(
        children: List.generate(_options.length, (i) {
          final active = selected == _options[i];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelect(_options[i]),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: active ? AppColors.accent : AppColors.tabUnselected,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _labels[i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: active ? AppColors.onAccent : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Chart view ────────────────────────────────────────────────────────────

class _ChartView extends StatelessWidget {
  final List<Reading> readings;
  const _ChartView({required this.readings});

  @override
  Widget build(BuildContext context) {
    final valid = readings.where((r) => r.soilMoisture != null).toList();
    if (valid.isEmpty) return const _EmptyReadings();

    final spots = valid.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.soilMoisture!.toDouble()))
        .toList();

    final fmt = DateFormat('HH:mm');
    final values = valid.map((r) => r.soilMoisture!).toList();
    final avg = (values.reduce((a, b) => a + b) / values.length).round();
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final interval = (valid.length / 4).ceilToDouble().clamp(1.0, 999.0);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.base),
      child: Column(children: [
        // Stats row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.cardBorderRadius,
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _Stat(label: 'Min', value: '$minV%'),
            Container(width: 1, height: 32, color: AppColors.divider),
            _Stat(label: 'Avg', value: '$avg%'),
            Container(width: 1, height: 32, color: AppColors.divider),
            _Stat(label: 'Max', value: '$maxV%'),
          ]),
        ),
        const SizedBox(height: AppSpacing.base),

        // Chart
        Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.base, AppSpacing.base, AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.cardBorderRadius,
              border: Border.all(color: AppColors.divider),
            ),
            child: LineChart(
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
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────

class _Stat extends StatelessWidget {
  final String label, value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ]);
  }
}

class _EmptyReadings extends StatelessWidget {
  const _EmptyReadings();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.show_chart, size: 48, color: AppColors.divider),
        const SizedBox(height: AppSpacing.base),
        Text('No readings in this range', style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}

class _EmptyDevices extends StatelessWidget {
  const _EmptyDevices();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.grass_outlined, size: 56, color: AppColors.divider),
        const SizedBox(height: AppSpacing.base),
        Text('No devices yet', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text('Add a device first to see its history.',
            style: Theme.of(context).textTheme.bodySmall),
      ]),
    );
  }
}
